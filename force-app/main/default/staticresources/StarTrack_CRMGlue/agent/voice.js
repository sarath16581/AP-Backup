/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the voice methods
 */
define(['util', 'config', 'agent/comms'], function (util, config, comms) {
    var log_prefix = "agent/voice: ";

    /**
     * entry point for the talking event
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
            console.error(log_prefix + "ERROR - " + e.stack);
        }
    };

    /**
     * Start a make call to WDE.
     * @param params
     */
    var dial = function(params) {
        console.log(log_prefix + "dial - " + params.phoneNumber);

        var msg = {
            action: "Dial",
            CI: config.CI,
            actionData: {
                number: params.phoneNumber,
                userData: params.userData
            }
        };

        comms.send(msg, params.callback, params.error);
    };

    return {
        onMessage: onMessage,
        dial: dial
    };
});