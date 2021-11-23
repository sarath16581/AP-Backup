/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the SFDC task methods
 */
define(['util', 'moment', 'SFDC/api', 'i18next', 'config', 'SFDC/tracking'],
            function (util, moment, sfdc, i18n, config, tracking) {
    var log_prefix = "SFDC/task: ";

    /**
     * Initialize a new task if a "new task on pop" is defined.
     * @param params
     * @returns a promise
     */
    var start = function(params) {
        console.log(log_prefix + "start");

        if (config.taskStartOverride) {
            return config.taskStartOverride(params);
        }

        var ixn = params.ixn;
        var contact = params.contact;
        var caseId = params.caseId || null;
        var popOnly = params.popOnly || false;

        var d = $.Deferred();
        if (config.CREATE_TASK && config.NEW_TASK_ON_POP && !popOnly) {
            var whatId = caseId || (contact ? contact.AccountId : null) || null;
            var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
            var primaryTabId = tracking.getPrimaryTabId(ixn.id);
            var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
            var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();
            console.log(log_prefix + "create task " + subject);

            var taskMap = {};
            if (ixn.userData !== undefined) {
                var taskMapArray = config.TASK_MAP.split(',');
                $.each(taskMapArray, function (index, value) {
                    var fieldMap = value.split(':');
                    var sfdcField = fieldMap[0];

                    if (fieldMap.length > 1) {
                        var genesysValue = ixn.userData[fieldMap[1]];
                        if (genesysValue !== undefined) {
                            console.log(log_prefix + "Map - " + sfdcField + ":" + genesysValue);
                            taskMap[sfdcField] = genesysValue;
                        }
                    }
                });
            }

            ConnectorController.createTask(ixn.id, contact ? contact.Id : null, whatId, subject, ixn.userData, taskMap,
                function (task) {
                    if (task !== null) {
                        console.log(log_prefix + "redirect to new task - " + task.Id +
                            ' under ' + primaryTabId + " or " + currentPrimaryTabId);

                        var tabSuccess = function(tab) {
                            if (tab.success) {
                                tracking.setWhatId(ixn.id, whatId);
                                tracking.setTaskTabId(ixn.id, tab.id);
                                tracking.setTaskId(ixn.id, task.Id);
                                tracking.setCaseId(ixn.id, caseId);
                                sfdc.refreshPrimaryTabById(primaryTabId || currentPrimaryTabId, false); // update everything
                                d.resolve();
                            }
                            else {
                                console.warn(log_prefix + "could not open tab");
                                d.reject();
                            }
                        };

                        var url = '/' + task.Id;
                        if (config.OPEN_INITIAL_TASK_IN_EDIT_MODE) {
                            url += '/e';
                        }

                        // if primary tab open, then use it to show a sub-tab 
                        if (primaryTabId !== null) {
                            console.log(log_prefix + "primaryTabId=" + primaryTabId);
                            
                            sfdc.openSubtab(primaryTabId, url, true, i18n.t('task.started'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        }
                        else if (currentPrimaryTabId !== null && 
                                    currentPrimaryTabObjectId !== null &&
                                    ((contact && currentPrimaryTabObjectId === contact.Id) ||
                                    (contact && currentPrimaryTabObjectId === contact.AccountId) ||
                                    currentPrimaryTabObjectId === caseId)) {
                            console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);

                            // if primary tab already exists then use that
                            sfdc.openSubtab(currentPrimaryTabId, url, true, i18n.t('task.started'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        } 
                        else {
                            console.log(log_prefix + "open new primary tab");

                            sfdc.openPrimaryTab(null, url, true, i18n.t('task.started'),
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        }
                    }
                    else {
                        console.warn(log_prefix + "Could not create task");
                        d.reject();
                    }
                }
            );
        }
        else {
            console.log(log_prefix + "No task on pop");
            d.reject();
        }

        console.log(log_prefix + "start - finished");
        return d.promise();
    };

    /***
     * Bring up the original task and update it or create a new task. Various params from Workspace are sent across.
     * @param id
     * @param comments
     * @param ixn
     * @param duration
     * @returns a promise
     */
    var finish = function(id, comments, ixn, duration) {
        console.log(log_prefix + "finish");

        if (config.taskFinishOverride) {
            return config.taskFinishOverride(id, coments, ixn, duration);
        }

        var d = $.Deferred();

        if (config.CREATE_TASK && ixn.isConsult === undefined) { // don't do tasks with consult calls
            var primaryTabId = tracking.getPrimaryTabId(id);
            var taskTabId = tracking.getTaskTabId(id);
            var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
            if (duration === undefined) {
                duration = 0;
            }

            console.log(log_prefix + "create/update the task");
            var whatId = tracking.getWhatId(id);
            var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
            var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();
            var taskId = tracking.getTaskId(id);
            
            var tabSuccess = function(tab) {
                if (tab.success) {
                    console.log(log_prefix + "tab shown");
                    sfdc.refreshPrimaryTabById(primaryTabId || currentPrimaryTabId, false); // update everything
                    d.resolve();
                }
                else {
                    console.warn(log_prefix + "could not open tab");
                    d.reject();
                }
            };

            var taskMap = {};
            if (ixn.userData !== undefined) {
                var taskMapArray = config.TASK_MAP.split(',');
                $.each(taskMapArray, function (index, value) {
                    var fieldMap = value.split(':');
                    var sfdcField = fieldMap[0];

                    if (fieldMap.length > 1) {
                        var genesysValue = ixn.userData[fieldMap[1]];
                        if (genesysValue !== undefined) {
                            console.log(log_prefix + "Map - " + sfdcField + ":" + genesysValue);
                            taskMap[sfdcField] = genesysValue;
                        }
                    }
                });
            }

            ConnectorController.closeTask(id, taskId, whatId, subject, comments, ixn.userData, config.DISPOSITION_KVP,
                        taskMap, duration,
                function (result) {
                    if (result !== null) {
                        console.log(log_prefix + "redirect to new/existing task - " + result.Id +
                            ' under ' + primaryTabId + " or " + currentPrimaryTabId);
                        
                        var contact = tracking.getContact(id);
                        var caseId = tracking.getCaseId(id);

                        var url = '/' + result.Id;
                        if (config.OPEN_FINAL_TASK_IN_EDIT_MODE) {
                            url += '/e';
                        }

                        if (primaryTabId) {
                            console.log(log_prefix + "primaryTabId=" + primaryTabId);

                            // shouldn't really have to do this - SFDC won't re-openSubtab if agent closes the tab,
                            // so we need to close it first and the force an open. Could use getSubtabIds() I guess.
                            if (taskTabId) {
                                sfdc.closeTab(taskTabId);
                            }

                            sfdc.openSubtab(primaryTabId, '/' + result.Id, true, i18n.t('task.completed'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        }
                        else if (currentPrimaryTabId !== null &&
                                    currentPrimaryTabObjectId !== null &&
                                    ((contact && currentPrimaryTabObjectId === contact.Id) ||
                                    (contact && currentPrimaryTabObjectId === contact.AccountId) ||
                                    currentPrimaryTabObjectId === caseId)) {

                            console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);

                            if (taskTabId !== null) {
                                sfdc.closeTab(taskTabId);
                            }

                            // if primary tab already exists then use that
                            sfdc.openSubtab(currentPrimaryTabId, result.Id, true, i18n.t('task.completed'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        }
                        else {
                            console.log(log_prefix + "open new primary tab");

                            if (taskTabId) {
                                sfdc.closeTab(taskTabId);
                            }

                            sfdc.openPrimaryTab(null, '/' + result.Id, true, i18n.t('task.completed'),
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
                        }
                    }
                    else {
                        console.warn(log_prefix + "could not go to task");
                        d.reject();
                    }
                }
            );
        }
        else {
            console.log(log_prefix + "No task on close");
            d.reject();
        }

        console.log(log_prefix + "finish - finished");
        return d.promise();
    };

    return {
        start: start,
        finish: finish
    };
});