/**
 * @description A LiveChat Wrapper for case creation.
 *             The wrapper manages the LMS event, UI validation and display and pre-populate data to the embedded case creation LWC component.
 * @author: Marcel HK
 * @changelog:
 * 2024-09-10 - Marcel HK - Created
 * 2024-09-11 - Seth Heang - Updated to handle LMS event, liveChat fields wiring, UI validation display and pass down necessary data to case creation LWC
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/ldsUtils';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';
import getExistingCasesCount from '@salesforce/apex/UnifiedCaseHistoryController.getCountForDuplicatedCasesRelatedToArticle';

import ID_FIELD from '@salesforce/schema/LiveChatTranscript.Id';
import CONTACT_ID_FIELD from '@salesforce/schema/LiveChatTranscript.ContactId';
import CASE_ID_FIELD from '@salesforce/schema/LiveChatTranscript.CaseId';
import CONSIGNMENT_ID_FIELD from '@salesforce/schema/LiveChatTranscript.Consignment__c';
import LIVECHAT_INTENT_FIELD from '@salesforce/schema/LiveChatTranscript.Chat_Intent__c';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/LiveChatTranscript.EnquiryType__c';
import ENQUIRY_SUBTYPE_FIELD from '@salesforce/schema/LiveChatTranscript.EnquirySubType__c';
import PRODUCT_CATEGORY_FIELD from '@salesforce/schema/LiveChatTranscript.ProductCategory__c';
import PRODUCT_SUBCATEGORY_FIELD from '@salesforce/schema/LiveChatTranscript.ProductSubCategory__c';

const LIVECHAT_FIELDS = [
	CONTACT_ID_FIELD,
	CASE_ID_FIELD,
	CONSIGNMENT_ID_FIELD,
	LIVECHAT_INTENT_FIELD,
	ENQUIRY_TYPE_FIELD,
	ENQUIRY_SUBTYPE_FIELD,
	PRODUCT_CATEGORY_FIELD,
	PRODUCT_SUBCATEGORY_FIELD
];

/**
 * This component wraps the `UnifiedCaseCreation` component specifically for the `LiveChatTranscript` interaction record page.
 *
 * The wrapper retrieves data from the interaction record, and handles updates when linking/unlinking the Contact,
 * as well has controlling the visibility of the Case creation form based on the linked Case records or existing cases validation.
 */
export default class UnifiedCaseCreationLiveChatWrapper extends LightningElement {
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
	 * Retrieved from liveChat object and pass over to the Case Creation LWC
	 * @type {string}
	 */
	enquiryType;

	/**
	 * Retrieved from liveChat object and pass over to the Case Creation LWC
	 * @type {string}
	 */
	enquirySubType;

	/**
	 * Retrieved from liveChat object and pass over to the Case Creation LWC
	 * @type {string}
	 */
	productCategory;

	/**
	 * Retrieved from liveChat object and pass over to the Case Creation LWC
	 * @type {string}
	 */
	productSubCategory;

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
	 * The Contact Id related to the interaction record.
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
	@wire(getRecord, { recordId: "$recordId", fields: LIVECHAT_FIELDS })
	wiredInteractionRecord({ error, data }) {
		if (data) {
			this.interactionRecord = data;
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
		this.handleExistingCaseValidation();
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
					(message) => this.handleLMSEvent(message),
					{ scope: APPLICATION_SCOPE }
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
		// filter for `articlesSelected`
		if(message.source === 'HappyParcel' && message.type === 'articleSelected'){
			this.impactedArticles = message.body.selectedArticleIds;
			const consignmentTrackingId = message.body.consignmentId;
			this.handleExistingCaseValidation(consignmentTrackingId);
		}
	}

	/**
	 * Call apex controller to retrieve existing cases associated to this liveChat record that met specified criteria
	 * and update warningMessage if applicable
	 */
	async handleExistingCaseValidation(consignmentTrackingId){
		const existingCaseCount = await getExistingCasesCount(consignmentTrackingId);
		if(existingCaseCount){
			this.warningMessage = existingCaseCount + ' Existing Cases';
		}
	}

	/**
	 * Links or unlinks the Case Id to the interaction record.
	 * The `caseId` is passed in the event detail. This will be `null` in case of unlinking.
	 *
	 * Handles the following events:
	 *  - `linkcase`
	 *  - `unlinkcase`
	 *  - `casecreated`
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
			await updateRecord({ fields: { [ID_FIELD.fieldApiName]: this.recordId, [CASE_ID_FIELD.fieldApiName]: caseId } });
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
