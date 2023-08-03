/**
 * @author Paul Perry
 * 
 * Sequence for submitting an CSQ for approval
 * - Show Modal
 * - Perform submission (backend call)
 * - Show success toast
 * - Trigger record refresh in UI
 */
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { UIToasts } from '../utilities/generic';
import approvalModal from 'c/csqModals';
import submitForApproval from '@salesforce/apex/CSQApprovalsController.submitForApproval';
import TaskWorker from '../utilities/worker';

const
	DIALOG_TITLE = 'Submit for Approval',
	TOAST_MSG_SUCCESS = 'The record has been Submitted for Approval',
	
	TASKS = {
		StartingPoint : undefined,
		ShowModal : 'showModal',
		PerformUpdate : 'performUpdate',
		NotifyBackendUpdates : 'notifyBackendUpdates',
		ShowSuccessToast : 'showSuccessToast'
	};

export default class SubmitRecord { 
	constructor(thisArg) {
		this.thisArg = thisArg;
	}

	// Actions to be performed during approval
	actions = {
		[TASKS.ShowModal] : () => approvalModal.open({
			modal: 'CustomerScopingQuestionnaire_SubmitApprovalDialog',
			size: 'small',
			title: DIALOG_TITLE,
			description: DIALOG_TITLE,
			label: DIALOG_TITLE
		}),

		[TASKS.PerformUpdate] : ({ comments }) => {
			const { thisArg } = this;			
			
			return submitForApproval({
				recordId :  thisArg.recordId,
				comments
			});
		},

		[TASKS.ShowSuccessToast] : () => UIToasts.showToastSuccess({
			thisArg : this.thisArg,
			message: TOAST_MSG_SUCCESS
		}),

		[TASKS.NotifyBackendUpdates] : ({ recordIds }) => notifyRecordUpdateAvailable(
			recordIds.map(recordId => ({ recordId }))
		)
	}

	// Sequence of actions: current_action(outputArgs) => next_action(inputArgs)
	actionList = {
		[TASKS.StartingPoint] : () => ({ action : TASKS.ShowModal }),
		[TASKS.ShowModal] : args => ({ 
			action : args ? TASKS.PerformUpdate : null,
			args
		}),
		[TASKS.PerformUpdate] : args => {
			this.recordIds = args;
			return { action : TASKS.ShowSuccessToast };
		},
		// Consider adding forced refresh updates for child records as they'll get submitted for approvel as well
		[TASKS.ShowSuccessToast] : () => ({
			action : TASKS.NotifyBackendUpdates,
			args : { recordIds : [ this.thisArg.recordId ] } 
		})
	}

	run() {
		const { thisArg } = this;
		let isDestroyed;
		let startTime = new Date();

		thisArg.backgroundTasks.isDestroyed.promise.then(
			() => isDestroyed = true
		);
		
		const onstatus = (args) => {
			console.log({
				'duration (ms)': new Date() - startTime,
				'last action': args.lastcompleted?.action,
				status: args.status
			});

			// display spinner until all tasks completed
			thisArg.isWorking = args.status !== 'done';

			if (isDestroyed && args.nextTask?.action) {
				// Abort next task if present
				args.nextTask.action = null;
			} else {
				startTime = new Date();
			}
		};

		const onerror = (message) => {
			// hide spinner
			thisArg.isWorking = false;

			message instanceof Error
				? console.error(message)
				: console.warn(message);

			return UIToasts.showToastError({ 
				message,
				thisArg
			});
		}

		// Action process for approval
		const { actions, actionList } = this;

		const sequencedTasks = new TaskWorker({
			actions, actionList, onerror, onstatus
		});

		// Kick off the sequence of tasks
		sequencedTasks.run();
	}
}