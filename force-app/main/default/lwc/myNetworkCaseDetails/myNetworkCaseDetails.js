/**
 * @author			: arjun.singh@auspost.com.au
 * @date			: 23/03/2020
 * @description		: JS for Case Detail Page
 * @changelog
 * 2020-03-23 - Arjun Singh - Created
 * 2021-06-15 - Ranjeewa Silva - Fixed an issue where 'selectedCaseRecordWrapper' was not getting populated from results.
 * 2022-11-08 - Dattaraj Deshmukh - Added Case Investigation fields. 
 * 2023-03-02 - Dattaraj Deshmukh - Added 'caseInvestigationActiveSections' and 'caseActiveSections' properties to toggle active sections.
 * 2023-03-10 - Dattaraj Deshmukh - Added 'OWNER_NAME_FIELD' for a case to display case's owner name.
 * 2023-03-31 - Mahesh Parvathaneni - Added Initial contact fields under More Details for case investigation
 * 2023-04-05 - Mahesh Parvathaneni - Removed the field WEB_EMAIL_FIELD from More Details section
 * 2023-05-03 - Mahesh Parvathaneni - Updated SentToNetworkDatetime__c field for case investigation
 * 2023-12-20 - Talib Raza - INC2252982 - added back call to getCaseMessages
 */
/*******************************  History ************************************************
/* eslint-disable no-console */
import { LightningElement, track, api } from "lwc";
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
import getCaseMessages from "@salesforce/apex/MyNetworkCaseListController.getCaseMessages";
import PURPOSE_FIELD from '@salesforce/schema/Case.Call_Purpose__c';
//import CONSIGNMENT_ID_FIELD from '@salesforce/schema/Case.Consignment_Unique_External_ID__c';
import CONSIGNMENT_ID_FIELD from '@salesforce/schema/Case.Calc_Case_Consignment__c';

import RECEIVER_NAME_FIELD from '@salesforce/schema/Case.StarTrack_Receiver_Name__c';
import RECEIVER_ADDRESS_FIELD from '@salesforce/schema/Case.Address4__c';
import CREATED_BY_FIELD from '@salesforce/schema/Case.CreatedById';
import VALUE_OF_GOODS_FIELD from '@salesforce/schema/Case.Value_of_Goods__c';
import ENQUIRY_TYPE from '@salesforce/schema/Case.Enquiry_Type__c';
import STARTRACK_RECEIVER_NAME_FIELD from '@salesforce/schema/Case.Article_Receiver_Name__c';
import STARTRACK_RECEIVER_ADDRESS_FIELD from '@salesforce/schema/Case.Article_Receiver_Address__c';
import STARTRACK_SENDER_NAME_FIELD from '@salesforce/schema/Case.Article_Sender_Name__c';
import STARTRACK_SENDER_ADDRESS_FIELD from '@salesforce/schema/Case.Article_Sender_Address__c';
import STARTRACK_DESCRIPTION_OF_CONTENT_FIELD from '@salesforce/schema/Case.Description_of_contents__c';

/**'More Details' section fields to be shown ONLY ON CaseInvestigation's DETAIL page */
import RELATED_CASE from '@salesforce/schema/Case.RelatedCase__c';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import LEGAL_ENTITY_NAME_FIELD from '@salesforce/schema/Case.Calc_Link_Account__c';
import RELATED_BILLING_ACCOUNT_FIELD from '@salesforce/schema/Case.Related_Billing_Account__c';
import NETWORK_FIELD from '@salesforce/schema/Case.Network__c';
import OWNER_NAME_FIELD from '@salesforce/schema/Case.Calc_Owner_Name__c';
import DESCRIPTION_OF_PACKAGING_FIELD from '@salesforce/schema/Case.Description_of_packaging__c';
import INITIAL_CONTACT_FIRST_NAME_FIELD from '@salesforce/schema/Case.Initial_Caller_First_Name__c';
import INITIAL_CONTACT_LAST_NAME_FIELD from '@salesforce/schema/Case.Initial_Caller_Last_Name__c';
import INITIAL_CONTACT_MOBILE_FIELD from '@salesforce/schema/Case.Initial_Contact_Mobile_Number__c';
import INITIAL_CONTACT_EMAIL_FIELD from '@salesforce/schema/Case.Initial_Caller_Email__c';



