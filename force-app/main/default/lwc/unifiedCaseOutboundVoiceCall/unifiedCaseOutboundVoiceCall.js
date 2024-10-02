/**
 * @description A LWC component for automatically linking a case when agents initiate an outbound call from Case
 * @author: SteveL
 * @changelog:
 * 2024-09-26 - SteveL - CSLU-1088 SCV - Outbound Call - Created
 */
import { LightningElement,api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { IsConsoleNavigation, getAllTabInfo } from 'lightning/platformWorkspaceApi';

// fields needed to identify Voice Call as Outbound
import VOICE_CALL_TYPE from '@salesforce/schema/VoiceCall.CallType';
import VOICE_CALL_STATUS from '@salesforce/schema/VoiceCall.CallDisposition';
import VOICE_CALL_RELATED_RECORD from '@salesforce/schema/VoiceCall.RelatedRecordId';

const VOICE_CALL_FIELDS = [VOICE_CALL_TYPE,VOICE_CALL_STATUS,VOICE_CALL_RELATED_RECORD];

// field values that can be used to identify a Voice Call as outbound
const VOICE_CALL_IN_PROGRESS_STATUS = 'in-progress';
const VOICE_CALL_OUTBOUND_TYPE = 'Outbound';

export default class UnifiedCaseOutboundVoiceCall extends LightningElement {
	@api recordId;
	voiceCallFields = VOICE_CALL_FIELDS;
	voiceCallDetails = {};

	@wire(IsConsoleNavigation) isConsoleNavigation;

	@wire(getRecord, {recordId: '$recordId', fields: '$voiceCallFields'})
	wiredVoiceCallRecord({error,data}) {
		if (data) {
			VOICE_CALL_FIELDS.forEach((field)=>{
				this.voiceCallDetails[field.fieldApiName] = getFieldValue(data, field);
			});
			if (this.voiceCallDetails.CallType === VOICE_CALL_OUTBOUND_TYPE && this.voiceCallDetails.CallDisposition === VOICE_CALL_IN_PROGRESS_STATUS) {
				this.findCaseTab();
			}
		} else if (error) {
			console.error('Error retrieving voice call record:', error);
		}
	}

	/**
	 * use the functions from platformWorkspaceApi to identify if the user is on console page, and if so go through all the open tabs, and find the first one opened with Case
	 */
	findCaseTab() {
		if (!this.isConsoleNavigation) {
			return;
		}
		try {
			getAllTabInfo().then((tabsInfo) => {
				let caseTab = tabsInfo.find((tab) => {
					return tab?.recordId?.startsWith('500');
				});
				if (caseTab && caseTab.recordId != this.voiceCallDetails.RelatedRecordId) { // only update the RecordRecordId when it is empty or have a different value
					this.updateVoiceRecord(caseTab.recordId);
				}
			});
		} catch (error) {
			console.error(error);
		}
	}

	/**
	 * use the updateRecord function from uiRecordApi to update the Voice Call's RelatedRecordId with the caseId parameter, then use notifyRecordUpdateAvailable to notify other components within the same Flexipage
	 */
	updateVoiceRecord(caseId) {
		const fields = {};
		fields.Id = this.recordId;
		fields.RelatedRecordId = caseId;
		const voiceRecord = { fields };

		updateRecord(voiceRecord)
		.then((result)=>{
			notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
		})
		.catch(error => {
			console.error('Error updating voice record:', error);
		});
	}
}