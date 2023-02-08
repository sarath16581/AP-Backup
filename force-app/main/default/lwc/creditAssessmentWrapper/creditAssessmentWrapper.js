/**
 * @author Harry Wang
 * @date 2023-01-30
 * @group Controller
 * @tag Controller
 * @domain CSP
 * @description Javascript controller for creditAssessmentWrapper
 * @changelog
 * 2023-01-30 - Harry Wang - Created
 */
import {LightningElement, api, wire} from 'lwc';
import getCreditAssessment from '@salesforce/apex/CreditAssessmentController.getOpportunityCreditAssessment';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class CreditAssessmentWrapper extends LightningElement {
	messageBody;
	showCAClosedOpp;

	creditAssessments = [];
	oppClosedStage = ['Closed Won', 'Closed Lost', 'Closed Disqualified', 'Closed Duplicate'];
	@api recordId;

	@wire(getCreditAssessment, {opportunityId: '$recordId'})
	wiredCreditAssessmentResults({error, data}) {
		if (data) {
			console.log('data: ' + data);
			// opportunity closed?
			if (this.oppClosedStage.includes(data.opportunity.StageName)) {
				// any credit assessments associated to the opportunity
				if (data.creditAssessments.length === 0) {
					this.messageBody = data.messageBodyMap['OPPORTUNITY_CLOSED_NO_CA'];
				} else {
					// only one primary proposal?
					const primaryMap = new Map();
					data.creditAssessments.forEach(ca => {
						primaryMap.set(ca.APT_Proposal__r.Id, ca.APT_Proposal__r.Apttus_Proposal__Primary__c)
					});
					const primaryCount = [...primaryMap.values()].reduce((count, value) => (value ? count + 1 : count), 0);
					if (primaryCount === 1) {
						// Display list of credit assessments associated to the opportunity
						this.showCAClosedOpp = true;
						this.creditAssessments = data.creditAssessments;
					} else {
						this.messageBody = data.messageBodyMap['OPPORTUNITY_INCOMPLETE_OPC'];
					}
				}
			} else {
				// OPC complete?
				if (data.opportunity.Count_of_Contract_Start_Dates__c === 0 && data.opportunity.Count_of_Contract_End_Dates__c === 0 && data.opportunity.Count_of_Opportunity_Line_Items__c > 1) {
					// TODO: OPC complete
				} else {
					this.messageBody = data.messageBodyMap['OPPORTUNITY_INCOMPLETE_OPC'];
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
}