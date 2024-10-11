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
import { RefreshEvent } from "lightning/refresh";
// Object
import IMPACTED_ARTICLE_OBJECT from '@salesforce/schema/ImpactedArticle__c';
// Case Fields
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import CASE_ARTICLE_ID_FIELD from '@salesforce/schema/Case.ArticleTest__c';
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import CASE_TRACKING_ID_FIELD from '@salesforce/schema/Case.ArticleTest__r.Name';
import CASE_RECORDTYPE_NAME from '@salesforce/schema/Case.RecordType.DeveloperName';
// Impacted Article Fields
import IMPACTED_ARTICLE_ARTICLE_FIELD from '@salesforce/schema/ImpactedArticle__c.Article__c';
import IMPACTED_ARTICLE_NAME_FIELD from '@salesforce/schema/ImpactedArticle__c.Name';
import IMPACTED_ARTICLE_CASE_FIELD from '@salesforce/schema/ImpactedArticle__c.Case__c';
// Apex class
import checkIsUnifiedCase from '@salesforce/apex/UnifiedTrackingCaseWrapperController.isUnifiedCase';

const CASE_FIELDS = [CASE_STATUS_FIELD, CASE_ARTICLE_ID_FIELD, CASE_ID_FIELD, CASE_TRACKING_ID_FIELD, CASE_RECORDTYPE_NAME];
const IMPCATED_ARTICLE_FIELDS = ['ImpactedArticle__c.Id', 'ImpactedArticle__c.Article__c', 'ImpactedArticle__c.Name'];
const IMPACTED_ARTICLE_RELATION_ID = 'ImpactedArticles__r';

export default class UnifiedTrackingChatWrapper extends LightningElement {
	@api recordId;
	// Array to hold list of article Ids of impacted article records that are attached to a case.
	@track impactedArticleIds = [];
	// Object that holds tracking id as key and Inpacted article as value.
	@track impactedArticleIdsWithTrackingIds = {};
	// Boolean to determine if the current record is an unified case or not.
	isUnifiedCase = false;
	// Boolean to make search field read only and writable on happyparcel component.
	readOnly = true;
	// Boolean to hide and show Spinner
	showSpinner = false;
	// Boolean to hide and show checkboxes on the happy parcel component.
	enableSelectArticles = false;
	// Holds tracking Id provided on the record
	trackingId;
	// Consignment records that's available on the case record.
	consignmentIdFromRecord;
	// Holds case status value from the record
	statusFromRecord;
	// RecordType developer name
	recordTypeName;

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

			this.configHappyParcelComponent();
		}
	}
	/**Only executes on page load and when the record type changes. */
	@wire(checkIsUnifiedCase, { recordTypeDeveloperName: '$recordTypeName' })
	wiredIsUnifiedCase({ error, data }) {
		if (data) {
			this.isUnifiedCase = data;
			if(!this.isUnifiedCase){
				// Empty impacted articles related variables if it is not unified case
				this.impactedArticleIds = [];
				this.impactedArticleIdsWithTrackingIds = {};
			}
			this.configHappyParcelComponent();
		} else if (error) {
			this.isUnifiedCase = false;
			console.error(error);
		}
	}

	configHappyParcelComponent() {
		if (!this.consignmentIdFromRecord || !this.trackingId) {
			this.trackingId = '';
			if (this.template.querySelector('c-happy-parcel')) {
				this.template.querySelector('c-happy-parcel').resetSearch();
			}
			this.showSpinner = false;
		} else {
			this.handleEnableCheckBoxes(true);
		}

		if (this.statusFromRecord === 'Completed') {
			this.handleEnableCheckBoxes(false);
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
		} else if (data && data.records) {
			this.impactedArticleIds = [];
			data.records.forEach(element => {
				this.impactedArticleIds.push(element.fields.Name.value);
				this.impactedArticleIdsWithTrackingIds[element.fields.Name.value] = element.fields.Id.value;
			});
		}
	}

	// Handler to receive messages from happy parcel component after search completed.
	handleSearchResults(event) {
		const eventDetail = event.detail;
		if (eventDetail) {
			if (eventDetail.articleRecordId) {
				if (this.isUnifiedCase) {
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
		this.recordTypeName = getFieldValue(data, CASE_RECORDTYPE_NAME);
	}

	/** Handler to receive messages from happy parcel component when checkboxes selected.
	 * Publishes LMS on select event.
	 */
	handleSelectedArticles(event) {
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
				fields[IMPACTED_ARTICLE_NAME_FIELD.fieldApiName] = selectedArticles[indx];
				let recordInput = { apiName: IMPACTED_ARTICLE_OBJECT.objectApiName, fields };

				const impactedArticle = await createRecord(recordInput);

				if (impactedArticle) {
					this.impactedArticleIds.push(selectedArticles[indx]);
					this.impactedArticleIdsWithTrackingIds[selectedArticles[indx]] = impactedArticle.id;
				}
			}
			//Adding this as CreateRecord is not refreshing the related list.
			this.dispatchEvent(new RefreshEvent());
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

	handleEnableCheckBoxes(enableCheck) {
		this.enableSelectArticles = this.isUnifiedCase ? enableCheck : false;
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