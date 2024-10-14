import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';

import ID_FIELD from '@salesforce/schema/VoiceCall.Id';
import CONTACT_ID_FIELD from '@salesforce/schema/VoiceCall.Contact__c';
import CASE_ID_FIELD from '@salesforce/schema/VoiceCall.Case__c';
import CALL_TYPE_FIELD from '@salesforce/schema/VoiceCall.CallType';
import CALLER_PARTICIPANT_DISPLAY_NAME_FIELD from '@salesforce/schema/VoiceCall.Caller.ParticipantDisplayName';
import RECIPIENT_PARTICIPANT_DISPLAY_NAME_FIELD from '@salesforce/schema/VoiceCall.Recipient.ParticipantDisplayName';

/**
 * @typedef {object} PreFillData
 * @property {string} [phoneNumber]
 */

/**
 * This component wraps the Customer Search component specifically for the `VoiceCall` interaction record page.
 *
 * The wrapper retrieves data from the interaction record, and handles updates when linking/unlinking the Contact,
 * as well has controlling the availability of the Customer Search form based on the linked Contact and/or Case records.
 * 
 * @changelog:
 * 2024-10-03 - Removed 'auto-link' feature as handled via Apex Trigger (CSLU-1470)
 */
export default class UnifiedCustomerSearchVoiceCallWrapper extends LightningElement {
	/**
	 * The record Id from the `VoiceCall` record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * If enabled, the a search will be invoked when the search form is loaded.
	 * @type {boolean}
	 */
	autoSearchOnLoad = true;

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
	isUpdating = false;

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
		return getFieldValue(this.interactionRecord, CASE_ID_FIELD);
	}

	/**
	 * Context from the interaction record used to pre-fill the Customer Search form.
	 * @type {PreFillData}
	 */
	get preFillData() {
		const isOutboundCall = getFieldValue(this.interactionRecord, CALL_TYPE_FIELD)?.toLowerCase() === 'outbound';
		const callerPhoneNumber = getFieldValue(this.interactionRecord, CALLER_PARTICIPANT_DISPLAY_NAME_FIELD);
		const recipeintPhoneNumber = getFieldValue(this.interactionRecord, RECIPIENT_PARTICIPANT_DISPLAY_NAME_FIELD);
		return {
			// Outbound calls need to get the phoneNumber from a different field to inbound or transfer calls
			phoneNumber: (isOutboundCall ? recipeintPhoneNumber : callerPhoneNumber)?.replace(/[^0-9]/g, '')
		};
	}

	/**
	 * Show the Contact Card if a Contact has been linked.
	 */
	get showContactCard() {
		return !!this.linkedContactId;
	}

	/**
	 * Show the Customer Search Form if there is no linked Contact AND no linked Case (CSLU-491).
	 */
	get showSearchForm() {
		return !this.linkedContactId && !this.linkedCaseId;
	}

	/**
	 * Show the 'Unlink' button if a Contact has been linked AND a Case is not linked (CSLU-491).
	 */
	get showUnlinkButton() {
		return this.linkedContactId && !this.linkedCaseId;
	}

	/**
	 * Wire the interaction (Voice Call) record.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [CONTACT_ID_FIELD, CASE_ID_FIELD, CALLER_PARTICIPANT_DISPLAY_NAME_FIELD, CALL_TYPE_FIELD, RECIPIENT_PARTICIPANT_DISPLAY_NAME_FIELD] })
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
	 * Handle the `onconnected` event to pre-populate the form with initial values from the interaction.
	 * This action should only happen once, and not on every data refresh.
	 *
	 * @param {CustomEvent} event - The `onconnected` event from the Customer Search component.
	 */
	async handleCustomerSearchConnected(event) {
		try {
			event.target.setFormInputs(this.preFillData);
		} catch (error) {
			console.error(error);
			this.errorMessage = reduceErrors(error).join(', ');
		}
	}

	/**
	 * Links or unlinks the Contact Id to the interaction record.
	 * The `contactId` is passed in the event detail. This will be `null` in case of unlinking.
	 *
	 * Handles the following events:
	 *  - `linkcontact`
	 *  - `unlinkcontact`
	 *  - `customercreated`
	 *
	 * @param {CustomEvent<string|null>} event - The object for the `linkcontact` event.
	 */
	async handleLinkUnlinkContact(event) {
		try {
			// This event may have bubbled up from a child component
			event.stopPropagation();

			// Show loading spinner while updating the interation record
			this.isUpdating = true;

			// Note, if the contactId is null, it will be unlinked
			const contactId = event.detail?.contactId ?? null;

			// Update record and notify other components that the record was updated.
			await updateRecord({ fields: { [ID_FIELD.fieldApiName]: this.recordId, [CONTACT_ID_FIELD.fieldApiName]: contactId } });
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

			// Success toast message
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Contact ' + (contactId ? 'Linked' : 'Unlinked'),
					message: 'Contact has been ' + (contactId ? 'linked' : 'unlinked') + ' to this interaction.',
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
