import { LightningElement,api, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { IsConsoleNavigation, getAllTabInfo } from 'lightning/platformWorkspaceApi';

import VOICE_CALL_TYPE from '@salesforce/schema/VoiceCall.CallType';
import VOICE_CALL_STATUS from '@salesforce/schema/VoiceCall.CallDisposition';

const VOICE_CALL_FIELDS = [VOICE_CALL_TYPE,VOICE_CALL_STATUS];

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

	findCaseTab() {
		if (!this.isConsoleNavigation) {
			return;
		}
		try {
			getAllTabInfo().then((tabsInfo) => {
				let caseTab = tabsInfo.find((tab) => {
					return tab?.recordId?.startsWith('500');
				});
				if (caseTab) {
					this.updateVoiceRecord(caseTab.recordId);
				}
			});
		} catch (error) {
			console.error(error);
		}
	}

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