/**
 * @author Paul Perry
 * 
 * This class is the main entry point for APT Credit Assessment records
 * - Drives which fields need to be fetched for this APT_Credit_Assessment__c record
 * - Execute sequence of tasks to perform the Credit Suspect Registry check
 */
import { UIToasts } from "../utilities/generic";
import Schema from "../utilities/schema";
import suspectRegisterCheck from '@salesforce/apex/BCAFormController.performSuspectRegisterCheck';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

const TOAST = {
	IN_PROGRESS : {
		title : 'Verification in Progress...',
		message : 'Director and Contact details are verified against the Suspect Register',
		variant : 'info'
	},
	REFERRED : {
		title : 'Assessment Referred!',
		variant : 'warning',
		message : 'Matching details have been captured on this Credit Assessment record'
	},
	NO_MATCHES : {
		message : 'No matches were found in Suspect Register'
	}
};

export default class Main {
	static getRecordFields = [
		// APT_Credit_Assessment__c fields
		...Object.values(Schema.APT_Credit_Assessment__c.fields).map(
			field => field.fieldApiName
		)
	].map(
		fieldName => `${Schema.APT_Credit_Assessment__c.objectApiName}.${fieldName}`
	);

	constructor(thisArg) {
		this.thisArg = thisArg;
	}

	async invoke() {
		const { thisArg } = this;
		// Consolidate task detail in smaller methods
		const responseFeedback = (isReferred) => {
			// Response from backend will be true or false. Any exceptions will be handled in the catch block of the sequence execution
			if (isReferred) {
				UIToasts.showToast({ thisArg, ...TOAST.REFERRED });				
			} else {
				return UIToasts.showToastSuccess({ thisArg, ...TOAST.NO_MATCHES });
			}
		};

		// 5 Actions in the task list, to be executed in a sequence:
		const taskList = [
			// #0: Inform user we're running the check
			() => UIToasts.showToast({ thisArg, ...TOAST.IN_PROGRESS }),

			// #1: Obtain the current recordId as input for task #2
			() => Promise.resolve(thisArg.recordId),

			// #2: Verify (and optionally update) the credit assessment record, returns whether it's referred
			creditAssessmentId => suspectRegisterCheck({ creditAssessmentId }),

			// #3: Show feedback to user and optionally refresh the record information (after backend record update)
			isReferred => Promise.resolve(responseFeedback(isReferred)),

			// #4: Refresh the current record to reflect any updates
			() => Promise.resolve(notifyRecordUpdateAvailable([{ recordId: thisArg.recordId }]))
		];
		
		const execute = async (taskIdx = 0, args) => {
			try {
				const result = await taskList[taskIdx](args);
				// Continue sequence execution until completed or user navigated elsewhere (prevents errors in Console App)
				if (taskIdx < taskList.length - 1 && !thisArg.backgroundTasks.isDestroyed.status) {
					// Execute the next task in the sequence
					execute(taskIdx + 1, result);
				}
			} catch (ex) {
				// Handle all other type of Errors (like possible connectivity issues or insufficient record access)
				return await UIToasts.showToastError({ thisArg, message: ex });
			}
		};

		// Execute the sequence
		return await execute();
	}
}