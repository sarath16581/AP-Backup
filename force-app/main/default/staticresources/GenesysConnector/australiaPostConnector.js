/**
 * @description CTI Business logic for AP as part of Genesys CTI Integration
 * NOTE: This class is responsible for UI interactions (search/screenpopping) and activity tracking
 * @author Paul Perry
 * @date 2024-04-26
 * @changelog
 *
 */
class GenesysAPBusinessLogic {

	// required local variables:
	search = { };
	loggingEnabled = true;

	callLog;

	// Field mappings for cti event inbound: Genesys -> Salesforce
	// - Should contain names all call interaction attributes used within the business logic
	// - These mappings give us some meaningful names to work with
	apFieldMappings = {
		callUuid : 'userData.IWS_CallUuid',							// task capture
		caseId : 'userData.CaseID',									// search on case
		caseNumber : 'userData.CaseNumber',							// search on case
		caseUuid : 'userData.IW_CaseUid',							// task capture
		contactId : 'userData.ContactID',							// search on contact
		enquirySubType : 'userData.ENG_DimAttribute_1',				// minicase prefill
		enquiryType : 'userData.ENG_DimAttribute_2',				// minicase prefill
		id : 'id',													// used to uniquely identify the call interaction
		mediaType : 'userData.mediaType',							// task capture (subject),
		outcome : 'userData.BusinessResultDisplay',					// task
		participantId : 'attributes.Salesforce\\.ParticipantId',	// task unique Id
		phoneNumber : 'userData.PhoneNumber',						// phone number exposure
		productCategory : 'userData.r_IWS_ServiceType',				// minicase prefill
		productSubCategory : 'userData.r_IWS_ServiceSubType',		// minicase prefill
		queue : 'userData.IWS_DNIS',								// task
		referenceId : 'userData.UData_sstrackingid',				// minicase prefill
		serviceType : 'userData.r_IWS_ServiceType',					// minicase prefill
		segment : 'userData.r_IWS_CustomerSegment',					// task
		targetSkill : 'userData.RRequestedSkillCombination',		// task
		trackingNumber : 'userData.UData_sstrackingid',				// search on case
	};

	// Field mappings for updating the Genesys interaction log outbound: Salesforce -> Genesys
	genesysFieldMappings = {
		caseId : 'attributes.Salesforce\\.CaseId',
		contactId : 'attributes.Salesforce\\.ContactId',
		userId : 'attributes.Salesforce\\.SF_UserId',
		enquiryType : 'attributes.Salesforce\\.ENG_Outcome_4',
		enquirySubType : 'attributes.Salesforce\\.ENG_Outcome_1',
		productCategory : 'attributes.Salesforce\\.ENG_Outcome_2',
		productSubCategory : 'attributes.Salesforce\\.ENG_Outcome_3'
	}

	TRACKTYPES = {
		'500' : 'case',
		'001' : 'contact',
		'003' : 'contact'
	};

	constructor(callback) {
		UIInteraction.tabInteractionEvents = callback;
	}

	handleCtiEvent(eventName, event) {
		if (eventName === 'INTERACTION_EVENT') {
			
			this.callLog = new CallInteractionProxy(event.detail, this.apFieldMappings);
			// Manually overwrite this until we're getting the correct parameter input from Genesys
			// - Inbound => voiceInbound, Outbound => vouceOutbound
			this.callLog.mediaType = `voice${event.detail.direction}`;

			if (event.category === 'add') {
				// This is the very first event of every Interaction
				event.callLog = this.callLog;

				if (event.detail.isConnected) {
					this.tracking = GenesysCTIUtils.recallCallDetails(event.callLog.id);

					if (this.tracking) {
						console.log(...UIInteraction.logPrefix, 'Session recovered', this.tracking);
					}
				}

				console.log(...UIInteraction.logPrefix, 'All relevant props for this cti connector:', this.callLog?.toObject());
			}
		}

		console.log(...UIInteraction.logPrefix, eventName, event);

		// Get a list of all actions that should be executed for this current event
		const actionList = this.nextActions.filter(ac => ac.criteria(eventName, event));

		// Execute all related tasks, if any
		if (actionList && actionList.length) {
			const processes = actionList.reduce((res, action) => res.concat(
				action.tasks.map(task => {
					const proc = task.call(this, event);

					// Track the task in the UI, for testing/troubleshooting only
					this.monitorTask(task, proc);

					return proc;
				})
			), []);

			// Error handling and logging for all processes
			Promise.all(processes).then(
				() => console.log(...UIInteraction.logPrefix, `Completed action(s): ${actionList.map(ac => ac.name).join(', ')}`))
			.catch(
				err => console.error(err)
			);
		}
	}

