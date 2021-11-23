/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Attempt to make the methods for SFDC classic and lightning console compatible.
 * Unfortunately lightning has a bunch of stuff missing and as a result subtabs aren't
 * possible. So everything will appear as primary tabs.
 */
define(['integration', 'lightning'], function (sforce, force) {
    var log_prefix = "SFDC/api: ";
    var isLightning = false;

    var initialize = function(islightning) {
        isLightning = islightning;
    };

    var addEventListener = function(receiveSFMessage) {
        console.log(log_prefix + "addEventListener");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
        }
        else {
            sforce.console.addEventListener('CTIEvent', receiveSFMessage);
        }
    };

    var closeTab = function(id, callback) {
        console.log(log_prefix + "closeTab");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
            var result = {
                success: false
            };

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.closeTab(id, callback);
        }
    };

    var enableClickToDial = function(callback) {
        console.log(log_prefix + "enableClickToDial");
        if (isLightning) {
            sforce.opencti.enableClickToDial({
                callback: callback
            });
        }
        else {
            sforce.interaction.cti.enableClickToDial(callback);
        }
    };

    var fireEvent = function(eventType, message, callback) {
        console.log(log_prefix + "fireEvent");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
        }
        else {
            sforce.console.fireEvent(eventType, message, callback);
        }
    };

    var focusPrimaryTabById = function(id, callback) {
        console.log(log_prefix + "focusPrimaryTabById");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
        }
        else {
            sforce.console.focusPrimaryTabById(id, callback);
        }
    };

    var getFocusedPrimaryTabId = function(callback) {
        console.log(log_prefix + "getFocusedPrimaryTabId");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
            var result = {
                success: false
            };

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.getFocusedPrimaryTabId(callback);
        }
    };

    var onClickToDial = function(dial) {
        console.log(log_prefix + "onClickToDial");
        if (isLightning) {
            sforce.opencti.onClickToDial({
                listener: dial
            });
        }
        else {
            sforce.interaction.cti.onClickToDial(dial);
        }
    };

    var onFocus = function(eventHandler) {
        console.log(log_prefix + "onFocus");
        if (isLightning) {
            sforce.opencti.onNavigationChange({
                listener: eventHandler
            });
        }
        else {
            sforce.interaction.onFocus(eventHandler);
        }
    };

    var onFocusedPrimaryTab = function(eventHandler) {
        console.log(log_prefix + "onFocusedPrimaryTab");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
        }
        else {
            sforce.console.onFocusedPrimaryTab(eventHandler);
        }
    };

    var openPrimaryTab = function(id, url, active, tabLabel, callback, name) {
        console.log(log_prefix + "openPrimaryTab (" + url + ")");
        if (isLightning) {
            // NOT SUPPORTED in Lightning. Just send a screen pop.
            var result = {
                success: true
            };

            sforce.opencti.screenPop({
                type: sforce.opencti.SCREENPOP_TYPE.URL,
                params: { url: url }
            });

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.openPrimaryTab(id, url, active, tabLabel, callback, name);
        }
    };

    var openSubtab = function(primaryTabId, url, active, tabLabel, id, callback, name) {
        console.log(log_prefix + "openSubtab (" + url + ")");
        if (isLightning) {
            // NOT SUPPORTED in Lightning. Not actually ever called as the other
            // methods don't work.
            var result = {
                success: true
            };

            sforce.opencti.screenPop({
                type: sforce.opencti.SCREENPOP_TYPE.URL,
                params: { url: url }
            });

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.openSubtab(primaryTabId, url, active, tabLabel, id, callback, name);
        }
    };

    var refreshPrimaryTabByName = function(name, active, callback, fullRefresh) {
        console.log(log_prefix + "refreshPrimaryTabByName");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
            var result = {
                success: false
            };

            setTimeout(function() {
                sforce.opencti.refreshView(); // hope for the best
            }, 100); // give updates some time

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.refreshPrimaryTabByName(name, active, callback, fullRefresh);
        }
    };

    var refreshPrimaryTabById  = function(id, active, callback, fullRefresh) {
        console.log(log_prefix + "refreshPrimaryTabById");
        if (isLightning) {
            // NOT SUPPORTED in Lightning
            var result = {
                success: false
            };

            setTimeout(function() {
                sforce.opencti.refreshView(); // hope for the best
            }, 100); // give updates some time

            if (callback) {
                callback(result);
            }
        }
        else {
            sforce.console.refreshPrimaryTabById(id, active, callback, fullRefresh);
        }
    };

    var setSoftphoneLabel = function(text) {
        console.log(log_prefix + "setSoftphoneLabel");
        if (isLightning) {
            sforce.opencti.setSoftphoneItemLabel({label: text});
        }
        else {
            sforce.console.setCustomConsoleComponentButtonText(text);
        }
    };

    var setSoftphoneStyle = function(mode) {
        console.log(log_prefix + "setSoftphoneStyle");
        switch (mode) {
            case "connecting":
                if (isLightning) {
                    sforce.opencti.setSoftphoneItemIcon({key:"sync"});
                }
                else {
                    sforce.console.setCustomConsoleComponentButtonStyle('background: black;');
                    sforce.console.setCustomConsoleComponentButtonStyle('color: white;');
                }
                break;

            case "connected":
                if (isLightning) {
                    sforce.opencti.setSoftphoneItemIcon({key:"success"});
                }
                else {
                    sforce.console.setCustomConsoleComponentButtonStyle('background:#3bff3b;');
                    sforce.console.setCustomConsoleComponentButtonStyle('color:black;');
                }
                break;

            case "not connected":
                if (isLightning) {
                    sforce.opencti.setSoftphoneItemIcon({key:"warning"});
                }
                else {
                    sforce.console.setCustomConsoleComponentButtonStyle('color:black;');
                    sforce.console.setCustomConsoleComponentButtonStyle('background:#ff3b3b;');
                }
                break;
        }
    };

    var getPrimaryTabIds = function(callback) {
        if(isLightning) {
			console.error('getPrimaryTabIds not implemented');
		} else {
    		sforce.console.getPrimaryTabIds(callback);
    	}
    };

    var getTabLink = function(level, tabId, callback) {
        if(isLightning) {
            console.error('getTabLink not implemented');
        } else {
         	sforce.console.getTabLink(level, tabId, callback);
        }
    };

	var focusPrimaryTabByName = function(name, callback) {
	    if(isLightning) {
			console.error('focusPrimaryTabByName not implemented');
		} else {
			sforce.console.focusPrimaryTabByName(name, callback);
		}
 	}


    return {
        initialize: initialize,
        addEventListener: addEventListener,
        closeTab: closeTab,
        enableClickToDial: enableClickToDial,
        fireEvent: fireEvent,
        focusPrimaryTabById: focusPrimaryTabById,
        getFocusedPrimaryTabId: getFocusedPrimaryTabId,
        onClickToDial: onClickToDial,
        onFocus: onFocus,
        onFocusedPrimaryTab: onFocusedPrimaryTab,
        openPrimaryTab: openPrimaryTab,
        openSubtab: openSubtab,
        refreshPrimaryTabById: refreshPrimaryTabById,
        refreshPrimaryTabByName: refreshPrimaryTabByName,
        setSoftphoneLabel: setSoftphoneLabel,
        setSoftphoneStyle: setSoftphoneStyle,
        getPrimaryTabIds: getPrimaryTabIds,
        getTabLink: getTabLink,
        focusPrimaryTabByName: focusPrimaryTabByName
    };
});