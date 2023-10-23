/**
 * @author Paul Perry
 * 
 * Contains all the schematics used by this LWC
 * Adds objects and fields here to add creaste intentional hard-wired dependancies
 */

// Objects
import OBJ_CSQ from '@salesforce/schema/Customer_Scoping_Questionnaire__c';
import OBJ_PICKUPLOCATION from '@salesforce/schema/Pick_Up_Location__c';
// Fields for Pick_Up_Location__c
import FLD_PICKUPLOCATION_CSQ from '@salesforce/schema/Pick_Up_Location__c.CSQ__c';
import FLD_PICKUPLOCATION_ID from '@salesforce/schema/Pick_Up_Location__c.Id';
import FLD_PICKUPLOCATION_NOTES from '@salesforce/schema/Pick_Up_Location__c.Notes__c';
import FLD_PICKUPLOCATION_PUL_STATUS from '@salesforce/schema/Pick_Up_Location__c.Pick_up_Location_Status__c';

// Fields for Customer_Scoping_Questionnaire__c
import FLD_CSQ_ID from '@salesforce/schema/Customer_Scoping_Questionnaire__c.Id';
import FLD_CSQ_CSQ_STATUS from '@salesforce/schema/Customer_Scoping_Questionnaire__c.CSQ_Status__c';

export default class Schema {
	static Customer_Scoping_Questionnaire__c = {
		...OBJ_CSQ,
		fields : {
			Id : FLD_CSQ_ID,
			CSQ_Status__c : FLD_CSQ_CSQ_STATUS
		},
		childRelationships : { }
	}

	static Pick_Up_Location__c = {
		...OBJ_PICKUPLOCATION,
		fields : {
			Id : FLD_PICKUPLOCATION_ID,
			Pick_up_Location_Status__c : FLD_PICKUPLOCATION_PUL_STATUS,
			CSQ__c : FLD_PICKUPLOCATION_CSQ,
			Notes__c : FLD_PICKUPLOCATION_NOTES
		},
		childRelationships : { }
	}

	static QueryFields = [
		// Pick_Up_Location__c fields
		...Object.values(Schema.Pick_Up_Location__c.fields).map(
			field => field.fieldApiName
		),
		// Referenced fields through CSQ__r for Customer_Scoping_Questionnaire__c fields
		...Object.values(Schema.Customer_Scoping_Questionnaire__c.fields).map(
			field => `CSQ__r.${field.fieldApiName}`
		)
	].map(
		fieldName => `${OBJ_PICKUPLOCATION.objectApiName}.${fieldName}`
	)
}