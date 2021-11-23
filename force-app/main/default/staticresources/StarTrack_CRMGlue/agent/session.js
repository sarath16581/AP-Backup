/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Methods to work out an interaction life-cycle.
 */
define(['util', 'config', 'agent/voice', 'agent/email', 'agent/chat', 'agent/openmedia', 'agent/preview'],
            function (util, config, voice, email, chat, openmedia, preview) {
    var log_prefix = "agent/session: ";
    console.log(log_prefix + "Initializing");

    /**
     * Handle an event from Genesys
     * @param message
     */
    var onGenesysMessage = function (message) {
        console.log(log_prefix + 'onGenesysMessage - ' + message.channel);

        switch (message.channel) {
            case '/v2/me/calls':
                voice.onMessage(message.data);
                break;

            case '/v2/me/emails':
                email.onMessage(message.data);
                break;

            case '/v2/me/chats':
                chat.onMessage(message.data);
                break;

            case '/v2/me/openmedia': // just fudging this for now
                openmedia.onMessage(message.data);
                break;

            case '/v2/me/outbound':
                message.data.record.userData = message.data.record.customFields; // make it compatible with other media
                preview.onMessage(message.data);
                break;
        }
    };

    var initialize = function() {
        util.getInstance('genesys.message').subscribe(onGenesysMessage);
        console.log(log_prefix + "Initialized");
    };

    return {
        initialize: initialize
    };
});