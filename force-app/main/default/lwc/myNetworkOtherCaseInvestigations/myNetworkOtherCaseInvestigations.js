/**
 * @description Component to list Case Investigations on MyNetwork community.
 * @author Dattaraj Deshmukh
 * @date 2019-12-05
 * @changelog
 * 2019-12-05 - Dattaraj Deshmukh - Created
 */

import { LightningElement, api, track  } from 'lwc';
import getOtherCaseInvestigations from "@salesforce/apex/MyNetworkOtherCaseInvestigationsCntr.getOtherCaseInvestigations";

export default class MyNetworkOtherCaseInvestigations extends LightningElement {
	@api recordId;

	dataTable_columns = [
		{
			label: "Case Investigation #",
			fieldName: "caseInvestigationLink",
			wrapText: true,
			hideDefaultActions : true, 
			type: "url",
			typeAttributes: {
			label: { fieldName: "Name" },
			tooltip: "Go to detail page",
			target: "_self",
			variant: "base",
			},
		},
		{
			label: "Article ID",
			fieldName: "Article__r",
			wrapText: true,
			hideDefaultActions : true
		},
		{
			label: "Status",
			fieldName: "Status__c",
			wrapText: true,
			hideDefaultActions : true
		},
		{
			label: "Network",
			fieldName: "Network__r",
			wrapText: true,
			hideDefaultActions : true
		}
	  ];
	
	@track caseInvestigations;

	connectedCallback() {

		let sfdcBaseURL = window.location.origin;

		getOtherCaseInvestigations({ caseInvestigationRecordId: this.recordId })
      	.then(result => {
     
        let tempCaseInvestigations = [];
        if(result){
          
      
			result.forEach(function (cInvestigationRec) {
            let cInvestigationRecord = {};
            for(let c in cInvestigationRec){
              if(c === 'Article__r' || c === 'Network__r')  {
                cInvestigationRecord[c] = cInvestigationRec[c].Name;
              }
              else if(c === 'Id') {
                cInvestigationRecord[c] = cInvestigationRec[c];
                cInvestigationRecord['caseInvestigationLink']  = (sfdcBaseURL.includes("auspostbusiness") ? "/myNetwork" : "") + "/caseinvestigation/" +cInvestigationRec[c];
              }
              else {
                cInvestigationRecord[c] = cInvestigationRec[c];
              }   
            }
            tempCaseInvestigations.push(cInvestigationRecord);
          });
      
        }

        this.caseInvestigations = tempCaseInvestigations;
      })
      .catch(error => {
        console.log("error>>>", error);
      });
	}

	get isCaseInvestigationAvailable(){
		return (this.caseInvestigations && this.caseInvestigations.length > 0 ? true : false);
	}
	

}