import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import VOICE_CALL_RELATED_RECORD_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import VOICE_CALL_CASE_FIELD from '@salesforce/schema/VoiceCall.Case__c';

export default class UnifiedVoiceCallOpenCase extends NavigationMixin(LightningElement) {
    @api recordId; // Voice Call record Id
    relatedCaseId;

    // Wire adapter to fetch the VoiceCall record
    @wire(getRecord, {recordId: '$recordId', fields: [VOICE_CALL_RELATED_RECORD_FIELD]})
    wiredVoiceCallRecord({error,data}) {
        if (data) {
            this.relatedCaseId = getFieldValue(data, VOICE_CALL_RELATED_RECORD_FIELD) ?? getFieldValue(data, VOICE_CALL_CASE_FIELD);
        } else if (error) {
            console.error('Error retrieving voice call record:', error);
        }
    }

    handleNavigateToCase(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.relatedCaseId,
                actionName: 'view'
            }
        });
    }
}