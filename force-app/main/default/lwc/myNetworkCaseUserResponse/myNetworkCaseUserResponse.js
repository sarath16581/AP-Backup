/**
  * @author       : dattaraj.deshmukh@auspost.com.au
  * @date         : 29/11/2022
  * @description  : Component to add user responses on ST cases on myNetwork Community
--------------------------------------- History --------------------------------------------------
29.11.2022    dattaraj.deshmukh@auspost.com.au    Created
*/
import { LightningElement, track, wire, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import postCaseInvestigationChatterFeed from "@salesforce/apex/MyNetworkCaseUserResponseController.postCaseInvestigationChatterFeed";

import { updateRecord, getRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { NavigationMixin } from 'lightning/navigation';
import CASE_INVESTIGATION_OBJECT from '@salesforce/schema/CaseInvestigation__c';
import FEEDITEM from '@salesforce/schema/FeedItem';

import ADDRESS_TYPE_FIELD from '@salesforce/schema/CaseInvestigation__c.AddressType__c';
import COMMENTS_FIELD from '@salesforce/schema/CaseInvestigation__c.Comments__c';
import DELIVERY_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Deliveryinformation__c';
import DELIVERY_OFFICER_KNOWLEDGE_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOfficerKnowledge__c';
import DELIVERY_OPTIONS_FIELD from '@salesforce/schema/CaseInvestigation__c.DeliveryOptions__c';
import NETWORK_FIELD from '@salesforce/schema/CaseInvestigation__c.Network__c';
import QUALITY_OF_THE_CASE_FIELD from '@salesforce/schema/CaseInvestigation__c.Qualityofthecase__c';
import REQUIRE_MORE_INFORMATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Requiremoreinformation__c';
import STILL_UNDER_INVESTIGATION_FIELD from '@salesforce/schema/CaseInvestigation__c.Stillunderinvestigation__c';
import CASE_INVESTIGATION_RECORD_ID from '@salesforce/schema/CaseInvestigation__c.Id';

export default class MyNetworkCaseUserResponse extends LightningElement {

	@api recordId;
	@api caseInvestigationRecordId;
    @track error = false;
    @track errorMessage = null;
	caseInvestigationRecord;

    addressType = '';
    comments= '';
    deliveryInformation= '';
    deliveryOfficerKnowledge= '';
    deliveryOptions= '';
    networkId= '';
    qualityOfCase= false;
    requireMoreInformation ='';
    stillUnderInvestigation = false;


	handleCommentsChange(event) {
        this.comments = event.target.value;
        console.log("comments",this.comments);
    }
    handleNetworkChange(event) {
        this.networkId = event.target.value;
        console.log("networkId",this.networkId);
    }
    handleRequireMoreInfoChange(event) {
        this.requireMoreInformation = event.target.value;
        console.log("mon",this.monday);
    }
    handleStillUnderInvestigationChange(event) {
        this.stillUnderInvestigation = event.target.value;
    }
    handleQualityOfCaseChange(event) {
        this.qualityOfCase = event.target.value;
    }
    handleDeliveryInformationChange(event) {
        this.deliveryInformation = event.target.value;
    }
    handleDeliveryOfficerKnowledgeChange(event) {
        this.deliveryOfficerKnowledge = event.target.value;
    }
    handleAddressTypeChange(event) {
        this.addressType = event.target.value;
    }
	handleDeliveryOptionsChange(event) {
        this.deliveryOptions = event.target.value;
    }
	
	@wire(getRecord, { recordId: '$recordId', fields: [ADDRESS_TYPE_FIELD, COMMENTS_FIELD, DELIVERY_INFORMATION_FIELD, DELIVERY_OFFICER_KNOWLEDGE_FIELD, DELIVERY_OPTIONS_FIELD,
		NETWORK_FIELD,  QUALITY_OF_THE_CASE_FIELD, STILL_UNDER_INVESTIGATION_FIELD, REQUIRE_MORE_INFORMATION_FIELD] })
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
        } else if (data) {
            this.caseInvestigationRecord = data;
            this.comments = this.caseInvestigationRecord.fields.Comments__c.value;
            this.networkId = this.caseInvestigationRecord.fields.Network__c.value;
			this.addressType = this.caseInvestigationRecord.fields.AddressType__c.value;
			this.deliveryInformation = this.caseInvestigationRecord.fields.Deliveryinformation__c.value;
			this.deliveryOfficerKnowledge = this.caseInvestigationRecord.fields.DeliveryOfficerKnowledge__c.value;
			this.qualityOfCase = this.caseInvestigationRecord.fields.Qualityofthecase__c.value;
			this.requireMoreInformation = this.caseInvestigationRecord.fields.Requiremoreinformation__c.value;
			this.deliveryOptions = this.caseInvestigationRecord.fields.DeliveryOptions__c.value;
			this.stillUnderInvestigation = this.caseInvestigationRecord.fields.Stillunderinvestigation__c.value;
        }
    }

	updateCaseInvestigation(){

        const fields = {};
        fields[CASE_INVESTIGATION_RECORD_ID.fieldApiName] = this.recordId;
        fields[COMMENTS_FIELD.fieldApiName] = this.comments;
        fields[NETWORK_FIELD.fieldApiName] = this.networkId;

		fields[ADDRESS_TYPE_FIELD.fieldApiName] = this.addressType;
		fields[DELIVERY_INFORMATION_FIELD.fieldApiName] = this.deliveryInformation;
		fields[DELIVERY_OFFICER_KNOWLEDGE_FIELD.fieldApiName] = this.deliveryOfficerKnowledge;
		fields[QUALITY_OF_THE_CASE_FIELD.fieldApiName] = this.qualityOfCase;
		fields[STILL_UNDER_INVESTIGATION_FIELD.fieldApiName] = this.stillUnderInvestigation;
		fields[REQUIRE_MORE_INFORMATION_FIELD.fieldApiName] = this.requireMoreInformation;
		fields[DELIVERY_OPTIONS_FIELD.fieldApiName] = this.deliveryOptions;

        const recordInput = { fields };
        updateRecord(recordInput)
            .then(CaseInvestigation__c => {
            this.recordId = CaseInvestigation__c.id;
            console.log('Record Id', this.recordId);

            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Success',
            //         message: 'Network response updated successfully',
            //         variant: 'success'
            //     })
            // )
			
			//create a chatter feed for comments entered.
			this.createChatterFeed();
    })
    .catch(error => {
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
		postCaseInvestigationChatterFeed({ newtorkComments : this.comments, caseInvestigationId: this.recordId })
		.then((result) => {
			if (result) {
				new ShowToastEvent({
                    title: 'Success',
                    message: 'Network response updated successfully',
                    variant: 'success'
                })
			}
		})
		.catch((error) => {
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