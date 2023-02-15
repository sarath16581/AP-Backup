/**
 * @description Component to add user responses on ST cases on myNetwork Community.
 * 				This component updates case investigation records, post a chatter feed on the same record.
 * @author Dattaraj Deshmukh
 * @date 2022-11-29
 * @changelog
 * 2022-11-29 - Dattaraj Deshmukh - Created
 * 2023-02-13 - Dattaraj Deshmukh - updated QualityOfTheCase fields default value.
 */
import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import postCaseInvestigationChatterFeed from "@salesforce/apex/MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed";
import updateCase from "@salesforce/apex/MyNetworkCaseUserResponseController.updateCase";

import { updateRecord, getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';

import ADDRESS_TYPE_FIELD from '@salesforce/schema/CaseInvestigation__c.AddressType__c';
import COMMENTS_FIELD from '@salesforce/schema/CaseInvestigation__c.Comments__c';
import DELIVERY_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Deliveryinformation__c';
import DELIVERY_OFFICER_KNOWLEDGE_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOfficerKnowledge__c';
import DELIVERY_OPTIONS_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOptions__c';
import NETWORK_FIELD from '@salesforce/schema/CaseInvestigation__c.Network__c';
import QUALITY_OF_THE_CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Qualityofthecase__c';
import REQUIRE_MORE_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Requiremoreinformation__c';
import STILL_UNDER_INVESTIGATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Stillunderinvestigation__c';
import CASE_TYPE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__r.Enquiry_Type__c';
import PURPOSE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__r.Call_Purpose__c';
import STATUS_FIELD from '@salesforce/schema/CaseInvestigation__c.Status__c';
import INTERNAL_FACILITY_NOTES_FIELD from '@salesforce/schema/CaseInvestigation__c.InternalFacilityNotes__c';
import CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__c';


import CASE_INVESTIGATION_RECORD_ID from '@salesforce/schema/CaseInvestigation__c.Id';

const CASE_TYPE = 'Delivery Dispute';
const CASE_PURPOSE = 'Delivered';


export default class MyNetworkCaseUserResponse extends LightningElement {

	@api recordId;
	@api caseInvestigationRecordId;
	@track error = false;
	@track errorMessage = null;
	caseInvestigationRecord;
	@track isComponentVisible = false;
	@track isLoaded = false;
	
	isCaseUpdatedRequired = false;
	addressType = '';
	comments= '';
	deliveryInformation= '';
	deliveryOfficerKnowledge= '';
	deliveryOptions= '';
	networkId= '';
	qualityOfCase= '';
	requireMoreInformation ='';
	stillUnderInvestigation = false;
	internalFacilityNotes = '';
	status='';
	errorMsg = '';

	handleCommentsChange(event) {
		this.comments = event.target.value;
		console.log("comments",this.comments);
		this.isCaseUpdatedRequired = true;
	}
	handleNetworkChange(event) {
		this.networkId = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleRequireMoreInfoChange(event) {

		this.errorMsg ='';
		this.requireMoreInformation = event.target.value;

		//Require More Information and Still Under Investigation cannot be true at same time.
		if(event.target.value && this.stillUnderInvestigation) {
			this.errorMsg = 'Still under investigation and Require more information can not be selected at the same time';
		} 
		else if(event.target.value && !this.stillUnderInvestigation) {
			this.status = 'Closed - Required More Information' ;
		}
		else if(!event.target.value && !this.stillUnderInvestigation) {
			this.status = 'Closed' ;
		}
		this.isCaseUpdatedRequired = true;
	}
	handleStillUnderInvestigationChange(event) {
		
		this.errorMsg ='';
		this.stillUnderInvestigation = event.target.value;

		//Require More Information and Still Under Investigation cannot be true at same time.
		if(event.target.value && this.requireMoreInformation) {
			this.errorMsg = 'Still under investigation and Require more information can not be selected at the same time';
		} 
		else if(event.target.value && !this.requireMoreInformation) {
			this.status = 'Responded' ;
		}
		else if(!event.target.value && !this.requireMoreInformation) {
			this.status = 'Closed' ;
		}
		this.isCaseUpdatedRequired = true;
	}
	handleQualityOfCaseChange(event) {
		this.qualityOfCase = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleDeliveryInformationChange(event) {
		this.deliveryInformation = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleDeliveryOfficerKnowledgeChange(event) {
		this.deliveryOfficerKnowledge = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleAddressTypeChange(event) {
		this.addressType = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleDeliveryOptionsChange(event) {
		this.deliveryOptions = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleInternalFacilityNotesChange(event) {
		this.internalFacilityNotes = event.target.value;
	}
	
	
	

	@wire(getRecord, { recordId: '$recordId', fields: [ADDRESS_TYPE_FIELD, COMMENTS_FIELD, DELIVERY_INFORMATION_FIELD, DELIVERY_OFFICER_KNOWLEDGE_FIELD, DELIVERY_OPTIONS_FIELD,
		NETWORK_FIELD,  QUALITY_OF_THE_CASE_FIELD, STILL_UNDER_INVESTIGATION_FIELD, REQUIRE_MORE_INFORMATION_FIELD, CASE_TYPE_FIELD, PURPOSE_FIELD, STATUS_FIELD,
		INTERNAL_FACILITY_NOTES_FIELD, CASE_FIELD] })
	wiredRecord({ error, data }) {
		if (error) {
			let message = 'Unknown error';
			if (Array.isArray(error.body)) {
				message = error.body.map(e => e.message).join(', ');
			} else if (typeof error.body.message === 'string') {
				message = error.body.message;
			}
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error loading contact',
					message,
					variant: 'error',
				}),
			);
			this.isLoaded = true;

		} else if (data) {
			this.caseInvestigationRecord = data;
			// this.comments = this.caseInvestigationRecord.fields.Comments__c.value;
			this.networkId = this.caseInvestigationRecord.fields.Network__c.value;
			this.addressType = this.caseInvestigationRecord.fields.AddressType__c.value;
			this.deliveryInformation = this.caseInvestigationRecord.fields.Deliveryinformation__c.value;
			this.deliveryOfficerKnowledge = this.caseInvestigationRecord.fields.DeliveryOfficerKnowledge__c.value;
			this.qualityOfCase = this.caseInvestigationRecord.fields.Qualityofthecase__c.value;
			this.requireMoreInformation = this.caseInvestigationRecord.fields.Requiremoreinformation__c.value;
			this.deliveryOptions = this.caseInvestigationRecord.fields.DeliveryOptions__c.value;
			this.stillUnderInvestigation = this.caseInvestigationRecord.fields.Stillunderinvestigation__c.value;
			this.internalFacilityNotes = this.caseInvestigationRecord.fields.InternalFacilityNotes__c.value;
			this.isLoaded = true;

		}
	}

	updateCaseInvestigation(){

		const fields = {};
		fields[CASE_INVESTIGATION_RECORD_ID.fieldApiName] = this.recordId;
		// fields[COMMENTS_FIELD.fieldApiName] = this.comments;
		fields[NETWORK_FIELD.fieldApiName] = this.networkId;

		fields[ADDRESS_TYPE_FIELD.fieldApiName] = this.addressType;
		fields[DELIVERY_INFORMATION_FIELD.fieldApiName] = this.deliveryInformation;
		fields[DELIVERY_OFFICER_KNOWLEDGE_FIELD.fieldApiName] = this.deliveryOfficerKnowledge;
		fields[QUALITY_OF_THE_CASE_FIELD.fieldApiName] = this.qualityOfCase;
		fields[STILL_UNDER_INVESTIGATION_FIELD.fieldApiName] = this.stillUnderInvestigation;
		fields[REQUIRE_MORE_INFORMATION_FIELD.fieldApiName] = this.requireMoreInformation;
		fields[DELIVERY_OPTIONS_FIELD.fieldApiName] = this.deliveryOptions;
		fields[STATUS_FIELD.fieldApiName] = this.status;
		fields[INTERNAL_FACILITY_NOTES_FIELD.fieldApiName] = this.internalFacilityNotes;
		
		
		const recordInput = { fields };
		updateRecord(recordInput)
			.then(CaseInvestigation__c => {
			// this.recordId = CaseInvestigation__c.id;


			//create a chatter feed for comments entered.
			if(this.comments){
				this.createChatterFeed();
			}
			this.updateCaseRecord();
		})
		.catch(error => {
			
			this.isLoaded = true;
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error creating record',
					message: reduceErrors(error).join(', '),
					variant: 'error'
				})
			);
		});
		

	}

	createChatterFeed(){
		let caseRecId = getFieldValue(this.caseInvestigationRecord, CASE_FIELD);
		postCaseInvestigationChatterFeed({ newtorkComments : this.comments, caseInvestigationId: this.recordId, caseId : caseRecId })
		.then((result) => {
			if (result) {

				//reset text area values
				const inputFields = this.template.querySelectorAll(
					'lightning-textarea'
				);
				if(inputFields) {
					inputFields.forEach(field => {
						field.value = '';
					});
				}
				this.isLoaded = true;

				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Network response has been saved.',
						variant: 'success'
					})
				)
			}
		})
		.catch((error) => {
			this.isLoaded = true;
			this.error = error;
			console.log("error>", this.error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error in creating chatter feed',
					message: reduceErrors(error).join(', '),
					variant: 'error'
				})
			);
		});
	}

	get isDelieryFieldVisible(){
		return ( (getFieldValue(this.caseInvestigationRecord, CASE_TYPE_FIELD) === CASE_TYPE ) 
					&& (getFieldValue(this.caseInvestigationRecord, PURPOSE_FIELD) === CASE_PURPOSE) ? true : false
					);
	}

	updateCaseRecord(){
		let caseRecId = getFieldValue(this.caseInvestigationRecord, CASE_FIELD);
		updateCase({ caseId : caseRecId})
		.then((result) => {
			this.isLoaded = true;
		})
		.catch((error) => {
			this.isLoaded = true;
			this.error = error;
			console.log("error>", this.error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error in creating chatter feed',
					message: reduceErrors(error).join(', '),
					variant: 'error'
				})
			);
		});
	}
	
}