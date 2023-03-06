/**
 * @description Calls visualforce page and render case investigation details in PDF
 * @author Dattaraj Deshmukh
 * @date 2023-03-02
 * @group MyNetwork
 * @changelog
 * 2023-03-02 - Dattaraj Deshmukh - Created
 */
import { LightningElement, api, track, wire  } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__c';
import ID_FIELD from '@salesforce/schema/CaseInvestigation__c.Id';

export default class MyNetworkPrintSingleCaseInvestigation extends NavigationMixin(LightningElement) {
	@api recordId;
	@track url;
	@track myDomainUrl;
	@track siteName;
	@track instanceName;
	sfdcBaseURL;

	//get case investigation details
	@wire(getRecord, { recordId: '$recordId', fields: [CASE_FIELD, ID_FIELD]})
	caseInvestigation;

	handleClick(evt) {
		evt.preventDefault();
		evt.stopPropagation();

		let recordIds = getFieldValue(this.caseInvestigation.data, CASE_FIELD) + ','+  getFieldValue(this.caseInvestigation.data, ID_FIELD) ;
		this.sfdcBaseURL = window.location.origin;
		let hostname = window.location.hostname;
		this.VFpage = {
			type: "standard__webPage",
			attributes: {
				url:
					"https://" +
					hostname +
					(this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") +
					"/apex/myNetworkCasePDFGenerator?selectedIds=" + encodeURI(recordIds),
			},
		};
		
		// Navigate to the Case print VF page.
		this[NavigationMixin.Navigate](this.VFpage);
	}
}