	// All core CTI actions
	actions = {
		/**
		 * Responsible for closing all currently open console tabs
		 * @returns promise
		 */
		closeAllTabs : () => {
			// Skip this if user has custom permission assigned
			if (genCtiPermissions.maintainWindowState) {
				// Get focussed tabId
				const getFocussedTabId = UIInteraction.getFocusedPrimaryTabId();
				// Capture current tabId
				getFocussedTabId.then((tabId => this.landingTabId = tabId));
				// return promise for task completion
				return getFocussedTabId;
			}

			const closeAllTabs = new AsyncTask();

			// fetch all primary tabs
			UIInteraction.getPrimaryTabIds().then(
				(tabIds) => Promise.all(tabIds.map(
					// close each of all primary tabs
					tabId => new Promise(
						(callback) => UIInteraction.tabInteractionEvents('closeTab', tabId, callback)
					)
				)).then(res => closeAllTabs.complete(res))
			).catch(error => closeAllTabs.fail(error));

			return closeAllTabs.promise;
		},

		/**
		 * Performing a search on cti event details
		 * @returns promise
		 */
		search : () => {
			// Ensure we're not starting another search while searching
			if (this.searchTask && this.searchTask?.status !== 'failed') {
				// Task is either 'pending' or 'completed', return existing task
				return promise.resolve(this.searchTask.promise);
			}

			// Give dependant action screenpop a promise to hookup to
			this.searchTask = new AsyncTask();

			// obtain search parameters
			const { caseId, caseNumber, trackingNumber, contactId, phoneNumber } = this.callLog;

			// start backend search
			new Promise(callback => GenesysConnectorController.searchAP(
				// serialise the input to avoid issues in the apex backend controller
				JSON.stringify({ caseId, caseNumber, trackingNumber, contactId, phoneNumber }),
				callback
			)).then((result, event) => {
				if (result) {
					// resolve results (and therefor status -> 'completed')
					this.searchTask.complete(result);
				} else {
					// error in apex backend controller
					this.searchTask.fail(event);
				}
			}).catch(
				// any other unexpected error
				(error) => this.searchTask.fail(error)
			);

			return this.searchTask.promise;
		},

		/**
		 * Responsible for popping the correct screen once search has been completed
		 * @returns promise
		 */
		screenPop : (ctiEvent) => {
			const screenPop = new AsyncTask();

			let searchTask = this.searchTask?.promise;
			if (!searchTask) {
				// Kick off search, if search hasn't started/completed yet
				const task = this.actions.search;
				searchTask = task.call(this);
				this.monitorTask(task, searchTask);
			}

			// wait for search to complete first, if not already completed
			Promise.resolve(searchTask).then(searchResults => {
				const popTabDetail = this.getPopScreenTabDetail(searchResults, ctiEvent);

				if (popTabDetail) {
					const { url, title, tabName } = popTabDetail;

					UIInteraction.openTabByUrl(url, title, tabName).then((result) => {
						this.landingTabId = result.tabId;

						if (result.isExistingTab) {
							// Kick off syncMiniCaseFields for existing tab
							const task = this.actions.syncMiniCaseFields;
							// Track the task in the UI, for testing/troubleshooting only
							this.monitorTask(task, task.call(this));
						}

						return screenPop.complete(result.tabId);
					}).catch(err => screenPop.fail(err));
				} else {
					screenPop.fail('Screenpop details not found');
				}
			});

			return screenPop.promise;
		},

		/**
		 * Responsible for tracking user interactions (on screenpop and user navigation/record creation):
		 * - maintaining Genesys calls interaction object
		 * - maintaining call task in SF
		 * - logic for soft/hard linking case/contact references
		 * @returns promise
		 */
		track : (event) => {
			this.trackingTask = new AsyncTask();
			
			console.log(...UIInteraction.logPrefix, 'Track', event);
			const ctiEventDetail = event.lastDetail || event.detail || { };

			// Sync local attribute values to Genesys Call Log
			const pushGenesysAttributes = (syncAttribs) => {				
				// Map local names to Genesys Attribute Names:
				const syncToGenesysPromise = this.actions.updateGenesysInteraction.call(this, syncAttribs);
				this.monitorTask(this.actions.updateGenesysInteraction, syncToGenesysPromise);

				// Capture these values on the salesforce task as well
				[ 'enquiryType', 'enquirySubType', 'productCategory', 'productSubCategory' ].filter(
					key => syncAttribs.hasOwnProperty(key) && ![undefined, null].includes(syncAttribs[key])
				).forEach(
					key => this.tracking[key] = syncAttribs[key]
				)
				
				return syncToGenesysPromise;
			}

			/**
			 * Captures the current tracking references into browser cache to enable session recovery
			 * @param {*} searchResults as returned by search operation
			 */
			const updateTrackingRecovery = () => {
				const storageAttributeNames = ['Id', 'isLocked'];
				const tracking = ['case','contact','task'].reduce((trackedObjects, objName) => {
					if (this.tracking[objName]) {
						 trackedObjects = Object.assign(trackedObjects, {
							[objName] : storageAttributeNames.filter(
								prop => this.tracking[objName].hasOwnProperty(prop)
							).reduce(
								(res, prop) => Object.assign(res, { [prop] : this.tracking[objName][prop] }),
								{ }
							)
						 });
					}

					return trackedObjects;
				}, { });
				// Capture in local storage for session recovery
				GenesysCTIUtils.storeCallDetails(ctiEventDetail.id, tracking);
			};

			/**
			 * Processes the tab event and apply soft/hard linking
			 * @param {*} searchResults as returned by search operation
			 */
			const linkTabEventDetails = () => {
				const prefix = event.objectId?.slice(0,3);
				const tabEvents = ['PRIMTABFOCUS_CHANGE','SUBTABFOCUS_CHANGE'];
				if (tabEvents.includes(event.eventName) && this.TRACKTYPES[prefix]) {
					if (!this.tracking) {
						this.tracking = { };
					}

					if (!this.tracking[this.TRACKTYPES[prefix]]?.isLocked) {
						this.tracking[this.TRACKTYPES[prefix]] = {
							Id : event.objectId
						};

						updateTrackingRecovery();
					}
				}
			};

			/**
			 * Processes the search results and apply soft/hard linking
			 * @param {*} searchResults as returned by search operation
			 */
			const linkSearchResults = (searchResults) => {
				// hardlink the case, if single match on below case fields
				const singleMatchCaseFields = ['caseId', 'trackingNumber', 'caseNumber'];

				if (searchResults.Case?.length == 1 && singleMatchCaseFields.includes(searchResults.match)) {
					const hardLinkCase = !!searchResults.Case?.[0]?.Id
					// hardlink the caseId to the interaction when single match on caseId or trackingNumber
					this.tracking.case = {
						Id : searchResults.Case?.[0]?.Id,
						Name : searchResults.Case?.[0]?.CaseNumber,
						isLocked : !!searchResults.Case?.[0]?.Id,
						matchField : searchResults.match
					};

					// Don't replace an existing contact Id if a tab change caused it to get populated
					if (!this.tracking.contact?.Id && !this.tracking.contact?.isLocked) {
						this.tracking.contact = {
							Id : searchResults.Case[0]?.ContactId,
							Name : searchResults.Case[0]?.Contact?.Name
						};
					}

					// hardlink case related contact for single case match on caseNumber, trackingNumber and caseId
					if (['caseNumber','trackingNumber','caseId'].includes(this.tracking.case?.matchField)) {
						this.tracking.contact = {
							Id : searchResults.Case[0].ContactId,
							Name : searchResults.Case[0].Contact?.Name,
							isLocked : true
						};
					}
				} else if (searchResults.Contact?.length == 1) {
					if (!this.tracking.contact?.Id || searchResults.match === 'contactId') {
						const contact = searchResults.Contact[0];
						const contactId = (contact.Account?.IsPersonAccount ? contact.AccountId : contact.Id)?.slice(0,15)

						this.tracking.contact = {
							Id : contactId,
							Name : contact.Name,
							isLocked : searchResults.match === 'contactId'
						};
					}
				}

				updateTrackingRecovery();

				return {
					contactId : this.tracking.contact?.Id,
					caseId : this.tracking.case?.Id
				};
			};

			const fetchCaseAndTrackDetails = () => {
				// fetch the case details from Salesforce
				const asyncTask = this.actions.fetchCaseDetails.call(this);

				// Track the task in the UI, for testing/troubleshooting only
				this.monitorTask(this.actions.fetchCaseDetails, asyncTask);

				// once completed, process details and sync to 
				asyncTask.then(caseDetails => {
					let {  caseId, contactId, enquirySubType, enquiryType, productCategory, productSubCategory } = caseDetails;
					
					if (this.tracking?.case.isLocked) {
						// lock contact as well
						this.tracking.contact = {
							Id : contactId,
							isLocked : true
						}
					} else if (!this.tracking.contact?.isLocked) {
						this.tracking.contact = {
							Id : contactId
						}
					} else {
						// If contact was already locked, maintain contactId
						contactId = this.tracking.contact.Id;
					}

					const syncAttribs = {
						caseId, contactId, enquirySubType, enquiryType, productCategory, productSubCategory
					};

					pushGenesysAttributes(syncAttribs).then(
						result => this.trackingTask.complete(result)
					);
				}).catch(err => this.trackingTask.fail(err));
			}

			if ('CASEUPDATE' === event.eventName) {
				const updatedCaseId = event.message;
				// only fetch details if the updated case is the one we're currently tracking
				if (this.tracking?.case?.Id?.startsWith(updatedCaseId)) {
					// fetch the case details from Salesforce
					fetchCaseAndTrackDetails();
				}
			} else if (['PRIMTABFOCUS_CHANGE','SUBTABFOCUS_CHANGE'].includes(event.eventName)) {
				// This can be inbound as well as outbound
				linkTabEventDetails();
				// Obtain case details and sync caseId or contactId to Genesys
				if (this.tracking.case?.Id) {
					fetchCaseAndTrackDetails();
				} else {
					this.trackingTask.complete();
				}
			} else if (ctiEventDetail.direction === 'Inbound') {
				const searchTask = this.searchTask?.promise;
				// Ignore tracking when not in a call
				if (!this.tracking && ctiEventDetail.isConnected && searchTask) {
					
					const { enquiryType, enquirySubType, productCategory, productSubCategory } = this.callLog;
					// Init tracking object, used for task and genesys interaction log
					this.tracking = { enquiryType, enquirySubType, productCategory, productSubCategory };
					
					Promise.resolve(searchTask).then(searchResults => {
						// Capture search results and perform soft/hard linking
						const trackingAttribs = linkSearchResults(searchResults);
						trackingAttribs.userId = searchTask.userId;
						
						// Sync caseId and contactId to Genesys
						const promise = pushGenesysAttributes(trackingAttribs);

						// Fetch additional case details
						if (this.tracking.case?.Id) {
							return fetchCaseAndTrackDetails();
						}
						
						promise
							.then(result => this.trackingTask.complete(result))
							.catch(err => this.trackingTask.fail(err));
					}).catch(err => this.trackingTask.fail(err));
				} else {
					this.trackingTask.complete();
				}
			} else if (ctiEventDetail.direction === 'Outbound') {
				// get object Ids from both primary tab and sub tab for linking
				Promise.all([
					UIInteraction.getFocusedPrimaryTabObjectId(),
					UIInteraction.getFocusedSubtabObjectId()
				]).then(objectIds => {
					[...new Set(objectIds || [])].forEach(objectId => {
						const objType = this.TRACKTYPES[objectId?.substr(0, 3)];
						
						if (!this.tracking) {
							this.tracking = { }
						};

						if (objType) {
							this.tracking[objType] = {
								Id : GenesysCTIUtils.caseSafeId(objectId),
								isLocked : true
							};

							if (objType === 'case') {
								return fetchCaseAndTrackDetails();
							}
						}
					})

					this.trackingTask.complete();
				});
			}
			
			return this.trackingTask.promise;
		},

		/**
		 * Responsible for synchronising clearview codes into the mini case form
		 * @returns promise
		 */
		syncMiniCaseFields : () => new Promise((res) => {
			// Attempt to populate minicase field values
			const { enquiryType, enquirySubType, productCategory, productSubCategory, referenceId } = this.callLog;
			const caseSyncOrder = [ 'Type', 'ProductCategory__c', 'Type_and_Product__c', 'ProductSubCategory__c', 'EnquirySubType__c', 'ReferenceID__c'];
			const caseValues = {
				Type: enquiryType,
				EnquirySubType__c: enquirySubType,
				ProductCategory__c: productCategory,
				ProductSubCategory__c: productSubCategory,
				ReferenceID__c : referenceId
			};

			caseSyncOrder.filter(
				field => caseValues[field] !== undefined
			).forEach(
				(field) => sforce.console.fireEvent(`MiniCaseFieldSet_${field}`, caseValues[field] || '')
			);

			res();
		}),

		/**
		 * Responsible for clearing out clearview code values on the mini case form
		 * @returns promise
		 */
		clearMiniCaseFields : () => Promise.resolve(sforce.console.fireEvent('RequestValues', 'clear')),

		/**
		 * Responsible for cleaning up variables and localStorage, ready for the next call
		 * @returns promise
		 */
		wrapUp : () => {
			// clean up for next interaction
			console.log(...UIInteraction.logPrefix, 'Tracking:', this.tracking);
			this.tracking = null;
			this.searchTask = null;
			// Remove call details from local storage -> session recovery not required after this point in time
			GenesysCTIUtils.deleteCallDetails(this.callLog.id);

			return Promise.resolve();
		},

		logTask : (ctiEvent) => {
			const mediaTypeMap = {
				voiceInbound : 'Voice-Inbound',
				voiceInternal : 'Voice-Internal',
				voiceOutbound : 'Voice-Outbound'
			};

			const eventDetail = ctiEvent.detail || ctiEvent.lastDetail;
			const { enquiryType, enquirySubType, productCategory, productSubCategory } = this.tracking || { };

			const getTaskDetail = () => ({
				contactId : this.tracking.contact?.Id,
				caseId : this.tracking.case?.Id,
				disposition : undefined,
				durationInSeconds : (new Date().getTime() - new Date(eventDetail.connectedTime).getTime()) % 1000,
				// Unique ID for task is a combination of the callId + participantId
				interactionId : [ this.callLog.id, this.callLog.participantId ].join('.'),
				status : eventDetail.isConnected ? 'Open' : 'Completed',
				// Subject: "Voice-Inbound YYYY-MM-DD 24:mm:ss"
				subject : [ mediaTypeMap[this.callLog.mediaType], GenesysCTIUtils.formatDate(new Date()) ].join(' '),
				// provide tracked attributes
				enquiryType, enquirySubType, productCategory, productSubCategory
			});

			// Prevent updating the task when it hasn't completed initial creation
			const pendingTask = this.captureTask;
			this.captureTask = new AsyncTask();

			const processTaskUpsert = () => {
				new Promise(callback => {
					GenesysConnectorController.maintainTaskAP(
						// serialise the input to avoid issues in the apex backend controller
						JSON.stringify(this.callLog.toObject()),
						JSON.stringify(getTaskDetail()),
						eventDetail.isConnected ? null : JSON.stringify(eventDetail),
						callback
					)
				}).then((result, event) => {
					if (result?.success) {
						// resolve results (and therefor status -> 'completed')
						this.captureTask.complete(result);
					} else {
						// error in apex backend controller
						this.captureTask.fail(event);
					}
				}).catch(
					// any other unexpected error
					(error) => this.captureTask.fail(error)
				);
			};

			if (this.trackingTask?.status === 'completed' && pendingTask?.status !== 'pending') {
				// start backend search immediately
				processTaskUpsert();
			} else {
				// Await the first track action to complete to include ContactId and CaseId
				// Kick off regardles of outcome resolved/failed
				Promise.allSettled([
					this.trackingTask?.promise || Promise.resolve(),
					pendingTask?.promise || Promise.resolve()
				]).then(
					// start backend search once tracking completed
					() => processTaskUpsert()
				);
			}

			return this.captureTask.promise;
		},

		fetchCaseDetails : () => {
			const fetchCaseTask = new AsyncTask();
			
			new Promise(callback => {
				GenesysConnectorController.getCaseByIdAP(
					this.tracking.case.Id,
					callback
				)
			}).then((result) => {
				if (!result) {
					throw new Error('Case coudn\'t be obtained');
				}

				fetchCaseTask.complete(result);
			}).catch(
				// any other unexpected error
				(error) => fetchCaseTask.fail(error)
			);

			return fetchCaseTask.promise;
		},

		updateGenesysInteraction : (syncAttribs) => new Promise(res => {
			const genesysCustomAttribs = Object.keys(this.genesysFieldMappings).reduce(
				(res,key) => {
					// Only add attributes, don't remove or overwrite with empty values
					if (syncAttribs.hasOwnProperty(key) && ![null, undefined].includes(syncAttribs[key])) {
						GenesysCTIUtils.setObjProp(res, this.genesysFieldMappings[key], syncAttribs[key]);
					}

					return res;
				}, { }
			);

			if (Object.keys(genesysCustomAttribs).length) {					
				consoleMethods.setCustomAttributes(
					this.callLog.id, genesysCustomAttribs,
					(result) => res(result)
				);
			} else {
				// no action required
				res();
			}
		})
	}

