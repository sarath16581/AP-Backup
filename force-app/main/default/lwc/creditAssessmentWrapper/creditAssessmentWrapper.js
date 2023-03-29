/**
 * @author Harry Wang
 * @date 2023-01-30
 * @group Controller
 * @tag Controller
 * @domain Sales
 * @description Javascript controller for creditAssessmentWrapper
 * @changelog
 * 2023-01-30 - Harry Wang - Created
 */
import {LightningElement, api, wire} from 'lwc';
import getCreditAssessment from '@salesforce/apex/CreditAssessmentController.getOpportunityCreditAssessment';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';

export default class CreditAssessmentWrapper extends LightningElement {
	messageBody;
	showCAClosedOpp;
	showProposal;
	showApprovedCAs;
	showCACreate;
	primaryProposal;
	creditAssessments = [];
	oppClosedStage = ['Closed Won', 'Closed Lost', 'Closed Disqualified', 'Closed Duplicate'];
	_wiredResult;
	reloadDisabled;
	@api recordId;

	@wire(getCreditAssessment, {opportunityId: '$recordId'})
	wiredCreditAssessmentResults(result) {
		const { data, error} = result;
		this._wiredResult = result;
		//reset views
		this.messageBody = null;
		this.showCACreate = false;
		this.showProposal = false;
		this.showApprovedCAs = false;
		this.showCAClosedOpp = false
		if (data) {
			this.creditAssessments = data.creditAssessments;
			// opportunity closed?
			if (this.oppClosedStage.includes(data.opportunity.StageName)) {
				// any credit assessments associated to the opportunity
				if (this.creditAssessments.length > 0) {
					// Display list of credit assessments associated to the opportunity
					this.showCAClosedOpp = true;
				} else {
					this.messageBody = data.messageBodyMap.OPPORTUNITY_CLOSED_NO_CA;
				}
			} else {
				// no proposal
				if (!data.opportunity.Apttus_Proposal__R00N70000001yUfDEAU__r) {
					this.messageBody = data.messageBodyMap.OPPORTUNITY_INCOMPLETE_OPC;
					return;
				}
				let primaryCount = 0;
				data.opportunity.Apttus_Proposal__R00N70000001yUfDEAU__r.forEach(p => {
					if (p.Apttus_Proposal__Primary__c) {
						this.primaryProposal = p;
						primaryCount++;
					}
				});
				// only one primary proposal?
				if (primaryCount === 1) {
					// Primary proposal checked out?
					if (this.primaryProposal && this.primaryProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c) {
						// OPC complete?
						if (data.opportunity.Count_of_Contract_Start_Dates__c === 0 && data.opportunity.Count_of_Contract_End_Dates__c === 0 && data.opportunity.Count_of_Opportunity_Line_Items__c > 0) {
							// Any credit assessments under primary proposal?
							if (this.creditAssessments.reduce((isPrimary, ca) => isPrimary || ca.APT_Proposal__r.Apttus_Proposal__Primary__c, false)) {
								this.showProposal = true;
							} else if (this.creditAssessments.length > 0 && this.creditAssessments.reduce((isApproved, ca) => isApproved || ca.APT_Credit_Assessment_Status__c === 'Approved' || ca.APT_Credit_Assessment_Status__c === 'Auto-Approved', false)) {
								this.showApprovedCAs = true;
								this.creditAssessments = this.creditAssessments.filter(ca => ca.APT_Credit_Assessment_Status__c === 'Approved' || ca.APT_Credit_Assessment_Status__c === 'Auto-Approved');
							} else {
								this.showCACreate = true;
							}
						} else {
							this.messageBody = data.messageBodyMap.OPPORTUNITY_INCOMPLETE_OPC;
						}
					} else {
						this.messageBody = data.messageBodyMap.OPPORTUNITY_PRIMARY_NOT_CHECKED;
					}
				} else {
					this.messageBody = data.messageBodyMap.OPPORTUNITY_INCOMPLETE_OPC;
				}
			}
		} else if (error) {
			console.error(error);
			let event = new ShowToastEvent({
				message: error.body.message,
				variant: 'error'
			});
			this.dispatchEvent(event);
		}
	}

	get primaryProposalId() {
		return this.primaryProposal.Id;
	}

	creditAssessmentRelinked() {
		this.showApprovedCAs = false;
		this.showProposal = true;
	}

	creditAssessmentCreate() {
		this.showApprovedCAs = false;
		this.showCACreate = true;
	}

	handleReload() {
		this.reloadDisabled = true;
		refreshApex(this._wiredResult).then(() => {this.reloadDisabled = false});
	}
}