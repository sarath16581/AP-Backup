/**
 * @author Paul Perry
 * 
 * Sequence for updating the status to Pending Information or Information Received while (locked) in approval process
 * - Show Modal
 * - Perform updates (backend call)
 * - Show success toast
 * - Trigger record refresh in UI
 */
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { UIToasts } from '../utilities/generic';
import approvalModal from 'c/csqModals';
import Schema from '../utilities/schema';
import updatePickupLocationStatus from '@salesforce/apex/CSQApprovalsController.updatePickupLocationStatus';
import TaskWorker from '../utilities/worker';

const
	DIALOG_TITLE = 'Update Pick-Up Location',
	TOAST_MSG_SUCCESS = 'Pick-Up Location Status Updated',
	
	TASKS = {
		StartingPoint : undefined,
		ShowModal : 'showModal',
		PerformUpdate : 'performUpdate',
		NotifyBackendUpdates : 'notifyBackendUpdates',
		ShowSuccessToast : 'showSuccessToast'
	},
	
	NEW_STATUS = {
		'Submitted for Approval' : 'Pending',
		'Pending Information' : 'Received',
		'Received Information' : 'Pending'
	};

export default class UpdateStatus { 
	constructor(thisArg) {
		this.thisArg = thisArg;

		const currentStatus = thisArg.record.fields[
			Schema.Pick_Up_Location__c.fields.Pick_up_Location_Status__c.fieldApiName
		].value;

		this.status = NEW_STATUS[currentStatus];
		this.notes = thisArg.record.fields[
			Schema.Pick_Up_Location__c.fields.Notes__c.fieldApiName
		].value;
	}

	// Actions to be performed during approval
	actions = {
		[TASKS.ShowModal] : () => approvalModal.open({
			modal : 'PickUpLocation_StatusUpdate',
			size : 'small',
			// title: DIALOG_TITLE, => will be provided dynamically based on status
			description : DIALOG_TITLE,
			label : DIALOG_TITLE,
			args: {
				status : this.status,
				notes : this.notes
			}
		}),

		[TASKS.PerformUpdate] : ({ comments }) => {
			const { thisArg } = this;
			
			return updatePickupLocationStatus({
				recordId : thisArg.recordId,
				status : this.status,
				comments
			});
		},

		[TASKS.ShowSuccessToast] : () => UIToasts.showToastSuccess({
			thisArg : this.thisArg,
			message : TOAST_MSG_SUCCESS
		}),

		// Consider adding related child record Ids here that got submitted along with its parent
		// to make them force refresh as well within the UI
		[TASKS.NotifyBackendUpdates] : ({ recordIds }) => notifyRecordUpdateAvailable(
			recordIds.map(recordId => ({ recordId }))
		)
	}

	// Sequence of actions: current_action(outputArgs) => next_action(inputArgs)
	actionList = {
		[TASKS.StartingPoint] : (args) => ({ action : TASKS.ShowModal, args }),
		[TASKS.ShowModal] : args => ({ 
			action : args ? TASKS.PerformUpdate : null,
			args
		}),
		[TASKS.PerformUpdate] : args => {
			this.recordIds = args;
			return { action : TASKS.ShowSuccessToast };
		},
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

		// Process for approval
		const { actions, actionList } = this;

		const sequencedTasks = new TaskWorker({
			actions, actionList, onerror, onstatus
		});

		sequencedTasks.run(thisArg.args);
	}
}