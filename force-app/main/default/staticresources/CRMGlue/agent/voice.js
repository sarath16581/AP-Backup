/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the voice methods
 */
define(['util', 'config'], function (util, config) {
    var log_prefix = "agent/voice: ";

    /**
     * entry point for the ringing event
     * @param data
     */
    var onMessage = function (data) {
        console.log(log_prefix + data.messageType);

        try {
            // GWS compatible (mostly)
            if (data.messageType === "CallStateChangeMessage" && data.notificationType === "StatusChange") {
                console.log(log_prefix + "id - " +  data.call.id);
                console.log(log_prefix + "state - " + data.call.state);
                console.log(log_prefix + "call type - " + data.call.callType);
                data.call.mediaType = "voice" + data.call.callType;

                if (data.call.dnis !== undefined) {
                    console.log(log_prefix + "dnis - " + data.call.dnis);
                }

                switch (data.call.state) {
                    case 'Established':
                        console.log(log_prefix + "publish voice.pop");
                        util.getInstance('voice.pop').publish(data);
                        break;

                    case "Completed":
                        console.log(log_prefix + "publish voice.ended");
                        util.getInstance('voice.ended').publish(data);
                        break;
                }
            }
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.message);
        }
    };

    /**
     * Start a make call to WDE.
     * @param params
     */
    var dial = function(params) {
        try {
            console.log(log_prefix + "dial - " + params.phoneNumber);

            var msg = {
                Action: "Dial",
                CI: config.CI,
                ActionData: {
                    number: params.phoneNumber
                }
            };

            $.ajax({
                url: config.URL,
                data:"/request=" + JSON.stringify(msg),
                type: 'GET',
                processData: false,
                timeout: 5000,
                async: false,
                crossDomain: true,
                cache: false,
                dataType: 'jsonp',
                success: function(data) {
                    if (params.callback) {
                        params.callback();
                    }
                },
                error: function(xhr, ajaxOptions, thrownError) {
                    console.error(log_prefix + config.URL + ' ' + ajaxOptions + ' - ' + xhr.status + ' ' + thrownError);
                    if (params.error) {
                        params.error();
                    }
                }
            });
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.message);
        }
    };

    return {
        onMessage: onMessage,
        dial: dial
    };
});