/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Methods common to all interactions
 */
define(['agent/comms'], function (comms) {
    var log_prefix = "agent/interaction: ";

    /**
     * Attach data to the interaction
     * @param msg
     */
    var attachData = function(msg) {
        console.log(log_prefix + "attachData");
        comms.send(msg);
    };

    /**
     * Mark an interaction as done
     * @param msg
     */
    var markDone = function(msg) {
        console.log(log_prefix + "markDone");
        comms.send(msg);
    };

    /**
     * release a voice call
     * @param msg
     */
    var releaseCall = function(msg) {
        console.log(log_prefix + "releaseCall");
        comms.send(msg);
    };

    /**
     * send a user event
     * @param msg
     */
    var userEvent = function(msg) {
        console.log(log_prefix + "userEvent");
        comms.send(msg);
    };

    return {
        attachData: attachData,
        markDone: markDone,
        releaseCall: releaseCall,
        userEvent: userEvent
    };
});
