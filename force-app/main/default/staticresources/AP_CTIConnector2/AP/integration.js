/**
 * @description Various methods for integrating with console functions and remote apex functions
 * @author Nathan Franklin
 * @date 2018-08-20
 * @changelog
 * 2021-09-07 - Nathan Franklin - Added getPrimaryTabIdByUrl and modified searchSSSW (added tab name)
 */
define(['config', 'AP/utils', 'SFDC/tracking', 'i18next'],
    function (config, apUtils, tracking, i18n) {
        var log_prefix = 'AP/integration: ';

        /**
         * When case/contacts are loaded from CTI logic, notify the main page controller for display logic to be updated
         */
        var fireLoadedEvents = function(params) {

            // a contact was loaded from the call to search for a case
            // if the caseNumber or contact values exist then we need to report back to our main page controller
            if(!apUtils.isEmpty(params) && !apUtils.isEmpty(params.contactObj) && !apUtils.isEmpty(params.contactObj.Id) && !apUtils.isEmpty(params.contactObj.Name)) {
                sforce.console.fireEvent('CTILoaded_Contact', JSON.stringify({contactId: params.contactObj.Id, name: params.contactObj.Name}));
            }

            if(!apUtils.isEmpty(params) && !apUtils.isEmpty(params.caseObj) && !apUtils.isEmpty(params.caseObj.Id) && !apUtils.isEmpty(params.caseObj.CaseNumber)) {
                sforce.console.fireEvent('CTILoaded_Case', JSON.stringify({caseId: params.caseObj.Id, caseNumber: params.caseObj.CaseNumber}));
            }

            if(!apUtils.isEmpty(params) && !apUtils.isEmpty(params.phoneNumber)) {
                sforce.console.fireEvent('CTILoaded_PhoneNumber', JSON.stringify({phoneNumber: params.phoneNumber}));
            }

            // sends this when a new call is received
            // this param is passed from AP/connected.js in the voicePop method
            if(!apUtils.isEmpty(params) && !apUtils.isEmpty(params.voiceInteractionId)) {
                sforce.console.fireEvent('CTILoaded_VoiceInteractionId', JSON.stringify({voiceInteractionId: params.voiceInteractionId}));
            }

            // this param is passed from AP/connected.js in the voicePop method
            if(!apUtils.isEmpty(params) && !apUtils.isEmpty(params.referenceId)) {
                sforce.console.fireEvent('CTILoaded_ReferenceId', JSON.stringify({referenceId: params.referenceId}));
            }

        };

        /**
         * Send a message to the interface controller that it should clear all the display values
         */
        var fireClearEvents = function() {
            sforce.console.fireEvent('CTILoaded_ClearValues');
        };

        /**
         * Send attachment data to Workspace. This is used to send updates based on the current interaction.
         */
        var sendAttachmentData = function(actionData) {
            console.log(log_prefix, 'sendAttachmentData - start', actionData);
            var payload = { action: 'AttachData', actionData: actionData };
            sforce.console.fireEvent('CTIEvent', JSON.stringify(payload), function (ctiresult) {
                console.log(log_prefix, 'CTIEvent Result', ctiresult);
            });
        };

        /**
         * Close every primary tab in service cloud.
         */
        var closeAllTabs = function() {
            sforce.console.getPrimaryTabIds(function(result){
                for(i = 0; i < result.ids.length; i++)
                    sforce.console.closeTab(result.ids[i]);
            });
        };

        /**
         * this will push the values received from queue mappings and ivr responses to the Mini Case component
         */
        var syncMiniCaseComponent = function(mappings) {
            // note these values should be pushed to minicase in a specific order due to controlling field dependencies
            var keys = config.CASE_SYNC_ORDER;

            for(var i=0;i<config.CASE_SYNC_ORDER.length;i++) {
                if(keys[i] === 'Type_and_Produce__c') {
                    // special parameter
                    if(!apUtils.isEmpty(mappings.Type) && !apUtils.isEmpty(mappings.ProductCategory__c) && !apUtils.isEmpty(mappings.ProductSubCategory__c)) {
                        var typeProduct = mappings.Type + '|' +  mappings.ProductCategory__c + '|' + mappings.ProductSubCategory__c;
                        sforce.console.fireEvent('MiniCaseFieldSet_Type_and_Product__c', typeProduct);
                    }
                } else {
                    var fieldName = 'MiniCaseFieldSet_' + keys[i];
                    var fieldValue = mappings[keys[i]];
                    if(!apUtils.isEmpty(fieldValue)) {
                        sforce.console.fireEvent(fieldName, fieldValue);
                    }
                }
            }

            sforce.console.fireEvent('CTILoaded_CaseMappings', JSON.stringify(mappings));
        };

        /**
         * This will pop the SSSW search page and pass the phone number for a more extensive search
         *
         */
        var searchSSSW = function(params, type, searchString) { // renamed from doSearch
            console.log(log_prefix, 'searchSSSW', params, type, searchString);

            var title = 'MyCustomers Search';
            var tabName = 'ctissswsearch';
            var url = '/apex/SSSWSearch?cti=1&aId=null'  ;//+ '&ANI=' +  params.ixn.id;

            if(type === 'phoneNumber' && !apUtils.isEmpty(searchString) && !apUtils.isAnonymousPhoneNumber(searchString)) {
                url += '&ANI=' + searchString;
                tabName += searchString;
                title += ' - ' + searchString;
            }
            console.log(log_prefix, 'searchSSSW url', url);

            sforce.console.openPrimaryTab(null, url, true, title, function(result) {}, tabName);
        };

        var isPersonAccount = function(accountId, completionCallback, failedCallback) {
            console.log(log_prefix, 'getIsPersonAccount - start', accountId);
            invokeController('AP_ConnectorController2.isPersonAccount', [accountId], completionCallback, failedCallback);
            console.log(log_prefix, 'getIsPersonAccount - end');
        };

        /**
         * Search Salesforce for the contact by the phone number that was received
         */
        var findContactByPhone = function(phoneNumber, completionCallback, failedCallback) {
            console.log(log_prefix, 'findContactByPhone - start', phoneNumber);
            invokeController('AP_ConnectorController2.findContactByPhone', [phoneNumber], completionCallback, failedCallback);
            console.log(log_prefix, 'findContactByPhone - end');
        };

        var findContactByField = function(fieldName, fieldValue, completionCallback, failedCallback) {
            console.log(log_prefix, 'findContactByField - start', fieldName, fieldValue);
            invokeController('AP_ConnectorController2.findContactByField', [fieldName, fieldValue], completionCallback, failedCallback);
            console.log(log_prefix, 'findContactByField - end');
        };

        var getCaseByCaseNumber = function(caseNumber, completionCallback, failedCallback) {
            console.log(log_prefix, 'getCaseByCaseNumber - start', caseNumber);
            invokeController('AP_ConnectorController2.getCaseByCaseNumber', [caseNumber], completionCallback, failedCallback);
        };

        var getCaseById = function(id, completionCallback, failedCallback) {
            console.log(log_prefix, 'getCaseById - start', id);
            invokeController('AP_ConnectorController2.getCaseById', [id], completionCallback, failedCallback);
        };

        var getCaseByReferenceId = function(referenceId, completionCallback, failedCallback) {
            console.log(log_prefix, 'getCaseByReferenceId - start', referenceId);
            invokeController('AP_ConnectorController2.getCaseByReferenceId', [referenceId], completionCallback, failedCallback);
        };

        //	This is not required.
        //  		var createCase = function(contact, origin, subject, userData, caseMappings, completionCallback, failedCallback) {
        //  		    var contactId = (!apUtils.isEmpty(contact) ? contact.Id : null);
        //  		    var accountId = (!apUtils.isEmpty(contact) ? contact.AccountId : null);
        //  		    invokeController('AP_ConnectorController2.createCase', [contactId, accountId, origin, subject, userData, caseMappings], completionCallback, failedCallback);
        //  		};

        /**
         * Create a task
         */
        var createTask = function(contactId, whatId, subject, userData, taskMappings, completionCallback, failedCallback) {
            invokeController('AP_ConnectorController2.createTask', [contactId, whatId, subject, userData, taskMappings], completionCallback, failedCallback);
        };

        /**
         * Close a task at the end of the interaction
         */
        var closeTask = function(taskId, whatId, whoId, subject, comments, userData, dispositionKVP, taskMappings, duration, interactionId, callType, completionCallback, failedCallback) {
            invokeController('AP_ConnectorController2.closeTask', [taskId, whatId, whoId, subject, comments, userData, dispositionKVP, taskMappings, duration, interactionId, callType], completionCallback, failedCallback);
        };

        /**
         * If an existing tab is already opened then we attempt to find it an refresh it
         * This allows more granular control and does not rely on tab name's which doesn't always work
         */
        var getPrimaryTabIdByUrl = function(url, successCallback) {
            var nextIteration = function(ids, url, matchedCallback) {
                var id = ids.shift();
                if(id === undefined) {
                    return;
                }

                sforce.console.getPageInfo(id, function(result) {
                    var obj = JSON.parse(result.pageInfo);
                    if(obj.objectId && ('/' + obj.objectId.substr(0, 15)) === url.substr(0, 16) && /\/([A-Za-z0-9]{15}|[A-Za-z0-9]{18})$/i.test(url)) {
                        // this will check the 15 character id of the tab
                        if(matchedCallback)
                            matchedCallback(id);
                    } else if(obj.url === url) {
                        if(matchedCallback)
                            matchedCallback(id);
                    } else {
                        nextIteration(ids, url, matchedCallback);
                    }
                });
            }

            sforce.console.getPrimaryTabIds(function(result) {
                if(result.success && result.ids) {
                    // NOTE: JSON.parse(JSON.stringify( to clone
                    nextIteration(JSON.parse(JSON.stringify(result.ids)), url, successCallback);
                }
            });
        }

        /**
         * Internal method for invoking Apex Remote Actions
         */
        var invokeController = function(controllerMethod, params, completionCallback, failedCallback) {
            console.log(log_prefix, 'invokeController - start', controllerMethod, params);

            // add a callback for when the request is complete
            var responseHandler = function(response, event) {
                console.log(log_prefix, 'invoke remote - response received', event, response);

                if(event.status) {
                    // the remote action was invoked successfully
                    completionCallback(response);
                } else {
                    // the remote action failed
                    failedCallback(response, event);
                }
            };

            var args = params.slice(0); // clone array to bypass by ref
            args.unshift(controllerMethod); // the controller method to the start of the args list
            args.push(responseHandler); // add the response handler callback

            console.log(log_prefix, 'invokeController', args);

            Visualforce.remoting.Manager.invokeAction.apply(Visualforce.remoting.Manager, args);
        };

        return {
            getPrimaryTabIdByUrl: getPrimaryTabIdByUrl,
            fireLoadedEvents: fireLoadedEvents,
            syncMiniCaseComponent: syncMiniCaseComponent,
            searchSSSW: searchSSSW,
            sendAttachmentData: sendAttachmentData,
            getCaseByReferenceId: getCaseByReferenceId,
            closeAllTabs: closeAllTabs,
            closeTask: closeTask,
            createTask: createTask,
            findContactByPhone: findContactByPhone,
            findContactByField: findContactByField,
            getCaseByCaseNumber: getCaseByCaseNumber,
            getCaseById: getCaseById,
            isPersonAccount: isPersonAccount,
            fireClearEvents: fireClearEvents
        }
    }
);

