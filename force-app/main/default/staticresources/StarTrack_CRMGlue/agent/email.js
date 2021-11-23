/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the email methods
 */
define(['util', 'moment', 'config'], function (util, moment, config) {
    var log_prefix = "agent/email: ";

    /**
     * entry point for the ringing (invite) event
     * @param data
     */
    var onMessage = function (data) {
        console.log(log_prefix + data.messageType);

        try {
            // emulate GWS (as much as possible)
            if (data.messageType === "EmailStateChangeMessage" && data.notificationType === "StatusChange") {
                console.log(log_prefix + "id - " + data.email.id);
                console.log(log_prefix + "state - " + data.email.state);
                data.email.mediaType = "email";

                switch (data.email.state) {
                    case 'Processing':
                        console.log(log_prefix + "publish email.pop");
                        util.getInstance('email.pop').publish(data);
                        break;

                    case 'Completed':
                        console.log(log_prefix + "publish email.ended");
                        util.getInstance('email.ended').publish(data);
                        break;
                }
            }
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.stack);
        }
    };

    return {
        onMessage: onMessage
    };
});