import CASEINVISTIGATION_ARTICLE_FIELD from "@salesforce/schema/CaseInvestigation__c.Article__c";
import CASEINVISTIGATION_NAME_FIELD from "@salesforce/schema/CaseInvestigation__c.Name";
import CASEINVISTIGATION_PRIORITY_FIELD from "@salesforce/schema/CaseInvestigation__c.Priority__c";
import CASEINVISTIGATION_STATUS_FIELD from "@salesforce/schema/CaseInvestigation__c.Status__c";
import CASEINVISTIGATION_SENT_TO_NETWORK_FIELD from "@salesforce/schema/CaseInvestigation__c.SentToNetworkDatetime__c";

import CASEINVISTIGATION_NETWORK_MILESSTONES_VIOLATED_FIELD from "@salesforce/schema/CaseInvestigation__c.NetworkMilestonesViolated__c";

import CASEINVISTIGATION_PRODUCT_CATEGORY_FIELD from "@salesforce/schema/CaseInvestigation__c.ProductCategory__c";
import CASEINVISTIGATION_PRODUCT_SUB_CATEGORY_FIELD from "@salesforce/schema/CaseInvestigation__c.ProductSubCategory__c";
import CASEINVISTIGATION_NETWORK_TIER_ESCALATION_EMAIL_FIELD from "@salesforce/schema/CaseInvestigation__c.NetworkTierEscalationEmail__c";
import CASEINVISTIGATION_NETWORK_FIELD from "@salesforce/schema/CaseInvestigation__c.Network__c";


import getCaseRecord from "@salesforce/apex/MyNetworkCaseListController.getCaseRecord";

