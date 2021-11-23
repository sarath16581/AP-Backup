/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

define(['jquery', 'util', 'config', 'SFDC/api', 'agent/session', 'agent/comms', 'SFDC/tracking'],
            function($, util, config, sfdc, session, comms, tracking) {
    var log_prefix = "Glue: ";
    var _connectionTimeout = null;
    var _connectionDate = new Date().getTime() + 'a';

    function processMessage(obj) {
        if (obj.action !== 'Complete') {
            console.log(log_prefix + "processMessage - " + obj.action);
        }
        var message = { };

        switch (obj.action) {
            case "OpenObject":
                switch (obj.type) {
                    case "Voice":
                        // replicate GWS message as much as possible
                        message = {
                            channel: "/v2/me/calls",
                            data: {
                                notificationType: "StatusChange",
                                call: {
                                    id: obj.id,
                                    state: "Established",
                                    ani: obj.source,
                                    dnis: obj.destination,
                                    callType: obj.calltype,
                                    userData: obj.userData,
                                    // Start - APRivera - 23/01/18 - Additional parameters
                                    enquiryType : obj.userData.r_EnquiryType,
                                    consignmentNumber : obj.userData.r_RecordID,
                                    phoneNumber : obj.userData.PhoneNumber,
                                    customerSegment : obj.userData.CustomerSegment,
                                    serviceType : obj.userData.ServiceType,
                                    serviceSubType : obj.userData.ServiceSubType,
                                    exitCode : obj.userData.r_ExitCode,
                                    atlFlag : obj.userData.r_ATL
                                    // End - APRivera - 23/01/18 - Additional parameters

                                },
                                messageType: "CallStateChangeMessage",
                                fieldName: obj.fieldName,       // WDE setting
                                fieldValue: obj.fieldValue      // WDE setting
                            }
                        };
                        break;

                    case "Email":
                        message = {
                            channel: "/v2/me/emails",
                            data: {
                                notificationType: "StatusChange",
                                email: {
                                    id: obj.id,
                                    state: "Processing",
                                    to: obj.destination,
                                    from: obj.source,
                                    userData: obj.userData
                                },
                                messageType: "EmailStateChangeMessage",
                                fieldName: obj.fieldName,       // WDE setting
                                fieldValue: obj.fieldValue      // WDE setting
                            }
                        };
                        break;

                    case "Chat":
                        message = {
                            channel: "/v2/me/chats",
                            data: {
                                notificationType: "StatusChange",
                                chat: {
                                    id: obj.id,
                                    state: "Chatting",
                                    userData: obj.userData
                                },
                                messageType: "ChatStateChangeMessage",
                                fieldName: obj.fieldName,       // WDE setting
                                fieldValue: obj.fieldValue      // WDE setting
                            }
                        };
                        break;

                    case "Preview":
                        message = {
                            channel: "/v2/me/outbound",
                            data: {
                                notificationType: "StatusChanged",
                                record: {
                                    id: obj.id,
                                    state: "ReadyToCall",
                                    phone: obj.destination,
                                    customFields: obj.customFields
                                },
                                messageType: "OutboundRecordMessage",
                                fieldName: obj.fieldName,       // WDE setting
                                fieldValue: obj.fieldValue      // WDE setting
                            }
                        };
                        break;

                    case "OpenMedia":
                        message = {
                            channel: "/v2/me/openmedia",
                            data: {
                                notificationType: "StatusChange",
                                openmedia: {
                                    id: obj.id,
                                    state: "Processing",
                                    mediaType: obj.mediaType,
                                    userData: obj.userData
                                },
                                messageType: "OpenMediaStateChangeMessage",
                                fieldName: obj.fieldName,       // WDE setting
                                fieldValue: obj.fieldValue      // WDE setting
                            }
                        };
                        break;
                }

                util.getInstance('genesys.message').publish(message);
                break;

            case "CreateActivity":
                switch (obj.type) {
                    case "Voice":
                        // replicate GWS message as much as possible
                        message = {
                            channel: "/v2/me/calls",
                            data: {
                                notificationType: "StatusChange",
                                call: {
                                    id: obj.id,
                                    state: "Completed",
                                    ani: obj.source,
                                    dnis: obj.destination,
                                    callType: obj.calltype,
                                    duration: obj.duration,
                                    notes: obj.notes,
                                    userData: obj.userData
                                },
                                messageType: "CallStateChangeMessage"
                            }
                        };
                        break;

                    case "Email":
                        message = {
                            channel: "/v2/me/emails",
                            data: {
                                notificationType: "StatusChange",
                                email: {
                                    id: obj.parentId || obj.id,
                                    state: "Completed",
                                    duration: obj.duration,
                                    notes: obj.notes,
                                    emailDescription: obj.emailDescription,
                                    userData: obj.userData
                                },
                                messageType: "EmailStateChangeMessage"
                            }
                        };
                        break;

                    case "Chat":
                        message = {
                            channel: "/v2/me/chats",
                            data: {
                                notificationType: "StatusChange",
                                chat: {
                                    id: obj.id,
                                    state: "Completed",
                                    duration: obj.duration,
                                    notes: obj.notes,
                                    transcript: obj.transcript,
                                    userData: obj.userData
                                },
                                messageType: "ChatStateChangeMessage"
                            }
                        };
                        break;

                    case "OpenMedia":
                        message = {
                            channel: "/v2/me/openmedia",
                            data: {
                                notificationType: "StatusChange",
                                openmedia: {
                                    id: obj.id,
                                    mediaType: obj.mediaType,
                                    state: "Completed",
                                    duration: obj.duration,
                                    notes: obj.notes,
                                    transcript: obj.transcript,
                                    userData: obj.userData
                                },
                                messageType: "OpenMediaStateChangeMessage"
                            }
                        };
                }

                util.getInstance('genesys.message').publish(message);
                break;

            case "IxnSelectedFromWDE":
                var ixnId = obj.actionData.id;
                var primaryTabId = tracking.getPrimaryTabId(ixnId);
                if (primaryTabId) {
                    sfdc.focusPrimaryTabById(primaryTabId);
                }
                break;

            case "ConnectionDenied":
                util.getInstance('glue.state').publish('not connected');
                break;
        }
    }

    /**
     * Used by the HTTP JSON mechanism
     */
    function poll() {
        var msg = {
            CI: config.CI
        };

        $.ajax({
            url: config.URL + "/poll=" + JSON.stringify(msg),
            type: 'GET',
            timeout: 10000,
            cache: false,
            dataType: 'jsonp',
            success: function (data) {
                if (data.action !== 'NoWork') {
                    processMessage(data);
                }

                connectionTimeout = setTimeout(function () {
                    poll();
                }, 100);
            },
            error: function (xhr, ajaxOptions, thrownError) {
                console.error(log_prefix + config.URL + ' ' + xhr.status + ' ' + thrownError);
                util.getInstance('glue.state').publish('not connected');
                connectionTimeout = setTimeout(function () {
                    requestConnection();
                }, 5000);
            }
        });
    }

    function requestConnection() {
        if (!config.IS_UNIT_TEST) {
            console.log(log_prefix + "requestConnection: " + _connectionDate);
            comms.initialize();

            var hasFocus = function(response) {
                console.log(log_prefix + "has focus");
                var msg = {
                    action: "SetSessionFocusFromSFDC"
                };

                if (response) {
                    if (response.result) {
                        var result = JSON.parse(response.result);

                        if (result.objectId) {
                            msg.actionData = {
                                tabId: result.objectId
                            }
                        }
                    }
                }

                comms.send(msg);
            };

            if (config.USE_WEB_SOCKETS === 'true') {
                util.getInstance('websocket.onopen').subscribe(function () {
                    console.log(log_prefix + "onopen");

                    var msg = {
                        action: "ConnectionRequest"
                    };

                    comms.send(msg);
                });

                util.getInstance('websocket.onmessage').subscribe(function (data) {
                    console.log(log_prefix + "onmessage");
                    var msg = JSON.parse(data.message);

                    if (msg.action === 'ConnectionAccepted') {
                        console.log(log_prefix + 'accepted');
                        util.getInstance('glue.state').publish('connected');

                        sfdc.onFocus(function(response) {
                            hasFocus(response);
                        });

                        // any new successful connection will have the focus
                        hasFocus();

                        sfdc.onFocusedPrimaryTab(function(result) {
                            tracking.primaryTabFocused(result);

                            var msg = {
                                action: "SetSessionFocusFromSFDC",
                                actionData: {
                                    tabId: result.id
                                }
                            };

                            comms.send(msg);
                        });
                    }
                    else {
                        processMessage(msg);

                        var msg = {
                            sessionid: data.sessionid,
                            code: 0,
                            reason: "OK"
                        };

                        comms.send(msg);
                    }
                });

                util.getInstance('websocket.onclose').subscribe(function () {
                    console.warn(log_prefix + "onClose: disconnected");
                    util.getInstance('glue.state').publish('not connected');

                    setTimeout(function() {
                        requestConnection();
                    }, 10000);
                });
            }
            else { // AJAX JSONP
                config.CI = _connectionDate;

                var msg = {
                    action: "ConnectionRequest"
                };

                comms.send(msg, function(data) {
                    if (data.action === 'ConnectionAccepted') {
                        console.log(log_prefix + 'accepted');
                        util.getInstance('glue.state').publish('connected');
                        poll();

                        sfdc.onFocus(function(response) {
                            hasFocus(response);
                        });

                        // any new successful connection will have the focus
                        hasFocus();

                        sfdc.onFocusedPrimaryTab(function(result) {
                            tracking.primaryTabFocused(result);

                            var msg = {
                                action: "SetSessionFocusFromSFDC",
                                actionData: {
                                    tabId: result.id
                                }
                            };

                            comms.send(msg);
                        });
                    }
                    else if (data.action === 'ConnectionDenied') {
                        console.warn(log_prefix + 'connection denied, do not retry');
                        util.getInstance('glue.state').publish('not connected');
                        _connectionTimeout = setTimeout(function () {
                            requestConnection();
                        }, 5000);
                    }
                    else {
                        _connectionTimeout = setTimeout(function () {
                            requestConnection();
                        }, 5000);
                    }
                }, function() {
                    _connectionTimeout = setTimeout(function () {
                        requestConnection();
                    }, 5000);
                });
            }
        }
        else {
            util.getInstance('glue.state').publish('connected');
        }
    }

    /**
     * Initialize this module
     */
    function initialize(connectorSettings) {
        try {
            console.log(log_prefix + "initialize");
            util.getInstance('glue.state').publish('connecting');

            config.PERSIST_USER_SETTINGS = connectorSettings.persistUserSettings;
            config.SHOW_CONTACT = connectorSettings.showContact;
            config.POP_ON_CONSULT_CALL = connectorSettings.popOnConsultCall;
            config.NO_DEFAULT_SEARCH = connectorSettings.noDefaultSearch;
            config.NO_ANI_SEARCH = connectorSettings.noANISearch;
            config.SHOW_CASE = connectorSettings.showCase;
            config.NEW_CASE_ON_POP = connectorSettings.newCaseOnPop;
            config.NEW_CASE_IF_NO_SEARCH_KVP_PRESENT = connectorSettings.newCaseIfNoSearchKVPPresent;
            config.SEARCH_CASE_IF_WRONG_CASE = connectorSettings.searchCaseIfWrongCase;
            config.OPEN_NEW_CASE_IN_EDIT_MODE = connectorSettings.openNewCaseInEditMode;
            config.OPEN_EXISTING_CASE_IN_EDIT_MODE = connectorSettings.openExistingCaseInEditMode;
            config.CREATE_TASK = connectorSettings.createTask;
            config.NEW_TASK_ON_POP = connectorSettings.newTaskOnPop;
            config.OPEN_INITIAL_TASK_IN_EDIT_MODE = connectorSettings.openInitialTaskInEditMode;
            config.OPEN_FINAL_TASK_IN_EDIT_MODE = connectorSettings.openFinalTaskInEditMode;
            config.CASE_MAP = connectorSettings.caseMap;
            config.TASK_MAP = connectorSettings.taskMap;
            config.DISPOSITION_KVP = connectorSettings.dispositionKVP;

            config.USE_WEB_SOCKETS = connectorSettings.useWebSockets;
            if (config.USE_WEB_SOCKETS === 'true') {
                config.URL = "wss://localhost:" + connectorSettings.pollPort + '/SFDCSocketListener';
            }
            else {
                config.URL = "https://localhost:" + connectorSettings.pollPort;
            }

            session.initialize();
            requestConnection();
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
        }
    }

    var terminate = function() {
        console.log(log_prefix + "terminate");
    };

    return {
        initialize: initialize,
        terminate: terminate
    };
});
