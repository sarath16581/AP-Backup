/**
 * @description Calls visualforce page and render case investigation details in PDF
 * @author Dattaraj Deshmukh
 * @date 2023-03-02
 * @group MyNetwork
 * @changelog
 * 2023-03-02 - Dattaraj Deshmukh - Created
 * 06.07.2023    Swati Mogadala    INC2170610: After summer '23 release, _target fix on NavigationMixin
 */
import { LightningElement, api, track, wire  } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__c';
import ID_FIELD from '@salesforce/schema/CaseInvestigation__c.Id';

export default class MyNetworkPrintSingleCaseInvestigation extends NavigationMixin(LightningElement) {
	@api recordId;
	@track url;

	//get case investigation details
	@wire(getRecord, { recordId: '$recordId', fields: [CASE_FIELD, ID_FIELD]})
	caseInvestigation;

	handleClick(evt) {
		evt.preventDefault();
		evt.stopPropagation();

		let recordIds = getFieldValue(this.caseInvestigation.data, CASE_FIELD) + ','+  getFieldValue(this.caseInvestigation.data, ID_FIELD) ;
		
		// Navigate to the Case print VF page.
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
				attributes: {
					url: '/apex/myNetworkCasePDFGenerator?selectedIds=' + recordIds
				}
			}).then(generatedUrl => {
				window.open(generatedUrl, '_blank');
			});
		
	}
}