	/**
	 * Next Actions is an array of a combination of action name, criteria and task[]. It can
	 * be used to drive the next set tasks requiring to be executed.
	 *
	 * @params {*} (object[])
	 * @params {obj.name} (string):			Descriptive name of action see what/when is happening
	 * @params {obj.criteria} (function):   Function that matches the current ctiEvent criteria in order to qualify for the tasks to be executed
	 * @params {obj.tasks} (function[]):	Array of actions (methods) returning a promise upon completion
	 **/
	nextActions = [
		{
			// Search will be triggered on state == 'ALERTING' when search != 'pending' OR search != 'completed'
			name : 'onalert',
			criteria : (eventName, event) =>
				eventName === 'INTERACTION_EVENT' && !this.searchTask?.status
				&& (!event.changes || event.changes?.includes('state'))
				&& event.detail?.state === 'ALERTING'
				&& event.detail?.direction === 'Inbound',
			tasks : [ this.actions.search ]
		}, {
			// Will get invoked once when call gets connected (= just once on every call), Inbound only
			name : 'onInboundCallAnswered',
			criteria : (eventName, event) => eventName === 'INTERACTION_EVENT'
				&& event.changes?.includes('isConnected')
				&& event.detail?.isConnected
				&& event.detail?.direction === 'Inbound',
			tasks : [ this.actions.closeAllTabs, this.actions.screenPop, this.actions.track, this.actions.logTask ]
		}, {
			name : 'onOutboundCallAnswered',
			criteria : (eventName, event) => {
				return eventName === 'INTERACTION_EVENT'
					&& event.changes?.includes('isConnected')
					&& event.detail?.isConnected
					&& event.detail?.direction === 'Outbound'
			},
			tasks : [ this.actions.track, this.actions.logTask ]
		},
		{
			// Whenever a localStorage event gets captured with a key starting with CTI_[tabId]
			name : 'onStorage',
			criteria : (eventName, event) =>
				eventName === 'STORAGE'
				&& event.key === `CTI_${this.landingTabId}`
				&& event.lastDetail?.isConnected,
			tasks : [ this.actions.syncMiniCaseFields ]
		}, {
			// When user is navigating to different tabs/subtabs and case and object are not both hard-linked
			name : 'onTrackUpdate',
			criteria : (eventName, event) => (
				// original criteria
				(event.lastDetail || event.detail)?.isConnected
				&& ('CASEUPDATE' === eventName) || (
					['PRIMTABFOCUS_CHANGE','SUBTABFOCUS_CHANGE'].includes(eventName)
					&& ['case','contact'].find(obj => !this.tracking?.[obj]?.isLocked)
				)
			
			),
			tasks : [ this.actions.track ]
		}, {
			name : 'onDisconnect',
			criteria : (eventName) => eventName === 'INTERACTION_DISCONNECTED',
			tasks : [ this.actions.logTask ]
		}, {
			// Call has disconnected, cleanup for the next interaction
			name : 'onWrapUp',
			criteria : (eventName, event) => eventName === 'ACW_COMPLETED',
			tasks : [ this.actions.wrapUp ]
		}
	];

