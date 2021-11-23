/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

define(['jquery', 'util', 'config', 'agent/session'],
            function($, util, config, session) {
    var log_prefix = "Glue: ";
    var _connectionTimeout = null;
    var _connectionDate = new Date().getTime() + 'a';
	
	
    function processMessage(obj) {
		console.log(log_prefix + "DATA: " + JSON.stringify(obj));
        console.log(log_prefix + "processMessage " + obj.action);
        var message = { };

        switch (obj.action) {
            case "OpenObject":
                var message = { };

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
                                    userData: obj.userData
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

                    default:
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

                    default:
                        break;
                }

                util.getInstance('genesys.message').publish(message);
                break;

            case "ConnectionDenied":
                util.getInstance('glue.state').publish('not connected');
                break;
        }
    }

	
    function poll() {
        var msg = {
            CI: _connectionDate
        };

        $.ajax({
            url: config.URL + "/poll=" + JSON.stringify(msg),
            type: 'GET',
            timeout: 30000,
            async: true,
            crossDomain: true,
            cache: false,
            dataType: 'jsonp',
            success: function(data) {
                if (data.action !== 'NoWork') {
                    processMessage(data);
                }

                connectionTimeout = setTimeout(function() { poll(); }, 100);
            },
            error: function(xhr, ajaxOptions, thrownError) {
                console.error(log_prefix + config.URL + ' ' + xhr.status + ' ' + thrownError);
                util.getInstance('glue.state').publish('not connected');
                connectionTimeout = setTimeout(function() { poll(); }, 5000);
            }
        });
    }

    function requestConnection() {
        console.log(log_prefix + "requestConnection");
        var msg = {
            action: "ConnectionRequest",
            pollInterval: "100",
            CI: _connectionDate
        };

        $.ajax({
            url: config.URL,
            data: '/request=' + JSON.stringify(msg),
            type: 'GET',
            timeout: 30000,
            async: true,
            crossDomain: true,
            cache: false,
            dataType: 'jsonp',
            success: function(data) {
                if (data.action === 'ConnectionAccepted') {
                    console.log(log_prefix + 'accepted');
                    util.getInstance('glue.state').publish('connected');
                    poll();
                }
                else if (data.action === 'ConnectionDenied') {
                    console.warn(log_prefix + 'connection denied, do not retry');
                    util.getInstance('glue.state').publish('not connected');
                    _connectionTimeout = setTimeout(function() { requestConnection(); }, 5000);
                }
                else {
                    _connectionTimeout = setTimeout(function() { requestConnection(); }, 5000);
                }
            },
            error: function(xhr, ajaxOptions, thrownError) {
                console.error(log_prefix + config.URL + ' ' + xhr.status + ' ' + thrownError);
                _connectionTimeout = setTimeout(function() { requestConnection(); }, 5000);
            }
        });
    }

    /**
     * Initialize this module
     */
    function initialize(connectorSettings) {
        try {
            console.log(log_prefix + "initialize");
            util.getInstance('glue.state').publish('connecting');

            config.URL = "https://" + (connectorSettings.useLocalHost ? "localhost" : "127.0.0.1") + ":" + connectorSettings.pollPort;
            config.CI = _connectionDate;
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

            session.initialize();
            requestConnection();
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.message);
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
