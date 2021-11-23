/**
 * @author       : arjun.singh@auspost.com.au
 * @date         : 23/03/2020
 * @description  : JS for Case Detail Page
 * @changelog
 * 2020-03-23 - Arjun Singh - Created
 * 2021-06-15 - Ranjeewa Silva - Fixed an issue where 'selectedCaseRecordWrapper' was not getting populated from results.
 */
/*******************************  History ************************************************
/* eslint-disable no-console */
import { LightningElement, track, api, wire } from "lwc";
import CASENUMBER_FIELD from "@salesforce/schema/Case.CaseNumber";
import CASE_PRIORITY from "@salesforce/schema/Case.Priority";
import SUBJECT_FIELD from "@salesforce/schema/Case.Subject";
import ENQUIRYSUBTYPE_FIELD from "@salesforce/schema/Case.EnquirySubType__c";
import CREATEDDATE_FIELD from "@salesforce/schema/Case.CreatedDate";
import ADDRESSEE_FIELD from "@salesforce/schema/Case.Secondary_Contact__c";
import ADDRESSEEADDRESS_FIELD from "@salesforce/schema/Case.Address2__c";
import LASTMODIFIEDBY_FIELD from "@salesforce/schema/Case.LastModifiedById";
import CASESTATUS_FIELD from "@salesforce/schema/Case.Status";
import TYPE_FIELD from "@salesforce/schema/Case.Type";
import REFERENCE_FIELD from "@salesforce/schema/Case.ReferenceID__c";
import SENDERNAME_FIELD from "@salesforce/schema/Case.Primary_Name__c";
import SENDERADDRESS_FIELD from "@salesforce/schema/Case.Address1__c";
import LASTMODIFIEDDATE_FIELD from "@salesforce/schema/Case.LastModifiedDate";
import CASE_ORIGINATOR from "@salesforce/schema/Case.CaseOriginator__c";
import DESCRIPTION_CONTENT from "@salesforce/schema/Case.DescriptionofContents__c";
import SENT_TO_NETWORK from '@salesforce/schema/Case.Sent_To_Network_Date__c';
import VALUE_OF_CONTENTS from '@salesforce/schema/Case.ValueofContents__c';
import getSelectedCases from "@salesforce/apex/MyNetworkCaseListController.getSelectedCases";
import getCaseMessages from "@salesforce/apex/MyNetworkCaseListController.getCaseMessages";
import { loadStyle } from "lightning/platformResourceLoader";
import customStyle from "@salesforce/resourceUrl/MYNetworkCustomStyle";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CaseDetails extends LightningElement {
  @track selectedCaseRecordWrapper = [];
  @track selectecCaseRecordId;
  @track recordFound = false;
  fields = [
    CASENUMBER_FIELD,
    CASESTATUS_FIELD,
    SUBJECT_FIELD,
    TYPE_FIELD,
    CASE_PRIORITY,
    ENQUIRYSUBTYPE_FIELD,
    ADDRESSEE_FIELD,
    ADDRESSEEADDRESS_FIELD,
    REFERENCE_FIELD,
    SENDERNAME_FIELD,
    SENDERADDRESS_FIELD,
    CREATEDDATE_FIELD,
    LASTMODIFIEDDATE_FIELD,
    LASTMODIFIEDBY_FIELD,
    CASE_ORIGINATOR,
    SENT_TO_NETWORK,
    DESCRIPTION_CONTENT,
    VALUE_OF_CONTENTS
  ];
  @api recordId;
  @track objectApiName = "Case";
  @track activeSections = ["A"];

  connectedCallback() {
    console.log("recordId>>>", this.recordId);

    Promise.all([
      loadStyle(this, customStyle + "/MYNetworkCustomStyle.css")
    ]).catch(error => {
      // eslint-disable-next-line no-console
      console.log("error in loading the style>>", error);
    });
    getSelectedCases({ caseRecordId: this.recordId })
      .then(result => {
        this.recordFound = true;
        this.selectedCaseRecordWrapper = result;
      })
      .catch(error => {
        console.log("error>>>", error);
      });
    console.log("Inside hasrelated NetoworkResp");
    
    getCaseMessages({ caseRecordId: this.recordId})
      .then(result =>{
          console.log('result>>>>>',result);
          for (let i = 0; i < result.length; i++) {
              this.showToast(result[i].messageType, result[i].messageString, 'sticky', 'success') ;
          }
      })
      .catch(error =>{
          console.log('error>>>',error);
      }) 
  }
  showToast(titleVar, messageVar, modeVar, variantVar) {
    const event = new ShowToastEvent({
      title: titleVar,
      message: messageVar,
      mode: modeVar,
      variant: variantVar
    });
    this.dispatchEvent(event);
  }
  handleSectionToggle(event) {
    const openSections = event.detail.openSections;
  }
}