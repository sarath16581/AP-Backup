import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';

import ID_FIELD from '@salesforce/schema/VoiceCall.Id';
import CONTACT_ID_FIELD from '@salesforce/schema/VoiceCall.Contact__c';
import RELATED_RECORD_ID_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import CONSIGNMENT_ID_FIELD from '@salesforce/schema/VoiceCall.Consignment__c';

/**
 * This component wraps the `unifiedCaseHistory` component specifically for the `VoiceCall` interaction record page.
 *
 * @changelog:
 * 2024-09-12 - Marcel HK - Created
 * 2024-09-25 - Marcel HK - Updated Case linking to use `ReleatedRecordId` instead of `Case__c`
 */
export default class UnifiedCaseHistoryVoiceCallWrapper extends LightningElement {
	/**
	 * The record Id from the `VoiceCall` record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * Used to display an error message to the user.
	 * @type {string}
	 */
	errorMessage;

	/**
	 * The interaction object returned from the `@wire` adapter.
	 * @type {object}
	 */
	interactionRecord;

	/**
	 * Used to track the initial load of this component, and display a spinner.
	 * @type {boolean}
	 */
	get isLoading() {
		return !this.interactionRecord;
	}

	/**
	 * Used to track updating the interaction record, and display a spinner.
	 * @type {boolean}
	 */
	isUpdating;

	/**
	 * The Consignment Id (lookup to the `Article__c` object) related to the interaction record.
	 * @type {string}
	 */
	get linkedConsignmentId() {
		return getFieldValue(this.interactionRecord, CONSIGNMENT_ID_FIELD);
	}

	/**
	 * The Contact Id related to the interaction record.
	 * @type {string}
	 */
	get linkedContactId() {
		return getFieldValue(this.interactionRecord, CONTACT_ID_FIELD);
	}

	/**
	 * The Case Id related to the interaction record.
	 * @type {string}
	 */
	get linkedCaseId() {
		return getFieldValue(this.interactionRecord, RELATED_RECORD_ID_FIELD);
	}

	/**
	 * Wire the interaction (VoiceCall) record.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [CONSIGNMENT_ID_FIELD, CONTACT_ID_FIELD, RELATED_RECORD_ID_FIELD] })
	wiredInterationRecord({ error, data }) {
		if (data) {
			this.interactionRecord = data;
		} else if (error) {
			console.error(error);
			this.interactionRecord = undefined;
			this.errorMessage = reduceErrors(error).join(', ');
		}
	}

	/**
	 *
	 * @param {CustomEvent<{caseId:string|null}>} event - The object for the `linkcase` event.
	 */
	async handleLinkUnlinkCase(event) {
		try {
			// This event may have bubbled up from a child component
			event.stopPropagation();

			// Show loading spinner while updating the interation record
			this.isUpdating = true;

			// Note, if the caseId is null, it will be unlinked
			const caseId = event.detail?.caseId ?? null;

			// Update record and notify other components that the record was updated.
			await updateRecord({ fields: { [ID_FIELD.fieldApiName]: this.recordId, [RELATED_RECORD_ID_FIELD.fieldApiName]: caseId } });
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

			// Success toast message
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Case ' + (caseId ? 'Linked' : 'Unlinked'),
					message: 'Case has been ' + (caseId ? 'linked' : 'unlinked') + ' to this interaction.',
					variant: 'success'
				})
			);
		} catch (error) {
			console.error(error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error',
					message: reduceErrors(error).join(', '),
					mode: 'sticky',
					variant: 'error'
				})
			);
		} finally {
			this.isUpdating = false;
		}
	}
}
