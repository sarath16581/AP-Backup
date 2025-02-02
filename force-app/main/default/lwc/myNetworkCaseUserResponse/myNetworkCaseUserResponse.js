/**
 * @description Component to add user responses on ST cases on myNetwork Community.
 * 				This component updates case investigation records, post a chatter feed on the same record.
 * @author Dattaraj Deshmukh
 * @date 2022-11-29
 * @changelog
 * 2022-11-29 - Dattaraj Deshmukh - Created
 * 2023-02-13 - Dattaraj Deshmukh - updated QualityOfTheCase fields default value.
 * 2023-02-16 - Dattaraj Deshmukh - Added updateCase method. Updated internal facility notes field placeholder.
 * 2023-03-01 - Mahesh Parvathaneni - SF-830 Updated logic if the related case is closed
 * 2023-03-06 - Dattaraj Deshmukh - Fixed bug SF-864. Made network response field required.
 * 2023-03-14 - Dattaraj Deshmukh - SF(SF-886) Set DeliveryOption__c(controlling) field values. 
 * 									SF(SF-895) Fixed status update issue where SUI/Require More Info statuses were updated to Closed.
 * 2023-03-16 - Mahesh Parvathaneni - SF-876 Set case status based on SUI
 * 2023-03-20 - Mahesh Parvathaneni - SF-854 - Updated status 'Closed - Required More information' to 'More information required'.
 * 2023-03-20 - Dattaraj Deshmukh - SF-900 Navigated to 'Home' page after Network Response is added.
 * 2023-03-23 - Dattaraj Deshmukh - SF-892 Made Network response mandatory when SUI/RequireMoreInfo checkbox is changed and response is NOT added.
 * 2023-03-24 - Mahesh Parvathaneni - SF-921 Restrict the network response to save when SUI and Require More Information is checked. 
 * 2023-05-25 - jacob.isaac@auspost.com.au - REQ3111278: Changing Quality Of Case Label to Flag Case for Review, changing picklist and labels
 */
import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import postCaseInvestigationChatterFeed from "@salesforce/apex/MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed";
import updateCase from "@salesforce/apex/MyNetworkCaseUserResponseController.updateCase";

