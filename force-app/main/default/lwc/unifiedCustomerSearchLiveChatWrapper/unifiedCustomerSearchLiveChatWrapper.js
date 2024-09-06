import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPreChatContext from '@salesforce/apex/UnifiedCustomerSearchChatWrapCtrl.getPreChatContext';
import { reduceErrors } from 'c/ldsUtils';

import ID_FIELD from '@salesforce/schema/LiveChatTranscript.Id';
import CONTACT_ID_FIELD from '@salesforce/schema/LiveChatTranscript.ContactId';
import CASE_ID_FIELD from '@salesforce/schema/LiveChatTranscript.CaseId';

/**
 * @typedef {object} PreFillData
 * @property {string} [firstName]
 * @property {string} [lastName]
 * @property {string} [emailAddress]
 * @property {string} [phoneNumber]
 */

/**
 * This component wraps the Customer Search component specifically for the `LiveChatTranscript` interaction record page.
 *
 * The wrapper retrieves data from the interaction record, and handles updates when linking/unlinking the Contact,
 * as well has controlling the availability of the Customer Search form based on the linked Contact and/or Case records.
 */
export default class UnifiedCustomerSearchLiveChatWrapper extends LightningElement {
	/**
	 * The record Id from the `LiveChatTranscript` record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * If enabled, the a search will be invoked when the search form is loaded.
	 * @type {boolean}
	 */
	autoSearchOnLoad = true;

	/**
	 * If enabled, the a search will automatically link the Contact if only one is found.
	 * @type {boolean}
	 */
	autoLinkContact = true;

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
		return !this.interactionRecord || !this.preFillData;
	}

	/**
	 * Used to track updating the interaction record, and display a spinner.
	 * @type {boolean}
	 */
	isUpdating;

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
	preFillData;

	/**
	 * Show the Contact Card if a Contact has been linked.
	 */
	get showContactCard() {
		return this.linkedContactId;
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
	 * Wire the interaction (Live Chat Transcript) record.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [CONTACT_ID_FIELD, CASE_ID_FIELD] })
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
	 * Wire the Pre-Chat Context details related to the interaction.
	 */
	@wire(getPreChatContext, { liveChatTranscriptId: '$recordId' })
	wiredPreChatContext({ data, error }) {
		if (data) {
			this.preFillData = data;
		} else if (error) {
			console.error(error);
			this.preFillData = undefined;
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

			// Disable auto-linking after first link/unlink event
			// TODO: handle this better based on component initial load/search rather than link
			this.autoLinkContact = false;

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
