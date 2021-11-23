/**
 * @description Scenario file for handling AP Call Centre scenarios
 * @author Nathan Franklin
 * @date 2018-08-20
 * @changelog
 * 2021-09-01 - Nathan Franklin - Added additional permissions capability for overflow agents taking CTI interactions
 */
define(['util', 'integration', 'config', 'AP/utils', 'SFDC/case', 'SFDC/pop', 'SFDC/tracking', 'SFDC/task', 'AP/integration'],
    function (util, sforce, config, apUtils, caseObj, pop, tracking, task, apIntegration) {
        var log_prefix = 'AP/connected';

        /**
         * Called when initialized, this will set overrides for custom processing
         * called from main Visualforce page
         */
        var setOverrides = function() {
            config.overrideVoicePop = voicePop;

            // set the correct userData before an outbound call is made
            // this is used to:
            // 1. overwrite the original result object to stop the standard Genesys dial() function from running (trying to use ConnectorController class which doesn exist)
            // 2. set the correct userData params to pass back through into voice.pop as an Outbound call type
            config.beforeDial = beforeDial;

            // the framework currently doesn't override this, so we add our own listener.
            util.getInstance('voice.ended').subscribe(voiceEnded);
        };

        /**
         * When the voice call has ended this message will be fired
         */
        var voiceEnded = function(message) {

            // we need to clear all IVR values from the CTI Popup interface
            // fire a message that the controller will pick up
            // NOTE: This is not clearing sync'd values from MyCustomers
            apIntegration.fireClearEvents();

        };

        /**
         * this is called from within SFDC/connected.js on voice.pop overrideVoicePop
         *
         *	Inbound Call Scenarios and Outbound Callback scenario (ixn.callType === 'Outbound' && userData['ENG_CB_Status'] === 'Success')
         *  1. Attempt to find Case by userData.CaseNumber/CaseId or tracking id (userData.UData_sstrackingid)
         *  2. If fail, Attempt to find Contact by userData.ContactId
         *  3. If fail, Attempt to find Contact by phone number (userData.r_INFO_CustomerANI)
         *  If contact or case could not matched to a single record based on the data in payload, controller/controller.js monitors navigation in service cloud and will link the last viewed case/contact to this interaction when it ends.
         *
         *  Outbound Call Scenarios:
         *  1. Attempt to find Case by userData.CaseNumber/CaseId or tracking id (userData.UData_sstrackingid)
         *  2. If fail, Attempt to find Contact by userData.ContactId
         *  If a contact is not matched to a single record based on data in the payload (userData.ContactId), then no contact will be associated to the call log
         *  If a case is not matched to a sinlge record based on data in the payload, controller/controller.js monitors navigation in service cloud and will link the last viewed case to this interaction when it ends.
         *
         * 	When using click to dial, the process flows like so:
         *		1. User clicks phone number
         *		2. Custom dial handler connect.js/dial checks if either contact object or case object and set dial params
         *		3. open cti send command to Workspace to dial the phone number click
         *		4. Params set in custom dialer are passed back into Salesforce in the voice.pop handler
         *  When using Workspace to dial then no contact will be matched.
         */
        var voicePop = function(ixn, params) {
            console.log(log_prefix, 'voice.pop');

            var userData = ixn.userData;

            console.log(log_prefix,"voice.pop - all params: ", JSON.stringify(params));
            console.log(log_prefix, "voice.pop - ixn: ", JSON.stringify(ixn));

            // these params are received from the call to override function
            // var params = {
            //		These fields correspond to the keys sfdc-connector.voice-sfdc-field and sfdc-connector.voice-sfdc-value in Genesys Administrator.
            // 		searchField: message.fieldName, // <-- this comes from Workspace app (WDE setting... propagated in Glue.js.. from the administrator settings)
            //		searchValue: message.fieldValue,  // <-- this comes from Workspace app (WDE setting... propagated in Glue.js.. from the administrator settings)
            //		searchType: searchSettings.voiceSearchType,
            //		ixn: ixn,
            //		popOnly: ixn.parentCallUri !== undefined, /* just a pop for consult calls */
            //		noCase: ixn.callType === 'Outbound'
            // };

            // Inbound call, internal and consult calls, make sure no other tabs interfere with this call
            // also, 'callback' calls
            if(ixn.callType === 'Inbound' || ixn.callType === 'Internal' || ixn.callType === 'Consult' || (ixn.callType === 'Outbound' && userData['ENG_CB_Status'] === 'Success')) {
                if(!config.maintainWindowStateOnNewInteraction) {
                    apIntegration.closeAllTabs();

                    // reset all mini case values
                    sforce.console.fireEvent('RequestValues', 'clear');
                }

                // we need to clear all IVR values from the CTI Popup interface
                // fire a message that the controller will pick up
                // NOTE: This is not clearing sync'd values from MyCustomers
                apIntegration.fireClearEvents();
            }

            var loadedValues = {};

            // broadcast the new voice interaction id so other integrations can use it.
            // specifically the controller/controller.js interface/integration handler
            loadedValues.voiceInteractionId = ixn.id;

            // grab the tracking id from the interaction if it's available
            var trackingId = userData.UData_sstrackingid;
            if(!apUtils.isEmpty(trackingId)) {
                // broadcast the new tracking id received from CTI.
                loadedValues.referenceId = trackingId;
            }

            // grab the callers phone number from the interaction if it's available
            var ani = ixn.userData.r_INFO_CustomerANI; // inbound
            if(apUtils.isEmpty(ani)) {
                ani = (ixn.dnis+'').substr(3); // outbound
            }
            loadedValues.phoneNumber = ani;
            loadedValues.callType = ixn.callType;

            // broadcast the values for this interaction
            apIntegration.fireLoadedEvents(loadedValues);

            // 1. Attempt to find Case by userData.CaseNumber or tracking id (UData_sstrackingid)
            caseObj.search(params).then(
                function(contact, caseObj) {
                    // a case/contact was successfully found
                    if(ixn.callType === 'Inbound' || ixn.callType === 'Internal' || ixn.callType === 'Consult' || (ixn.callType === 'Outbound' && userData['ENG_CB_Status'] === 'Success')) {
                        // inbound or internal transfer calls
                        // this should pop a window in salesforce
                        if (!apUtils.isEmpty(caseObj)) {

                            // the receiving agent should see the case in the primary tab and not as a subtab to a Contact
                            // Remove the contact from the found case to make this happen.
                            // NOTE: at the end of a transfer interaction, the contact will still be linked to the call log, because the contact on the case always takes preference.
                            //params.contact = contact;

                            params.caseId = caseObj.Id;
                            params.caseNumber = caseObj.CaseNumber;

                            // send the case/contact details to the fronend page controller to display in the CTI window
                            apIntegration.fireLoadedEvents({contactObj: contact, caseObj: {Id: caseObj.Id, CaseNumber: caseObj.CaseNumber}});
                        } else {
                            // multiple cases or no cases were found so we pop a SSSW search
                            // NOTE: syncMiniCaseComponent is called below to send the clearview mappings to the search page after it loads
                            //			the sync is managed by the QuickLinksFooterPanel console component
                            apIntegration.searchSSSW(params, 'phoneNumber', ani);
                        }

                        // map clearview/tracking parameters received from Workspace payload in the userData param to the values for case
                        // and send them to the minicase component
                        var caseValues = apUtils.getCaseMappingValues(ixn.userData);
                        console.log(log_prefix, 'case values', ixn.userData, caseValues);
                        apIntegration.syncMiniCaseComponent(caseValues);

                        //  Pop a contact/case if they were passed in the 'params' var and create a new call log
                        //	FLOW: SFDC/pop.js -> AP/case.js -> AP/task.js
                        //		pop.js
                        //			the contact record will pop if it's been passed through params
                        //			triggers case.js pop
                        //		case.js
                        //			pops case if case was passed in through params
                        //			apIntegration.fireLoadedEvents is also called within AP/case.js to pass the found case info back to the page controller.
                        //		pop.js
                        //			after case.js finishes, pop.js will trigger task.js (start)
                        //		task.js
                        //			a new call log record is created
                        //

                        // make sure that a task isn't created for consult calls
                        if(ixn.callType === 'Consult')
                            params.popOnly = true;

                        pop.start(params);
                    } else if(ixn.callType === 'Outbound') {
                        // We don't pop a salesforce tab for outbound because it should already be open.
                        // since no popping occurs for outbound calls we need to manually add tracking information for the current interaction
                        tracking.add(ixn.id, null, contact);

                        if (!apUtils.isEmpty(caseObj)) {
                            params.contact = contact;
                            params.caseId = caseObj.Id;
                            params.caseNumber = caseObj.CaseNumber;

                            // send the case/contact details to the fronend page controller to display in the CTI window
                            apIntegration.fireLoadedEvents({contactObj: contact, caseObj: {Id: caseObj.Id, CaseNumber: caseObj.CaseNumber}});

                            // when using click to dial the case number will be attached to payload without any enquiry type details
                            // we need to force the details from the case to be sent back to Workspace
                            // this will convert Case sobject record to Workspace params
                            // example: { ServiceType: '', ServiceSubType: '', ENG_DimAttribute_1: '', ... }
                            var actionData = apUtils.getCaseAttachmentActionData(ixn.id, caseObj);

                            // push the data to Workspace (this is picked up in the CTI Adapter connected.js native code)
                            console.log(log_prefix, 'Attaching Case Details to Genesys: ', actionData);
                            apIntegration.sendAttachmentData(actionData);

                            // set the case as the what id for the current tracking
                            tracking.setWhatId(ixn.id, caseObj.Id);
                        }

                        // create the initial call log
                        task.start(params);
                    }
                },
                function () { // rejected (no case found during search)
                    // 2. If fail, Attempt to find Contact by userData.ContactId
                    // no cases where found based on CaseNumber or tracking id
                    // the next search is based on contact id if it exists and the user has access
                    // the ContactId field is set in these scenarios:
                    //		1. Click to Dial
                    //			if the phone number clicked is clicked from a contact record
                    //			the ContactId will be passed back through to Salesforce.
                    //		2. When contact is found in Service cloud (either by matching to case or direct phone number search)
                    //			and then a consult or transfer is made
                    var contactId = userData.ContactId;
                    var promise = null;

                    if(!apUtils.isEmpty(contactId)) {
                        params.searchField = 'Id';
                        params.searchValue = contactId;

                        // perform the contact field search and return results
                        // this will resolve() if there is a contact match
                        // this will reject if no contact match was found or multiple contact matches
                        promise = contactFieldSearch(params);
                    } else {
                        promise = $.Deferred().reject();
                    }

                    // map clearview/tracking parameters received from Workspace payload in the userData param to the values for case
                    // and send them to the minicase component
                    var caseValues = apUtils.getCaseMappingValues(ixn.userData);
                    console.log(log_prefix, 'case values', ixn.userData, caseValues);
                    apIntegration.syncMiniCaseComponent(caseValues);

                    return promise.promise();
                }
            ).then(function() {
                // a contact was found by field kvp
            }, function() {
                if(ixn.callType === 'Outbound' && userData['ENG_CB_Status'] !== 'Success') {
                    // an outbound call but not a callback call
                    // since no popping occurs for outbound calls we need to manually add tracking information for the current interaction
                    // if a case or contact above is not matched, then any outbound calllog created here will NEVER be linked to a contact as per requirements
                    //	this is solidified in the task.finish method where we check if call is outbound and contact id was not initially set, then make sure no contact is linked to the call log
                    tracking.add(ixn.id, null, {});

                    // create the initial call log
                    task.start(params);
                } else {
                    // 3. If fail, Attempt to find Contact by phone number (userData.r_INFO_CustomerANI for inbound)
                    // this will catch most inbound/transfer call scenarios
                    phoneNumberSearch(params);
                }
            });
        };

        /**
         * Find a contact based on a KVP (key/value pair)
         */
        var contactFieldSearch = function(params) {
            var d = $.Deferred();

            var searchField = params.searchField;
            var searchValue = params.searchValue;
            var ixn = params.ixn;
            var searchType = params.searchType || null;

            try {
                console.log(log_prefix, 'fieldSearch');

                if(!apUtils.isEmpty(searchValue) && !apUtils.isEmpty(searchValue)) {
                    console.log(log_prefix + 'fieldSearch - search field', searchField, searchValue);

                    apIntegration.findContactByField(searchField, searchValue,
                        function(contact) {
                            if(apUtils.isEmpty(contact) || apUtils.isEmpty(contact.Id)) {
                                // either no contact or multiple contacts
                                // reject this and continue to the next promise
                                console.log(log_prefix + 'fieldSearch - multiple/none', contact);

                                d.reject();
                            } else {
                                console.log(log_prefix + 'fieldSearch', contact);

                                // contact was successfully found
                                contact.Name = $('<div/>').html(contact.Name).text(); // contains HTML chars
                                params.contact = contact;

                                // send loaded notifications to the main page controller
                                // to display the values on the page
                                apIntegration.fireLoadedEvents({contactObj: contact});

                                if(ixn.callType === 'Inbound' || ixn.callType === 'Internal' || ixn.callType === 'Consult' || (ixn.callType === 'Outbound' && ixn.userData['ENG_CB_Status'] === 'Success')) {
                                    // inbound or internal transfer call OR callback call
                                    //  Pop a contact/case if they were passed in the 'params' var and create a new call log
                                    //	FLOW: SFDC/pop.js -> AP/case.js -> AP/task.js
                                    //		pop.js
                                    //			the contact record will pop if it's been passed through params
                                    //			triggers case.js pop
                                    //		case.js
                                    //			pops case if case was passed in through params
                                    //			apIntegration.fireLoadedEvents is also called within AP/case.js to pass the found case info back to the page controller.
                                    //		pop.js
                                    //			after case.js finishes, pop.js will trigger task.js (start)
                                    //		task.js
                                    //			a new call log record is created
                                    //

                                    // make sure that a task isn't created for consult calls
                                    if(ixn.callType === 'Consult')
                                        params.popOnly = true;

                                    pop.start(params);
                                } else if(ixn.callType === 'Outbound') {
                                    // since no popping occurs for outbound calls we need to manually add tracking information for the current interaction
                                    // link the contact to the interaction
                                    tracking.add(ixn.id, null, contact);

                                    // create the initial call log
                                    task.start(params);
                                }

                                d.resolve();
                            }
                        }
                    );
                } else {
                    console.log(log_prefix + 'fieldSearch - no field search');
                    d.reject();
                }
            } catch (e) {
                console.error(log_prefix + e.stack);
                d.reject();
            }

            console.log(log_prefix + 'fieldSearch - finished');
            return d.promise();
        };

        /**
         * if all else fails then try and find contact by phone number
         * NOTE:
         * 	In an OUTBOUND (non callback call) call flow, this will never be hit since it's handled above before entering into this method.
         *	When click to dial is used on Case or Contact, the applicable Id's are sent back through into Salesforce and the above methods should catch them.
         */
        var phoneNumberSearch = function(params) {
            console.log(log_prefix, 'phoneSearch - start');

            // search for an existing case first
            console.log(log_prefix, params);
            var ixn = params.ixn; //message.call;
            var transId = ixn.id;

            // phone number reference field
            var ani = ixn.userData['r_INFO_CustomerANI'];

            console.log(log_prefix, 'processing call', ixn.callType, ani);

            // if the phone number exists, search for contact in SF by phone number
            if(!apUtils.isAnonymousPhoneNumber(ani)) {
                // search salesforce
                apIntegration.findContactByPhone(ani, function(contact) {
                    console.log(log_prefix, 'findContactByPhone results', contact);

                    if(!apUtils.isEmpty(contact) && !apUtils.isEmpty(contact.Id)) {
                        // contact was successfully found
                        contact.Name = $('<div/>').html(contact.Name).text(); // contains HTML chars
                        params.contact = contact;

                        // send loaded notifications to the main page controller
                        // to display the values on the page
                        apIntegration.fireLoadedEvents({contactObj: contact});

                    } else {
                        console.log(log_prefix + 'contact search - multiple contacts');
                        // all other conditions should force the SSSW Search page to open up
                        // NOTE: syncMiniCaseComponent is called below to send the clearview mappings to the search page after it loads
                        //			the sync is managed by the QuickLinksFooterPanel console component
                        apIntegration.searchSSSW(params, 'phoneNumber', ani);
                    }

                    // map parameters received through Workspace in the userData payload to the values for case
                    // push any values received from CTI payload to the mini case component to prepopulate it
                    var caseValues = apUtils.getCaseMappingValues(ixn.userData);
                    console.log(log_prefix, 'case values', ixn.userData, caseValues);
                    apIntegration.syncMiniCaseComponent(caseValues);

                    // inbound or internal transfer call
                    //  Pop a contact/case if they were passed in the 'params' var and create a new call log
                    //	FLOW: SFDC/pop.js -> AP/case.js -> AP/task.js
                    //		pop.js
                    //			the contact record will pop if it's been passed through params
                    //			triggers case.js pop
                    //		case.js
                    //			pops case if case was passed in through params
                    //			apIntegration.fireLoadedEvents is also called within AP/case.js to pass the found case info back to the page controller.
                    //		pop.js
                    //			after case.js finishes, pop.js will trigger task.js (start)
                    //		task.js
                    //			a new call log record is created
                    //
                    pop.start(params);
                }, function(error) {
                    console.log(log_prefix, 'findContactByPhone error', error);
                });
            } else {
                // even though the phone number was private, still pop SSSW search page
                console.log(log_prefix + 'contact search - private number');

                // NOTE: syncMiniCaseComponent is called below to send the clearview mappings to the search page after it loads
                //			the sync is managed by the QuickLinksFooterPanel console component
                apIntegration.searchSSSW(params, 'phoneNumber', ani);

                // map parameters received through Workspace in the userData payload to the values for case
                // push any values received from CTI payload to the mini case component to prepopulate it
                var caseValues = apUtils.getCaseMappingValues(ixn.userData);
                console.log(log_prefix, 'case values', ixn.userData, caseValues);
                apIntegration.syncMiniCaseComponent(caseValues);

                //  Pop a contact/case if they were passed in the 'params' var and create a new call log
                //	FLOW: SFDC/pop.js -> AP/case.js -> AP/task.js
                //		pop.js
                //			the contact record will pop if it's been passed through params
                //			triggers case.js pop
                //		case.js
                //			pops case if case was passed in through params
                //			apIntegration.fireLoadedEvents is also called within AP/case.js to pass the found case info back to the page controller.
                //		pop.js
                //			after case.js finishes, pop.js will trigger task.js (start)
                //		task.js
                //			a new call log record is created
                //
                pop.start(params);
            }

            console.log(log_prefix, 'phoneSearch - finished');
        };

        /**
         * When a user clicks on a phone number in service cloud to dial out, we check the source of which object the phone number came from
         * If it's case, we add the case number into the params that are sent back into the voice.pop method (with CallType of 'Outbound')
         */
        var beforeDial = function(result) {
            //result = (object){"number":"0481133933","objectId":"5005D000003kVRI","objectName":"19893381","object":"Case","displayName":"Case"}
            console.log(log_prefix, 'beforeDial override', result);
            if(apUtils.isEmpty(result))
                return;

            // get the userData object ready
            result.userData = {};

            var foundMatch = false;
            if(!apUtils.isEmpty(result.params)) {
                // using <support:clickToDial> in places throughout service console we pass additional params
                //	example usage: CaseContactSidepanel passes 'CaseNumber:xxx'
                try {
                    var params = result.params.split('|');
                    var parsedParams = {};
                    for(var i=0;i<params.length;i++) {
                        var kvp = params[i].split(':');
                        if(kvp.length === 2) {
                            parsedParams[kvp[0]] = kvp[1];
                        }
                    }
                    if(!apUtils.isEmpty(parsedParams.CaseNumber)) {
                        foundMatch = true;
                        result.userData.CaseNumber = parsedParams.CaseNumber;
                        console.log(log_prefix, 'beforeDial - linking case to outbound call', parsedParams.CaseNumber);
                    }
                } catch(exception) { }
            }

            if(!foundMatch) {
                if(result.object === 'Case' && !apUtils.isEmpty(result.objectName)) {
                    // make sure the case number gets passed in to the voice.pop outbound call
                    console.log(log_prefix, 'beforeDial - linking case to outbound call', result.objectName);
                    result.userData.CaseNumber = result.objectName;
                } else if((result.object === 'Contact' && !apUtils.isEmpty(result.objectId)) || (result.object === 'Account' && result.personAccount === true && !apUtils.isEmpty(result.objectId))) {
                    // make sure the contact id gets passed in to the voice.pop outbound call
                    console.log(log_prefix, 'beforeDial - linking contact to outbound call', result.objectId);
                    result.userData.ContactId = result.objectId;
                }
            }

            // make sure none of the standard flows are invoked in the CTI framework
            result.object = 'Override';
        };

        return {
            setOverrides: setOverrides
        };
    }
);

