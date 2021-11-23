/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the methods that do a pop in SFDC
 */
define(['util', 'SFDC/api', 'config', 'SFDC/tracking', 'SFDC/case', 'SFDC/task', 'agent/comms', 'agent/interaction'],
        function (util, sfdc, config, tracking, caseObj, task, comms, interaction) {
    var log_prefix = "SFDC/pop: ";

    /**
     * Start the pop. Then show the associated case and then create the task.
     * @param params
     */
    var start = function(params) {
        console.log(log_prefix + "start");
        var ixn = params.ixn;
        var contact = params.contact;

        var tabSuccess = function (tab) {
            if (tab !== null && !tab.success) {
                console.warn("could not open pop tab");
                tab = null;
            }

            if (tab !== null) {
                console.log(log_prefix + "tab id is " + tab.id);
                var msg = {
                    action: "SetTabIdFromSFDC",
                    actionData: {
                        id: ixn.id,
                        tabId: tab.id
                    }
                };

                comms.send(msg);
            }

            tracking.add(ixn.id, tab !== null ? tab.id : null, contact);

            // needed to get an activity to work
            if (ixn.id !== null) {
                var msg = {
                    Action: "AttachData",
                    ActionData: {
                        id: ixn.id,
                        userData: {
                            sfdcObjectId: ixn.id
                        }
                    }
                };

                interaction.attachData(msg);

                caseObj.pop(params).then(
                    function (newCaseId) {
                        tracking.setWhatId(ixn.id, newCaseId);
                        params.caseId = newCaseId;
                        return task.start(params);
                    },
                    function () {
                        return task.start(params);
                    }
                );
            }
        };

        if (config.overridePop) {
            config.overridePop(params);
        }
        else {
            if (config.SHOW_CONTACT && contact) {
                console.log(log_prefix + "attempt to refresh first");
                sfdc.refreshPrimaryTabByName(contact.Id, true,
                    function(tab) {
                        if (tab.success) {
                            console.log(log_prefix + "refresh successful");
                            sfdc.getFocusedPrimaryTabId(
                                function(result) {
                                    tab.id = result.id;
                                    tabSuccess(tab);
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "couldn't refresh so open primary tab");
                            sfdc.openPrimaryTab(null, '/' + contact.Id, true, contact.Name,
                                function (tab) {
                                    tabSuccess(tab);
                                }, contact.Id);
                        }
                    }
                );
            }
            else {
                tabSuccess(null);
            }
        }
    };

    return {
        start: start
    };
});
