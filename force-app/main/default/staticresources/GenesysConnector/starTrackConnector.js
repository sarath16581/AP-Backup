/**********************************************************
 * @ Vasu Gorakati - 16-04-2024 Initial version CTI Uplift project
 **********************************************************/

const consignmentSearchTabName = 'ConsignmentSearch';
const consignmentSearchUrl = '/apex/StarTrackConsignmentSearch';
const logPrefix = 'StarTrackLog ';

class GenSTBusinessLogic {
    callLog;
    stFieldMappings = {
        enquiryType: 'userData.ENG_DimAttribute_2',
        consignmentNumber: 'userData.r_RecordID',
        phoneNumber: 'userData.PhoneNumber',
        customerSegment: 'userData.CustomerSegment',
        serviceType: 'userData.r_IWS_ServiceType',
        serviceSubType: 'userData.ServiceSubType',
        atlFlag: 'userData.r_ATL',
        exitCode: 'userData.r_ExitCode',
        partyType: 'userData.r_PartyType'
    };

    handleCtiEvent(eventName, eventDetail) {
        console.log(logPrefix + 'eventName ' + eventName);
        console.log(logPrefix + 'eventDetail ' + eventDetail);

        if (eventName === 'INTERACTION_EVENT') {
            this.callLog = new CallInteractionProxy(eventDetail.detail, this.stFieldMappings);
        }

        if (eventName === 'INTERACTION_CONNECTED' && eventDetail.lastDetail.direction === 'Inbound') {
            this.handleSTLogic();
        }
    }

