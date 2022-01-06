/***********************************************************************
 * Copyright Cameron Rich. All Rights Reserved
 ************************************************************************/

var _currentContactName = null;
var _currentContactId = null;

/**
 * Define the SFDC test harness methods
 */
define(['util', 'SFDC/tracking'], function (util, tracking) {
    var _currentTabId = null;
    var _currentSubtabId = null;
    var _subtabIds = [];
    var _isValidTab = true;
    var _clickToDialListener = null;

    var interaction = {
        cti: {
            getCallCenterSettings: function(f) {
                var response = {
                    result: '{"/CaseSettings/NewCaseOnPop":"false","/CaseSettings/ShowCase":"true","/ConnectorSettings/AgentChannels":"voice,email,chat","/ConnectorSettings/PersistUserSettings":"true","/ConnectorSettings/ReadOnly":"false","/ConnectorSettings/URI":"https://demosrv.live.genesys.com:8043","/ConnectorSettings/UseDefaultPlace":"false","/FieldSearchSettings/ChatSearchType":"name","/FieldSearchSettings/EmailSearchType":"email","/FieldSearchSettings/SearchCaseKVP":"CaseNumber","/FieldSearchSettings/SearchChatField":"Name","/FieldSearchSettings/SearchChatKVP":"FullName","/FieldSearchSettings/SearchEmailField":"Email","/FieldSearchSettings/SearchEmailKVP":"FromAddress","/FieldSearchSettings/SearchVoiceField":"Phone","/FieldSearchSettings/SearchVoiceKVP":"contact_info","/FieldSearchSettings/VoiceSearchType":"phoneNumber","/PopSettings/PopOnConsultCall":"false","/PopSettings/PopOnMediaEstablished":"true","/PopSettings/PopOnVoiceEstablished":"false","/PopSettings/ShowContact":"true","/TaskSettings/CreateTask":"true","/TaskSettings/NewTaskOnPop":"true","/displayNameLabel":"Display Name","/internalNameLabel":"Internal Name","/reqGeneralInfo/reqAdapterUrl":"/apex/CRMConnector","/reqGeneralInfo/reqDescription":"SFDC Genesys Connector","/reqGeneralInfo/reqSoftphoneHeight":"250","/reqGeneralInfo/reqSoftphoneWidth":"230","/reqGeneralInfo/reqUseApi":"true","/reqGeneralInfo/reqVersion":"1","/reqGeneralInfo/reqDisplayName":"SFDC Genesys Connector","/reqGeneralInfo/reqInternalName":"SFDCGenesysConnector"}'
                };

                f(response);
            },
            enableClickToDial: function() {
            },
            onClickToDial: function(listener) {
                _clickToDialListener = listener;
            },
            clickToDial: function(result) { // test method
                var params = {
                    result: result
                };
                _clickToDialListener(params);
            }
        }
    };

    var console = {
        isInConsole: function() {
            return true;
        },
        setCustomConsoleComponentButtonText: function() {
        },
        setCustomConsoleComponentButtonStyle: function() {
        },
        addEventListener: function(eventType, eventHandler) {
            util.getInstance(eventType).subscribe(eventHandler);
        },
        fireEvent: function(eventType, message) {
            var result = {
                message: message
            };
            util.getInstance(eventType).publish(result);
        },
        openPrimaryTab: function(id, URL, active, tabLabel, response, name) {
            _currentTabId = 'openPrimaryTab-' + tabLabel;

            var tab = {
                success: _isValidTab,
                id: _currentTabId
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        openSubtab: function(primaryTabId, URL, active, tabLabel, id, response, name) {
            _currentSubtabId = "openSubtab-" + tabLabel;
            _subtabIds.push(_currentSubtabId);

            var tab = {
                success: true,
                id: _currentSubtabId
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        refreshPrimaryTabByName: function(name, active, response, fullRefresh) {
            var tab = {
                success: false
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        refreshPrimaryTabById: function(id, active, response) {
            var tab = {
                success: false
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        getFocusedPrimaryTabId: function(response) {
            var tab = {
                success: _isValidTab,
                id: "openPrimaryTabFooBar"
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        onFocusedPrimaryTab : function(response) {
            var tab = {
                id: "PrimaryTabFooBar",
                objectId: "123456789012345"
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        closeTab: function(id, response) {
            var tab = {
                success: true
            };

            if (response !== undefined && response !== null) {
                response(tab);
            }
        },
        testGetCurrentTabId: function() {
            return _currentTabId;
        },
        testGetCurrentSubtabId: function() {
            return _currentSubtabId;
        },
        testIsSubtabId: function(subtabId) {
            return $.inArray(subtabId, _subtabIds);
        },
        testSetCurrentContact: function(id, name) {
            _currentContactId = id;
            _currentContactName = name;
        },
        testReset: function() {
            _currentContactId = null;
            _currentContactName = null;
            _currentTabId = null;
            _currentSubtabId = null;
            tracking.reset();
            _subtabIds.length = 0;
        },
        testValidTab: function(isValidTab) {
            _isValidTab = isValidTab;
        }
    };

    return {
        console: console,
        interaction: interaction
    };
});

var ConnectorController = {
    findContact: function(searchId, searchValue, response) {
        var contact = {
            Id: _currentContactId,
            Name: _currentContactName
        };

        if (response !== undefined && response !== null) {
            if (searchValue === 'multiple') {
                contact.Id = undefined;
            }
            else if (searchValue === 'unknown') {
                contact = null;
            }

            response(contact);
        }
    },
    findCase: function(caseNumber, response) {
        var caseObj = null;

        if (caseNumber === "123") {
            caseObj = {
                Id: "case-123",
                CaseNumber: "123",
                ContactId: _currentContactId
            };
        }

        if (response !== undefined && response !== null) {
            response(caseObj);
        }
    },
    createTask: function(contactId, whatId, subject, userData, taskMap, response) {
        var task = {
            Type: 'Interaction',
            Status: 'In Progress',
            Subject: subject,
            WhoId: contactId,
            WhatId: whatId,
            Id: "createTask"
        };

        if (response !== undefined && response !== null) {
            response(task);
        }
    },
    closeTask: function(taskId, whatId, subject, comments, userData, dispositionKVP, taskMap, callDuration, response) {
        var task = {
            Id: "closeTask"
        };

        if (response !== undefined && response !== null) {
            response(task);
        }
    },
    createCase: function(contactId, accountId, mediaType, subject, userData, caseMap, response) {
        var caseObj = {
            Id: "case-" + contactId
        };

        if (response !== undefined && response !== null) {
            response(caseObj);
        }
    },
    getContact : function(contactId, field, response) {
        var contact = null;

        if (contactId !== null) {
            contact = {
                Id: _currentContactId,
                Name: _currentContactName
            };
        }

        if (response !== undefined && response !== null) {
            response(contact);
        }
    }
};

