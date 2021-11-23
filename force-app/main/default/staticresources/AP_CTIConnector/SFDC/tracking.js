/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Some helper methods for what is going on in a pop lifecycle.
 */
define(['util'], function (util) {
    var log_prefix = "SFDC/tracking: ";
    var _trackingIds = {};
    var _currentPrimaryTabId = null;
    var _currentPrimaryTabObjectId = null;

    var add = function(id, primaryTabId, contact) {
        _trackingIds[id] = {
            whatId: contact.AccountId || null,
            primaryTabId: primaryTabId,
            taskTabId: null,
            contact: contact
        };
    };

    var exists = function(id) {
        return _trackingIds[id] !== undefined;
    };
    
    var setTaskId = function(id, taskId) {
        var track = _trackingIds[id];

        if (track !== undefined) {  
            track.taskId = taskId;
        }
        else {
            console.warn(log_prefix + "setTaskId-" + id + " does not exist");
        }
    };
    
    var setWhatId = function(id, whatId) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            track.whatId = whatId;
        }
        else {
            console.warn(log_prefix + "setTaskTabId-" + id + " does not exist");
        }
    };

    var setTaskTabId = function(id, taskTabId) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            track.taskTabId = taskTabId;
        }
        else {
            console.warn(log_prefix + "setTaskTabId-" + id + " does not exist");
        }
    };

    var setCaseId = function(id, caseId) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            track.caseId = caseId;
        }
        else {
            console.warn(log_prefix + "setCaseId-" + id + " does not exist");
        }
    };

    var setParams = function(params) {
        if (params.ixn !== undefined) {
            _trackingIds[params.ixn.id] = {
                params: params
            };
        }
    };

    var getContact = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.contact;
        }
        else {
            console.warn(log_prefix + "getContact-" + id + " does not exist");
            return null;
        }
    };
    
    var getTaskId = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.taskId;
        }
        else {
            console.warn(log_prefix + "getTaskId-" + id + " does not exist");
            return null;
        }
    };

    var getWhatId = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.whatId;
        }
        else {
            console.warn(log_prefix + "getWhatId-" + id + " does not exist");
            return null;
        }
    };

    var getPrimaryTabId = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.primaryTabId;
        }
        else {
            console.warn(log_prefix + "getPrimaryTabId-" + id + " does not exist");
            return null;
        }
    };

    var getTaskTabId = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.taskTabId;
        }
        else {
            console.warn(log_prefix + "getTaskTabId-" + id + " does not exist");
            return null;
        }
    };

    var getCaseId = function(id) {
        var track = _trackingIds[id];

        if (track !== undefined) {
            return track.caseId;
        }
        else {
            console.warn(log_prefix + "getCaseId-" + id + " does not exist");
            return null;
        }
    };

    var getParams = function(id) {
        var track = _trackingIds[id];
		console.log(log_prefix + "track: " + JSON.stringify(_trackingIds[id]));

        if (track !== undefined && track.params !== undefined) {
            return track.params;
        }
        else {
            console.warn(log_prefix + "getParams-" + id + " does not exist");
            return null;
        }
    };

    var remove = function(id) {
        delete _trackingIds[id];
    };

    /**
     * Used by the test harness to reset things
     */
    var reset = function() {
        _trackingIds= {};
    };

    /**
     * Updated whenever the primary tab changes
     * @param result
     */
    var primaryTabFocused = function(result) {
        _currentPrimaryTabId = result.id;

        // need to convert from 15 chars to 18 char id
        var y = result.objectId;
        if (y.length === 15) {
            var s = "";
            for (var i = 0; i < 3; i++) {
                var f = 0;
                for (var j = 0; j < 5; j++) {
                    var c = y.charAt(i * 5 + j);
                    if (c >= "A" && c <= "Z") f += 1 << j;
                }

                s += "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(f);
            }

            _currentPrimaryTabObjectId = y + s;
        } else {
            _currentPrimaryTabObjectId = null;
        }

        console.log(log_prefix + "primaryTabFocused - " + _currentPrimaryTabId + ", " + _currentPrimaryTabObjectId)
    };

    var getCurrentPrimaryTabId = function() {
        return _currentPrimaryTabId;
    };

    var getCurrentPrimaryTabObjectId = function() {
        return _currentPrimaryTabObjectId;
    };

    return {
        add: add,
        exists: exists,
        setTaskId: setTaskId,
        setWhatId: setWhatId,
        setTaskTabId: setTaskTabId,
        setCaseId: setCaseId,
        setParams: setParams,
        getContact: getContact,
        getTaskId: getTaskId,
        getWhatId: getWhatId,
        getPrimaryTabId: getPrimaryTabId,
        getTaskTabId: getTaskTabId,
        getCaseId: getCaseId,
        getParams: getParams,
        remove: remove,
        reset: reset,
        primaryTabFocused: primaryTabFocused,
        getCurrentPrimaryTabId: getCurrentPrimaryTabId,
        getCurrentPrimaryTabObjectId: getCurrentPrimaryTabObjectId
    };
});
