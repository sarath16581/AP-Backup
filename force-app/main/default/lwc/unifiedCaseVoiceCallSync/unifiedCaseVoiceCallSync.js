import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import RELATED_RECORD_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import CASE_PRODUCT_CATEGORY_FIELD from '@salesforce/schema/Case.ProductCategory__c';
import CASE_PRODUCT_SUBCATEGORY_FIELD from '@salesforce/schema/Case.ProductSubCategory__c';
import CASE_ENQUIRY_SUBTYPE_FIELD from '@salesforce/schema/Case.EnquirySubType__c';
import CASE_ENQUIRY_TYPE_FIELD from '@salesforce/schema/Case.CHASEnquiryType__c';

export default class UnifiedCaseVoiceCallSync extends LightningElement {
	@api recordId; // Voice Call record Id
	@track relatedCaseId;
	@track caseProductCategory;
	@track caseProductSubCategory;
	@track caseEnquirySubType;
	@track caseEnquiryType;

	// Wire adapter to fetch the VoiceCall record
	@wire(getRecord, { recordId: '$recordId', fields: [RELATED_RECORD_FIELD] })
	wiredVoiceCallRecord(result) {
		if (result.data) {
			this.relatedCaseId = result.data.fields.RelatedRecordId.value;
		} else if (result.error) {
			console.error('Error retrieving voice call record:', result.error);
		}
	}

	// Wire adapter to fetch the Case record
	@wire(getRecord, { recordId: '$relatedCaseId', fields: [CASE_PRODUCT_CATEGORY_FIELD, CASE_PRODUCT_SUBCATEGORY_FIELD, CASE_ENQUIRY_SUBTYPE_FIELD, CASE_ENQUIRY_TYPE_FIELD] })
	caseRecord({ error, data }) {
		if (data) {
			this.caseProductCategory = data.fields.ProductCategory__c.value;
			this.caseProductSubCategory = data.fields.ProductSubCategory__c.value;
			this.caseEnquirySubType = data.fields.EnquirySubType__c.value;
			this.caseEnquiryType = data.fields.CHASEnquiryType__c.value;

			console.log('Case fields:', {
				ProductCategory__c: this.caseProductCategory,
				ProductSubCategory__c: this.caseProductSubCategory,
				EnquirySubType__c: this.caseEnquirySubType,
				CHASEnquiryType__c: this.caseEnquiryType
			});

			if (this.recordId) {
				this.updateVoiceRecord();
			}
		} else if (error) {
			console.error('Error retrieving case record:', error);
		}
	}

	//Update voicecall record
	updateVoiceRecord() {
		// Construct the voice record for updateRecord
		const fields = {};
		fields.Id = this.recordId;
		fields.ProductCategory__c = this.caseProductCategory;
		fields.ProductSubCategory__c = this.caseProductSubCategory;
		fields.EnquirySubType__c = this.caseEnquirySubType;
		fields.EnquiryType__c = this.caseEnquiryType;

		const voiceRecord = { fields };

		updateRecord(voiceRecord)
			.then(() => {})
			.catch(error => {
				console.error('Error updating voice record:', error);
			});
	}
}