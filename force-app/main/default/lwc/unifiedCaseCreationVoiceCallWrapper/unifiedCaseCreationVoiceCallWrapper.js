/**
 * @description A VoiceCall Wrapper for case creation.
 *			The wrapper manages the LMS event, UI validation and display and pre-populate data to the embedded case creation LWC component.
 * @author: Seth Heang
 * @changelog:
 * 2024-09-12 - Seth Heang - Created
 * 2024-09-25 - Marcel HK - Updated Case linking to use `ReleatedRecordId` instead of `Case__c`
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';
import getExistingCasesCount from '@salesforce/apex/UnifiedCaseHistoryController.getCountForDuplicatedCasesRelatedToArticle';

import ID_FIELD from '@salesforce/schema/VoiceCall.Id';
import CONTACT_ID_FIELD from '@salesforce/schema/VoiceCall.Contact__c';
import RELATED_RECORD_ID_FIELD from '@salesforce/schema/VoiceCall.RelatedRecordId';
import CONSIGNMENT_ID_FIELD from '@salesforce/schema/VoiceCall.Consignment__c';
import CONSIGNMENT_TRACKING_NUMBER_FIELD from '@salesforce/schema/VoiceCall.Consignment__r.ConsignmentTrackingNumber__c';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/VoiceCall.EnquiryType__c';
import ENQUIRY_SUBTYPE_FIELD from '@salesforce/schema/VoiceCall.EnquirySubType__c';
import PRODUCT_CATEGORY_FIELD from '@salesforce/schema/VoiceCall.ProductCategory__c';
import PRODUCT_SUBCATEGORY_FIELD from '@salesforce/schema/VoiceCall.ProductSubCategory__c';

const VOICECALL_FIELDS = [
	CONTACT_ID_FIELD,
	RELATED_RECORD_ID_FIELD,
	CONSIGNMENT_ID_FIELD,
	ENQUIRY_TYPE_FIELD,
	ENQUIRY_SUBTYPE_FIELD,
	PRODUCT_CATEGORY_FIELD,
	PRODUCT_SUBCATEGORY_FIELD,
	CONSIGNMENT_TRACKING_NUMBER_FIELD
];

/**
 * This component wraps the `UnifiedCaseCreation` component specifically for the `VoiceCall` interaction record page.
 *
 * The wrapper retrieves data from the interaction record, and handles updates when linking/unlinking the Contact,
 * as well has controlling the visibility of the Case creation form based on the linked Case records or existing cases validation.
 */
export default class UnifiedCaseCreationVoiceCallWrapper extends LightningElement {
	/**
	 * The record Id from the `LiveChatTranscript` record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * Used to display an error message to the user.
	 * @type {string}
	 */
	errorMessage;

	/**
	 * Used to display an warning message to the user.
	 * @type {string}
	 */
	warningMessage;

	/**
	 * The interaction object returned from the `@wire` adapter.
	 * @type {object}
	 */
	interactionRecord;

	/**
	 * The subscription object for listening to LMS message
	 */
	subscription;

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
	 * List of Impacted articles received from Unified Tracking LMS event and pass over to the Case Creation LWC
	 * @type {string[]}
	 */
	impactedArticles;

	/**
	 * The Contact Id related to the interaction record.
	 * @type {string}
	 */
	get linkedContactId() {
		return getFieldValue(this.interactionRecord, CONTACT_ID_FIELD);
	}

	/**
	 * The Consignment Id related to the interaction record.
	 * @type {string}
	 */
	get linkedConsignmentId() {
		return getFieldValue(this.interactionRecord, CONSIGNMENT_ID_FIELD);
	}

	/**
	 * The enquiry type related to the interaction record.
	 * @type {string}
	 */
	get linkedEnquiryType() {
		return getFieldValue(this.interactionRecord, ENQUIRY_TYPE_FIELD);
	}

	/**
	 * The enquiry sub type related to the interaction record.
	 * @type {string}
	 */
	get linkedEnquirySubType() {
		return getFieldValue(this.interactionRecord, ENQUIRY_SUBTYPE_FIELD);
	}

