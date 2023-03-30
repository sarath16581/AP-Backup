/**
 * @author Harry Wang
 * @date 2023-01-30
 * @group Controller
 * @tag Controller
 * @domain CreditAssessment
 * @description Javascript controller for creditAssessmentDetailsClosedOpp
 * @changelog
 * 2023-01-30 - Harry Wang - Created
 */
import {LightningElement, api, wire} from 'lwc';
import getDatatableColumns from '@salesforce/apex/CreditAssessmentController.retrieveDatatableColumns';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class CreditAssessmentDetailsClosedOpp extends LightningElement {
	bodyMessage = 'Approved credit assessments are found under this Opportunity, please select one from below and click Next or click Next without selecting to submit a new credit assessment';
	@api creditAssessments;
	columns = [];

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

	get creditAssessmentsData() {
		let tempCAList = [];
		this.creditAssessments.forEach((ca, i) => {
			let tempCA = Object.assign({}, ca);
			tempCAList[i] = tempCA;
			tempCAList[i].caUrl = '/' + tempCA.Id;
		});
		return tempCAList;
	}
}