import { updateRecord, getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';

import ADDRESS_TYPE_FIELD from '@salesforce/schema/CaseInvestigation__c.AddressType__c';
import DELIVERY_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryInformation__c';
import DELIVERY_OFFICER_KNOWLEDGE_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOfficerKnowledge__c';
import DELIVERY_OPTIONS_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOptions__c';
import NETWORK_FIELD from '@salesforce/schema/CaseInvestigation__c.Network__c';
import QUALITY_OF_THE_CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Qualityofthecase__c';
import REQUIRE_MORE_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.RequireMoreInformation__c';
import STILL_UNDER_INVESTIGATION_FIELD from '@salesforce/schema/CaseInvestigation__c.StillUnderInvestigation__c';
import CASE_TYPE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__r.Enquiry_Type__c';
import PURPOSE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__r.Call_Purpose__c';
import STATUS_FIELD from '@salesforce/schema/CaseInvestigation__c.Status__c';
import INTERNAL_FACILITY_NOTES_FIELD from '@salesforce/schema/CaseInvestigation__c.InternalFacilityNotes__c';
import CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Case__c';
import IS_CASE_CLOSED from '@salesforce/schema/CaseInvestigation__c.Case__r.IsClosed';

import LABEL_MANIFESTADDRESS from '@salesforce/label/c.GPS_SDI_match_manifest_address';
import LABEL_INCORRECTFACILITY from '@salesforce/label/c.Incorrect_facility';
import LABEL_INVALIDDATA from '@salesforce/label/c.Invalid_Incorrect_Missing_data';
import LABEL_MANIFESTONLY from '@salesforce/label/c.Manifest_only';
import LABEL_AGENTRESPONSE from '@salesforce/label/c.The_agent_was_equipped_to_provide_a_response'
import LABEL_OTHER from '@salesforce/label/c.Other';
import LABEL_REQOUTSIDESERVICE from '@salesforce/label/c.Request_outside_service_offering';
import LABEL_UNABLETOFULFILREQ from '@salesforce/label/c.Unable_to_fulfil_request';
import LABEL_WITHINEDD from '@salesforce/label/c.Within_EDD';
import LABEL_TWOWEEKPASTDELIVERY from '@salesforce/label/c.X2_weeks_past_delivered_date';

import CASE_INVESTIGATION_RECORD_ID from '@salesforce/schema/CaseInvestigation__c.Id';

const CASE_TYPE = 'Delivery Dispute';
const CASE_PURPOSE = 'Delivered';
const STATUS_CLOSED = 'Closed';
const STATUS_RESPONDED = 'Responded';
const STATUS_IN_PROGRESS = 'In Progress';
const STATUS_MORE_INFO_REQUIRED = 'More information required';
const NETWORK_RESPONSE_REQUIRED = 'Please enter the network response.';
const CASE_UPDATE_OPERATIONS_RESPONDED = 'Operations Responded';
const CASE_STATUS_AWAITING_REVIEW = 'Awaiting Review';

export default class MyNetworkCaseUserResponse extends NavigationMixin(LightningElement) {

	@api recordId;
	@api caseInvestigationRecordId;
	@track error = false;
	@track errorMessage = null;
	caseInvestigationRecord;
	@track isComponentVisible = false;
	@track isLoaded = false;
	flagCaseReviewLabel = '';
	isCaseUpdatedRequired = false;
	addressType = '';
	comments= '';
	deliveryInformation= '';
	deliveryOfficerKnowledge= '';
	deliveryOptions= '';
	networkId= '';
	originalNetworkId = '';
	qualityOfCase= '';
	requireMoreInformation ='';
	stillUnderInvestigation = false;
	internalFacilityNotes = '';
	status='';
	errorMsg = '';
	isCaseClosed = false; //flag to show/hide the component if the case related to case investigation is closed.
	originalInternalFacilityNotes = '';
	originalStillUnderInvestigationValue = false;
	originalRequireMoreInfoValue = false;

	handleCommentsChange(event) {
		this.comments = event.target.value;
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
		if(this.requireMoreInformation && this.stillUnderInvestigation) {
			this.errorMsg = 'Still under investigation and Require more information can not be selected at the same time';
		} 
		else if(this.requireMoreInformation && !this.stillUnderInvestigation) {
			this.status = STATUS_MORE_INFO_REQUIRED ;
		}
		else if(this.comments !== '' &&  !this.requireMoreInformation && !this.stillUnderInvestigation) {
			this.status = STATUS_CLOSED ;
		}
		else if(!this.requireMoreInformation && this.stillUnderInvestigation) {
			this.status = STATUS_RESPONDED ;
		}
		this.isCaseUpdatedRequired = true;
	}
	handleStillUnderInvestigationChange(event) {
		
		this.errorMsg ='';
		this.stillUnderInvestigation = event.target.value;

		//Require More Information and Still Under Investigation cannot be true at same time.
		if(this.stillUnderInvestigation && this.requireMoreInformation) {
			this.errorMsg = 'Still under investigation and Require more information can not be selected at the same time';
		} 
		else if(this.stillUnderInvestigation && !this.requireMoreInformation) {
			this.status = STATUS_RESPONDED ;
		}
		else if(this.comments !== '' && !this.stillUnderInvestigation && !this.requireMoreInformation) {
			this.status = STATUS_CLOSED ;
		}
		else if(!this.stillUnderInvestigation && this.requireMoreInformation) {
			this.status = STATUS_MORE_INFO_REQUIRED ;
		}
		this.isCaseUpdatedRequired = true;
	}
	handleQualityOfCaseChange(event) {
		this.qualityOfCase = event.target.value;
		this.isCaseUpdatedRequired = true;

		switch(this.qualityOfCase){
			case 'GPS_SDI_match_manifest_address':
				this.flagCaseReviewLabel=LABEL_MANIFESTADDRESS;
				break;
			case 'Incorrect_facility':
				this.flagCaseReviewLabel=LABEL_INCORRECTFACILITY;
				break;
			case 'Invalid_Incorrect_Missing_data':
				this.flagCaseReviewLabel=LABEL_INVALIDDATA;
				break;
			case 'Manifest_only':
				this.flagCaseReviewLabel=LABEL_MANIFESTONLY;
				break;
			case 'The_agent_was_equipped_to_provide_a_response':
				this.flagCaseReviewLabel=LABEL_AGENTRESPONSE;
				break;
			case 'Other':
				this.flagCaseReviewLabel=LABEL_OTHER;
				break;
			case 'Request_outside_service_offering':
				this.flagCaseReviewLabel=LABEL_REQOUTSIDESERVICE;
				break;
			case 'Unable_to_fulfil_request':
				this.flagCaseReviewLabel=LABEL_UNABLETOFULFILREQ;
				break;
			case 'Within_EDD':
				this.flagCaseReviewLabel=LABEL_WITHINEDD;
				break;
			case 'X2_weeks_past_delivered_date':
				this.flagCaseReviewLabel=LABEL_TWOWEEKPASTDELIVERY;
				break;
			default:
				this.flagCaseReviewLabel='';

		}
	}
	handleDeliveryInformationChange(event) {
		this.deliveryInformation = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleDeliveryOfficerKnowledgeChange(event) {
		this.deliveryOfficerKnowledge = event.target.value;
		this.isCaseUpdatedRequired = true;
		//setting value of controlling field.
		//Business wants to use logic of setting controlling field value based on combination of addresstype__c and deliveryofficerknowledge__c.
		this.deliveryOptions = (this.addressType && this.deliveryOfficerKnowledge) ? (this.addressType + this.deliveryOfficerKnowledge) : '';

	}
	handleAddressTypeChange(event) {
		this.addressType = event.target.value;
		this.isCaseUpdatedRequired = true;
		//setting value of controlling field.
		//Business wants to use logic of setting controlling field value based on combination of addresstype__c and deliveryofficerknowledge__c.
		this.deliveryOptions = (this.addressType && this.deliveryOfficerKnowledge) ? (this.addressType + this.deliveryOfficerKnowledge) : '';

	}
	handleDeliveryOptionsChange(event) {
		this.deliveryOptions = event.target.value;
		this.isCaseUpdatedRequired = true;
	}
	handleInternalFacilityNotesChange(event) {
		this.internalFacilityNotes = event.target.value;
	}
	
	
	

	@wire(getRecord, { recordId: '$recordId', fields: [ADDRESS_TYPE_FIELD, DELIVERY_INFORMATION_FIELD, DELIVERY_OFFICER_KNOWLEDGE_FIELD, DELIVERY_OPTIONS_FIELD,
		NETWORK_FIELD,  QUALITY_OF_THE_CASE_FIELD, STILL_UNDER_INVESTIGATION_FIELD, REQUIRE_MORE_INFORMATION_FIELD, CASE_TYPE_FIELD, PURPOSE_FIELD, STATUS_FIELD,
		INTERNAL_FACILITY_NOTES_FIELD, CASE_FIELD, IS_CASE_CLOSED] })
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
			this.originalNetworkId = this.networkId = this.caseInvestigationRecord.fields.Network__c.value; // setting this value so we can detect if the user changes it. 
			this.addressType = this.caseInvestigationRecord.fields.AddressType__c.value;
			this.deliveryInformation = this.caseInvestigationRecord.fields.DeliveryInformation__c.value;
			this.deliveryOfficerKnowledge = this.caseInvestigationRecord.fields.DeliveryOfficerKnowledge__c.value;
			this.qualityOfCase = this.caseInvestigationRecord.fields.Qualityofthecase__c.value;
			this.originalRequireMoreInfoValue = this.requireMoreInformation = this.caseInvestigationRecord.fields.RequireMoreInformation__c.value;
			this.deliveryOptions = this.caseInvestigationRecord.fields.DeliveryOptions__c.value;
			this.originalStillUnderInvestigationValue = this.stillUnderInvestigation = this.caseInvestigationRecord.fields.StillUnderInvestigation__c.value;
			this.originalInternalFacilityNotes = this.internalFacilityNotes = this.caseInvestigationRecord.fields.InternalFacilityNotes__c.value;
			this.status = this.caseInvestigationRecord.fields.Status__c.value;

			if (getFieldValue(this.caseInvestigationRecord, IS_CASE_CLOSED) === true) {
				this.isCaseClosed = true;
				//show toast message if case is closed
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Case',
						message: 'This case is now closed. No further action is required.',
						variant: 'success',
						mode: 'sticky'
					})
				)
			}
			this.isLoaded = true;
		}
	}

	updateCaseInvestigation(){
		let validInput = true;

		const fields = {};
		fields[CASE_INVESTIGATION_RECORD_ID.fieldApiName] = this.recordId;
		fields[NETWORK_FIELD.fieldApiName] = this.networkId;
		fields[ADDRESS_TYPE_FIELD.fieldApiName] = this.addressType;
		fields[DELIVERY_INFORMATION_FIELD.fieldApiName] = this.deliveryInformation;
		fields[DELIVERY_OFFICER_KNOWLEDGE_FIELD.fieldApiName] = this.deliveryOfficerKnowledge;
		fields[QUALITY_OF_THE_CASE_FIELD.fieldApiName] = this.qualityOfCase;
		fields[DELIVERY_OPTIONS_FIELD.fieldApiName] = this.deliveryOptions;

		// If they have changed it then it is a case of Reassigning to another network. 
		if(this.originalNetworkId !== this.networkId) { 
			fields[STILL_UNDER_INVESTIGATION_FIELD.fieldApiName] = false;
			fields[REQUIRE_MORE_INFORMATION_FIELD.fieldApiName] = false;
			fields[STATUS_FIELD.fieldApiName] = STATUS_IN_PROGRESS;
		} else {
			fields[STILL_UNDER_INVESTIGATION_FIELD.fieldApiName] = this.stillUnderInvestigation;
			fields[REQUIRE_MORE_INFORMATION_FIELD.fieldApiName] = this.requireMoreInformation;
			fields[STATUS_FIELD.fieldApiName] = (this.comments  !== '' && !this.stillUnderInvestigation && !this.requireMoreInformation) ? STATUS_CLOSED : this.status;
		}

		fields[INTERNAL_FACILITY_NOTES_FIELD.fieldApiName] = this.internalFacilityNotes;
		
		
		const recordInput = { fields };
		const networkResponseField = this.template.querySelector('[data-id="networkRes"]');

		
		/** Show Network Response error message if 
		 * 		1. Network Response is empty. AND
		 * 		2. Either Still Under Investigation OR Require More Information checkbox is CHANGED.
		 * 	
		 */
		if((this.comments === undefined || this.comments === '' ) && (this.originalStillUnderInvestigationValue !== this.stillUnderInvestigation || this.originalRequireMoreInfoValue !== this.requireMoreInformation) ) {
			
			validInput = false;
			//show message if required field is missing
			networkResponseField.setCustomValidity(NETWORK_RESPONSE_REQUIRED);
			networkResponseField.reportValidity();
		}
		else {
			networkResponseField.setCustomValidity('');
			networkResponseField.reportValidity();
		}

		//restrict the network response to save if SUI and Require more information is checked
		if(this.stillUnderInvestigation  && this.requireMoreInformation){
			validInput = false;
		}

		if(validInput) {
			updateRecord(recordInput)
				.then(result => {
				
				//create a chatter feed for comments entered.
				
				if(this.comments){
					this.createChatterFeed();
				}
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Network response has been saved.',
						variant: 'success'
					})
				)
				this.navigateToHome(); //navigate to home page
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
		

	}

	createChatterFeed(){
		//this.isLoaded = false;
		let caseRecId = getFieldValue(this.caseInvestigationRecord, CASE_FIELD);
		postCaseInvestigationChatterFeed({ newtorkComments : this.comments, caseInvestigationId: this.recordId, caseId : caseRecId })
		.then((result) => {
			if (result) {
				this.isLoaded = true;
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

	//function to update the case record
	updateCaseRecord(){
		let caseRecId = getFieldValue(this.caseInvestigationRecord, CASE_FIELD);
		let caseToUpdate = {
			"Id": caseRecId,
			"Case_Update__c": CASE_UPDATE_OPERATIONS_RESPONDED,
			"sobjectType": "Case"
		};

		//if SUI is not ticked, set the case status
		if (!this.stillUnderInvestigation) {
			caseToUpdate = {...caseToUpdate, "Status" : CASE_STATUS_AWAITING_REVIEW};
		}

		//call apex method
		updateCase({ caseToUpdate : caseToUpdate})
		.then(() => {
			this.isLoaded = true;
		})
		.catch((error) => {
			this.isLoaded = true;
			this.error = error;
			console.error("error>", this.error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error in creating chatter feed',
					message: reduceErrors(error).join(', '),
					variant: 'error'
				})
			);
		});
	}

	//handler on Acknowledge button click
	handleAcknowledgeBtnClick() {
		this.isLoaded = false;
		const fields = {};
		fields[CASE_INVESTIGATION_RECORD_ID.fieldApiName] = this.recordId;
		fields[STATUS_FIELD.fieldApiName] = STATUS_CLOSED;

		const recordInput = { fields };
		updateRecord(recordInput)
			.then(() => {
			if(this.comments){
				this.createChatterFeed();
			} 	
			this.isLoaded = true;
			this.navigateToHome();
		})
		.catch(error => {
			this.isLoaded = true;
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error closing the case investigation record',
					message: reduceErrors(error).join(', '),
					variant: 'error'
				})
			);
			console.error('handleAcknowledgeBtnClick call failed: ' + reduceErrors(error).join(', '));
		});
	}

	//Navigate to home page
	navigateToHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}
}