/**
 * @author Paul Perry
 * 
 * This class is the main entry point for Pick-up Location records
 * - Drives which fields need to be fetched for this Pick_Up_Location__c record
 * - Brings up the correct dialog based on its current record state
 */
import { UIToasts } from "../utilities/generic";
import Schema from "../utilities/schema"
import UpdateStatus from "./updateStatus";

const MATCHING_STATUSSES = new Set([
	'Submitted for Approval',
	'Pending Information',
	'Received Information'
]);

export default class Main {
	static getRecordFields = [
		// Pick_Up_Location__c fields
		...Object.values(Schema.Pick_Up_Location__c.fields).map(
			field => field.fieldApiName
		),
		
		// Referenced fields through CSQ__r for Customer_Scoping_Questionnaire__c fields
		...Object.values(Schema.Customer_Scoping_Questionnaire__c.fields).map(
			field => `CSQ__r.${field.fieldApiName}`
		)
	].map(
		fieldName => `${Schema.Pick_Up_Location__c.objectApiName}.${fieldName}`
	);

	constructor(thisArg) {
		this.thisArg = thisArg;
	}

	showModal() {
		const { thisArg } = this;

		thisArg.backgroundTasks.getRecord.promise.then((record) => {
			let status = record.fields.Pick_up_Location_Status__c?.value;
			let process;

			if (MATCHING_STATUSSES.has(status)) {
				process = new UpdateStatus(thisArg);
			} else {
				return UIToasts.showToastError({
					thisArg,
					message : 'This action cannot be performed at this time'
				});
			}

			process.run();
		});
	}
}