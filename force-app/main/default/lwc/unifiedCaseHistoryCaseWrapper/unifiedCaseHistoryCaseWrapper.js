import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';

import CONTACT_ID_FIELD from '@salesforce/schema/Case.ContactId';
import ARTICLE_ID_FIELD from '@salesforce/schema/Case.ArticleTest__c';

/**
 * This component wraps the `unifiedCaseHistory` component specifically for the `Case` record page.
 * 
 * @changelog:
 * 2024-09-30 - Marcel HK - Created
 */
export default class UnifiedCaseHistoryCaseWrapper extends LightningElement {
	/**
	 * The record Id from the `Case` record page where this component is used.
	 * @type {string}
	 */
	@api recordId;

	/**
	 * Used to display an error message to the user.
	 * @type {string}
	 */
	errorMessage;

	/**
	 * The Case object returned from the `@wire` adapter.
	 * @type {object}
	 */
	caseRecord;

	/**
	 * Used to track the initial load of this component, and display a spinner.
	 * @type {boolean}
	 */
	get isLoading() {
		return !this.caseRecord;
	}

	/**
	 * The Consignment Id (lookup to the `Article__c` object) related to the Case record.
	 * @type {string}
	 */
	get linkedConsignmentId() {
		return getFieldValue(this.caseRecord, ARTICLE_ID_FIELD);
	}

	/**
	 * The Contact Id related to the Case record.
	 * @type {string}
	 */
	get linkedContactId() {
		return getFieldValue(this.caseRecord, CONTACT_ID_FIELD);
	}

	/**
	 * Wire the Case record.
	 */
	@wire(getRecord, { recordId: '$recordId', fields: [ARTICLE_ID_FIELD, CONTACT_ID_FIELD] })
	wiredCaseRecord({ error, data }) {
		if (data) {
			this.caseRecord = data;
		} else if (error) {
			console.error(error);
			this.caseRecord = undefined;
			this.errorMessage = reduceErrors(error).join(', ');
		}
	}
}
