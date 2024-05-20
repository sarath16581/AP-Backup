/**
 * @description Genesys CTI Integration. This logic hooks up all the cti (and cti related) events
 *  and forward these to either the AP or ST connector, based on the interaction's ccDivision attribute value
 * @author Paul Perry
 * @date 2024-04-26
 * @changelog
 *
 */
	console.log('Genesys Connector Widget Integration: init');

	// Properties used for each interaction
	let businessLogic;
	let lastCtiInteractionLog = { };
	let ccDivision; // Either AP or ST

	// Properties used for testing and tracking
	let eventTracking = { };
	let mockCtiParams = { };
	let eventList = [ ];

	addCustomAttributesMethod = (id, attributes, callback) => {
		sforce.console.fireEvent(
			'inin.salesforce.constants.consoleevent.addCustomAttributes',
			JSON.stringify({ data: { id, attributes } }),
			callback ? callback : (data) => console.log(data)
		);
	}

	// create map for console interaction methods
	// - https://developer.salesforce.com/docs/atlas.en-us.api_console.meta/api_console/sforce_api_console_methods_tabs.htm
	const consoleMethods = {
		// tab related methods
		// Please refer to the documentation in order to provide the correct parameters for each console interaction method:
		closeTab : sforce.console.closeTab,
		disableTabClose : sforce.console.disableTabClose,
		focusPrimaryTabById : sforce.console.focusPrimaryTabById,
		generateConsoleUrl : sforce.console.generateConsoleUrl,

		// These don't work as this logic doesn't sit on the tab itself...
		getEnclosingPrimaryTabId : sforce.console.getEnclosingPrimaryTabId,
		getFocusedPrimaryTabId : sforce.console.getFocusedPrimaryTabId,
		getFocusedPrimaryTabObjectId : sforce.console.getFocusedPrimaryTabObjectId,
		getFocusedSubtabId : sforce.console.getFocusedSubtabId,
		getFocusedSubtabObjectId : sforce.console.getFocusedSubtabObjectId,
		getPageInfo : sforce.console.getPageInfo,
		getPrimaryTabIds : sforce.console.getPrimaryTabIds,
		openPrimaryTab : sforce.console.openPrimaryTab,
		getTabLink : sforce.console.getTabLink,
		// custom attributes -> update call interaction details
		setCustomAttributes : this.addCustomAttributesMethod
	}

	// Invoke a console event from the Business logic implementation class
	invokeConsoleEvent = (methodName, ...params) => {
		if (!consoleMethods[methodName]) {
			throw new Error(`Method not implememnted: ${methodName}`);
		}

		return consoleMethods[methodName](...params);
	}

	connectAllCtiEvents = () => {
		// Always turn off mocking onload:
		// GenesysCTIUtils.mockActive = false;

		const ALL_EVENTS = {
			// ALL CTI Events:
			'INTERACTION_CONNECTED' : 'inin.salesforce.constants.consoleevent.pc.INTERACTION_CONNECTED',
			'INTERACTION_DISCONNECTED' : 'inin.salesforce.constants.consoleevent.pc.INTERACTION_DISCONNECTED',
			'LOGGED_OUT' : 'inin.salesforce.constants.consoleevent.pc.LOGGED_OUT',
			'ACW_REQUIRED' : 'inin.salesforce.constants.consoleevent.pc.ACW_REQUIRED',
			'ACW_COMPLETED' : 'inin.salesforce.constants.consoleevent.pc.ACW_COMPLETED',
			'INTERACTION_EVENT' : 'inin.salesforce.constants.consoleevent.pc.INTERACTION_EVENT'
		};

		// Wireup all event handlers to CTI EventListener
		Object.keys(ALL_EVENTS).forEach(eventName => sforce.console.addEventListener(
			ALL_EVENTS[eventName], (event) => handleCtiEvent(eventName, event)
		));

		// Wireup tab focus change
		sforce.console.onFocusedPrimaryTab((event) => handleCtiEvent('PRIMTABFOCUS_CHANGE', event));
		sforce.console.onFocusedSubtab((event) => handleCtiEvent('SUBTABFOCUS_CHANGE', event));		

		// Wire up storage event to CTI Eventlistener
		// - Storage events are used for cross window / iframe communication
		window.addEventListener('storage', (event) => {
			if (event.key.startsWith('CTI_')) {
				// Provide event detail newValue and oldValue
				const detail = ['newValue', 'oldValue'].reduce(
					(res, item) => Object.assign(res, { [item] : GenesysCTIUtils.jsonToObj(event[item]) }), { }
				);
				// Provide array of changed attributes
				detail.changes = GenesysCTIUtils.getDiff(detail.newValue, detail.oldValue);
				handleCtiEvent('STORAGE', { detail, key : event.key });
			}
		});

		// Clearview codes
		['Complaint__c', 'Type', 'ProductCategory__c', 'ProductSubCategory__c', 'EnquirySubType__c'].forEach(
			field => sforce.console.addEventListener(
				`MiniCaseFieldSet_${field}`, (event) => handleCtiEvent('CLEARVIEWCODES', { field, event })
			)
		);

		sforce.console.addEventListener('CaseDetails_Refreshed', (caseId) => {
			handleCtiEvent('CASEUPDATE', caseId)
		});

		sforce.console.addEventListener('genesys.connector.mockevent', (event) => {
			const ctiEvent = JSON.parse(event.message);
			handleCtiEvent(ctiEvent.eventName, ctiEvent.message);
		});
	}

	// Which call centre logic do we need to handle calls? (AP / ST)
	// The below solution is based on the idea that Genesys provides an attribute called 
	// Participant.Division that would drive this logic to pick the correct handler class
	initialiseCallCentreHandlerInstance = (ctiEvent) => {
		this.ccDivision = ctiEvent.detail?.attributes?.['Participant.Division'];

		if (this.ccDivision === 'ST') {
			return new GenSTBusinessLogic();
		} else if (this.ccDivision === 'AP') {
			return new GenesysAPBusinessLogic(invokeConsoleEvent);
		} else {
			throw Error(`Missing/unknown value for Participant.Division attribute: "${this.ccDivision}"`);
		}
	}

	// Returns milliseconds since last invocation, used to track operation time
	timerLapse = () => {
		const stamp = new Date().getTime();

		if (!this._timer) {
			this._timer = stamp;
			return 0;
		} else {
			try {
				return stamp - this._timer;
			} finally {
				this._timer = stamp;
			}
		}
	}

	handleCtiEvent = (eventName, event) => {
		console.log(eventName, event);
		const result = GenesysCTIUtils.extractEventDetail(eventName, event);

		if (eventName === 'INTERACTION_EVENT') {
			// merge mocked interaction properties, if provided
			if (GenesysCTIUtils.mockActive) {
				result.detail = GenesysCTIUtils.deepCloneObj(result.detail, GenesysCTIUtils.mockParams);
			}

			lastCtiInteractionLog = result.detail;

			// TODO: Decide whether we need this on every call, or only the first one:
			if (result.category === 'add' /*&& !businessLogic*/) {
				// first CTI event for inbound call (category 'add') means wiring up the division specific CTI adapter logic
				businessLogic = initialiseCallCentreHandlerInstance(result);
			}
		} else if (eventName !== 'INTERACTION_EVENT') {
			if (eventName === 'INTERACTION_DISCONNECTED' && lastCtiInteractionLog) {
				// Stop incoming minicase updates from being processed when disconnected
				lastCtiInteractionLog.isConnected = false;
				lastCtiInteractionLog.state = 'DISCONNECTED';
			}

			// In case the event isn't an InteractionEvent containing the current Call Interaction details,
			// provide the last known object
			result.lastDetail = lastCtiInteractionLog;
		}

		// For tracking purposes only
		const trackedEvents = ['INTERACTION_CONNECTED', 'INTERACTION_DISCONNECTED', 'LOGGED_OUT', 'ACW_REQUIRED', 'ACW_COMPLETED', 'INTERACTION_EVENT'];
		if (trackedEvents.includes(eventName)) {
			eventList.push({
				...result,
				timeSinceLast : timerLapse()
			});
		}

		sforce.console.fireEvent('genesys.connector.trackevent', JSON.stringify({ eventName, ctiEvent : result }));

		// Pass the event onto the instance that handles the business logic
		if (businessLogic && (eventName !== 'INTERACTION_EVENT' || (result.category === 'add' || result.changes?.length))) {
			// Only invoke the handler if any cti attributes have actually changed or if not an interaction event
			businessLogic.handleCtiEvent(eventName, result);
		}
	}