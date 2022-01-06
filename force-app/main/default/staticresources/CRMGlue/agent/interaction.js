/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Methods common to all interactions
 */
define(['jquery', 'util', 'config'], function ($, util, config) {
    var log_prefix = "agent/interaction: ";

    /**
     * Attach data to the interaction
     * @param id
     * @param userData
     */
    var attachData = function(id, userData) {
        console.log(log_prefix + "attachData " + $.param(userData));
        userData.id = id;

        var msg = {
            Action: "AttachData",
            CI: config.CI,
            ActionData: userData
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
            },
            error: function(xhr, ajaxOptions, thrownError) {
                console.error(log_prefix + config.URL + ' ' + ajaxOptions + ' - ' + xhr.status + ' ' + thrownError);
            }
        });
    };

    return {
        attachData: attachData
    };
});
