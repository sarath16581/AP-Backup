/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
* Define the SFDC case methods
*/
define(['util', 'SFDC/api', 'config', 'i18next', 'SFDC/tracking', 'agent/interaction'],
                function (util, sfdc, config, i18n, tracking, interaction) {
    var log_prefix = "SFDC/case: ";
    var _caseKVP = null;
    var _activeCases = {}; // TODO: should be a fixed size cache

    /**
     * Find a case
     * @param params
     * @returns a promise
     */
    var search = function(params) {
        console.log(log_prefix + "search");

        if (config.caseSearchOverride) {
            return config.caseSearchOverride(params);
        }

        var d = $.Deferred();
        var ixn = params.ixn;
        
        if (config.SHOW_CASE && _caseKVP !== null && ixn.userData !== undefined ) { // userData not defined for internal calls
            var caseNumber = ixn.userData[_caseKVP];
            console.log(log_prefix + "search " + _caseKVP + "=" + caseNumber);

            if (caseNumber !== undefined && caseNumber !== '') {
                ConnectorController.findCase(caseNumber,
                    function (caseObj) {
                        if (caseObj !== null) {
                            console.log(log_prefix + "case found (" + caseObj.Id + ', ' + caseObj.ContactId + ')');
                            ConnectorController.getContact(caseObj.ContactId, null,
                                function (contact) {
                                    if (contact !== null) {
                                        d.resolve(contact, caseObj.Id, caseNumber);
                                    }
                                    else {
                                        console.log(log_prefix + "contact not found");
                                        d.reject();
                                    }
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "case not found");

                            if (config.SEARCH_CASE_IF_WRONG_CASE) {
                                var url = '/apex/CRMCaseSearch?id=' + ixn.id + '&caseNumber=' + caseNumber;
                                console.log(log_prefix + "opening case search: " + url);
                                tracking.setParams(params);
                                sfdc.openPrimaryTab(null, url, true, i18n);
                                d.resolve(null);
                            }
                            else {
                                console.log(log_prefix + "keep going with search");
                                d.reject();
                            }
                        }
                    }
                );
            }
            else {
                console.log(log_prefix + "no case KVP in interaction");
                d.reject();
            }
        }
        else {
            console.log(log_prefix + "no case search");
            d.reject();
        }

        console.log(log_prefix + "search - finished");
        return d.promise();
    };

    /**
     * Pop a case inside SFDC. Work out if a new case is created.
     * @param params
     * @returns a promise
     */
    var pop = function(params) {
        console.log(log_prefix + "pop");

        if (config.casePopOverride) {
            return config.casePopOverride(params);
        }

        var ixn = params.ixn;
        var contact = params.contact;
        var searchKVP = params.searchKVP || null;
        var caseId = params.caseId || null;
        var caseNumber = params.caseNumber || null;
        var popOnly = params.popOnly || false;
        var noCase = params.noCase || false;
        
        var d = $.Deferred();
        var primaryTabId = tracking.getPrimaryTabId(ixn.id);

        if (config.SHOW_CASE && !popOnly && !noCase) {
            var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
            var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();

            // automatically create a new case?
            if (config.NEW_CASE_ON_POP && caseId === null) {

                // map what KVPs are going to be sent to SFDC for a new case
                var caseMap = {};
                if (ixn.userData !== undefined) {
                    var caseMapArray = config.CASE_MAP.split(',');
                    $.each(caseMapArray, function (index, value) {
                        var fieldMap = value.split(':');
                        var sfdcField = fieldMap[0];

                        if (fieldMap.length > 1) {
                            var genesysValue = ixn.userData[fieldMap[1]];
                            if (genesysValue !== undefined) {
                                console.log(log_prefix + "Map - " + sfdcField + ":" + genesysValue);
                                caseMap[sfdcField] = genesysValue;
                            }
                        }
                    });
                }

                // check to see if we create the case - base this on if a particular KVP is present
                if (ixn.userData[searchKVP] !== undefined || config.NEW_CASE_IF_NO_SEARCH_KVP_PRESENT) {
                    ConnectorController.createCase(contact ? contact.Id : null, contact ? (contact.AccountId || null) : null,
                                    i18n.t('mediaType.' + ixn.mediaType), i18n.t('case.new'), ixn.userData, caseMap,
                        function (caseObj) {
                            if (caseObj !== null) {
                                console.log(log_prefix + "redirect to new case - " + caseObj.Id +
                                    ' under ' + primaryTabId + " or " + currentPrimaryTabId);

                                var tabSuccess = function (tab) {
                                    if (tab.success) {
                                        // update the case number KVP
                                        if (_caseKVP !== null && caseObj.CaseNumber) {
                                            var params = {
                                                id: ixn.id,
                                                mediaType: ixn.mediaType,
                                                userData: {}
                                            };

                                            params.userData[_caseKVP] = caseObj.CaseNumber;

                                            if (contact) {
                                                _activeCases[contact.Id] = caseObj.CaseNumber;
                                            }

                                            var msg = {
                                                action: "AttachData",
                                                actionData: {
                                                    id: ixn.id,
                                                    userData: params.userData
                                                }
                                            };

                                            interaction.attachData(msg);
                                        }

                                        // send up the new SFDC case id
                                        d.resolve(caseObj.Id);
                                    }
                                    else {
                                        console.warn(log_prefix + "could not open tab");
                                        d.reject();
                                    }
                                };

                                var url = '/' + caseObj.Id;
                                if (config.OPEN_NEW_CASE_IN_EDIT_MODE) {
                                    url += '/e';
                                }

                                // if primary tab open, then use it to show a sub-tab
                                if (primaryTabId !== null) {
                                    console.log(log_prefix + "primaryTabId=" + primaryTabId);
                                    
                                    sfdc.openSubtab(primaryTabId, url, true, i18n.t('case.new'), null,
                                        function (tab) {
                                            tabSuccess(tab);
                                        }
                                    );
                                }
                                else if (currentPrimaryTabId !== null &&
                                            currentPrimaryTabObjectId !== null &&
                                            ((contact && currentPrimaryTabObjectId === contact.Id) ||
                                            (contact && currentPrimaryTabObjectId === contact.AccountId))) {

                                    console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);

                                    // if primary tab already exists then use that
                                    sfdc.openSubtab(currentPrimaryTabId, url, true, i18n.t('case.new'), null,
                                        function (tab) {
                                            tabSuccess(tab);
                                        }
                                    );
                                }
                                else {
                                    console.log(log_prefix + "open new primary tab");

                                    sfdc.openPrimaryTab(null, url, true, i18n.t('case.new'),
                                        function (tab) {
                                            tabSuccess(tab);
                                        }
                                    );
                                }
                            }
                            else {
                                console.warn(log_prefix + "Could not create case");
                                d.reject();
                            }
                        });
                }
                else {
                    console.log(log_prefix + "No present KVP - did not create case");
                    d.reject();
                }
            }
            else if (caseId !== null) { // existing case
                console.log(log_prefix + "redirect to existing case - " + caseId +
                    ' under ' + primaryTabId + " or " + currentPrimaryTabId);

                var tabSuccess = function (tab) {
                    if (tab.success) {
                        _activeCases[contact.Id] = caseNumber;
                        d.resolve(caseId); // no change in case id here
                    }
                    else {
                        console.warn(log_prefix + "could not open tab");
                        d.reject();
                    }
                };

                var url = '/' + caseId;
                if (config.OPEN_EXISTING_CASE_IN_EDIT_MODE) {
                    url += '/e';
                }

                // if primary tab open, then use it to show a sub-tab
                if (primaryTabId !== null) {
                    console.log(log_prefix + "primaryTabId=" + primaryTabId);

                    sfdc.openSubtab(primaryTabId, url, true, i18n.t('case.existing'), null,
                        function (tab) {
                            tabSuccess(tab);
                        }
                    );
                }
                else if (currentPrimaryTabId !== null &&
                            currentPrimaryTabObjectId !== null &&
                            (currentPrimaryTabObjectId === contact.Id ||
                            currentPrimaryTabObjectId === contact.AccountId)) {
                    console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);

                    // if primary tab already exists then use that
                    sfdc.openSubtab(currentPrimaryTabId, url, true, i18n.t('case.existing'), null,
                        function (tab) {
                            tabSuccess(tab);
                        }
                    );
                }
                else {
                    console.log(log_prefix + "open new primary tab");

                    sfdc.openPrimaryTab(null, url, true, i18n.t('case.existing'),
                        function (tab) {
                            tabSuccess(tab);
                        }
                    );
                }
            }
            else {
                console.log(log_prefix + "no case");
                d.reject();
            }
        }
        else {
            console.log(log_prefix + "no case pop");
            d.reject();
        }

        console.log(log_prefix + "pop - finished");
        return d.promise();
    };

    var getCaseNumber = function(contactId) {
        console.log(log_prefix + "getCaseNumber contact - " + contactId);
        var caseNumber = _activeCases[contactId];
        if (caseNumber === undefined) {
            caseNumber = null;
        }
        
        return caseNumber;
    };

    /**
     * Workout the Case KVP used in Genesys so it can be set/searched on.
     * @param searchCaseKVP
     */
    var initialize = function(searchCaseKVP) {
        if (searchCaseKVP !== null && searchCaseKVP !== "") {
            _caseKVP = searchCaseKVP;
        }
    };

    return {
        initialize: initialize,
        search: search,
        pop: pop,
        getCaseNumber: getCaseNumber
    };
});