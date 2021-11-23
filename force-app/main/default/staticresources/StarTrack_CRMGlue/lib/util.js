/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 *
 * Event handler using jQuery.
 * See https://addyosmani.com/blog/jquery-1-7s-callbacks-feature-demystified/ for more information
 *
 ***********************************************************************/

define(['jquery'], function ($) {
    var topics = {};

    var getInstance = function(id) {
        var topic = id && topics[id];

        if (!topic) {
            var callbacks = $.Callbacks();

            topic = {
                publish: callbacks.fire,
                subscribe: callbacks.add,
                unsubscribe: callbacks.remove,
                empty: callbacks.empty
            };

            if (id) {
                topics[id] = topic;
            }
        }

        return topic;
    };

    return {
        getInstance: getInstance
    };
});