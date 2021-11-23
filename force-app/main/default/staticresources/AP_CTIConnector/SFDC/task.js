/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Define the SFDC task methods
 */
define(['util', 'moment', 'integration', 'i18next', 'config', 'SFDC/tracking'],
            function (util, moment, sforce, i18n, config, tracking) {
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
            var whatId = caseId || contact.AccountId || null;
            //var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
            var subject = ixn.callType + " call" ;
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

            AP_ConnectorController.createTask(contact.Id, whatId, subject, ixn.userData, taskMap,
                function (task) {
                    if (task !== null) {
                        console.log(log_prefix + "redirect to new task - " + task.Id +
                            ' under ' + primaryTabId + " or " + currentPrimaryTabId);

						// Since the tabs aren't being popped in this flow
						// store the task tracking information here:
						tracking.setWhatId(ixn.id, whatId);
						tracking.setTaskId(ixn.id, task.Id);
						tracking.setCaseId(ixn.id, caseId);

//                        var tabSuccess = function(tab) {
//                            if (tab.success) {
//                                tracking.setWhatId(ixn.id, whatId);
//                                tracking.setTaskTabId(ixn.id, tab.id);
//                                tracking.setTaskId(ixn.id, task.Id);
//                                tracking.setCaseId(ixn.id, caseId);
//                                sforce.console.refreshPrimaryTabById(primaryTabId || currentPrimaryTabId, false); // update everything
//                                d.resolve();
//                            }
//                            else {
//                                console.warn(log_prefix + "could not open tab");
//                                d.reject();
//                            }
//                        };
//
//                        var url = '/' + task.Id;
//                        if (config.OPEN_INITIAL_TASK_IN_EDIT_MODE) {
//                            url += '/e';
//                        }
//
//                        // if primary tab open, then use it to show a sub-tab
//                        if (primaryTabId !== null) {
//                            console.log(log_prefix + "primaryTabId=" + primaryTabId);
//                            /*
//                            sforce.console.openSubtab(primaryTabId, url, true, i18n.t('task.started'), null,
//                                function (tab) {
//                                    tabSuccess(tab);
//                                }
//                            );
//							*/
//                        }
//                        else if (currentPrimaryTabId !== null &&
//                                    currentPrimaryTabObjectId !== null &&
//                                    (currentPrimaryTabObjectId === contact.Id ||
//                                    currentPrimaryTabObjectId === contact.AccountId ||
//                                    currentPrimaryTabObjectId === caseId)) {
//                            console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);
//
//                            // if primary tab already exists then use that
//                            /*
//							sforce.console.openSubtab(currentPrimaryTabId, url, true, i18n.t('task.started'), null,
//                                function (tab) {
//                                    tabSuccess(tab);
//                                }
//                            );
//							*/
//                        }
//                        else {
//                            console.log(log_prefix + "open new primary tab");
//							/*
//                            sforce.console.openPrimaryTab(null, url, true, i18n.t('task.started'),
//                                function (tab) {
//                                    tabSuccess(tab);
//                                }
//                            );
//							*/
//                        }
						
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

        if (config.CREATE_TASK && ixn.parentCallUri === undefined) { // don't do tasks with consult calls
            var primaryTabId = tracking.getPrimaryTabId(id) === undefined || tracking.getPrimaryTabId(id)=== '' ? getPrimaryTabId() : tracking.getPrimaryTabId(id);
			console.log('--primaryTabId-'+primaryTabId);
            var taskTabId = tracking.getTaskTabId(id);
            //var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
			var subject = ixn.callType + " call" ;
            if (duration === undefined) {
                duration = 0;
            }

            console.log(log_prefix + "create/update the task");
            var whatId = tracking.getWhatId(id) === undefined ? '' : tracking.getWhatId(id);
			console.log('---whatId'+whatId);
            var currentPrimaryTabId = tracking.getCurrentPrimaryTabId() === undefined || tracking.getCurrentPrimaryTabId() === ''? getFocusedPrimaryTabId() : tracking.getCurrentPrimaryTabId();
			console.log('--currentPrimaryTabId-'+currentPrimaryTabId);
            var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId() === undefined || tracking.getCurrentPrimaryTabObjectId() === '' ? getFocusedPrimaryTabObjectId() : tracking.getCurrentPrimaryTabObjectId();
			console.log('--currentPrimaryTabObjectId-'+currentPrimaryTabObjectId);
            var taskId = tracking.getTaskId(id) === undefined ? '' : tracking.getTaskId(id);
			console.log('---taskId'+tracking.getTaskId(id)+ '--'+ taskId);
			var taskId2 = '';
            var whatId2 = '';
			
			
            var tabSuccess = function(tab) {
                if (tab.success) {
                    console.log(log_prefix + "tab shown");
                    sforce.console.refreshPrimaryTabById(primaryTabId || currentPrimaryTabId, false); // update everything
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
	
			var refId = ''; 
			if(taskMap.ReferenceID_c != null && taskMap.ReferenceID_c.trim() != '') {
				refId = taskMap.ReferenceID_c;
			}
			console.log('--taskMap.ReferenceID_c--'+taskMap.ReferenceID_c);
			var queue = '';
			//added by Kapita for contact and case id from AP_CRMCOnnector vfpage -
			var conId = whatId===undefined || whatId === '' || whatId === null ? j$('#hfContactID').val(): whatId;
			var cseId = j$('#hfCaseID').val();
			
			console.log('Task close taskId ---'+ taskId );
			console.log('Task close whatId ---'+ whatId );
			console.log('Task close subject ---'+ subject );
			console.log('Task close comments ---'+ comments );
			console.log('Task close ixn.userData ---'+ JSON.stringify(ixn.userData));
			console.log('Task close config.DISPOSITION_KVP ---'+ config.DISPOSITION_KVP );
			console.log('Task close taskMap ---'+ JSON.stringify(taskMap));
			console.log('Task close duration ---'+ duration );
			console.log('Task close refId ---'+ refId );
			console.log('Task close ixn.callType ---'+ ixn.callType );
			console.log('Task close queue ---'+ queue );
			console.log('Task close ixn.id ---'+ ixn.id );
			console.log('Task close conId ---'+ conId );
			console.log('Task close cseId ---'+ cseId );
			
            AP_ConnectorController.closeTask(taskId, whatId, subject, comments, ixn.userData, config.DISPOSITION_KVP,
                        taskMap, duration, ixn.callType, queue, ixn.id,conId, cseId,
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

                        if (primaryTabId !== null) {
                            console.log(log_prefix + "primaryTabId=" + primaryTabId);

                            // shouldn't really have to do this - SFDC won't re-openSubtab if agent closes the tab,
                            // so we need to close it first and the force an open. Could use getSubtabIds() I guess.
                            if (taskTabId !== null) {
                                sforce.console.closeTab(taskTabId);
                            }
							/*
                            sforce.console.openSubtab(primaryTabId, '/' + result.Id, true, i18n.t('task.completed'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
							*/
                        }
                        else if (currentPrimaryTabId !== null &&
                                    currentPrimaryTabObjectId !== null &&
                                    (currentPrimaryTabObjectId === contact.Id ||
                                    currentPrimaryTabObjectId === contact.AccountId ||
                                    currentPrimaryTabObjectId === caseId)) {

                            console.log(log_prefix + "currentPrimaryTabId=" + currentPrimaryTabId);

                            if (taskTabId !== null) {
                                sforce.console.closeTab(taskTabId);
                            }

                            // if primary tab already exists then use that
                            /*
							sforce.console.openSubtab(currentPrimaryTabId, result.Id, true, i18n.t('task.completed'), null,
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
							*/
                        }
                        else {
                            console.log(log_prefix + "open new primary tab");

                            if (taskTabId !== null) {
                                sforce.console.closeTab(taskTabId);
                            }
                            
							/*
                            sforce.console.openPrimaryTab(null, '/' + result.Id, true, i18n.t('task.completed'),
                                function (tab) {
                                    tabSuccess(tab);
                                }
                            );
							*/
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
	
	//added by Kalpita for primary tab id
	function getFocusedPrimaryTabId() {
		sforce.console.getFocusedPrimaryTabId(showTabId);
	}
	
	function getPrimaryTabId() {
		  sforce.console.getPrimaryTabIds(showTabId);
	}
	
	function getFocusedPrimaryTabObjectId() {
		sforce.console.getFocusedPrimaryTabObjectId(showTabId);
	}
		
	var showTabId = function showTabId(result) {
		//Display the tab ID
		console.log('Tab ID: ' + result.id);
		return result.Id;
	};

    return {
        start: start,
        finish: finish
    };
});