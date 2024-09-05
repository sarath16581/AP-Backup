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
const VOICE_CALL_FIELDS = [RELATED_RECORD_FIELD, PREVIOUS_CALL_ID_FIELD, DIVISION_FIELD, NEXT_CALL_ID_FIELD, CALL_STATUS_FIELD, CONSIGNMENT_FIELD, TRACKING_NUMBER_FIELD, RELATED_RECORD_ID_FIELD];

import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import TYPE_FIELD from '@salesforce/schema/Case.Type';
const CASE_FIELDS = [CASE_NUMBER_FIELD, SUBJECT_FIELD, STATUS_FIELD, TYPE_FIELD];

const IN_PROGRESS_VOICE_STATUS = 'in-progress';

export default class UnifiedVoiceCallFieldSync extends LightningElement {
    @api recordId; // Voice Call record Id
    relatedCaseId;
    voiceCallDetails = {};
    caseDetails = {};
    channelName = '/data/VoiceCallChangeEvent';
    subscription = {}; // holds subscription, used for unsubscribe

    voiceCallFields = VOICE_CALL_FIELDS;

    @wire(getRecord, { recordId: '$recordId', fields: '$voiceCallFields'})
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

    @wire(getRecord, { recordId: '$relatedCaseId', fields: CASE_FIELDS})
    caseRecord({ error, data }) {
        if (data) {
            CASE_FIELDS.forEach((field)=>{
                this.caseDetails[field.fieldApiName] = getFieldValue(data, field);
            });
            console.log('Case data changes:', this.caseDetails);
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
            const changePayload = changeEvent.data.payload;
            const fieldApiNames = [];
            VOICE_CALL_FIELDS.forEach((field)=>{
                fieldApiNames.push(field.fieldApiName);
            });

            if (recordIds.includes(this.recordId)) {
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            }
        } catch (err) {
            console.error(reduceErrors(error).join(','));
        }
    }
}