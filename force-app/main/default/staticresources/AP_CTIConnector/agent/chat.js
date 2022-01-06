/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the chat methods
 */
define(['util', 'moment', 'config'], function (util, moment, config) {
    var log_prefix = "agent/chat: ";

    /**
     * entry point for the ringing (invite) event
     * @param data
     */
    var onMessage = function (data) {
        console.log(log_prefix + data.messageType);

        try {
            if (data.messageType === "ChatStateChangeMessage" && data.notificationType === "StatusChange") {
                console.log(log_prefix + "id - " + data.chat.id);
                console.log(log_prefix + "state - " + data.chat.state);
                data.chat.mediaType = "chat";
                var ixnId = data.chat.id;
    
                switch (data.chat.state) {
                    case 'Chatting':
                        console.log(log_prefix + "publish chat.pop");
                        util.getInstance('chat.pop').publish(data);
                        break;
    
                    case 'Completed':
                        console.log(log_prefix + "publish chat.ended");
                        util.getInstance('chat.ended').publish(data);
                        break;
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