	/**
	 * The product category related to the interaction record.
	 * @type {string}
	 */
	get linkedProductCategory() {
		return getFieldValue(this.interactionRecord, PRODUCT_CATEGORY_FIELD);
	}

	/**
	 * The product sub category related to the interaction record.
	 * @type {string}
	 */
	get linkedProductSubCategory() {
		return getFieldValue(this.interactionRecord, PRODUCT_SUBCATEGORY_FIELD);
	}

	/**
	 * Wire the interaction (Live Chat Transcript) record.
	 */
	@wire(getRecord, { recordId: "$recordId", fields: VOICECALL_FIELDS })
	wiredInteractionRecord({ error, data }) {
		if (data) {
			this.interactionRecord = data;
			this.handleExistingCaseValidation(this.linkedConsignmentId);
		} else if (error) {
			console.error(error);
			this.interactionRecord = undefined;
			this.errorMessage = reduceErrors(error).join(", ");
		}
	}

	/**
	 * Wire MessageContext for subscribing to LMS event
	 */
	@wire(MessageContext)
	messageContext;

	connectedCallback() {
		// subscribe to LMS
		this.subscribeToMessageChannel();
	}

	disconnectedCallback() {
		// unsubscribe to LMS
		this.unsubscribeToMessageChannel();
	}

	/**
	 * Subscribe to LMS event and set scope to Application Level
	 */
	subscribeToMessageChannel() {
		if (!this.subscription) {
			this.subscription = subscribe(
					this.messageContext,
					GENERIC_LMS_CHANNEL,
					(message) => this.handleLMSEvent(message)
			);
		}
	}

	/**
	 * Unsubscribe from LMS event
	 */
	unsubscribeToMessageChannel() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}

	/**
	 * Receive LMS event from Unified Tracking and get the list of impacted articles for display and pass over to case creation form
	 * @param message
	 */
	handleLMSEvent(message) {
		// filter for source = `unifiedTrackingVoiceWrapper` and type = `articlesSelected`
		if(message.source === 'unifiedTrackingVoiceWrapper' && message.type === 'articleSelected'){
			this.impactedArticles = message.body.selectedArticleIds;
		}
	}

	/**
	 * Call apex controller to retrieve existing cases associated to this liveChat record that met specified criteria
	 * and update warningMessage if applicable
	 */
	async handleExistingCaseValidation(trackingNumber){
		try {
			const existingCaseCount = await getExistingCasesCount({
				trackingId: trackingNumber
			});
			if(existingCaseCount){
				this.warningMessage = existingCaseCount + ' Existing Cases';
			}
		} catch (error) {
			console.error(error);
			this.errorMessage = reduceErrors(error).join(", ");
		}
	}

	/**
	 * Links or unlinks the Case Id to the interaction record.
	 * The `caseId` is passed in the event detail. This will be `null` in case of unlinking.
	 *
	 * Handles the following events:
	 * - `casecreated`
	 *
	 * @param {CustomEvent<{caseId:string|null}>} event
	 */
	async handleLinkUnlinkCase(event) {
		try {
			// This event may have bubbled up from a child component
			event.stopPropagation();

			// Show loading spinner while updating the interaction record
			this.isUpdating = true;

			// Note, if the contactId is null, it will be unlinked
			const caseId = event.detail?.caseId ?? null;

			// Update record and notify other components that the record was updated.
			await updateRecord({ fields: { [ID_FIELD.fieldApiName]: this.recordId, [RELATED_RECORD_ID_FIELD.fieldApiName]: caseId } });
			await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

			// Success toast message
			this.dispatchEvent(
					new ShowToastEvent({
						title: "Case " + (caseId ? "Linked" : "Unlinked"),
						message: "Case has been " + (caseId ? "linked" : "unlinked") + " to this interaction.",
						variant: "success"
					})
			);
		} catch (error) {
			console.error(error);
			this.dispatchEvent(
					new ShowToastEvent({
						title: "Error",
						message: reduceErrors(error).join(", "),
						mode: "sticky",
						variant: "error"
					})
			);
		} finally {
			this.isUpdating = false;
		}
	}
}