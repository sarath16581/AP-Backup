/**************************************************
Description: CTI methods for creating and closing tasks when interactions begin and end

History:
--------------------------------------------------
2018-08-20	nathan.franklin@auspost.com.au	Created
**************************************************/
define(['util', 'integration', 'config', 'SFDC/tracking', 'AP/utils', 'AP/integration', 'i18next', 'moment'],
	function (util, sforce, config, tracking, apUtils, apIntegration, i18n, moment) {
		var log_prefix = 'AP/task';

		/**
		 * Called when initialized, this will set overrides for custom processing
		 */
		var setOverrides = function() {
		    config.taskStartOverride = taskStart;
		    config.taskFinishOverride = taskFinish;
  		};

		/**
		 * this is called from within SFDC/task.js to override a tasking functionality
		 */
		var taskStart = function(params) {
			console.log(log_prefix, 'taskStart', params);

			var ixn = params.ixn;
			var contact = params.contact || {};
			var caseId = params.caseId || '';
			var popOnly = params.popOnly || false;

			// as a little hack we need to 'track' the call type to determine whether navigating to a contact id in service cloud (controller.js) should pass details back to Workspace or not
			tracking.setCallType(ixn.id, ixn.callType);
            tracking.setCallbackStatus(ixn.id, ixn.userData['ENG_CB_Status']);

			var d = $.Deferred();
			if (config.CREATE_TASK && config.NEW_TASK_ON_POP && !popOnly) {
				var whoId = (!apUtils.isEmpty(contact) && !apUtils.isEmpty(contact.Id) ? contact.Id : '');
				var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
				var primaryTabId = tracking.getPrimaryTabId(ixn.id);
				var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
				var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();
				console.log(log_prefix + "create task " + subject);

				var taskMappings = apUtils.getTaskMappingValues(ixn.userData);
				apIntegration.createTask(whoId, caseId, subject, ixn.userData, taskMappings,
					function (task) {
						if (!apUtils.isEmpty(task)) {
							console.log(log_prefix, 'redirect to new task', task.Id, primaryTabId, currentPrimaryTabId);

							// add all the tracking information to this task
							tracking.setWhatId(ixn.id, caseId);
							//tracking.setTaskTabId(ixn.id, tab.id);
							tracking.setTaskId(ixn.id, task.Id);
							tracking.setCaseId(ixn.id, caseId);

							d.resolve();
						} else {
							console.warn(log_prefix + "Could not create task");
							d.reject();
						}
					}
				);
			} else {
				console.log(log_prefix + "No task on pop");
				d.reject();
			}

			console.log(log_prefix + "start - finished");
			return d.promise();

		};

		/**
		 * this is called from within SFDC/case.js to override a case pop after a case is found
		 * Initially task.start() is called and then at the end of the call task.finish is called
		 */
		var taskFinish = function(id, comments, ixn, duration) {
			console.log(log_prefix, 'taskFinish', id, comments, ixn, duration);

			var d = $.Deferred();

			if (config.CREATE_TASK && ixn.isConsult === undefined) { // don't do tasks with consult calls
				var primaryTabId = tracking.getPrimaryTabId(id);
				var taskTabId = tracking.getTaskTabId(id);
				var subject = i18n.t('mediaType.' + ixn.mediaType) + " " + moment().format('YYYY-MM-DD HH:mm:ss');
				if (duration === undefined) {
					duration = 0;
				}

				console.log(log_prefix + "create/update the task");

				// grab the custom attributes if they have been attached to the tracking interaction
				var custom = tracking.getCustom(id);

				// either get the case id from the initial CTI flow or if that is empty get the last case id the agent was looking at in service cloud (set in controller/controller.js)
				var contact = tracking.getContact(id);
				var caseId = tracking.getCaseId(id);
				var whatId = tracking.getWhatId(id) || (!apUtils.isEmpty(custom) && !apUtils.isEmpty(custom.tempCaseId) ? custom.tempCaseId : '');

				// for OUTBOUND calls, a contact must be matched at the start of the interaction
				// this will be using click to dial on either the Contact or Case pages
				// if a call was started directly from within Workspace or if click to dial is used outside the Contact/Case layouts, the whoId needs to be empty because a contact should never be 'found' for outbound calls
				var whoId = (!apUtils.isEmpty(contact) && !apUtils.isEmpty(contact.Id) ? contact.Id : ((ixn.callType !== 'Outbound' || (ixn.callType === 'Outbound' && ixn.userData['ENG_CB_Status'] === 'Success')) && !apUtils.isEmpty(custom) && !apUtils.isEmpty(custom.tempContactId) ? custom.tempContactId : ''));

				var currentPrimaryTabId = tracking.getCurrentPrimaryTabId();
				var currentPrimaryTabObjectId = tracking.getCurrentPrimaryTabObjectId();
				var taskId = tracking.getTaskId(id) || '';

				var taskMappings = apUtils.getTaskMappingValues(ixn.userData);
				apIntegration.closeTask(taskId, whatId, whoId, subject, comments, ixn.userData, config.DISPOSITION_KVP, taskMappings, duration, ixn.id, ixn.callType,
					function (result) {
					    if(!apUtils.isEmpty(result)) {
							d.resolve();
						} else {
							console.warn(log_prefix + "could not close task");
							d.reject();
						}
					}
				);
			} else {
				console.log(log_prefix + "No task on close");
				d.reject();
			}

			console.log(log_prefix + "finish - finished");
			return d.promise();
		};

		return {
		    setOverrides: setOverrides
  		};
	}
);

