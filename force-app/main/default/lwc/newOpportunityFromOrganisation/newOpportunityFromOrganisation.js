/**
 * @author Harry Wang
 * @date 2023-06-15
 * @group Controller
 * @tag Controller
 * @domain Sales
 * @description Javascript controller for newOpportunityFromOrganisation
 * Allowing users to create simple record type Opportunity based on the inputs and navigate to opportunity record page on successful creation
 * Replacing existing flow: Create_New_Opportunity_From_Organisation as implementing dependent picklist with controlling picklist as read only not possible with flow
 * @changelog
 * 2023-06-15 - Harry Wang - Created
 */
import {LightningElement, api, wire} from 'lwc';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import NAME from '@salesforce/schema/Account.Name';
import ROLE_TYPE from '@salesforce/schema/Account.Role_Type_Roll_Up__c';
import {getRecord, getFieldValue, createRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
export default class NewOpportunityFromOrganisation extends NavigationMixin(LightningElement) {
	@api recordId;
	isStartrackOpportunity;
	errorMessage;
	isLoading;

	@wire(getRecord, { recordId: '$recordId', fields: [NAME, ROLE_TYPE]})
	organisation;

	@wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
	OpportunityInfo;

	get roleType() {
		const type = getFieldValue(this.organisation.data, ROLE_TYPE);
		if (type === 'Customer') {
			return 'Existing Customer';
		}
		return 'New Customer';
	}

	get organisationName() {
		return getFieldValue(this.organisation.data, NAME);
	}

	handleIsStartrackOpportunity(event) {
		this.isStartrackOpportunity = event.detail.value === 'Yes';
	}

	handleSave(event) {
		event.preventDefault();
		const fields = event.detail.fields;
		// Assign simple record type Id
		const recordTypeInfo = this.OpportunityInfo.data.recordTypeInfos;
		const simpleRecordTypeId = Object.keys(recordTypeInfo).find(i => recordTypeInfo[i].name === 'Simple');
		fields.RecordTypeId = simpleRecordTypeId;
		// Assign account Id
		fields.AccountId = this.recordId;
		const recordInput = {apiName: OPPORTUNITY_OBJECT.objectApiName, fields};
		this.isLoading = true;
		createRecord(recordInput).then((record) => {
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: record.id,
					objectApiName: 'Opportunity',
					actionName: 'view'
				}
			});
		}).catch((error) => {
			const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
			if (errorMessages) {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error creating opportunity",
						message: errorMessages,
						variant: "error",
					}),
				);
			}
			this.isLoading = false;
		});

	}
}