import { loadStyle } from "lightning/platformResourceLoader";
import customStyle from "@salesforce/resourceUrl/MYNetworkCustomStyle";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CaseDetails extends LightningElement {
	@track selectedCaseRecordWrapper = [];
	@track caseInvestigations = []; //array to pass CI records to happy parcel component.
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

	//array of CASE fields to be used ONLY for StarTrack cases.
	//Section: Case Details 
	caseInvestigation_casefields = [
		CASENUMBER_FIELD,
		CASESTATUS_FIELD,
		SUBJECT_FIELD,
		ENQUIRY_TYPE,
		PURPOSE_FIELD,
		CONSIGNMENT_ID_FIELD,
		STARTRACK_RECEIVER_NAME_FIELD,
		STARTRACK_RECEIVER_ADDRESS_FIELD,
		CASE_ORIGINATOR,
		STARTRACK_SENDER_NAME_FIELD,
		STARTRACK_SENDER_ADDRESS_FIELD,
		CREATED_BY_FIELD,
		LASTMODIFIEDDATE_FIELD,
		LASTMODIFIEDBY_FIELD,
		STARTRACK_DESCRIPTION_OF_CONTENT_FIELD,
		VALUE_OF_GOODS_FIELD
	];

	//array of CASE INVESTIGATION fields to be used ONLY for StarTrack cases.
	//Section: Case Investigation Details 
	caseInvestigation_fields = [
		CASEINVISTIGATION_ARTICLE_FIELD, CASEINVISTIGATION_NETWORK_FIELD,
		CASEINVISTIGATION_NAME_FIELD,
		CASEINVISTIGATION_PRIORITY_FIELD, 
		CASEINVISTIGATION_STATUS_FIELD, 
		CASEINVISTIGATION_PRODUCT_CATEGORY_FIELD,
		CASEINVISTIGATION_PRODUCT_SUB_CATEGORY_FIELD, CASEINVISTIGATION_NETWORK_MILESSTONES_VIOLATED_FIELD, 
		CASEINVISTIGATION_SENT_TO_NETWORK_FIELD,CASEINVISTIGATION_NETWORK_TIER_ESCALATION_EMAIL_FIELD
	];

	//array of CASE fields to be used ONLY for StarTrack cases.
	//Section: More Details
	starTrack_more_details_casefields = [
		RELATED_CASE,
		ORIGIN_FIELD,
		LEGAL_ENTITY_NAME_FIELD,
		RELATED_BILLING_ACCOUNT_FIELD,
		NETWORK_FIELD,
		OWNER_NAME_FIELD,
		DESCRIPTION_OF_PACKAGING_FIELD,
		INITIAL_CONTACT_FIRST_NAME_FIELD,
		INITIAL_CONTACT_LAST_NAME_FIELD,
		INITIAL_CONTACT_MOBILE_FIELD,
		INITIAL_CONTACT_EMAIL_FIELD
	];

	@api recordId;
	@track objectApiName = "Case";
	@track caseActiveSections = ['A'];
	@track caseInvestigationActiveSections = ['A','C'];
	@track caseInvestigationObjectApiName = "CaseInvestigation__c";
	@track happyParcelArticleId;
	@track caseId;
	sObjectTypeName;

	/**
	 * @desc get case details based on recordId.
	 * record Id can be of Case record id or Case Investigation record ID. 	
	 */
	async getRequiredDetails(){
		try {
			const getCaseRecordResponse = await getCaseRecord({ recordId: this.recordId });
			if(getCaseRecordResponse){
				this.caseId = getCaseRecordResponse.caseRecord.Id;
				this.sObjectTypeName = getCaseRecordResponse.sObjectTypeName;
			}

			//const getSelectedCasesResponse = await getSelectedCases({ recordId: getCaseRecordResponse.caseRecord.Id });
			if(getCaseRecordResponse){
				this.populateCaseDetails(getCaseRecordResponse.caseRecord);
			}

		}
		catch(error) {
			console.log('error'+error);
		}
	}

	populateCaseDetails(caseDetails){

		this.recordFound = true;
		this.selectedCaseRecordWrapper = caseDetails;
		this.caseId = caseDetails.Id;

		let tempCaseInvestigations = [];
		if(caseDetails.hasOwnProperty('CaseInvestigations__r') && caseDetails.CaseInvestigations__r){
			let caseInvestigationsRecords = caseDetails.CaseInvestigations__r;
			
			if(caseInvestigationsRecords){
			let recordIdToFind = (this.sObjectTypeName === 'Case' ? caseDetails.Id : this.recordId);
			let caseInvestigation  = caseInvestigationsRecords.find(cInv => cInv.Id === recordIdToFind);
			this.happyParcelArticleId = caseInvestigation ? caseInvestigation.Article__r.Name : caseDetails.Calc_Case_Consignment__c;
			}
			
			
			caseInvestigationsRecords.forEach(function (cInvestigationRec) {
			let cInvestigationRecord = {};
			for(let c in cInvestigationRec) {
				if(c === 'Article__r' || c === 'Network__r')  {
				cInvestigationRecord[c] = cInvestigationRec[c].Name;
				}
				else if(c === 'Id') {
				cInvestigationRecord[c] = cInvestigationRec[c];
				}
				else {
				cInvestigationRecord[c] = cInvestigationRec[c];
				}
			}
			tempCaseInvestigations.push(cInvestigationRecord);
			});

		}
		this.caseInvestigations = tempCaseInvestigations;
	}

	connectedCallback() {
		Promise.all([
			loadStyle(this, customStyle + "/MYNetworkCustomStyle.css")
		]).catch(error => {
			// eslint-disable-next-line no-console
			console.log("error in loading the style>>", error);
		});
		console.log('this.recordId: '+this.recordId +' getCaseMessages({ caseRecordId: this.recordId}): ' + getCaseMessages({ caseRecordId: this.recordId}));
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
		//get case record when called from CI Detail Page
		this.getRequiredDetails();
	}

	get happyParcelId() {
		return (this.sObjectTypeName === 'CaseInvestigation__c' && this.happyParcelArticleId ? this.happyParcelArticleId : this.selectedCaseRecordWrapper.Calc_Case_Consignment__c);
	}
  
	/**
	 * @desc: Returns true if case has any investigations. 
	 *		Any case which have Case Investigations are considered as StarTrack cases.
	 */
	get isStarTrackCase() {
		if(this.selectedCaseRecordWrapper && this.selectedCaseRecordWrapper.StarTrack_RecordType__c) {
			return true;
		}
		return false;
	}

	/**
	 * @desc: Cases can be accessed by Global Search or from MyNetwork home page list view (LWC Component)
	 * Different views are rendered if case is navigated to from Global Search or from  MyNetwork home page list view.
	 */
	get isGlobalSearch() {
		if(this.selectedCaseRecordWrapper && this.selectedCaseRecordWrapper.StarTrack_RecordType__c && this.sObjectTypeName === 'Case') {
			return true;
		}
		return false;
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