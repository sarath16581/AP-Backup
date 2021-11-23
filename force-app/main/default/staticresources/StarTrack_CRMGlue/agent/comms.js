/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Some web socket handling
 */
define(['jquery', 'util', 'config'], function ($, util, config) {
    var log_prefix = "agent/comms: ";
    var websocket;

    var initialize = function() {
        if (config.USE_WEB_SOCKETS === 'true') {
            websocket = new WebSocket(config.URL);

            function send(message) {
                console.log("send: " + message);
                websocket.send(message);
            }

            websocket.onopen = function (e) {
                console.log("onOpen");
                util.getInstance('websocket.onopen').publish();
            };

            websocket.onmessage = function (e) {
                console.log("onmessage: " + e.data);
                var jsonreq = JSON.parse(e.data);
                util.getInstance('websocket.onmessage').publish(jsonreq);
            };

            websocket.onerror = function (e) {
                console.error("onError");
            };

            websocket.onclose = function (e) {
                console.warn("onClose: disconnected");
                util.getInstance('websocket.onclose').publish();
            };
        }
    };

    var send = function(jsonObjToSend, onsuccess, onerror) {
        if (config.CI) {
            jsonObjToSend.CI = config.CI;
        }

        var msg = JSON.stringify(jsonObjToSend);

        if (!config.IS_UNIT_TEST) {
            console.log(log_prefix + "send - " + msg);

            try {
                if (config.USE_WEB_SOCKETS === 'true') {
                    websocket.send(msg);
                }
                else {
                    $.ajax({
                        url: config.URL,
                        data: "/request=" + msg,
                        type: 'GET',
                        timeout: 5000,
                        processData: false,
                        cache: false,
                        dataType: 'jsonp',
                        success: function (data) {
                            if (onsuccess) {
                                onsuccess(data);
                            }
                        },
                        error: function (xhr, ajaxOptions, thrownError) {
                            console.error(log_prefix + config.URL + ' ' + ajaxOptions + ' - ' + xhr.status + ' ' + thrownError);

                            if (onerror) {
                                onerror(xhr, ajaxOptions, thrownError);
                            }
                        }
                    });
                }
            }
            catch (e) {
                console.error(log_prefix + "ERROR - " + e.stack);
            }
        }
    };

    return {
        initialize: initialize,
        send: send
    };
});
