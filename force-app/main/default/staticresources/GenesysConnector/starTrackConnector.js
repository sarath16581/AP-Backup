/**********************************************************
@ Vasu Gorakati - 16-04-2024 Initial version  CTI Uplift project
***********************************************************/
var consignmentSearchTabName = 'ConsignmentSearch';
var consignmentSearchUrl = '/apex/StarTrackConsignmentSearch';
var log_prefix = 'CTI_Widget ';


class GenSTBusinessLogic {

	activeInteractionLog;
	log_prefix = "SFDC/connected: ";
	loggingEnabled = true;
	callLog;
	stFieldMappings = {
		enquiryType :'userData.ENG_DimAttribute_2',
		consignmentNumber : 'userData.r_RecordID',
		phoneNumber : 'userData.PhoneNumber',
    	customerSegment : 'userData.CustomerSegment',	
        serviceType : 'userData.r_IWS_ServiceType',
		serviceSubType : 'userData.ServiceSubType',
        atlFlag : 'userData.r_ATL',
        exitCode : 'userData.r_ExitCode',
        partyType :	'userData.r_PartyType'					
	};

    handleCtiEvent(eventName, eventDetail) {

        if (eventName === 'INTERACTION_EVENT') {
			this.callLog = new GenCallInteractionProxy(eventDetail.detail, this.stFieldMappings);
            this.activeInteractionLog = eventDetail.detail;
        }

        console.log(eventName);
        console.log(eventDetail);

        const actionList = this.nextAction.filter(ac => ac.criteria(eventDetail));

        if (actionList && actionList.length) {
            Promise.all(actionList.reduce(
                (res, action) => res.concat(
                    action.tasks.map(
                        task => this.executeTask(task, eventDetail)
                    )
                ), []
            )).then(() => console.log(`Completed action(s): ${actionList.map(ac => ac.name).join(', ')}`))
            .catch(err => console.error(err));
        }
    }

    executeTask(task, ...params) {

        if (!this.loggingEnabled) {
            return task.call(this, ...params);
        }

        const timeStamp = () => new Date().getTime();
        const id = crypto.randomUUID();
        const taskName = Object.keys(this.actions).find(
            ac => this.actions[ac] == task
        );
        const startTime = timeStamp();
        const fireEvent = (state) => {
            const duration = timeStamp() - startTime;
            document.dispatchEvent(
                new CustomEvent('ctiwidget.process', {
                    detail: Object.assign(
                        { id, taskName, state, startTime },
                        state !== 'start' ? { duration } : null
                    )
                })
            );
        }

        fireEvent('start');
        const proc = task.call(this, ...params);

        Promise.resolve(proc).then(
            () => fireEvent('success')
        ).catch(
            () => fireEvent('error')
        );

        return proc;
    };

	actions = {

		initialize: function (ctiEvent) {
			businessLogic.handleSTLogic(ctiEvent);
		}
	}

