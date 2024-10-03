/**
 * @description : This component is to provide a button to be put in the Case Tab on the Live Chat Flexipage.
 *  It opens up a new console tab and navigate to the related case of the Live Chat record.
 * @changelog:
 * 2024-10-03 - Seth Heang - created
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import LIVE_CHAT_CASE_FIELD from '@salesforce/schema/LiveChatTranscript.CaseId';

export default class UnifiedLiveChatOpenCase extends NavigationMixin(LightningElement) {
	/**
	 * live chat record id
	 */
	@api recordId;
	/**
	 * store related case Id associated with live chat record field data
	 */
	relatedCaseId;

	/**
	 * Wire adapter to fetch the Live Chat record
	 */
	@wire(getRecord, {recordId: '$recordId', fields: [LIVE_CHAT_CASE_FIELD]})
	wiredLiveChatRecord({error,data}) {
		if (data) {
			this.relatedCaseId = getFieldValue(data, LIVE_CHAT_CASE_FIELD);
		} else if (error) {
			console.error('Error retrieving live chat call record:', error);
		}
	}

	/**
	 * @description navigate to the related case Id associated to the live chat record
	 * @param event
	 */
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