	getPopScreenTabDetail(searchResults, ctiEvent) {
		// pop screen order priority:
		// - (1) single case match (caseId, tracking / casenumber): pop case
		// - (2) single contact match (contactId, phone number): pop contact
		// - (3) case number typo: pop Case search
		// - (4) no record match: pop search screens, prefill values, etc.
		const popScreens = [
			// 1. Obtain Case matches from search results
			() => {
				if (searchResults.Case?.length == 1) {
					return searchResults.Case
						.map(obj => ({ ...obj, Id : obj.Id?.slice(0,15) }))
						.map(record => ({
							url : `/${record.Id}`,
							title : record.CaseNumber,
							recordId : record.Id
						})).shift();
				}
			},
			// 2. Obtain Contact matchtes from search results
			() => {
				if (searchResults.Contact?.length == 1) {
					return searchResults.Contact
						// ensure to use AccountId instead of ContactId if present
						.map(obj => ({
							...obj,
							Id : (obj.Account?.IsPersonAccount ? obj.AccountId : obj.Id)?.slice(0,15)
						})).map(record => ({
							url : `/${record.Id}`,
							title : record.Name,
							recordId : record.Id
						})).shift();
				}
			},
			// 3. Case number provided without match, scenario for typo
			() => {
				if ((ctiEvent.detail || ctiEvent.lastDetail)?.userData?.CaseNumber) {
					return {
						url : `/apex/CRMCaseSearch?id=${ctiEvent.lastDetail.id}&caseNumber=${ctiEvent.lastDetail.userData.CaseNumber}`,
						title : 'Case search',
						tabName : 'Case search'
					};
				}
			},
			// 4. Pop search screen with pre-populated values (phoneNumber)
			() => {
				const { phoneNumber } = this.callLog;

				let title = 'MyCustomers Search';
				let tabName = 'ctissswsearch';
				let url = `/apex/SSSWSearch?cti=1&aId=null`;

				if (phoneNumber) {
					if(!GenesysCTIUtils.isAnonymousPhoneNumber(phoneNumber)) {
						url += `&ANI=${phoneNumber}`;
						tabName += phoneNumber;
						title += ' - ' + phoneNumber;
					}
				}

				return { url, title, tabName };
			}
		];

		// Find the first matching screenpop in order of match priority
		let result;
		popScreens.find((popScreen) => {
			result = popScreen.call(this);
			return result;
		});

		return result;
	}

