import { LightningElement, api, wire } from 'lwc';
import { subscribe,unsubscribe,onError } from 'lightning/empApi';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';

import RELATED_RECORD_FIELD from '@salesforce/schema/VoiceCall.Case__c';
import PREVIOUS_CALL_ID_FIELD from '@salesforce/schema/VoiceCall.PreviousCallId';
import DIVISION_FIELD from '@salesforce/schema/VoiceCall.Division__c';
import NEXT_CALL_ID_FIELD from '@salesforce/schema/VoiceCall.NextCallId';
import CALL_STATUS_FIELD from '@salesforce/schema/VoiceCall.CallDisposition';
import CONSIGNMENT_FIELD from '@salesforce/schema/VoiceCall.Consignment__c';
import TRACKING_NUMBER_FIELD from '@salesforce/schema/VoiceCall.TrackingNumber__c';
import RELATED_RECORD_ID_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import PRODUCT_CATEGORY_FIELD from '@salesforce/schema/VoiceCall.ProductCategory__c';
import PRODUCT_SUB_CATEGORY_FIELD from '@salesforce/schema/VoiceCall.ProductSubCategory__c';
import CONTACT_FIELD from '@salesforce/schema/VoiceCall.Contact__c';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/VoiceCall.EnquiryType__c';
import ENQUIRY_SUB_TYPE_FIELD from '@salesforce/schema/VoiceCall.EnquirySubType__c';
import ROOT_CAUSE_FIELD from '@salesforce/schema/VoiceCall.RootCause__c';
import OUTCOME_FIELD from '@salesforce/schema/VoiceCall.Outcome__c';
const VOICE_CALL_FIELDS = [RELATED_RECORD_FIELD,PREVIOUS_CALL_ID_FIELD,DIVISION_FIELD,NEXT_CALL_ID_FIELD,CALL_STATUS_FIELD,CONSIGNMENT_FIELD,TRACKING_NUMBER_FIELD,RELATED_RECORD_ID_FIELD,PRODUCT_CATEGORY_FIELD,PRODUCT_SUB_CATEGORY_FIELD,CONTACT_FIELD,ENQUIRY_TYPE_FIELD,ENQUIRY_SUB_TYPE_FIELD,ROOT_CAUSE_FIELD,OUTCOME_FIELD];

import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import TYPE_FIELD from '@salesforce/schema/Case.Type';
import CASE_PRODUCT_CATEGORY_FIELD from '@salesforce/schema/Case.ProductCategory__c';
const CASE_FIELDS = [CASE_NUMBER_FIELD, SUBJECT_FIELD, STATUS_FIELD, TYPE_FIELD, CASE_PRODUCT_CATEGORY_FIELD];

const IN_PROGRESS_VOICE_STATUS = 'in-progress';

export default class UnifiedVoiceCallFieldSync extends LightningElement {
    @api recordId; // Voice Call record Id
    relatedCaseId;
    voiceCallDetails = {};
    caseDetails = {};
    channelName = '/data/VoiceCallChangeEvent';
    subscription = {}; // holds subscription, used for unsubscribe

    voiceCallFields = VOICE_CALL_FIELDS;

    @wire(getRecord, { recordId: '$recordId', fields: '$voiceCallFields' })
    voiceCallRecord({ error, data }) {
        if (data) {
            this.relatedCaseId = getFieldValue(data, RELATED_RECORD_FIELD);
            VOICE_CALL_FIELDS.forEach((field)=>{
                this.voiceCallDetails[field.fieldApiName] = getFieldValue(data, field);
            });
        } else if (error) {
            console.error('Error retrieving voice call record:', reduceErrors(error).join(','));
        }
    }

    @wire(getRecord, { recordId: '$relatedCaseId', fields: CASE_FIELDS })
    caseRecord({ error, data }) {
		if (data) {
            CASE_FIELDS.forEach((field)=>{
				const newFieldValue = getFieldValue(data, field);
				this.caseDetails[field.fieldApiName] = newFieldValue;
            });
        } else if (error) {
            console.error('Error retrieving case details:', reduceErrors(error).join(','));
        }
    }

    connectedCallback() {
        this.registerErrorListener();
        this.registerSubscribe();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
    }

    registerErrorListener() {
        onError(error => {
            console.error('Salesforce error', reduceErrors(error).join(','));
        });
    }

    registerSubscribe() {
        const changeEventCallback = changeEvent => {
            this.processChangeEvent(changeEvent);
        };

        subscribe(this.channelName, -1, changeEventCallback).then(subscription => { // parameters for subscribe (channel, replayId, onMessageCallback) Specify -1 to get new events from the tip of the stream
            this.subscription = subscription;
        });
    }

    processChangeEvent(changeEvent) {
        try {
			const recordIds = changeEvent.data.payload.ChangeEventHeader.recordIds; // this is the Id of the subsequent record, i.e the one that initiated the change
			const changeType = changeEvent.data.payload.ChangeEventHeader.changeType; // this is the Id of the subsequent record, i.e the one that initiated the change
			if (recordIds.includes(this.recordId) && changeType === 'UPDATE') {
				const changePayload = changeEvent.data.payload;				
				const monitorFields = VOICE_CALL_FIELDS.map(field => field.fieldApiName);
				let hasMatchingField = changePayload.ChangeEventHeader.changedFields.some((field) => {
                    if (monitorFields.includes(field)) {
                        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                    }
                });
			}
        } catch (err) {
            console.error(err);
        }
    }
}