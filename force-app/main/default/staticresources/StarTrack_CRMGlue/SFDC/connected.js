/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * The main interface between the Cephas generic code and SFDC
 */
define(['util', 'i18next', 'agent/voice', 'config', 'SFDC/api', 'SFDC/tracking', 'SFDC/case', 'SFDC/task', 'SFDC/pop', 'agent/interaction'],
            function (util, i18n, voice, config, sfdc, tracking, caseObj, task, pop, interaction) {
    var log_prefix = "SFDC/connected: ";
    var _searchSettings = null;

    // Start - APRivera - 16/01/18 - variable assignment
    var consignmentSearchUrl = '/apex/StarTrackConsignmentSearch';
    var consignmentSearchTabName = 'ConsignmentSearch';
    var screenPopNoData = false;
    var trackingSearchConsigment = false, trackingSearchCase = false;
    var cardIVRSearchCase = false;
    var initiateCallLog = false;
    var ixn;
    var userData;
    // End - variable assignment

    var initialize = function (searchSettings) {
        try {
            console.log(log_prefix + 'initialize');
            _searchSettings = searchSettings;

            // enable native click to dial functionality
            sfdc.enableClickToDial();
            sfdc.onClickToDial(dial);

            //caseObj.initialize(searchSettings.searchCaseKVP);

            // listen for the CTIEvent message
            console.log(log_prefix, 'Setting up listener for CTIEvent');
            sfdc.addEventListener(receiveSFMessage);

            /*
             * Voice: Search on case, then a custom search field, then the ANI
             */
            util.getInstance('voice.pop').subscribe(function (message) {
				var caseType = '';
				var casePurpose = '';

                trackingSearchConsigment = false;
                cardIVRSearchCase = false;
                screenPopNoData = false;
                initiateCallLog = false;
                trackingSearchCase = false;

                console.log(log_prefix + "voice.pop");
                ixn = message.call;
                userData = message.call.userData;
                ixn.isConsult = message.isConsult;
                console.log(log_prefix + "voice.pop - ixn: " + JSON.stringify(ixn));
                console.log(log_prefix + "voice.pop - ixn.userData: " + JSON.stringify(userData));
                try {
                    if(ixn.callType === 'Inbound' || ixn.callType === 'Internal') {
                        console.log(log_prefix + "userData.r_EnquiryType: " + userData.r_EnquiryType);
                        console.log(log_prefix + "ixn.enquiryType: " + ixn.enquiryType);
                        console.log(log_prefix + "enquiryType: " + ixn.enquiryType);
                        console.log(log_prefix + "consignmentNumber: " + ixn.consignmentNumber);
                        console.log(log_prefix + "phoneNumber: " + ixn.phoneNumber);
                        console.log(log_prefix + "customerSegment: " + ixn.customerSegment);
                        console.log(log_prefix + "serviceType: " + ixn.serviceType);
                        console.log(log_prefix + "serviceSubType: " + ixn.serviceSubType);
                        console.log(log_prefix + "atlFlag: " + ixn.atlFlag);
                        console.log(log_prefix + "exitCode: " + ixn.exitCode);


                        // Start - APRivera - 22/01/18 - Logic for Screen pops
                        if(ixn.enquiryType === "Priority" && (ixn.consignmentNumber === null || ixn.consignmentNumber === undefined)
                                && (ixn.customerSegment === "Priority 1" || ixn.customerSegment === "Priority 2")
                                    && (ixn.serviceSubType === "Invalid or No Selection" || ixn.serviceSubType === "Tracking Enquiry")
                                        && ixn.serviceType === "Main Menu"){

                                console.log(log_prefix + "Scenario: Tracking - Screen Pop without data.");
                                screenPopNoData = true; //Flag to Pop out the search consignment page without data

                        } else if(ixn.enquiryType === "BusinessSolutions"){
							if(ixn.consignmentNumber === null || ixn.consignmentNumber === undefined) {
                                console.log(log_prefix + "Scenario: BusinessSolutions - Screen Pop with data.");
                                trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
                            } else{
                                screenPopNoData = true; //Flag to Pop out the search consignment page without data
                                console.log(log_prefix + "Scenario: BusinessSolutions - Screen Pop without data.");
                            }
                        } else if (ixn.enquiryType === "Tracking" && ixn.serviceType === "Tracking and Cards" && ixn.customerSegment === "Main") {
                            console.log(log_prefix + "Scenario: Tracking|Tracking and Cards");
                            if((ixn.exitCode === "Error" || ixn.exitCode === "Duplicate") && (ixn.serviceSubType === "Error" || ixn.serviceSubType === "Duplicate Consignment Found" || ixn.serviceSubType === "Duplicate Consignments Found")) {
                                trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
                                console.log(log_prefix + "Scenario: Error| Duplicate");
                            } else if((ixn.exitCode === "NoScan" || ixn.exitCode === "TransferRequired" || ixn.exitCode === "Transit")) { // removed as hopefully not needed! && (ixn.serviceSubType === "No Scanning Events" || ixn.serviceSubType === "In Transit or Delivered")){
                                trackingSearchCase = true; //Flag to search for the related case on a consignment
                                console.log(log_prefix + "Scenario: NoScan| Transit");
                            } else if((ixn.exitCode === "Redeliver" || ixn.exitCode === "Redirect" || ixn.exitCode === "Depot") && (ixn.serviceSubType === "Organise Redelivery" || ixn.serviceSubType === "Organise Redirection" || ixn.serviceSubType === "Depot Collection")){
                                cardIVRSearchCase = true; //Flag to search for the related case on a consignment
                                console.log(log_prefix + "Scenario: Redeliver|Redirect|Depot");

                                // based on the exit code, any case that is created should be created with a specific case type
                                casePurpose = 'Card Left';
								if(ixn.exitCode === "Redeliver") {
								    caseType = 'Redelivery';
								} else if(ixn.exitCode === "Redirect") {
								    caseType = 'Redirection';
								} else if(ixn.exitCode === "Depot") {
								    caseType = 'Depot Collection';
								}
							} else {
                                console.log(log_prefix + "Scenario: Tracking|Tracking and Cards| Main - No conditions met.");
                            }
                        } else if (ixn.enquiryType === "Tracking" && ixn.serviceType === "Main Menu" && ixn.customerSegment === "Training"){
							trackingSearchConsigment = true; //flag to Pop out the search consignment page with data
							console.log(log_prefix + "Scenario: Training");
                        } else {
                            console.log(log_prefix + "Selection is not valid on any scenario");
                        }
                        // End - Logic for Screen pops
                    }

                    // Start - APRivera - 23/01/18 - Added logic based call parameters to drive SF console behavior
                    if(screenPopNoData){
                        popConsignmentSearchpage();
                    } else if(trackingSearchConsigment){
                        popConsignmentSearchpage(ixn.consignmentNumber, userData.r_PartyType);
                    } else if(trackingSearchCase){
                        searchCaseUsingConsigment(ixn.consignmentNumber, ixn.phoneNumber, ixn.atlFlag, casePurpose, caseType, userData.r_PartyType);
                    } else if(cardIVRSearchCase){
                        searchCaseUsingConsigment(ixn.consignmentNumber, ixn.phoneNumber, ixn.atlFlag, casePurpose, caseType, userData.r_PartyType);
                    }
                    // End - Added logic based call parameters to drive SF console behavior
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }

                console.log(log_prefix + "voice.pop - finished");
            });
            /*
            util.getInstance('voice.ended').subscribe(function (message) {
                console.log(log_prefix + "voice.ended");

                try {
                    var ixn = message.call;
                    var id = ixn.id;

                    if (tracking.exists(id)) {
                        var comments = "";
                        if (ixn.notes) {
                            comments += "Note:\n" + ixn.notes + '\n\n';
                        }

                        task.finish(id, comments, ixn, ixn.duration).done(
                            function() {
                                tracking.remove(id);
                            }
                        );
                    }
                    else {
                        console.log(log_prefix + "could not find " + id);
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                }
            });


            /******************************************************************************
             *                  Preview Outbound - pop
             ******************************************************************************/
            /*
            util.getInstance('preview.pop').subscribe(function (message) {
                console.log(log_prefix + "preview.pop");
                var ixn = message.record;

                var phoneSearch = function () {
                    var phoneNumber = ixn.phone;
                    console.log(log_prefix + "phoneSearch - " + phoneNumber);
                    var params = {
                        ixn: ixn,
                        searchValue: message.fieldValue,
                        popOnly: true
                    };

                    ConnectorController.findContact('Phone', phoneNumber,
                        function (contact) {
                            if (contact !== null) {
                                if (contact.Id === undefined) { // multiple contacts
                                    console.log(log_prefix + "contact search - multiple contacts");
                                    doSearch(params, 'phoneNumber', phoneNumber, true);
                                }
                                else {
                                    contact.Name = $("<div/>").html(contact.Name).text(); // convert HTML to plain text
                                    console.log(log_prefix + "phoneSearch: " + contact.Id + ", " + contact.Name + " (" + message.record.id + ")");
                                    params.contact = contact;
                                    pop.start(params);
                                }
                            }
                            else {
                                console.log(log_prefix + "contact search - no records found");
                                doSearch(params, 'phoneNumber', phoneNumber);
                            }
                        }
                    );
                    console.log(log_prefix + "phoneSearch - finished");
                };

                var params = {
                    searchField: message.fieldName,
                    searchValue: message.fieldValue,
                    searchType: searchSettings.voiceSearchType,
                    ixn: ixn,
                    popOnly: true
                };
                fieldSearch(params).
                    then(null, phoneSearch);
            });

            /******************************************************************************
             *                  Other functions
             ******************************************************************************/

            // Start - APRivera - 23/01/18 - Added function that pops out the consignment search page

            //method called when displaying consignment seaarch page
            function popConsignmentSearchpage(consignment, partyType){
                console.log(log_prefix + "popConsignmentSearchpage");

				if(sforce.console.isInConsole()) {

				    // attempt to refresh the primary consignment search tab
				    // if it fails, it's not open and we attempt to open it as a new tab
					sfdc.refreshPrimaryTabByName(consignmentSearchTabName, true, function(result) {
						var openCompleteCallback = function() {
							if(consignment != null && consignment != '' && consignment !== false) {
							    console.log(log_prefix, 'consignment search opened', consignment)
								// fire the event to set the consignment search string and trigger a search.
								// this is picked up by StarTrack Consignment Search page.
								// also send the caller type which is either Sender / Receiver based on the response they gave in the IVR
								var listener = function(result) {
								    console.log(log_prefix, 'RequestParentData_SearchString received');
									var datapop = {'consignment': consignment, 'contactType': ''};
									if(partyType != null && partyType != '' ){
										datapop = {'consignment': consignment, 'contactType': partyType};
									}
									sforce.console.fireEvent('ParentDataResponse_SearchString', JSON.stringify(datapop));
								   	sforce.console.removeEventListener('RequestParentData_SearchString', listener);
								};
								sforce.console.addEventListener('RequestParentData_SearchString', listener);
							}
						};

						if(!result.success) {
							// the window could not be focused so that generally means it doesn't exist.
							// attempt to open up a window
							sfdc.openPrimaryTab(null, consignmentSearchUrl, true, i18n.t('search.search'), openCompleteCallback, consignmentSearchTabName);
						} else {
						    if(consignment != null && consignment != '' && consignment !== false) {
						    	sforce.console.fireEvent('ParentDataResponse_SearchString', consignment);
						    }
						}
					});
				}
            }

            //method called for searching consignment number via searchconsignment page
            function searchCaseUsingConsigment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
                console.log(log_prefix + "searchCaseUsingConsigment" + consignmentNumber);
                StarTrack_ConnectorController.findConsignment(consignmentNumber,
                    function(result) {
                        console.log(log_prefix, 'findConsignment result', result);

                        var res = result.split("_");

                        if (result.includes("NoCase")) { //No case exist against Consignment, Create a case
                            createCaseForConsignment(res[1], phoneNumber, atlFlag, casePurpose, caseType, contactType);
                        } else if(result.includes("MultipleCase")) {
                        	//pop completed consigment search page
                        	// this also includes a scenario where the consignment doesn't exist in salesforce yet too.
                            popConsignmentSearchpage(consignmentNumber, contactType);
                        } else {
                        	//if only one case is related to a consignment
                            if(!result.includes("Closed")) {
                            	//make sure Case is not Closed
                            	//Check related contacts of case
                                checkRelatedContactOfCase(res[0], res[1], phoneNumber, contactType);
                            } else if(result != '') {
                                openCaseRecord(res[0], res[1], false); //open closed case
                            }
                        }
                    }
                );
            }


            //method to check related contacts on a case
            function checkRelatedContactOfCase(caseId, caseNumber, phoneNumber, callerType) {
                console.log(log_prefix + "checkRelatedContactOfCase");

                StarTrack_ConnectorController.checkRelatedContactOfCase(caseId, phoneNumber,
                    function(result) {
                        if(result !== null) { //related contact with same phone number found
                            updateCaseWithRelatedContact(result, caseId);
                        } else { //no related contact found against case
                            // Pop up the case and add logic for prepopulating contact side panel in edit mode
                            openCaseRecord(caseId, caseNumber, false);
                            prepopulateContactSidePanel(phoneNumber, callerType, caseId);
                        }
                    }
                );
            }

            //method to update case with new related contact and pops out the case
            function updateCaseWithRelatedContact(relatedContact, caseId) {
                console.log(log_prefix + "updateCaseWithRelatedContact");

                StarTrack_ConnectorController.updateCaseWithRecentCaller(relatedContact,caseId,
                    function(result) {
                        if(result !== null) {
                            // Pop up the case and loads related contact on contact side panel in edit mode
                            openCaseRecord(result.Id, result.CaseNumber, true);
                            loadRelatedContact(relatedContact.Id, result.Id);
                        }
                    }
                );
            }

            //create case for consignment
            function createCaseForConsignment(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType) {
                console.log(log_prefix + "createCaseForConsignment");

                //logic here to create a case against a consignment
                StarTrack_ConnectorController.createCasewithConsignmentNumber(consignmentNumber, phoneNumber, atlFlag, casePurpose, caseType, contactType,
                    function(result) {
                        if(result !== null) {
                            // Pop up the case and add logic for prepopulating contact side panel in edit mode
                            openCaseRecord(result.Id, result.CaseNumber, false);
                            prepopulateContactSidePanel(phoneNumber, contactType, result.Id);
                        }
                    }
                );
            }

            //pops out the case related to a consignment
            function openCaseRecord(caseId, caseNumber, callLog) {
                console.log(log_prefix + "openCaseRecord", caseId, caseNumber, callLog);
                //Open a new primary tab with the salesforce.com home page in it
                if(caseId != null){
                    if(sforce.console.isInConsole()) {
                        sforce.console.openPrimaryTab(null, '/' + caseId, true, caseNumber,'caseTab');
                    }

                    if(callLog){
                        createCallLog(caseId);
                    }
                }
            }

            //creates call log of case
            function createCallLog(caseId){
                console.log(log_prefix + "createCallLog");
                if(caseId != null){
                    StarTrack_ConnectorController.createCallLog(caseId,
                        function (result) {
                            console.log("openCaseRecord_createCallLog" + result);
                        }
                    );
                }
            }

            //fires event for the prepopulation of contact fields
            function prepopulateContactSidePanel(phoneNumber, callerType, recordId){
                console.log(log_prefix + 'prepopulateContactSidePanel');
                if(sforce.console.isInConsole()){
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
            function loadRelatedContact(relatedContactId, caseId){
                console.log(log_prefix + 'loadRelatedContact');
                if(sforce.console.isInConsole()){
                    var listener = function (result){
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

            // End - Added function that pops out the consignment search page


            /**
             * Find a contact based on a KVP
             * @param params
             * @returns {*}
             */

            /*
            var fieldSearch = function(params) {
                var d = $.Deferred();

                var searchField = params.searchField;
                var searchValue = params.searchValue;
                var ixn = params.ixn;
                var searchType = params.searchType || null;

                try {
                    console.log(log_prefix + "fieldSearch");

                    if (searchField !== null &&
                            searchValue !== null) {
                        console.log(log_prefix + "fieldSearch - search field=" + searchField);
                        console.log(log_prefix + "fieldSearch - search value=" + searchValue);

                        if (searchValue !== undefined && searchValue !== '') {
                            ConnectorController.findContact(searchField, searchValue,
                                function (contact) {
                                    if (contact !== null) {
                                        if (contact.Id === undefined) { // multiple contacts
                                            console.log(log_prefix + 'fieldSearch - multiple contacts');
                                            doSearch(params, searchType, searchValue, true);
                                        }
                                        else {
                                            contact.Name = $("<div/>").html(contact.Name).text(); // convert to non-HTML
                                            console.log(log_prefix + "fieldSearch - " + contact.Id + ", " + contact.Name + " (" + ixn.id + ")");
                                            params.contact = contact;
                                            pop.start(params);
                                            console.log(log_prefix + "fieldSearch - success for " + ixn.id);
                                        }

                                        d.resolve();
                                    }
                                    else {
                                        console.log(log_prefix + "fieldSearch - no field value found");
                                        d.reject();
                                    }
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "fieldSearch - no field KVP in interaction");
                            d.reject();
                        }
                    }
                    else {
                        console.log(log_prefix + "fieldSearch - no field search");
                        d.reject();
                    }
                }
                catch (e) {
                    console.error(log_prefix + e.stack);
                    d.reject();
                }

                console.log(log_prefix + "fieldSearch - finished");
                return d.promise();
            };

            /**
             * Open up the VisualForce search page with the appropriate parameters.
             * @param params - search parameters
             * @param type - the column to show the search parameter
             * @param searchString
             * @returns a promise
             */
            
            /*
            var doSearch = function(params, type, searchString, isMultiContact) {
                console.log(log_prefix + "doSearch - " + type + ", " + searchString);
                var d = $.Deferred();
                var url = '/apex/StarTrackConsignmentSearch' + params.ixn.id;

                if (config.NO_DEFAULT_SEARCH && !isMultiContact) {
                    console.log(log_prefix + "doSearch - not enabled, do pop instead");
                    pop.start();
                    d.resolve();
                }
                else if (searchString !== undefined && searchString !== null && searchString !== '' && type !== null) {
                    url += "&" + type + '=' + searchString;
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sfdc.openPrimaryTab(null, url, true, i18n.t('search.search'));
                    d.resolve();
                }
                else {
                    console.log(log_prefix + "url=" + url);
                    tracking.setParams(params);
                    sfdc.openPrimaryTab(null, url, true, i18n.t('search.search'));
                    d.reject();
                }

                return d.promise();
            };
            */
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
        }

        console.log(log_prefix + "initialized");
        util.getInstance('sfdc.connected').publish('initialized');
    };

    /**
     * Receive a message from SF
     * @param result
     */
    function receiveSFMessage(result) {
        var msg = JSON.parse(result.message /* sfdc */ || result.data /* lightning */);
        console.log("receiveSFMessage CTIEvent = " + msg.action);

        switch (msg.action) {
            case "AttachData": // comes from customized SFDC page

            	// Updated to include the call ID if it doesn't already exist
            	if(msg.hasOwnProperty('ActionData') && !msg.ActionData.hasOwnProperty('id') && ixn != null) {
            		msg.ActionData.id = ixn.id;
            	}

                interaction.attachData(msg);
                break;

            case "MarkDone": // comes from customized SFDC page
                interaction.markDone(msg);
                break;

            case "ReleaseCall": // comes from customized SFDC page
                interaction.releaseCall(msg);
                break;

            case "UserEvent": // comes from customized SFDC page
                interaction.userEvent(msg);
                break;

            case "ContactSelected": // comes from Search page
                console.log(log_prefix + "ContactSelected - " + msg.objectId + ", " + msg.id);
                ConnectorController.getContact(msg.objectId, null,
                    function (contact) {
                        var params = tracking.getParams(msg.id);
                        if (params !== null) {
                            params.contact = contact;

                            // start the whole process again...
                            pop.start(params);
                        }
                    }
                );
                break;

            case "CaseSelected": // comes from Case Search page
                console.log(log_prefix + "CaseSelected - " + msg.objectId + ", " + msg.id);
                ConnectorController.getContact(msg.objectId, null,
                    function (contact) {
                        var params = tracking.getParams(msg.id);
                        if (params !== null) {
                            params.contact = contact;
                            params.caseId = msg.caseId;
                            params.caseNumber = msg.caseNumber;

                            // start the whole process again...
                            pop.start(params);
                        }
                    }
                );
                break;
        }
    }

    /**
     * Dial a number via the SFDC "click to dial" functionality.
     * @param request
     */
    function dial(request) {
        var result = null;
        if (typeof request.result === 'string') { // classic console
            result = JSON.parse(request.result);
        }
        else { // lightning
            result = request;
        }

        var caseNumber = null;
        var contactId = null;
        console.log(log_prefix + "dial: " + result.number);

        if (config.beforeDial) {
            console.log(log_prefix + 'go to custom dial handler');
            config.beforeDial(result);
        }

        var params = {
            phoneNumber: result.number,
            userData: result.userData ? result.userData : {}
        };

        /**
         * Get the contact (and case?) for a given object
         * @returns
         **/
        var getContact = function() {
            var d = $.Deferred();
            console.log(log_prefix + 'getContact: ' + result.object);

            if (result.object === 'Contact') {
                caseNumber = caseObj.getCaseNumber(result.objectId);
                contactId = result.objectId;
                console.log(log_prefix + "case number is " + caseNumber + ", contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Account') {
                contactId = result.contactId;
                console.log(log_prefix + "contact is " + contactId);
                d.resolve();
            }
            else if (result.object === 'Case') {
                caseNumber = result.objectName;
                console.log(log_prefix + "case number is " + caseNumber);
                d.resolve();
            }
            else if (result.object === 'Task') {
                var taskId = result.objectId;
                console.log(log_prefix + "task is " + taskId);

                ConnectorController.getContactByTask(taskId,
                    function (task) {
                        contactId = task.WhoId;
                        caseNumber = task.CallObject;
                        console.log(log_prefix + "contact is " + contactId + ", case number is " + caseNumber);
                        d.resolve();
                    }
                );
            }
            else {
                console.log(log_prefix + "object is " + result.object);
                d.resolve();
            }

            return d;
        };

        var getDetails = function () {
            var d = $.Deferred();

            try {
                // make sure we can bring up an existing case/contact
                if (_searchSettings.searchVoiceKVP !== "") {

                    // get the contact id
                    getContact().done(function() {
                        if (caseNumber !== null && _searchSettings.searchCaseKVP !== "") {
                            params.userData[_searchSettings.searchCaseKVP] = caseNumber;
                        }

                        if (contactId !== null) {
                            console.log(log_prefix + "search contact: " + contactId + ", " + _searchSettings.voiceSearchField, ", " + _searchSettings.voiceSearchKVP);
                            if (_searchSettings.voiceSearchField && _searchSettings.voiceSearchKVP) {
                                ConnectorController.getContact(contactId, _searchSettings.voiceSearchField,
                                    function (contact) {
                                        // add the KVP to a make call so we can search on this when the call is established
                                        if (contact !== null) {
                                            var voiceField = contact[_searchSettings.voiceSearchField];

                                            if (voiceField !== null) {
                                                console.log(log_prefix + "voice field is " + voiceField);
                                                params.userData[_searchSettings.voiceSearchKVP] = voiceField;
                                            }
                                        }

                                        d.resolve();
                                    }
                                );
                            }
                            else {
                                d.resolve();
                            }
                        }
                        else {
                            d.resolve();
                        }
                    });
                }
                else {
                    d.resolve();
                }
            }
            catch (e) {
                console.error(log_prefix + e.stack);
                d.resolve();
            }

            return d;
        };

        getDetails().done(
            function () {
                voice.dial(params);
            });
    }

    return {
        initialize: initialize
    };
});