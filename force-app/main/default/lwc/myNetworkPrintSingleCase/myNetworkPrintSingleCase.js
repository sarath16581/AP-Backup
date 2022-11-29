/*
  * @author       : haraprasad.sahoo@auspost.com.au
  * @date         : 23/03/2020
  * @description  : Component for Case Print(Single)
--------------------------------------- History --------------------------------------------------
23.03.2020    Hara Sahoo    Created
08.09.2022	  Naveen Rajanna 	REQ2963906: domain check to populate prefix myNetwork if required
14.11.2022	  Dattaraj Deshmukh Added getSelectedCases() method to get case investigations under a case to show/hide 'Case Print' button. 
								'Case Print' button is hidden from StarTrack cases which are navigated from Global Search.
								Added 'caseInvestigationRecordId' to populate case investigation record Id. 
*/
import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getSelectedCases from "@salesforce/apex/MyNetworkCaseListController.getSelectedCases";

export default class myNetworkPrintSingleCase extends NavigationMixin(LightningElement) {
	@api recordId;
	@api caseInvestigationRecordId;
	@track url;
	@track myDomainUrl;
	@track siteName;
	@track instanceName;
	@track showPrintButton = true;
	sfdcBaseURL;

	connectedCallback() {
		this.sfdcBaseURL = window.location.origin;
		var hostname = window.location.hostname;
		this.VFpage = {
			type: "standard__webPage",
			attributes: {
				url:
					"https://" +
					hostname +
					(this.sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") +
					"/apex/myNetworkCasePDFGenerator?selectedIds=" +
					encodeURI(this.recordId),
			},
		};

		//get case details to check if case investigations exists under a case.
		getSelectedCases({ caseRecordId: this.recordId })
      	.then(result => {

			//caseInvestigationRecordId is passed ONLY from MyNetwork Home Page case list view when Case Investigation link is clicked. 
			//This id helps navigate to case investigation record under a given case. 
			//'Case Print' button is hidden when a StarTrack case is accessed via Global Search.
			if(result.hasOwnProperty('CaseInvestigations__r') && result.CaseInvestigations__r && !this.caseInvestigationRecordId){
				this.showPrintButton = false;
			}
      	})
      	.catch(error => {
        	console.log("error>>>", error);
      	});
	}

	handleClick(evt) {
		evt.preventDefault();
		evt.stopPropagation();
		// Navigate to the Case print VF page.
		this[NavigationMixin.Navigate](this.VFpage);
	}
}