	// For tracking purposes only. Will fire a 'genesys.connector.trackevent' to notify the Genesys Monitor widget
	monitorTask(task, proc) {
		if (!this.loggingEnabled) {
			return;
		}

		// Log start.end time
		const startTime = GenesysCTIUtils.timeStamp();
		// Unique id to update completed tasks in the UI
		const id = crypto.randomUUID();
		// Display Name
		const taskName = Object.keys(this.actions).find(
			ac => this.actions[ac] == task
		);

		// Notify parent (widget) page with the event details
		const fireEvent = (state) => {
			const duration = GenesysCTIUtils.timeStamp() - startTime;
			const detail = Object.assign(
				{ id, taskName, state, startTime },
				state !== 'start' ? { duration } : null
			);

			if (taskName) {
				console.log(...UIInteraction.logPrefix, `Task ${taskName}: ${state}`);
			}

			sforce.console.fireEvent(
				'genesys.connector.trackevent',
				JSON.stringify({ eventName : 'ConnectorAction', detail })
			);
		}

		fireEvent('start');

		Promise.resolve(proc).then(
			() => fireEvent('success')
		).catch(
			() => fireEvent('error')
		);
	}
}

/**
 * @description Interaction related utility methods.
 * This is used for console tab interactions
 */
class UIInteraction {
	static tabInteractionEvents;

