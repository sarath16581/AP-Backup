/**
 * @description Wraps Happy Parcel component to show it on the LiveChatTranscript record
 * @author Raghav Ravipati
 * @date 2026-09-05
 * @group Tracking
 * @changelog
 * 2024-10-01 - Seth Heang - added notifyRecordUpdateAvailable after successful update on LiveChat
 */
import { api, LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { publish, MessageContext } from 'lightning/messageService';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';
//Fields
import TRACKING_ID_FIELD from '@salesforce/schema/LiveChatTranscript.Tracking_Number__c';
import ARTICLE_ID_FIELD from '@salesforce/schema/LiveChatTranscript.Consignment__c';
import ID_FIELD from '@salesforce/schema/LiveChatTranscript.Id';
import CASE_FIELD from '@salesforce/schema/LiveChatTranscript.CaseId';

const CHAT_FIELDS = [ARTICLE_ID_FIELD, TRACKING_ID_FIELD, CASE_FIELD, ID_FIELD];
const IMPACTED_ARTICLE_FIELDS = ['ImpactedArticle__c.Id', 'ImpactedArticle__c.Article__c', 'ImpactedArticle__c.Name'];
const IMPACTED_ARTICLE_RELATION_ID = 'ImpactedArticles__r';

export default class UnifiedTrackingChatWrapper extends LightningElement {
	@api recordId;
	// Array to hold list of article Ids of impacted article records that are attached to a case.
	@track impactedArticleIds = [];
	// Boolean to make search field read only and writable on happyparcel component
	readOnly = false;
	// Boolean to hide and show Spinner
	showSpinner = false;
	// Boolean to hide and show checkboxes on the happy parcel component.
	enableSelectArticles = false;
	// Boolean to identify if there is no consignment for the given record
	noConsignment = false;
	// Holds tracking Id provided on the record
	trackingId;
	// Holds the consignment record Id the we got from the tracking query results.
	articleRecordId;
	// Tracking Id that is available on the interation record.
	trackingIdFromRecord;
	// Consignment records that ois available on the interation record.
	consignmentIdFromRecord;
	// Holds case record Id available on the chat record.
	caseId;
	// Holds tracking Id that has duplicates
	duplicateTrackingId;
	// wire the message context and pass to publisher to send LMS events
	@wire(MessageContext)
	messageContext;

	/**
	 * Uses getRecord to get the chat records field values and passes variables to happy parcel component.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: CHAT_FIELDS })
	chatRecord({ error, data }) {
		if (error) {
			this.showSpinner = false;
			console.error(error);
		} else {
			this.mapValuesToVariablesFromGetRecord(data);

			// Assigns the tracking number to trackingId If tracking number is porvided on the record and trackingId variable is blank.
			// If there is consignment attached on the record enables the checkboxes.
			if (this.trackingIdFromRecord) {
				if (this.trackingId !== this.trackingIdFromRecord) {
					this.trackingId = this.trackingIdFromRecord;
				}
				if (this.consignmentIdFromRecord) {
					this.enableSelectArticles = true;
				}
			} // Resets happy parcel component if the tracking number is removed from the record.
			else {
				this.trackingId = '';
				if (this.template.querySelector('c-happy-parcel')) {
					this.template.querySelector('c-happy-parcel').resetSearch();
				}
			}

			// If case available, make happy parcel component read only.
			if (this.caseId) {
				this.readOnly = true;
				this.enableSelectArticles = false;
			} else {
				this.readOnly = false;
				this.impactedArticleIds = [];
				this.enableSelectArticles = true;
				// Passes empty array of impacted article to uncheck the impacted articles upon case removal.
				if (this.template.querySelector('c-happy-parcel')) {
					this.selectOrDeselectImpactedArticles();
				}
			}
		}
	}
	/**
	 * Uses getRelatedListRecords to get the related impacted article records of case the is available on the chat record.
	 */
	@wire(getRelatedListRecords, {
		parentRecordId: '$caseId',
		relatedListId: IMPACTED_ARTICLE_RELATION_ID,
		fields: IMPACTED_ARTICLE_FIELDS
	})
	listInfo({ error, data }) {
		if (error) {
			this.showSpinner = false;
			console.error(error);
		} else if (data && data.records) {
			data.records.forEach(element => this.impactedArticleIds.push(element.fields.Name.value));
			this.selectOrDeselectImpactedArticles();
		}
	}

	// Handler to receive messages from happy parcel component after search completed.
	handleSearchResults(event) {
		const eventDetail = event.detail;
		if (eventDetail) {
			if (eventDetail.articleRecordId) {
				this.articleRecordId = eventDetail.articleRecordId;
				this.trackingId = eventDetail.trackingId;
				// Auto link only if there are no duplicates
				if(!eventDetail.hasDuplicates){
					
					if(!this.duplicateTrackingId){
						// Link only consignment if there is no consignment on the chat record
						if (this.trackingIdFromRecord && !this.consignmentIdFromRecord && !this.noConsignment) {
							this.autoLinkOnlyConsignment();
						} else if (this.articleRecordId && this.consignmentIdFromRecord !== this.articleRecordId) {
							this.autoLink();
						}
					}else{
						// This will only run if the previous transaction has duplicates.
						this.duplicateTrackingId = '';
						this.autoLink();
					}
				}else{
					this.duplicateTrackingId = this.trackingId;
				}
				// executes only if case available and the page loaded or refreshed.
				if (this.caseId) {
					this.selectOrDeselectImpactedArticles();
				}
			} else {
				this.noConsignment = true;
			}
		}
	}
	/** Maps fields to variables */
	mapValuesToVariablesFromGetRecord(data) {
		this.caseId = getFieldValue(data, CASE_FIELD);
		this.trackingIdFromRecord = getFieldValue(data, TRACKING_ID_FIELD);
		this.consignmentIdFromRecord = getFieldValue(data, ARTICLE_ID_FIELD);
	}

	/** Handler to receive messages from happy parcel component when checkboxes selected.
	* Publishes LMS on select event.
	*/
	handleSelectedArticles(event) {
		// build and publish LMS Event for selected articles
		this.publishSelectedArticlesLMS(this.trackingId, event.detail);
	}
	/** Update the interaction record with tracking Id and consigment record. */
	autoLink() {
		// Create the recordInput object
		const fields = {};
		fields[ID_FIELD.fieldApiName] = this.recordId;
		fields[ARTICLE_ID_FIELD.fieldApiName] = this.articleRecordId;
		fields[TRACKING_ID_FIELD.fieldApiName] = this.trackingId;

		const recordInput = { fields };

		this.showSpinner = true;
		this.doUpdate(recordInput);
	}
	/** Update the interaction record with consigment record.*/
	autoLinkOnlyConsignment() {
		// Create the recordInput object
		const fields = {};
		fields[ID_FIELD.fieldApiName] = this.recordId;
		fields[ARTICLE_ID_FIELD.fieldApiName] = this.articleRecordId;

		const recordInput = { fields };

		this.showSpinner = true;
		this.doUpdate(recordInput);
	}

	doUpdate(recordInput) {
		updateRecord(recordInput)
			.then(() => {
				this.enableSelectArticles = true;
				notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			})
			.catch(error => {
				console.error(error);
				this.displayToastMessage('Article link failed', 'Error', 'Error');
			})
			.finally(() =>{
				this.showSpinner = false;
			});
	}

	selectOrDeselectImpactedArticles() {
		this.template.querySelector('c-happy-parcel').selectOrDeselectImpactedArticles(this.impactedArticleIds);
	}

	get disableSelectArticles() {
		return !this.enableSelectArticles;
	}

	/**
	 * @description Publish the selected articles LMS event
	 * @param trackingId
	 * @param selectedArticles
	 */
	publishSelectedArticlesLMS(trackingId, selectedArticles) {
		const lmsEventPayload = {
			source: 'unifiedTrackingChatWrapper',
			type: 'articleSelected',
			body: {
				consignmentId: trackingId,
				selectedArticleIds: selectedArticles
			}
		};
		try {
			publish(this.messageContext, GENERIC_LMS_CHANNEL, lmsEventPayload);
		} catch (error) {
			// One of the scenario that we expect to excecute the catch block is when user opens and closes the interaction record quickly before / while loading the happyparcel component.
			console.error(error);
		}
	}

	displayToastMessage(toastMessage, toastTittle, toastVariant) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: toastTittle,
				message: toastMessage,
				variant: toastVariant
			})
		);
	}
}