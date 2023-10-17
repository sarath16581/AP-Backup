/**
 * @author Paul Perry
 * 
 * Sequence for submitting an CSQ for approval
 * - Show Modal
 * - Perform submission (backend call)
 * - Show success toast
 * - Trigger record refresh in UI
 */
import { UIToasts } from '../utilities/generic';
import approvalModal from 'c/csqModals';
import cloneCSQTree from '@salesforce/apex/CSQApprovalsController.cloneCSQTree';
import TaskWorker from '../utilities/worker';

const
	DIALOG_TITLE = 'Duplicate CSQ records',
	TOAST_MSG_SUCCESS = 'CSQ Record has been duplicated. Click {0} to open',
	TOAST_MSG_INPROGRESS = 'This might take some time. You\'ll be redirected once completed.',
	
	TASKS = {
		StartingPoint : undefined,
		ShowModal : 'showModal',
		ShowInProgressToast : 'showInProgressToast',
		PerformCloning : 'performCloning',
		NotifyBackendUpdates : 'notifyBackendUpdates',
		ShowSuccessToast : 'showSuccessToast',
		ShowErrorToast : 'showErrorToast',
		NavigateToClone : 'navigateToClone'
	};

export default class CSQClone { 
	constructor(thisArg) {
		this.thisArg = thisArg;
	}

	// Actions to be performed during approval
	actions = {
		[TASKS.ShowModal] : () => approvalModal.open({
			modal: 'CustomerScopingQuestionnaire_Clone',
			size: 'small',
			title: DIALOG_TITLE,
			description: DIALOG_TITLE,
			label: DIALOG_TITLE
		}),

		[TASKS.PerformCloning] : (inputArgs) => {
			const { thisArg } = this;			
			UIToasts.showToast({
				thisArg,
				title : 'Cloning in Progress',
				variant : 'info',
				message : TOAST_MSG_INPROGRESS
			});
			
			return cloneCSQTree({ recordId : thisArg.recordId, cloneOptions : [ inputArgs.rgCloneOptions ] });
		},

		[TASKS.ShowSuccessToast] : (cloneId) => {
			return UIToasts.showToastSuccess({
				thisArg : this.thisArg,
				message : TOAST_MSG_SUCCESS,
				messageData: [{
					url : `../${cloneId}/view`,
					label: 'here',
				}]
			});
		},

		[TASKS.ShowErrorToast] : (result) => {
			debugger;
			console.log(result);
			return UIToasts.showToastError({
				thisArg : this.thisArg,
				message : 'Something went wrong'
			});
		},
		
		[TASKS.NavigateToClone] : () => {
			this.thisArg.navToRecordId(this.cloneId);
		}
	}

	// Sequence of actions: current_action(outputArgs) => next_action(inputArgs)
	actionList = {
		[TASKS.StartingPoint] : () => ({ action : TASKS.ShowModal }),
		[TASKS.ShowModal] : args => ({ 
			action : args ? TASKS.PerformCloning : null,
			args
		}),
		[TASKS.PerformCloning] : result => {
			if (result.success) {
				this.cloneId = result.dmlResults.find(r => r.sourceId === this.thisArg.recordId)?.targetId;
				return { action : TASKS.ShowSuccessToast, args : this.cloneId };
			} else {
				return { action : TASKS.ShowErrorToast, args : result };
			}
		},
		[TASKS.ShowSuccessToast] : args => {
			return { action : TASKS.NavigateToClone, args };
		}
	}

	run() {
		const { thisArg } = this;
		let isDestroyed;
		let startTime = new Date();
	
		thisArg.backgroundTasks.isDestroyed.promise.then(
			() => {
				isDestroyed = true;
				return null;
			}
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

			if (message instanceof Error) {
				console.error(message);
			} else {
				console.warn(message);
			}

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