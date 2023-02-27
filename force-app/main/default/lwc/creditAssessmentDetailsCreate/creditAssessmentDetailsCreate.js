/**
 * @author Harry Wang
 * @date 2023-02-23
 * @group Controller
 * @tag Controller
 * @domain CSP
 * @description Javascript controller for creditAssessmentDetailsCreate
 * @changelog
 * 2023-02-23 - Harry Wang - Created
 */
import {api, LightningElement} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ACCOUNT_TYPE from '@salesforce/schema/Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c';
import ID from '@salesforce/schema/Apttus_Proposal__Proposal__c.Id';

export default class CreditAssessmentDetailsCreate extends NavigationMixin(LightningElement) {
	@api proposalId;
	@api opportunityId;
	selectedValue;

	get disabled() {
		return !this.selectedValue;
	}

	get options() {
		return [
			{ label: 'Charge Account', value: 'Charge Account' },
			{ label: 'Charge Account + Sub Account', value: 'Charge Account + Sub Account' },
		];
	}

	handleChange(event) {
		this.selectedValue = event.detail.value;
	}

	handleNext() {
		// Update primary proposal with selected account type
		const fields = {};
		fields[ID.fieldApiName] = this.proposalId;
		fields[ACCOUNT_TYPE.fieldApiName] = this.selectedValue;
		const recordInput = {fields};
		updateRecord(recordInput).then(() => {
			// Generate a URL to a User record page
			this[NavigationMixin.GenerateUrl]({
				type: 'standard__webPage',
				attributes: {
					url: '/apex/Apt_CreditAssessment?proposalId='+ this.proposalId + '&contextId=' + this.opportunityId
				}
			}).then((url) => {
				window.open(url);
			});
		}).catch(error => {
			console.error(error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error updating primary account.',
					message: error.body.message,
					variant: 'error'
				})
			);
		});

	}
}