    handleSTLogic() {
        console.log(logPrefix + 'call log==>' + JSON.stringify(this.callLog));
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
        let trackingSearchConsignment = false;
        let cardIVRSearchCase = false;
        let screenPopNoData = false;
        let trackingSearchCase = false;

        console.log(logPrefix + "enquiryType ==>" + enquiryType);
        console.log(logPrefix + "consignmentNumber ==>" + consignmentNumber);
        console.log(logPrefix + "phoneNumber ==>" + phoneNumber);
        console.log(logPrefix + "customerSegment ==>" + customerSegment);
        console.log(logPrefix + "serviceType ==>" + serviceType);
        console.log(logPrefix + "serviceSubType ==>" + serviceSubType);
        console.log(logPrefix + "atlFlag ==>" + atlFlag);
        console.log(logPrefix + "exitCode ==>" + exitCode);

        // Logic for Screen pops
        if (enquiryType === "Priority" && (consignmentNumber === null || consignmentNumber === undefined)
            && (customerSegment === "Priority 1" || customerSegment === "Priority 2")
            && (serviceSubType === "Invalid or No Selection" || serviceSubType === "Tracking Enquiry")
            && serviceType === "Main Menu") {
            console.log(logPrefix + "Scenario: Tracking - Screen Pop without data.");
            screenPopNoData = true; // Flag to Pop out the search consignment page without data
        } else if (enquiryType === "BusinessSolutions") {
            if (consignmentNumber === null || consignmentNumber === undefined) {
                console.log(logPrefix + "Scenario: BusinessSolutions - Screen Pop without data.");
                screenPopNoData = true; // Flag to Pop out the search consignment page with data
            } else {
                console.log(logPrefix + "Scenario: BusinessSolutions - Screen Pop with data.");
                trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
            }
        } else if (enquiryType === "Tracking" && serviceType === "Tracking and Cards" && customerSegment === "Main") {
            console.log(logPrefix + "Scenario: Tracking|Tracking and Cards");
            if ((exitCode === "Error" || exitCode === "Duplicate") && (serviceSubType === "Error" || serviceSubType === "Duplicate Consignment Found" || serviceSubType === "Duplicate Consignments Found")) {
                trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
                console.log(logPrefix + "Scenario: Error| Duplicate");
            } else if ((exitCode === "NoScan" || exitCode === "TransferRequired" || exitCode === "Transit")) { // Removed as hopefully not needed! && (serviceSubType === "No Scanning Events" || serviceSubType === "In Transit or Delivered")){
                trackingSearchCase = true; // Flag to search for the related case on a consignment
                console.log(logPrefix + "Scenario: NoScan|Transit|TransferRequired");
            } else if ((exitCode === "Redeliver" || exitCode === "Redirect" || exitCode === "Depot") && (serviceSubType === "Organise Redelivery" || serviceSubType === "Organise Redirection" || serviceSubType === "Depot Collection")) {
                cardIVRSearchCase = true; // Flag to search for the related case on a consignment
                console.log(logPrefix + "Scenario: Redeliver|Redirect|Depot");

                // Based on the exit code, any case that is created should be created with a specific case type
                casePurpose = 'Card Left';
                if (exitCode === "Redeliver") {
                    caseType = 'Redelivery';
                } else if (exitCode === "Redirect") {
                    caseType = 'Redirection';
                } else if (exitCode === "Depot") {
                    caseType = 'Depot Collection';
                }
            } else {
                console.log(logPrefix + "Scenario: Tracking|Tracking and Cards| Main - No conditions met.");
            }
        } else if (enquiryType === "Tracking" && serviceType === "Main Menu" && customerSegment === "Training") {
            trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
            console.log(logPrefix + "Scenario: Training");
        } else {
            console.log(logPrefix + "Selection is not valid on any scenario");
        }

        if (screenPopNoData) {
            this.popConsignmentSearchpage(null, null);
        } else if (trackingSearchConsignment) {
            this.popConsignmentSearchpage(consignmentNumber, partyType);
        } else if (trackingSearchCase) {
            this.searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, partyType);
        } else if (cardIVRSearchCase) {
            this.searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, partyType);
        }
    }

    popConsignmentSearchpage(consignment, partyType) {
        console.log(logPrefix + "popConsignmentSearchpage");

        if (sforce.console.isInConsole()) {
            // Attempt to refresh the primary consignment search tab
            // If it fails, it's not open and we attempt to open it as a new tab
            sforce.console.refreshPrimaryTabByName(consignmentSearchTabName, true, function (result) {
                const openCompleteCallback = function () {
                    if (consignment != null && consignment != '' && consignment !== false) {
                        console.log(logPrefix, 'consignment search opened', consignment)
                        // Fire the event to set the consignment search string and trigger a search.
                        // This is picked up by StarTrack Consignment Search page.
                        // Also send the caller type which is either Sender / Receiver based on the response they gave in the IVR
                        const listener = function (result) {
                            console.log(logPrefix, 'RequestParentData_SearchString received');
                            let datapop = { 'consignment': consignment, 'contactType': '' };
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
                    // The window could not be focused so that generally means it doesn't exist.
                    // Attempt to open up a window
                    sforce.console.openPrimaryTab(null, consignmentSearchUrl, true, 'Consignment Search', openCompleteCallback, consignmentSearchTabName);
                } else {
                    if (consignment != null && consignment != '' && consignment !== false) {
                        sforce.console.fireEvent('ParentDataResponse_SearchString', consignment);
                    }
                }
            });
        }
    }

    // Method called for searching consignment number via searchconsignment page
    searchCaseUsingConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
        console.log(logPrefix + "searchCaseUsingConsignment" + consignmentNumber);

		new Promise(callback => GenesysConnectorController.findConsignmentStarTrack(consignmentNumber, callback))
		.then((result ) =>{
                console.log(logPrefix, 'findConsignment result', result);

                const res = result.split("_");

                if (result.includes("NoCase")) { // No case exists against Consignment, Create a case
                    this.createCaseForConsignment(res[1], phoneNumber, atlFlag, casePurpose, caseType, contactType);
                } else if (result.includes("MultipleCase")) {
                    // Pop completed consignment search page
                    // This also includes a scenario where the consignment doesn't exist in Salesforce yet too.
                    this.popConsignmentSearchpage(consignmentNumber, contactType);
                } else {
                    // If only one case is related to a consignment
                    if (!result.includes("Closed")) {
                        // Make sure Case is not Closed
                        // Check related contacts of case
                        this.checkRelatedContactOfCase(res[0], res[1], phoneNumber, contactType);
                    } else if (result != '') {
                        this.openCaseRecord(res[0], res[1], false); // Open closed case
                    }
                }
            }
        ).catch(
			function (err) { console.error(err); }
		);
    }


    // Method to check related contacts on a case
    checkRelatedContactOfCase(caseId, caseNumber, phoneNumber, callerType) {
		
        console.log(logPrefix + "checkRelatedContactOfCase");

        new Promise(callback => GenesysConnectorController.checkRelatedContactOfCaseStarTrack(caseId, phoneNumber, callback))
         .then((result) => {
                if (result !== null) {
                    this.updateCaseWithRelatedContact(result, caseId);
                } else {
                    // Pop up the case and add logic for prepopulating contact side panel in edit mode
                    this.openCaseRecord(caseId, caseNumber, false);
                    this.prepopulateContactSidePanel(phoneNumber, callerType, caseId);
                }
            }
        ).catch(
			function (err) { console.error(err); }
		);
    }

    // Method to update case with new related contact and pops out the case
    updateCaseWithRelatedContact(relatedContact, caseId) {
        console.log(logPrefix + "updateCaseWithRelatedContact");

        new Promise(callback =>GenesysConnectorController.updateCaseWithRecentCallerStarTrack(relatedContact, caseId, callback))
        .then((result) => {
                if (result !== null) {
                    // Pop up the case and loads related contact on contact side panel in edit mode
                    this.openCaseRecord(result.Id, result.CaseNumber, true);
                    this.loadRelatedContact(relatedContact.Id, result.Id);
                }
            }
        ).catch(
			function (err) { console.error(err); }
		);
    }

    // Create case for consignment
    createCaseForConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
        console.log(logPrefix + "createCaseForConsignment");

        // Logic here to create a case against a consignment
        new Promise(callback =>GenesysConnectorController.createCasewithConsignmentNumberStarTrack(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType, callback))
		.then((result) => {
                if (result !== null) {
                    // Pop up the case and add logic for prepopulating contact side panel in edit mode
                    this.openCaseRecord(result.Id, result.CaseNumber, false);
                    this.prepopulateContactSidePanel(phoneNumber, contactType, result.Id);
                }
            }
        ).catch(
			function (err) { console.error(err); }
		);
    }

    // Pops out the case related to a consignment
    openCaseRecord(caseId, caseNumber, callLog) {
        console.log(logPrefix + "openCaseRecord", caseId, caseNumber, callLog);
        // Open a new primary tab with the Salesforce.com home page in it
        if (caseId != null) {
            if (sforce.console.isInConsole()) {
                sforce.console.openPrimaryTab(null, '/' + caseId, true, caseNumber, 'caseTab');
            }

            if (callLog) {
                this.createCallLog(caseId);
            }
        }
    }

    // Creates call log of case
    createCallLog(caseId) {

        console.log(logPrefix + "createCallLog");
		
        if (caseId != null) {
            new Promise(callback =>GenesysConnectorController.createCallLogStarTrack(caseId, callback))
			.then((result) => {
                    console.log("openCaseRecord_createCallLog" + result);
                }
			).catch(
				function (err) { console.error(err); }
			);
        }
    }

    // Fires event for the prepopulation of contact fields
    prepopulateContactSidePanel(phoneNumber, callerType, recordId) {
        console.log(logPrefix + 'prepopulateContactSidePanel');
        if (sforce.console.isInConsole()) {
            const listener = function (result) {
                let payload = { phoneNumber: phoneNumber, callerType: callerType, caseId: recordId };
                payload = JSON.stringify(payload);
                sforce.console.fireEvent('ParentDataResponse_AddContactDetails', payload);
                sforce.console.removeEventListener('RequestParentData_AddContactDetails', listener);
            };

            // This may be problematic if the case is already open because the RequestParentData_AddContactDetails even will not fire
            // It's currently fired by StarTrackAddContactSidePanel only after the page is loaded
            sforce.console.addEventListener('RequestParentData_AddContactDetails', listener);
        }
    }

    // Fires event for the prepopulation of related contact data
    loadRelatedContact(relatedContactId, caseId) {
        console.log(logPrefix + 'loadRelatedContact');
        if (sforce.console.isInConsole()) {
            const listener = function (result) {
                let payload = { relatedContactId: relatedContactId, caseId: caseId };
                payload = JSON.stringify(payload);

                sforce.console.fireEvent('ParentDataResponse_LoadContact', payload);
                sforce.console.removeEventListener('RequestParentData_LoadContact', listener);
            };

            // This may be problematic if the case is already open because the RequestParentData_LoadContact even will not fire
            // It's currently fired by StarTrackAddContactSidePanel only after the page is loaded
            sforce.console.addEventListener('RequestParentData_LoadContact', listener);
        }
    }
}