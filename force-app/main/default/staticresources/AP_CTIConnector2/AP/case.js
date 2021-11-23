/**
 * @description Supports the case search and pop functionality for CTI Adapter
 * @author Nathan Franklin
 * @date 2018-08-20
 * @changelog
 * 2021-09-07 - Nathan Franklin - Changed the way tab opens happen. If an existing tab is open, then we focus on it. This is to support new 'overflow' permissions where tabs stay open rather than closing on new interaction
 */
define(['util', 'integration', 'config', 'AP/utils', 'AP/integration', 'SFDC/tracking', 'i18next'],
    function (util, sforce, config, apUtils, apIntegration, tracking, i18n) {
        var log_prefix = 'AP/case: ';

        /**
         * Called when initialized, this will set overrides for custom processing when a voice pop case search is required
         */
        var setOverrides = function() {
            // These methods do not need to be exposed publicly
            // Keeping them private adds a layer of control
            config.caseSearchOverride = caseSearch;
            config.casePopOverride = casePop;
        };

        /**
         * this is called from within SFDC/case.js to override a case search
         * Search for a case based on the UData_sstrackingid userData param or the CaseNumber
         */
        var caseSearch = function(params) {
            console.log(log_prefix, 'case search - start', params);

            var d = $.Deferred();
            var ixn = params.ixn;
            var userData = ixn.userData;
            var trackingId = userData.UData_sstrackingid;
            var caseNumber = userData.CaseNumber;

            // case id is 'attached' to the interaction navigating through Service Cloud
            // a Case Id check is done here because this value is passed during transfers and consultation
            var caseId = userData.CaseID;

            // in certain scenarios, it seems the IVR will send a Case Number in the CaseID field.
            // this check will ensure if thats happens, we adjust accordingly
            if(!apUtils.isEmpty(caseId) && caseId.length !== 15 && caseId.length !== 18) {
                caseNumber = caseId;
                caseId = '';
            }


            console.log(log_prefix, 'caseSearch - start', params, trackingId, caseNumber);


            if (config.SHOW_CASE && !apUtils.isEmpty(ixn.userData)) { // userData not defined for internal calls
                if (!apUtils.isEmpty(caseNumber)) {
                    // call apex remote method to get the case with the contact record
                    apIntegration.getCaseByCaseNumber(caseNumber, function(caseObj) {
                        if(!apUtils.isEmpty(caseObj)) {
                            // a case was found
                            console.log(log_prefix, 'case found: ', caseObj, ' contact: ', caseObj.Contact);
                            d.resolve(caseObj.Contact, caseObj);
                        } else {
                            // no case was found
                            console.log(log_prefix, 'case not found');
                            d.reject();
                        }
                    }, function(error, event) {
                        console.error(log_prefix, 'getCase Error', error, event);
                        d.reject();
                    });
                } else if(!apUtils.isEmpty(trackingId)) {
                    // search for a case by tracking number
                    apIntegration.getCaseByReferenceId(trackingId, function(cases) {
                        if(!apUtils.isEmpty(cases)) {
                            // found some cases
                            console.log(log_prefix, 'case found', cases);

                            if(cases.length == 1) {
                                // only 1 case found
                                // this is the optimal result as this allows the caller to pop the case tab open
                                console.log(log_prefix, 'case found: ', cases[0], ' contact: ', cases[0].Contact);
                                d.resolve(cases[0].Contact, cases[0]);
                            } else {
                                // more than 1 case found
                                // send a notification of success back to caller
                                // the call will check for the values and act accordingly
                                d.resolve(null, null);
                            }
                        } else {
                            console.log(log_prefix, 'keep going with search');
                            d.reject();
                        }
                    }, function(error, event) {
                        console.error(log_prefix, 'getCaseByReferenceId Error', error, event);
                        d.reject();
                    });
                } else if(!apUtils.isEmpty(caseId)) {
                    // search for a case by tracking number
                    apIntegration.getCaseById(caseId, function(caseObj) {
                        if(!apUtils.isEmpty(caseObj)) {
                            // a case was found
                            console.log(log_prefix, 'case found: ', caseObj, ' contact: ', caseObj.Contact);
                            d.resolve(caseObj.Contact, caseObj);
                        } else {
                            // no case was found
                            console.log(log_prefix, 'case not found');
                            d.reject();
                        }
                    }, function(error, event) {
                        console.error(log_prefix, 'getCaseById Error', error, event);
                        d.reject();
                    });
                } else {
                    console.log(log_prefix, 'no case values matched in interaction');
                    d.reject();
                }
            } else {
                console.log(log_prefix, 'no case search');
                d.reject();
            }

            console.log(log_prefix, 'search - finished');
            return d.promise();
        };

        /**
         * this is called from within SFDC/case.js to override a case pop after a case is found
         *
         * Flow:
         *	1. connected.js -> pop.js (caseObj.pop(params)) -> case.js (this file)
         *
         * AP Contact centre does not create cases automatically from the CTI flow
         * The casePop has been kept intact to pop existing cases where either
         * 			1. CaseNumber is passed by Workspace and apex remote methods finds a matching case in SF
         *			2. Tracking ID is passed by Workspace and apex remote methods finds a matching case in SF
         *		This happens in the caseSearch method above.
         */
        var casePop = function(params) {
            console.log(log_prefix, 'casePop', params);
            var ixn = params.ixn;

            // contact is passed in from AP/connected.js
            // it's set before pop.start is called which is rerouted to this method because of the overrides
            var contact = params.contact;

//			var settings = config.ALL;
//			var caseKVPField = apUtils.getCtiOption(settings, 'FieldSearchSettings', 'SearchCaseKVP', 'CaseNumber');
            var searchKVP = params.searchKVP || null;
            var caseId = params.caseId || null;
            var caseNumber = params.caseNumber || null;
            var popOnly = params.popOnly || false;
            var noCase = params.noCase || false;

            var d = $.Deferred();
            var primaryTabId = tracking.getPrimaryTabId(ixn.id);

            if (config.SHOW_CASE && !noCase) { // don't know why !popOnly was here.
                var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
                var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();

                if (caseId !== null) { // existing case
                    console.log(log_prefix + 'redirect to existing case - ' + caseId +
                        ' under ' + primaryTabId + ' or ' + currentPrimaryTabId);

                    // send loaded notifications to the main page controller
                    // trigger interface changes like displaying new case number etc..
                    apIntegration.fireLoadedEvents({caseObj: {Id: caseId, CaseNumber: caseNumber}});

                    // this is called from below AFTER the tab has successfully been popped
                    var tabSuccess = function (tab) {
                        if (tab.success) {
                            d.resolve(caseId, caseNumber); // no change in case id here
                        }
                        else {
                            console.warn(log_prefix + 'could not open tab');
                            d.reject();
                        }
                    };

                    var url = '/' + caseId;
                    if (config.OPEN_EXISTING_CASE_IN_EDIT_MODE) {
                        url += '/e';
                    }

                    // if primary tab open, then use it to show a sub-tab
                    if (primaryTabId !== null) {
                        console.log(log_prefix + 'primaryTabId=' + primaryTabId);

                        sforce.console.openSubtab(primaryTabId, url, true, (!apUtils.isEmpty(caseNumber) ? caseNumber : i18n.t('case.existing')), null,
                            function (tab) {
                                tabSuccess(tab);
                            }
                        );
                    } else if (!apUtils.isEmpty(currentPrimaryTabId) && !apUtils.isEmpty(currentPrimaryTabObjectId) &&
									(!apUtils.isEmpty(contact) && (currentPrimaryTabObjectId === contact.Id || currentPrimaryTabObjectId === contact.AccountId))) {
                        console.log(log_prefix + 'currentPrimaryTabId=' + currentPrimaryTabId);

                        // if primary tab already exists then use that
                        sforce.console.openSubtab(currentPrimaryTabId, url, true, (!apUtils.isEmpty(caseNumber) ? caseNumber : i18n.t('case.existing')), null,
                            function (tab) {
                                tabSuccess(tab);
                            }
                        );
                    } else {
                        console.log(log_prefix + 'open new primary tab');

                        sforce.console.openPrimaryTab(null, url, true, (!apUtils.isEmpty(caseNumber) ? caseNumber : i18n.t('case.existing')), function (tab) {
                            if(!tab.success) {
                                apIntegration.getPrimaryTabIdByUrl(url, function(primaryTabId) {
                                    console.log(log_prefix, 'found existing tab by url', primaryTabId);

                                    // found a matching tab and returned the Id
                                    // we do not refresh this tab but just focus on it. this is because the user may be making changes to the case which could be blown away if we refresh
                                    sforce.console.focusPrimaryTabById(primaryTabId, function(result) {
                                        result.id = primaryTabId;
                                        tabSuccess(result);
                                    });
                                });
                            } else {
                                tabSuccess(tab);
                            }
                        });
                    }
                } else {
                    console.log(log_prefix + 'no case');
                    d.reject();
                }
            }
            else {
                console.log(log_prefix + 'no case pop');
                d.reject();
            }

            console.log(log_prefix + 'pop - finished');
            return d.promise();
        };

        return {
            setOverrides: setOverrides
        };
    }
);

