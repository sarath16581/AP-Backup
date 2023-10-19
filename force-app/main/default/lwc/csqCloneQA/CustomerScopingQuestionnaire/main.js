/**
 * @author Paul Perry
 * 
 * This class is the main entry point for CustomerScopingQuestionnaire records
 * - Drives which fields need to be fetched for this Customer_Scoping_Questionnaire__c record
 * - Brings up the correct dialog based on its current record state
 */
import { UIToasts } from "../utilities/generic";
import Schema from "../utilities/schema"
import CloneRecordTree from "./clone";

export default class Main {
	static getRecordFields = [
		// Customer_Scoping_Questionnaire__c fields
		...Object.values(Schema.Customer_Scoping_Questionnaire__c.fields).map(
			field => field.fieldApiName
		)
	].map(
		fieldName => `${Schema.Pick_Up_Location__c.objectApiName}.${fieldName}`
	);

	constructor(args) {
		if (args && typeof args === 'object') {
			Object.keys(args).forEach(key => this[key] = args[key]);
		}
	}

	showModal() {
		const { thisArg } = this;

		thisArg.backgroundTasks.getRecord.promise.then((record) => {
			// Apply Conditions
			const validForCloning = true;
			if (!validForCloning) {
				UIToasts.showToastError({
					thisArg,
					message: 'This action cannot be performed at this time'
				});
			} else {
				const process = new CloneRecordTree(thisArg);
				process.run();
			}
		});
	}
}