	handleSTLogic(ctiEvent) {
		console.log(log_prefix + 'call log==>' + JSON.stringify(this.callLog));
		const {
			enquiryType,
            consignmentNumber,
            phoneNumber,
            customerSegment,
            serviceType,
            serviceSubType,
            atlFlag,
            exitCode,
            partyType
        } = this.callLog;

		let caseType = '';
		let casePurpose = '';
		let trackingSearchConsigment = false;
		let cardIVRSearchCase = false;
		let screenPopNoData = false;
		let trackingSearchCase = false;


		console.log(log_prefix + "enquiryType ==>" + enquiryType);
		console.log(log_prefix + "consignmentNumber ==>" + consignmentNumber);
		console.log(log_prefix + "phoneNumber ==>" + phoneNumber);
		console.log(log_prefix + "customerSegment ==>" + customerSegment);
		console.log(log_prefix + "serviceType ==>" + serviceType);
		console.log(log_prefix + "serviceSubType ==>" + serviceSubType);
		console.log(log_prefix + "atlFlag ==>" + atlFlag);
		console.log(log_prefix + "exitCode ==>" + exitCode);

		//Logic for Screen pops
		if (enquiryType === "Priority" && (consignmentNumber === null || consignmentNumber === undefined)
			&& (customerSegment === "Priority 1" || customerSegment === "Priority 2")
			&& (serviceSubType === "Invalid or No Selection" || serviceSubType === "Tracking Enquiry")
			&& serviceType === "Main Menu") {

			console.log(log_prefix + "Scenario: Tracking - Screen Pop without data.");
			screenPopNoData = true; //flag to Pop out the search consignment page without data

		} else if (enquiryType === "BusinessSolutions") {
			if (consignmentNumber === null || consignmentNumber === undefined) {
				console.log(log_prefix + "Scenario: BusinessSolutions - Screen Pop with data.");
				screenPopNoData = true; //flag to Pop out the search consignment page with data
			} else {
				console.log(log_prefix + "Scenario: BusinessSolutions - Screen Pop without data.");
				trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
			}
		} else if (enquiryType === "Tracking" && serviceType === "Tracking and Cards" && customerSegment === "Main") {
			console.log(log_prefix + "Scenario: Tracking|Tracking and Cards");
			if ((exitCode === "Error" || exitCode === "Duplicate") && (serviceSubType === "Error" || serviceSubType === "Duplicate Consignment Found" || serviceSubType === "Duplicate Consignments Found")) {
				trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
				console.log(log_prefix + "Scenario: Error| Duplicate");
			} else if ((exitCode === "NoScan" || exitCode === "TransferRequired" || exitCode === "Transit")) { // removed as hopefully not needed! && (serviceSubType === "No Scanning Events" || serviceSubType === "In Transit or Delivered")){
				trackingSearchCase = true; //Flag to search for the related case on a consignment
				console.log(log_prefix + "Scenario: NoScan| Transit");
			} else if ((exitCode === "Redeliver" || exitCode === "Redirect" || exitCode === "Depot") && (serviceSubType === "Organise Redelivery" || serviceSubType === "Organise Redirection" || serviceSubType === "Depot Collection")) {
				cardIVRSearchCase = true; //Flag to search for the related case on a consignment
				console.log(log_prefix + "Scenario: Redeliver|Redirect|Depot");

				// based on the exit code, any case that is created should be created with a specific case type
				casePurpose = 'Card Left';
				if (exitCode === "Redeliver") {
					caseType = 'Redelivery';
				} else if (exitCode === "Redirect") {
					caseType = 'Redirection';
				} else if (exitCode === "Depot") {
					caseType = 'Depot Collection';
				}
			} else {
				console.log(log_prefix + "Scenario: Tracking|Tracking and Cards| Main - No conditions met.");
			}
		} else if (enquiryType === "Tracking" && serviceType === "Main Menu" && customerSegment === "Training") {
			trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
			console.log(log_prefix + "Scenario: Training");
		} else {
			console.log(log_prefix + "Selection is not valid on any scenario");
		}

		if (screenPopNoData) {
			businessLogic.popConsignmentSearchpage(null, null);
		} else if (trackingSearchConsigment) {
			businessLogic.popConsignmentSearchpage(consignmentNumber, partyType);
		} else if (trackingSearchCase) {
			businessLogic.searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, partyType);
		} else if(cardIVRSearchCase){
			businessLogic.searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, partyType);
		}
	}

	popConsignmentSearchpage(consignment, partyType) {
		console.log(log_prefix + "popConsignmentSearchpage");

		if (sforce.console.isInConsole()) {

			// attempt to refresh the primary consignment search tab
			// if it fails, it's not open and we attempt to open it as a new tab
			sforce.console.refreshPrimaryTabByName(consignmentSearchTabName, true, function (result) {
				var openCompleteCallback = function () {
					if (consignment != null && consignment != '' && consignment !== false) {
						console.log(log_prefix, 'consignment search opened', consignment)
						// fire the event to set the consignment search string and trigger a search.
						// this is picked up by StarTrack Consignment Search page.
						// also send the caller type which is either Sender / Receiver based on the response they gave in the IVR
						var listener = function (result) {
							console.log(log_prefix, 'RequestParentData_SearchString received');
							var datapop = { 'consignment': consignment, 'contactType': '' };
							if (partyType != null && partyType != '') {
								datapop = { 'consignment': consignment, 'contactType': partyType };
							}
							sforce.console.fireEvent('ParentDataResponse_SearchString', JSON.stringify(datapop));
							sforce.console.removeEventListener('RequestParentData_SearchString', listener);
						};
						sforce.console.addEventListener('RequestParentData_SearchString', listener);
					}
				};

				if (!result.success) {
					// the window could not be focused so that generally means it doesn't exist.
					// attempt to open up a window
					sforce.console.openPrimaryTab(null, consignmentSearchUrl, true, 'Consignment Search', openCompleteCallback, consignmentSearchTabName);
				} else {
					if (consignment != null && consignment != '' && consignment !== false) {
						sforce.console.fireEvent('ParentDataResponse_SearchString', consignment);
					}
				}
			});
		}
	}


	//method called for searching consignment number via searchconsignment page
	searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
		console.log(log_prefix + "searchCaseUsingConsignment" + consignmentNumber);
		GenesysConnectorController.findConsignment(consignmentNumber,
			function (result) {
				console.log(log_prefix, 'findConsignment result', result);

				var res = result.split("_");

				if (result.includes("NoCase")) { //No case exist against Consignment, Create a case
					businessLogic.createCaseForConsignment(res[1], phoneNumber, atlFlag, casePurpose, caseType, contactType);
				} else if (result.includes("MultipleCase")) {
					//pop completed consigment search page
					// this also includes a scenario where the consignment doesn't exist in salesforce yet too.
					businessLogic.popConsignmentSearchpage(consignmentNumber, contactType);
				} else {
					//if only one case is related to a consignment
					if (!result.includes("Closed")) {
						//make sure Case is not Closed
						//Check related contacts of case
						businessLogic.checkRelatedContactOfCase(res[0], res[1], phoneNumber, contactType);
					} else if (result != '') {
						businessLogic.openCaseRecord(res[0], res[1], false); //open closed case
					}
				}
			}
		);
	}

	//method to check related contacts on a case
	checkRelatedContactOfCase(caseId, caseNumber, phoneNumber, callerType) {
		console.log(log_prefix + "checkRelatedContactOfCase");

		GenesysConnectorController.checkRelatedContactOfCase(caseId, phoneNumber,
			function (result) {
				if (result !== null) { //related contact with same phone number found
					businessLogic.updateCaseWithRelatedContact(result, caseId);
				} else { //no related contact found against case
					// Pop up the case and add logic for prepopulating contact side panel in edit mode
					businessLogic.openCaseRecord(caseId, caseNumber, false);
					businessLogic.prepopulateContactSidePanel(phoneNumber, callerType, caseId);
				}
			}
		);
	}

	//method to update case with new related contact and pops out the case
	updateCaseWithRelatedContact(relatedContact, caseId) {
		console.log(log_prefix + "updateCaseWithRelatedContact");

		GenesysConnectorController.updateCaseWithRecentCaller(relatedContact, caseId,
			function (result) {
				if (result !== null) {
					// Pop up the case and loads related contact on contact side panel in edit mode
					businessLogic.openCaseRecord(result.Id, result.CaseNumber, true);
					businessLogic.loadRelatedContact(relatedContact.Id, result.Id);
				}
			}
		);
	}

	//create case for consignment
	createCaseForConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
		console.log(log_prefix + "createCaseForConsignment");

		//logic here to create a case against a consignment
		GenesysConnectorController.createCasewithConsignmentNumber(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType,
			function (result) {
				if (result !== null) {
					// Pop up the case and add logic for prepopulating contact side panel in edit mode
					businessLogic.openCaseRecord(result.Id, result.CaseNumber, false);
					businessLogic.prepopulateContactSidePanel(phoneNumber, contactType, result.Id);
				}
			}
		);
	}

	//pops out the case related to a consignment
	openCaseRecord(caseId, caseNumber, callLog) {
		console.log(log_prefix + "openCaseRecord", caseId, caseNumber, callLog);
		//Open a new primary tab with the salesforce.com home page in it
		if (caseId != null) {
			if (sforce.console.isInConsole()) {
				sforce.console.openPrimaryTab(null, '/' + caseId, true, caseNumber, 'caseTab');
			}

			if (callLog) {
				businessLogic.createCallLog(caseId);
			}
		}
	}

	//creates call log of case
	createCallLog(caseId) {
		console.log(log_prefix + "createCallLog");
		if (caseId != null) {
			GenesysConnectorController.createCallLog(caseId,
				function (result) {
					console.log("openCaseRecord_createCallLog" + result);
				}
			);
		}
	}

	//fires event for the prepopulation of contact fields
	prepopulateContactSidePanel(phoneNumber, callerType, recordId) {
		console.log(log_prefix + 'prepopulateContactSidePanel');
		if (sforce.console.isInConsole()) {
			var listener = function (result) {
				var payload = { phoneNumber: phoneNumber, callerType: callerType, caseId: recordId };
				payload = JSON.stringify(payload);
				sforce.console.fireEvent('ParentDataResponse_AddContactDetails', payload);
				sforce.console.removeEventListener('RequestParentData_AddContactDetails', listener);
			};

			// this may be problematic if the case is already open because the RequestParentData_AddContactDetails even will not fire
			// it's currently fired by StarTrackAddContactSidePanel only after the page is loaded
			sforce.console.addEventListener('RequestParentData_AddContactDetails', listener);
		}
	}

	//fires event for the prepopulation of related contact data
	loadRelatedContact(relatedContactId, caseId) {
		console.log(log_prefix + 'loadRelatedContact');
		if (sforce.console.isInConsole()) {
			var listener = function (result) {
				var payload = { relatedContactId: relatedContactId, caseId: caseId };
				payload = JSON.stringify(payload);

				sforce.console.fireEvent('ParentDataResponse_LoadContact', payload);
				sforce.console.removeEventListener('RequestParentData_LoadContact', listener);
			};

			// this may be problematic if the case is already open because the RequestParentData_LoadContact even will not fire
			// it's currently fired by StarTrackAddContactSidePanel only after the page is loaded
			sforce.console.addEventListener('RequestParentData_LoadContact', listener);
		}
	}

	nextAction = [
		{
			name: 'oncallanswered',
			criteria: (event) =>
				event.eventName === 'INTERACTION_CONNECTED' && event.lastDetail.direction === 'Inbound',
			tasks: [this.actions.initialize]
		}
	];

}