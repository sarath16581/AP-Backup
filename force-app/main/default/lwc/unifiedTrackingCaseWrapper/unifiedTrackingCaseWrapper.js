/**
 * @description Wraps Happy Parcel component to show it on the case record
 * @author Raghav Ravipati
 * @date 2026-09-05
 * @group Tracking
 * @changelog
 */
import { api, LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, createRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { publish, MessageContext } from 'lightning/messageService';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';
// Object
import IMPACTED_ARTICLE_OBJECT from '@salesforce/schema/ImpactedArticle__c';
// Case Fields
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_ARTICLE_ID_FIELD from '@salesforce/schema/Case.ArticleTest__c';
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import CASE_TRACKING_ID_FIELD from '@salesforce/schema/Case.ArticleTest__r.TrackingID__c';
import CASE_IS_UNIFIED_CASE_FIELD from '@salesforce/schema/Case.IsUnifiedCase__c';
// Impacted Article Fields
import IMPACTED_ARTICLE_ARTICLE_FIELD from '@salesforce/schema/ImpactedArticle__c.Article__c';
import IMPACTED_ARTICLE_ARTICLEID_FIELD from '@salesforce/schema/ImpactedArticle__c.ArticleId__c';
import IMPACTED_ARTICLE_CASE_FIELD from '@salesforce/schema/ImpactedArticle__c.Case__c';

const CASE_FIELDS = [CASE_STATUS_FIELD, CASE_ARTICLE_ID_FIELD, CASE_ID_FIELD, CASE_TRACKING_ID_FIELD, CASE_IS_UNIFIED_CASE_FIELD];
const IMPCATED_ARTICLE_FIELDS = ['ImpactedArticle__c.Id', 'ImpactedArticle__c.Article__c', 'ImpactedArticle__c.ArticleId__c'];
const IMPACTED_ARTICLE_RELATION_ID = 'ImpactedArticles__r';

export default class UnifiedTrackingChatWrapper extends LightningElement {
	@api recordId;
	// Array to hold list of article Ids of impacted article records that are attached to a case.
	@track impactedArticleIds = [];
	// Object that holds tracking id as key and Inpacted article as value.
	@track impactedArticleIdsWithTrackingIds = {};
	// Boolean to determine if the current record is an unified case or not.
	isUnifiedCase = false;
	// Boolean to make search field read only and writable on happyparcel component
	readOnly = false;
	// Boolean to hide and show Spinner
	showSpinner = false;
	// Boolean to hide and show checkboxes on the happy parcel component.
	enableSelectArticles = false;
	// Holds tracking Id provided on the record
	trackingId;
	// Consignment records that's available on the interation record.
	consignmentIdFromRecord;
	// Holds case status value from the record
	statusFromRecord;

	// wire the message context and pass to publisher to send LMS events
	@wire(MessageContext)
	messageContext;

	/**
	 * Uses getRecord to get case records field values and passes variables to happy parcel component.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
	caseRecord({ error, data }) {
		if (error) {
			this.showSpinner = false;
			console.error(error);
		} else {
			this.showSpinner = true;
			this.mapValuesToVariablesFromGetRecord(data);

			if (!this.consignmentIdFromRecord) {
				this.trackingId = '';
				if (this.template.querySelector('c-happy-parcel')) {
					this.template.querySelector('c-happy-parcel').resetSearch();
				}
			} else {
				this.readOnly = true;
				this.handleEnableCheckBoxes(true);
			}

			if (this.statusFromRecord === 'Completed') {
				this.readOnly = true;
				this.handleEnableCheckBoxes(false);
			}
		}
	}
	/**
	 * Uses getRelatedListRecords to get the related impacted article records of case.
	 */
	@wire(getRelatedListRecords, {
		parentRecordId: '$recordId',
		relatedListId: IMPACTED_ARTICLE_RELATION_ID,
		fields: IMPCATED_ARTICLE_FIELDS
	})
	listInfo({ error, data }) {
		if (error) {
			console.error(error);
		} else if (data && data.records && this.isUnifiedCase) {
			this.impactedArticleIds = [];
			data.records.forEach(element => {
				this.impactedArticleIds.push(element.fields.ArticleId__c.value);
				this.impactedArticleIdsWithTrackingIds[element.fields.ArticleId__c.value] = element.fields.Id.value;
			});
		}
	}

	// Handler to receive messages from happy parcel component after search completed.
	handleSearchResults(event) {
		const eventDetail = event.detail;
		if (eventDetail) {
			if (eventDetail.articleRecordId) {
				if(this.isUnifiedCase){					
					this.selectOrDeselectImpactedArticles();
				}
			}
		}

		this.showSpinner = false;
	}
	/** Maps fields to variables */
	mapValuesToVariablesFromGetRecord(data) {
		this.trackingId = getFieldValue(data, CASE_TRACKING_ID_FIELD);
		this.consignmentIdFromRecord = getFieldValue(data, CASE_ARTICLE_ID_FIELD);
		this.statusFromRecord = getFieldValue(data, CASE_STATUS_FIELD);
		this.isUnifiedCase = getFieldValue(data, CASE_IS_UNIFIED_CASE_FIELD);
	}

	/** Handler to receive messages from happy parcel component when checkboxes selected.
	 * Publishes LMS on select event.
	 */
	handleSelectedArticles(event) {
		// build and publish LMS Event for selected articles
		this.publishSelectedArticlesLMS(this.trackingId, event.detail);
		this.processImpactedArticles(event.detail);
	}

	processImpactedArticles(selectedArticles) {
		let listToCreateImpactedArticles = selectedArticles.filter(item => {
			return !this.impactedArticleIds.includes(item);
		});
		let listToDeleteImpactedArticles = this.impactedArticleIds.filter(item => {
			return !selectedArticles.includes(item);
		});

		if (listToCreateImpactedArticles && listToCreateImpactedArticles.length > 0) {
			this.handleEnableCheckBoxes(false);			
			this.doCreate(listToCreateImpactedArticles);
		}
		if (listToDeleteImpactedArticles && listToDeleteImpactedArticles.length > 0) {
			this.handleEnableCheckBoxes(false);
			this.doDelete(listToDeleteImpactedArticles);
		}
	}

	async doCreate(selectedArticles) {
		// Create the recordInput object
		let fields = {};
		fields[IMPACTED_ARTICLE_CASE_FIELD.fieldApiName] = this.recordId;
		fields[IMPACTED_ARTICLE_ARTICLE_FIELD.fieldApiName] = this.consignmentIdFromRecord;

		try {
			for (let indx = 0; indx < selectedArticles.length; indx++) {
				fields[IMPACTED_ARTICLE_ARTICLEID_FIELD.fieldApiName] = selectedArticles[indx];
				let recordInput = { apiName: IMPACTED_ARTICLE_OBJECT.objectApiName, fields };

				const impactedArticle = await createRecord(recordInput);

				if (impactedArticle) {
					this.impactedArticleIds.push(selectedArticles[indx]);
					this.impactedArticleIdsWithTrackingIds[selectedArticles[indx]] = impactedArticle.id;
				}
			}
			this.handleEnableCheckBoxes(true);
		} catch (error) {
			this.handleEnableCheckBoxes(true);
			console.error(error);
			this.displayToastMessage('Error creating impacted articles', 'Error', 'Error');
		}
	}

	async doDelete(selectedArticles) {
		try {
			for (let indx = 0; indx < selectedArticles.length; indx++) {
				let impactedArticleId = this.impactedArticleIdsWithTrackingIds[selectedArticles[indx]];
				if (impactedArticleId) {
					await deleteRecord(impactedArticleId);

					let index = this.impactedArticleIds.indexOf(selectedArticles[indx]);
					this.impactedArticleIds.splice(index, 1);
					delete this.impactedArticleIdsWithTrackingIds[selectedArticles[indx]];
				}
			}
			this.handleEnableCheckBoxes(true);
		} catch (error) {
			this.handleEnableCheckBoxes(true);
			console.error(error);
			this.displayToastMessage('Error deleting impacted articles', 'Error', 'Error');
		}
	}

	selectOrDeselectImpactedArticles() {
		this.template.querySelector('c-happy-parcel').selectOrDeselectImpactedArticles(this.impactedArticleIds);
	}

	get disableSelectArticles() {
		return this.isUnifiedCase ? !this.enableSelectArticles : false;
	}

	handleEnableCheckBoxes(enableCheck){
		this.enableSelectArticles = this.isUnifiedCase ? enableCheck : false;
	}

	/**
	 * @description Publish the selected articles LMS event
	 * @param trackingId
	 * @param selectedArticles
	 */
	publishSelectedArticlesLMS(trackingId, selectedArticles) {
		const lmsEventPayload = {
			source: 'HappyParcel',
			type: 'articleSelected',
			body: {
				consignmentId: trackingId,
				selectedArticleIds: selectedArticles
			}
		};
		publish(this.messageContext, GENERIC_LMS_CHANNEL, lmsEventPayload);
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