	/**
	 * Get the current set of primary tabs from the salesforce console app
	 * @returns Promise [{ tabId : "console tab identifier", success : true/false, url : "/003AD00000MAqTp"  }]
	 */
	static getCurrentTabSet = () => {
		// 1. get all primary tab ids
		// 2. obtain all urls from all primary tabIds
		return new Promise(
			(res, rej) => UIInteraction.getPrimaryTabIds().then(
				// wait for primary tab ids to come back, if not already present
				tabIds => Promise.allSettled(tabIds.map(
					// map the tablink request for each of the tabIds
					tabId => UIInteraction.getTabLink(tabId)
				)).then((proms) => res(
					// all getTabLink promises that came back fulfilled
					proms.filter(prom => prom.status === 'fulfilled').map(prom => prom.value)
				)).catch(error => rej(error))
			).catch(error => rej(error))
		);
	}

	/**
	 * Get the current set of primary tabs from the salesforce console app
	 * @params {tabs} Tab[] containing all primary tabs (tabId, tabUrl, tabName)
	 * @params {url} Url of the tab that should be focussed
	 * @returns Promise [{ tabId : "tconsole tab identifier", success : true/false, url : "/003AD00000MAqTp"  }]
	 */
	static focusExistingUrl = (tabs, url) => {
		// find tab with matching url to focus
		const focusUrl = new URL(url, document.location.origin).pathname;
		const existingTab = tabs.find(tab => tab.url?.startsWith(focusUrl));
		const focusExistingUrl = new AsyncTask();

		if (existingTab) {
			UIInteraction.focusPrimaryTabById(matchingTab.tabId).then(res => {
				// set fields
				// thisArg.executeTask(thisArg.actions.syncMiniCaseFields, url);
				focusExistingUrl.complete(res);
			}).catch(error => focusExistingUrl.promise.fail(error));
		} else {
			focusExistingUrl.promise.fail('Tab not found');
		}

		return focusExistingUrl.promise;
	}

