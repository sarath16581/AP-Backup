let genSimulationTimeout = null;
	let eventTracking = { };

	window.onload = () => initCTIMonitor();
	initCTIMonitor = () => {
		let cbMockActive = document.getElementById('mockActive');

		cbMockActive.checked = GenesysCTIUtils ? GenesysCTIUtils.mockActive : false;

		// For testing purposes: Recall mock parameters from localStorage
		let paramStr = localStorage.getItem('mockedParams') || '{ "customAttrib" : "customnValue" }';

		try {
			mockCtiParams = JSON.parse(paramStr);
		} catch { }

		let mockTxtElem = document.getElementById('mockTxt');

		if (mockTxtElem) {
			mockTxtElem.value = paramStr;
			mockUpdated(mockTxtElem);
		}

		sforce.console.addEventListener('genesys.connector.trackevent',
			(event) => updateEventTracker(JSON.parse(event.message))
		);
	};

	// /**
	//  * Visual representation in the UI of the incoming events and call state
	//  */
	updateEventTracker = function({ eventName, ctiEvent, detail}) {
		if (eventName === 'ConnectorAction') {
			return trackEvent({ detail });
		}

		// Restart timer upon incoming call's first inbound alert
		if (eventName === 'INTERACTION_EVENT' && ctiEvent.category === 'add') {
			eventTracking.start = new Date().getTime();
			const elem = document.querySelector('ul[id="process-list"]');
			elem.replaceChildren();
		}

		const titleCase = (str) => str?.charAt(0).toUpperCase() + str?.slice(1)?.toLowerCase();

		const stateByEvent = {
			'INTERACTION_CONNECTED' : 'Connected',
			'INTERACTION_DISCONNECTED' : 'Disconnected',
			'LOGGED_OUT' : 'Logged out',
			'ACW_REQUIRED' : 'Wrap up required',
			'ACW_COMPLETED' : 'Idle'
		};

		const newState = stateByEvent[eventName] || titleCase(ctiEvent.detail?.state);
		let ignoreEvent;

		if (newState && eventTracking.state !== newState) {
			eventTracking.state = newState;
			const elem = document.querySelector('input[name="txtState"]');
			elem.value = newState;
		} else if (newState) {
			ignoreEvent = true;
		}

		if (!ignoreEvent) {
			trackEvent({
				detail : {
					state : 'event',
					startTime : new Date().getTime(),
					eventName : newState || eventName
				}
			});
		}
	}

	/**
	 * When activated, this will display in the widget which events have been
	 * fired and which actions have started/completed/failed.
	 *
	 * The time indicates the duration in milliseconds after the first call alert event
	 **/
	trackEvent = (event) => {
		const { state, id, taskName, startTime, duration, eventName } = event.detail;
		const fmtTime = () => {
			// duration: separate seconds, msecs
			const seg = eventTracking?.start
				? GenesysCTIUtils.divmod(startTime - eventTracking.start, 1000).map(val => val < 0 || val === NaN ? 0 : val)
				: [0, 0];

			return [
				GenesysCTIUtils.leadingZeros(seg[0], 2), // 2 decimal places before decimal separator
				GenesysCTIUtils.leadingZeros(seg[1], 3), // 3 decimal places for msecs
			].join('.');
		}
		const addElement = (parentElem, nodeName, props, innerHTML) => {
			const newElem = document.createElement(nodeName);

			if (props) {
				Object.keys(props).forEach(name => newElem.setAttribute(name, props[name]))
			}

			if (innerHTML) {
				newElem.innerHTML = innerHTML;
			}

			parentElem.appendChild(newElem);
			newElem.scrollIntoViewIfNeeded();
		}

		try {
			if (state === 'start') {
				const containerElem = document.querySelector('ul[id="process-list"]');
				addElement(containerElem, 'li', { id : `proc-${id}`, stamp : fmtTime() }, taskName);
			} else if (eventName) {
				const containerElem = document.querySelector('ul[id="process-list"]');
				addElement(containerElem, 'li', { class : 'track-event', stamp : fmtTime(), id : `proc-${id}` }, eventName.toUpperCase());
			} else if (`${duration}`) {
				const listElem = document.querySelector(`li[id="proc-${id}"]`);
				if (listElem) {
					listElem.innerHTML = `${taskName} - ${duration} msec`;
					listElem.className = `state-${state}`;
				}
			}
		} catch(ex) {
			console.error(ex);
		}
	}

	/**
	 * Simulate incoming call by playing back previously captured events
	 *  - use mock CTI Interaction JSON to extend the INTERACTION_EVENT payload detail
	 **/
	runSimulation = () => {
		const outputElem = document.getElementById('eventTxt');
		const next = () => {
			if (!trackEvent.mockEvents?.length) {
				// ending the sequence as the last event has already been processed
				return;
			}

			// Add the original delay in between events
			genSimulationTimeout = setTimeout(() => {
				// Process the next event
				const event = trackEvent.mockEvents.shift();
				// Set inactive after last event
				trackEvent.mockActive = !!trackEvent.mockEvents.length;
				// Output current event
				outputElem.value = `LastEvent: ${event.eventName}`;

				// Pass the event to the CTI Event Handler
				sforce.console.fireEvent('genesys.connector.mockevent', JSON.stringify(event));

				// Kick off the next event
				if (trackEvent.mockEvents.length) {
					next();
				} else {
					genSimulationTimeout = null;
				}
			}, trackEvent.mockEvents[0].timeSinceLast || 500);
		};

		// Reset the sequence, even if it was already running
		trackEvent.mockEvents = [...GenesysCTIMock.mockEvents];
		trackEvent.interactionId = crypto.randomUUID();

		// Kick off the sequence, only if not already running
		if (genSimulationTimeout) {
			clearTimeout(genSimulationTimeout);
		}

		try {
			next();
		} catch(ex) {
			// Sequence has broken
			console.error(ex);
		}
	}

	/**
	 * Click Event handler for Test UI.
	 */
	handleClick = (event) => {
		const { name } = event.target;

		if (name === 'btnApply') {
			// Apply the mock data as provided in the UI
			const mockElem = document.getElementById('mockTxt');
			const { value, style } = mockElem;

			try {
				const mockCtiParams = JSON.parse(value);
				const pValue = JSON.stringify(mockCtiParams, undefined, 2);
				localStorage.setItem('mockedParams', pValue);
				style.border = 'blue 1px solid';
				mockElem.title = '';
				mockElem.value = pValue;
				GenesysCTIUtils.mockParams = pValue;
				// sforce.console.fireEvent('genesys.connector.applymocking', mockCtiParams);
				setTimeout(() => mockUpdated(mockElem), 150);
			} catch (ex) {
				mockElem.setAttribute('has-error', true);
				style.border = 'red 2px solid';
				mockElem.title = ex.message;
			}
		} else if (name === 'btnMock') {
			// Kick off the event simulation mimicking an actual inbound call (as captured in GenesysCTIMock.mockEvents)
			runSimulation();
		} else if (name ==='mockActive') {
			const elem = document.getElementById('mockActive');
			GenesysCTIUtils.mockActive = elem.checked;
		}
	}

	/**
	 * Support for dropping files in to the mock text area
	 */
	handleDrop = (event) => {
		const { dataTransfer } = event;
		// Prevent default behavior (Prevent file from being opened)
		event.preventDefault();

		const file = (dataTransfer.items)
			? [...dataTransfer.items].find(f => f.kind === "file")
			: [...dataTransfer.files].shift();

		if (file) {
			const mockElem = document.getElementById('mockTxt');
			const reader = new FileReader();
			reader.readAsText(file.getAsFile());
			reader.onloadend = () => {
				mockElem.value = reader.result;
				mockElem.setAttribute('has-error', false);
				mockUpdated(mockElem);
			}
			//setTimeout(() => handleClick({ target : { name : 'btnApply' } }), 100);
		}
	}

	/**
	 * Support for dropping files in to the mock text area
	 */
	handleDragOver = (event) => {
		// Prevent default behavior (Prevent file from being opened)
		event.preventDefault();
	}

	handleInput = (event) => {
		const mockElem = document.getElementById('mockTxt');
		mockElem.setAttribute('has-error', false);
		mockUpdated(event.target);
	}

	mockUpdated = (elemMockTxt) => {
		const input = elemMockTxt.value;
		const isChanged = input !== GenesysCTIUtils.getStorageProp('GenesysMonitor.MockParams', false);
		elemMockTxt.setAttribute('is-dirty', isChanged);
		const btnApply = document.getElementById('btnApply');

		if (btnApply) {
			// btnApply.disabled = !isChanged;
		}
	}