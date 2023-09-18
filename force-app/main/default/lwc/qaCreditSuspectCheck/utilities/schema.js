/**
 * @author Paul Perry
 * 
 * Contains all the schematics used by this LWC
 * Adds objects and fields here to add creaste intentional hard-wired dependancies
 */

// Objects
import OBJ_APTCREDITASSESSMENT from '@salesforce/schema/APT_Credit_Assessment__c';
// Fields for APT_Credit_Assessment__c
import FLD_APTCREDITASSESSMENT_ID from '@salesforce/schema/APT_Credit_Assessment__c.Id';

export default class Schema {
	static APT_Credit_Assessment__c = {
		...OBJ_APTCREDITASSESSMENT,
		fields : {
			Id : FLD_APTCREDITASSESSMENT_ID
		},
		childRelationships : { }
	}
}