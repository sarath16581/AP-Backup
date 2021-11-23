/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the openmedia methods
 */
define(['util', 'moment', 'config'], function (util, moment, config) {
    var log_prefix = "agent/openmedia: ";

    /**
     * entry point for the talking event
     * @param data
     */
    var onMessage = function (data) {
        console.log(log_prefix + data.messageType);

        try {
            if (data.messageType === "OpenMediaStateChangeMessage" && data.notificationType === "StatusChange") {
                console.log(log_prefix + "id - " + data.openmedia.id);
                console.log(log_prefix + "state - " + data.openmedia.state);

                switch (data.openmedia.state) {
                    case 'Processing':
                        console.log(log_prefix + "publish openmedia.pop");
                        util.getInstance('openmedia.pop').publish(data);
                        break;
    
                    case 'Completed':
                        console.log(log_prefix + "publish openmedia.ended");
                        util.getInstance('openmedia.ended').publish(data);
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