	/**
	 * Open a new tab or focus the tab if already present
	 * @params {tabUrl}		'/0031234567890AB'
	 * @params {tabTitle}	'Contact Name'
	 * @params {tabName}	(optional)
	 * @returns (Promise)	tabId of opened/focussed tab. Promise will get rejected if operation can't be completed
	 */
	static openTabByUrl = (tabUrl, tabTitle, tabName) => {
		const openTab = new AsyncTask();

		UIInteraction.openPrimaryTab(tabUrl, tabTitle, tabName).then(
			(tabId) => openTab.complete(({ tabId }))
		).catch(() => UIInteraction.getCurrentTabSet().then((tabs) => {
			// Catch block: Couldn't open new tab, possibly because it already exists
			// Look at currently opened tabs to look for a match to focus
			const focusUrl = new URL(tabUrl, document.location.origin).pathname;
			const matchingTab = tabs.find(tab => tab.url?.startsWith(focusUrl));

			if (matchingTab) {
				// focus matching tab
				UIInteraction.focusPrimaryTabById(matchingTab.tabId).then(
					() => openTab.complete({ tabId : matchingTab.tabId, isExistingTab : true })
				).catch((err) => openTab.fail(err));
			} else {
				openTab.fail(`Unable to open tab for ${tabUrl}`);
			}
		}).catch((error) => openTab.fail(error)));

		return openTab.promise;
	}

