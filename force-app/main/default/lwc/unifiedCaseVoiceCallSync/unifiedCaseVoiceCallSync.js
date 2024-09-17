import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import VOICE_CALL_RELATED_RECORD_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import VOICE_CALL_CREATED_DATE_FIELD from '@salesforce/schema/VoiceCall.CreatedDate';
import CASE_PRODUCT_CATEGORY_FIELD from '@salesforce/schema/Case.ProductCategory__c';
import CASE_CREATED_DATE_FIELD from '@salesforce/schema/Case.CreatedDate';
import CASE_PRODUCT_SUBCATEGORY_FIELD from '@salesforce/schema/Case.ProductSubCategory__c';
import CASE_ENQUIRY_SUBTYPE_FIELD from '@salesforce/schema/Case.EnquirySubType__c';
import CASE_TYPE_FIELD from '@salesforce/schema/Case.Type';

const VOICE_CALL_FIELDS = [VOICE_CALL_RELATED_RECORD_FIELD,VOICE_CALL_CREATED_DATE_FIELD];
const CASE_FIELDS = [CASE_PRODUCT_CATEGORY_FIELD, CASE_CREATED_DATE_FIELD, CASE_PRODUCT_SUBCATEGORY_FIELD, CASE_ENQUIRY_SUBTYPE_FIELD, CASE_TYPE_FIELD];

const DEFAULT_VOICE_CALL_ROOT_CAUSE = 'Unclear EDD';
const CASE_TYPE_GENERAL_ENQUIRY = 'General Enquiry';
const CASE_TYPE_INVESTIGATION = 'Investigation';
const FCR = 'FCR';
const ENQUIRY_LODGED = 'Enquiry lodged';
const ENQUIRY_UPDATED = 'Enquiry updated';

export default class UnifiedCaseVoiceCallSync extends LightningElement {
	@api recordId; // Voice Call record Id
	relatedCaseId;
	caseField = CASE_FIELDS;
	voiceCallFields = VOICE_CALL_FIELDS;
	voiceCallDetails = {};
	caseDetails= {};
	originalCaseType;

	// Wire adapter to fetch the VoiceCall record
	@wire(getRecord, {recordId: '$recordId', fields: '$voiceCallFields'})
	wiredVoiceCallRecord({error,data}) {
		if (data) {
            this.relatedCaseId = getFieldValue(data, VOICE_CALL_RELATED_RECORD_FIELD);
			VOICE_CALL_FIELDS.forEach((field)=>{
                this.voiceCallDetails[field.fieldApiName] = getFieldValue(data, field);
            });
		} else if (error) {
            console.error('Error retrieving voice call record:', error);
		}
	}

	// Wire adapter to fetch the Case record
	@wire(getRecord, {recordId: '$relatedCaseId', fields: '$caseField'})
	caseRecord({ error, data }) {
		if (data) {
			this.originalCaseType ||= getFieldValue(data, CASE_TYPE_FIELD);
			CASE_FIELDS.forEach((field)=>{
                this.caseDetails[field.fieldApiName] = getFieldValue(data, field);
            });

			if (this.recordId) {
				this.updateVoiceRecord();
			}
		} else if (error) {
			console.error('Error retrieving case record:', error);
		}
	}

    determineVoiceCallOutcome() {
        let caseOlderThanVoice = this.caseDetails.CreatedDate < this.voiceCallDetails.CreatedDate;
        if (this.caseDetails.Type === CASE_TYPE_GENERAL_ENQUIRY && !caseOlderThanVoice) { // the case is created with Type = General Enquiry during the interaction
            return FCR;
        } else if ((this.caseDetails.Type === CASE_TYPE_INVESTIGATION && !caseOlderThanVoice) ||
                    (this.caseDetails.Type === CASE_TYPE_GENERAL_ENQUIRY && caseOlderThanVoice && this.originalCaseType === CASE_TYPE_GENERAL_ENQUIRY)) { // the case is created with Type = Investigation is before the call OR the case was of Type GE, but has been updated to Investigate during the call
            return ENQUIRY_LODGED;
        } else if ((this.caseDetails.Type === CASE_TYPE_INVESTIGATION && caseOlderThanVoice && this.originalCaseType === CASE_TYPE_INVESTIGATION) ||
                    (this.caseDetails.Type === CASE_TYPE_GENERAL_ENQUIRY && caseOlderThanVoice)) { // the case has always been of Type Investigation before and during the call
            return ENQUIRY_UPDATED;
        }
        return null;
    }

	//Update voicecall record
	updateVoiceRecord() {
        console.log('this.caseDetails');
        console.log(this.caseDetails);
        const fields = {};
        fields.Id = this.recordId;
        fields.ProductCategory__c = this.caseDetails.ProductCategory__c;
        fields.ProductSubCategory__c = this.caseDetails.ProductSubCategory__c;
        fields.EnquirySubType__c = this.caseDetails.EnquirySubType__c;
        fields.EnquiryType__c = this.caseDetails.Type;
        fields.RootCause__c = DEFAULT_VOICE_CALL_ROOT_CAUSE;
        fields.Outcome__c = this.determineVoiceCallOutcome();
        const voiceRecord = { fields };

		updateRecord(voiceRecord).catch(error => {
            console.error('Error updating voice record:', error);
        });
	}
}