/**********************************************************
 * @ Vasu Gorakati - 16-04-2024 Initial version CTI Uplift project
 **********************************************************/

const consignmentSearchTabName = 'ConsignmentSearch';
const consignmentSearchUrl = '/apex/StarTrackConsignmentSearch';
const logPrefix = 'StarTrackLog ';

class GenSTBusinessLogic {
    callLog;
	stFieldMappings = {
        enquiryType: 'attributes.Participant\\.Enquiry_Type',
        consignmentNumber: 'attributes.Participant\\.Consignment',
        phoneNumber: 'ani',
        customerSegment: 'attributes.Participant\\.Customer_Segment',
        serviceType: 'attributes.Participant\\.Service_Type',
        serviceSubType: 'attributes.Participant\\.Service_Subtype',
        atlFlag: 'attributes.Participant\\.ATL',
        exitCode: 'attributes.Participant\\.Exit_Code',
        partyType: 'attributes.Participant\\.Contact_Type'
    };

    handleCtiEvent(eventName, eventDetail) {
        if (eventName === 'INTERACTION_EVENT') {
            this.callLog = new CallInteractionProxy(eventDetail.detail, this.stFieldMappings);
			if (this.callLog.phoneNumber?.startsWith('+61')) {
				this.callLog.phoneNumber = `0${this.callLog.phoneNumber.slice(3)}`;
			}
        }

        if (eventName === 'INTERACTION_CONNECTED' && eventDetail.lastDetail.direction === 'Inbound') {
            this.handleSTLogic();
        }
    }

    handleSTLogic() {
        const {
            enquiryType,
            consignmentNumber,
            customerSegment,
            serviceType,
            serviceSubType,
            atlFlag,
            exitCode,
            partyType
        } = this.callLog;
		let { phoneNumber } = this.callLog;

        let caseType = '';
        let casePurpose = '';
        let trackingSearchConsignment = false;
        let cardIVRSearchCase = false;
        let screenPopNoData = false;
        let trackingSearchCase = false;

        // Logic for Screen pops
        if (enquiryType === "Priority" && (consignmentNumber === null || consignmentNumber === undefined)
            && (customerSegment === "Priority 1" || customerSegment === "Priority 2")
            && (serviceSubType === "Invalid or No Selection" || serviceSubType === "Tracking Enquiry")
            && serviceType === "Main Menu") {
            screenPopNoData = true; // Flag to Pop out the search consignment page without data
        } else if (enquiryType === "BusinessSolutions") {
            if (consignmentNumber === null || consignmentNumber === undefined) {
                screenPopNoData = true; // Flag to Pop out the search consignment page with data
            } else {
                trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
            }
        } else if (enquiryType === "Tracking" && serviceType === "Tracking and Cards" && customerSegment === "Main") {
            if ((exitCode === "Error" || exitCode === "Duplicate") && (serviceSubType === "Error" || serviceSubType === "Duplicate Consignment Found" || serviceSubType === "Duplicate Consignments Found")) {
                trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
            } else if ((exitCode === "NoScan" || exitCode === "TransferRequired" || exitCode === "Transit")) { // Removed as hopefully not needed! && (serviceSubType === "No Scanning Events" || serviceSubType === "In Transit or Delivered")){
                trackingSearchCase = true; // Flag to search for the related case on a consignment
            } else if ((exitCode === "Redeliver" || exitCode === "Redirect" || exitCode === "Depot") && (serviceSubType === "Organise Redelivery" || serviceSubType === "Organise Redirection" || serviceSubType === "Depot Collection")) {
                cardIVRSearchCase = true; // Flag to search for the related case on a consignment

                // Based on the exit code, any case that is created should be created with a specific case type
                casePurpose = 'Card Left';
                if (exitCode === "Redeliver") {
                    caseType = 'Redelivery';
                } else if (exitCode === "Redirect") {
                    caseType = 'Redirection';
                } else if (exitCode === "Depot") {
                    caseType = 'Depot Collection';
                }
            }
        } else if (enquiryType === "Tracking" && serviceType === "Main Menu" && customerSegment === "Training") {
            trackingSearchConsignment = true; // Flag to Pop out the search consignment page with data
        } else {
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
        if (sforce.console.isInConsole()) {
            // Attempt to refresh the primary consignment search tab
            // If it fails, it's not open and we attempt to open it as a new tab
            sforce.console.refreshPrimaryTabByName(consignmentSearchTabName, true, function (result) {
                const openCompleteCallback = function () {
                    if (consignment != null && consignment != '' && consignment !== false) {
                        // Fire the event to set the consignment search string and trigger a search.
                        // This is picked up by StarTrack Consignment Search page.
                        // Also send the caller type which is either Sender / Receiver based on the response they gave in the IVR
                        const listener = function (result) {
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
		new Promise(callback => GenesysConnectorController.findConsignmentStarTrack(consignmentNumber, callback))
		.then((result ) =>{
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
        if (caseId != null) {
            new Promise(callback =>GenesysConnectorController.createCallLogStarTrack(caseId, callback)).catch(
				function (err) { console.error(err); }
			);
        }
    }

    // Fires event for the prepopulation of contact fields
    prepopulateContactSidePanel(phoneNumber, callerType, recordId) {
        if (sforce.console.isInConsole()) {
            const listener = function (result) {
                let payload = { phoneNumber, callerType: callerType, caseId: recordId };
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
        if (sforce.console.isInConsole()) {
            const listener = function (result) {
                let payload = { relatedContactId, caseId: caseId };
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