	// Console wrappers for Promise result
	static openPrimaryTab = (tabUrl, tabTitle, tabName) => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'openPrimaryTab', null, tabUrl, true, tabTitle,
			(result, event) => {
				if (result.success && result.id) {
					res(result.id);
				} else {
					rej(event);
				}
			}, tabName
		)
	)

	static focusPrimaryTabById = (tabId) => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'focusPrimaryTabById', tabId,
			(result, event) => {
				if (result.success) {
					res(result.id);
				} else {
					rej(event);
				}
			}
		)
	)

	static getPrimaryTabIds = () => {
		const getPrimaryTabIds = new AsyncTask();

		UIInteraction.tabInteractionEvents('getPrimaryTabIds',
			(result, event) => {
				if (result?.success) {
					getPrimaryTabIds.complete(result.ids || []);
				} else {
					getPrimaryTabIds.fail(event);
				}
			}
		);

		return getPrimaryTabIds.promise;
	}

	static getTabLink = (tabId) => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'getTabLink', sforce.console.TabLink.SALESFORCE_URL, tabId,
			(result, event) => {
				if (result?.success) {
					res({
						// use relative url
						url : new URL(result.tabLink, document.location.origin).pathname,
						success : result.success, tabId
					});
				} else {
					rej(event);
				}
			}
		)
	)

	static getFocusedPrimaryTabId = () => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'getFocusedPrimaryTabId', (event) => {
				if (event.id) {
					res(event.id);
				} else {
					rej(event);
				}
			}
		)
	)

	static getFocusedPrimaryTabObjectId = () => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'getFocusedPrimaryTabObjectId', (event) => {
				if (event.id) {
					res(event.id);
				} else {
					rej(event);
				}
			}
		)
	)

	static getFocusedSubtabObjectId = () => new Promise(
		(res, rej) => UIInteraction.tabInteractionEvents(
			'getFocusedSubtabObjectId', (event) => {
				if (event.id) {
					res(event.id);
				} else {
					rej(event);
				}
			}
		)
	)

	static logPrefix = [`%c* GenCTI_AP *%c`, 'color:white;background-color:#dc1928;font-weight:bold', null];
}