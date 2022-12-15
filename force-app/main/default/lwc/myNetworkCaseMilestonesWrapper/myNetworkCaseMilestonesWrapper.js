/**
 * @description Component used to wrap around existing 'myNetworkCaseMilestoneTracker' VF page.
 * 				Existing Vf page expects CASE ID and this page needed to be put onto CaseInvestigation__c detail experience cloud page.
 * 				Associated case details are fetched to be able to pass CASE ID from CaseInvestigation record.
 * @author Dattaraj Deshmukh
 * @date 2022-11-29
 * @changelog
 * 2022-11-29 - Dattaraj Deshmukh - Created
 */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__c';

const FIELDS = [CASE_FIELD];

export default class MyNetworkCaseMilestonesWrapper extends LightningElement {
    @track siteURL;
    @api recordId;
    @api caseInvestigationRecordId;
    @track isComponentVisible = false;

	//get CI record details. 
	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    caseInvestigationWiredRecord({ error, data }) {
        if (error) {
            let message = 'Error checking CI details';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (data) {

			//prepare VF page URL with iFrame.
			let sfdcBaseURL = window.location.origin;
			this.siteURL = sfdcBaseURL +  "/myNetwork/apex/myNetworkCaseMilestoneTracker?id=" + data.fields.Case__c.value;
			this.isComponentVisible = true;
        }
    }
}