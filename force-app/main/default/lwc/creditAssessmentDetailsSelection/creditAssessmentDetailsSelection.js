/**
 * @author Harry Wang
 * @date 2023-02-15
 * @group Controller
 * @tag Controller
 * @domain CreditAssessment
 * @description Javascript controller for creditAssessmentDetailsSelection
 * @changelog
 * 2023-02-15 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import getDatatableColumns from '@salesforce/apex/CreditAssessmentController.retrieveDatatableColumns';
import updateCreditAssessmentDetails from '@salesforce/apex/CreditAssessmentController.updateCreditAssessmentDetails';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import LightningConfirm from 'lightning/confirm';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import CREDIT_ASSESSMENT_STATUS from "@salesforce/schema/Apttus_Proposal__Proposal__c.APT_Credit_Assessment_Status__c";
import NEW_ACCOUNT_TYPE from "@salesforce/schema/Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c";
import CREDIT_ASSESSMENT from "@salesforce/schema/Apttus_Proposal__Proposal__c.APT_Credit_Assessment__c";
import CREDIT_ASSESSMENT_PROPOSAL from "@salesforce/schema/APT_Credit_Assessment__c.APT_Proposal__c";
import CHARGE_ACCOUNT_PROPOSAL from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__c";
import SUB_CHARGE_ACCOUNT_PROPOSAL from "@salesforce/schema/APT_Sub_Account__c.APT_Quote_Proposal__c";

export default class CreditAssessmentDetailsSelection extends LightningElement {
	bodyMessage = 'Approved credit assessments are linked to this Opportunity. Please select one of the below Approved credit assessments to continue or create a new Credit Assessment using the Create button below.';
	@api creditAssessments;
	columns = [];
	@api primaryProposalId;
	isProcessing = false;
	chargeAccountId;

	@wire(getDatatableColumns)
	wiredColumns({error, data}) {
		if (data) {
			this.columns = data;
		} else if (error) {
			console.error(error);
			let event = new ShowToastEvent({
				message: error.body.message,
				variant: 'error'
			});
			this.dispatchEvent(event);
		}
	}

	@wire(getRelatedListRecords, {
		parentRecordId: '$chargeAccountId',
		relatedListId: 'Sub_Accounts__r'
	})
	subChargeAccounts;

	get creditAssessmentsData() {
		let tempCAList = [];
		this.creditAssessments.forEach((ca, i) => {
			let tempCA = Object.assign({}, ca);
			tempCAList[i] = tempCA;
			tempCAList[i].caUrl = '/' + tempCA.Id;
		});
		return tempCAList;
	}

	handleRowAction() {
		this.template.querySelector('[data-id="next"]').disabled = false;
	}

	handleCancel() {
		this.template.querySelector('lightning-datatable').selectedRows=[];
		this.template.querySelector('[data-id="next"]').disabled = true;
	}

	async handleNext() {
		const selectedCA =  this.template.querySelector("lightning-datatable").getSelectedRows()[0];
		this.chargeAccountId = selectedCA.APT_Charge_Account__c;
		const confirmed = await LightningConfirm.open({
			message: 'Are you sure you want to link the selected Credit Assessment: ' + selectedCA.Name + ' to the Primary Proposal under the Opportunity?',
			variant: 'headerless',
			label: 'Credit Assessment Reassignment'
		});
		if (confirmed) {
			try {
				this.isProcessing = true;
				// Relink selected CA to primary proposal from current proposal
				const primaryProposalFields = {};
				primaryProposalFields.Id = this.primaryProposalId;
				primaryProposalFields[CREDIT_ASSESSMENT_STATUS.fieldApiName] = selectedCA.APT_Proposal__r[CREDIT_ASSESSMENT_STATUS.fieldApiName];
				primaryProposalFields[NEW_ACCOUNT_TYPE.fieldApiName] = selectedCA.APT_Proposal__r[NEW_ACCOUNT_TYPE.fieldApiName];
				primaryProposalFields[CREDIT_ASSESSMENT.fieldApiName] = selectedCA.APT_Proposal__r[CREDIT_ASSESSMENT.fieldApiName];

				// Clear fields on current proposal
				const proposalFields = {};
				proposalFields.Id = selectedCA.APT_Proposal__c;
				proposalFields[CREDIT_ASSESSMENT_STATUS.fieldApiName] = null;
				proposalFields[NEW_ACCOUNT_TYPE.fieldApiName] = null;
				proposalFields[CREDIT_ASSESSMENT.fieldApiName] = null;

				// Update credit assessment
				const creditAssessmentFields = {};
				creditAssessmentFields.Id = selectedCA.Id;
				creditAssessmentFields[CREDIT_ASSESSMENT_PROPOSAL.fieldApiName] = this.primaryProposalId;

				// Relink charge account and sub charge accounts
				const chargeAccountFields = {};
				chargeAccountFields.Id = selectedCA.APT_Charge_Account__c;
				chargeAccountFields[CHARGE_ACCOUNT_PROPOSAL.fieldApiName] = this.primaryProposalId;

				const subChargeAccounts = [];
				this.subChargeAccounts.data.records.forEach(sca => {
					const subChargeAccountFields = {};
					subChargeAccountFields.Id = sca.id;
					subChargeAccountFields[SUB_CHARGE_ACCOUNT_PROPOSAL.fieldApiName] = this.primaryProposalId;
					subChargeAccounts.push(subChargeAccountFields);
				});

				const creditAssessmentDetails = [primaryProposalFields, proposalFields, creditAssessmentFields, chargeAccountFields, ...subChargeAccounts];
				updateCreditAssessmentDetails({creditAssessmentDetails: creditAssessmentDetails}).then(() => {
					this.isProcessing = false;
					let event = new ShowToastEvent({
						message: 'Relink Credit Assessment Succeeded',
						variant: 'success'
					});
					this.dispatchEvent(event);

					// send event back to wrapper lwc to reload view
					this.dispatchEvent(new CustomEvent('relinked'));
				});
			} catch (e) {
				console.error(e);
				let event = new ShowToastEvent({
					message: 'Relink Credit Assessment failed due to: ' + e.message,
					variant: 'error'
				});
				this.dispatchEvent(event);
			}
		}
	}

	async handleCreate() {
		const confirmed = await LightningConfirm.open({
			message: 'Are you sure you want to create a new Credit Assessment?',
			variant: 'headerless',
			label: 'New Credit Assessment Creation'
		});
		if (confirmed) {
			this.dispatchEvent(new CustomEvent('create'));
		}
	}
}