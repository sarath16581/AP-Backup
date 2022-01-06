/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the methods for push-preview and pull-preview records
 */
define(['util', 'config'], function (util, config) {
    var log_prefix = "agent/preview: ";

    /**
     * entry point for the outbound preview events
     * @param data
     */
    var onMessage = function (data) {
        console.log(log_prefix + data.messageType);

        try {
            if (data.messageType === "OutboundRecordMessage" && data.notificationType === "StatusChanged") {
                console.log(log_prefix + "id - " + data.record.id);
                console.log(log_prefix + "state - " + data.record.state);
                console.log(log_prefix + "phone - " + data.record.phone);
                data.record.mediaType = "preview";

                if (data.record.state === 'ReadyToCall') {
                    // let CRM know about it (for the pop)
                    console.log(log_prefix + "publish preview.pop");
                    util.getInstance('preview.pop').publish(data);
                }
            }
        }
        catch (e) {
            console.error(log_prefix + "ERROR - " + e.message);
        }
    };

    return {
        onMessage: onMessage
    };
});
