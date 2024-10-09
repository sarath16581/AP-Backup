/**
 * @description LWC wrapper on the main hub tab for the LiveChat flexipage.
 * It contains Unified Tracking wrapper component and Customer Search wrapper component, under each respective accordion.
 * The accordion headers are customised to be dynamic with population of article number and contact name.
 * Both accordions can be opened and closed without restriction.
 */
import { LightningElement,api,wire } from 'lwc';
import CONTACT_FIELD from '@salesforce/schema/LiveChatTranscript.ContactId';
import FIRST_NAME_FIELD from '@salesforce/schema/LiveChatTranscript.Contact.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/LiveChatTranscript.Contact.LastName';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const LIVE_CHAT_FIELDS = [
	CONTACT_FIELD,
	FIRST_NAME_FIELD,
	LAST_NAME_FIELD
];

export default class UnifiedLiveChatMainHub extends LightningElement {
	@api recordId;
	activeSections = ['consignment', 'customer'];
	consignmentNumber = '';
	numberOfArticles = 0;
	relatedContactId;
	customerName = '';

	/**
	 * Wire adapter to fetch the Live Chat record field data
	 */
	@wire(getRecord, { recordId: '$recordId', fields: LIVE_CHAT_FIELDS })
	liveChatRecord({ error, data }) {
		if (data) {
			this.relatedContactId = getFieldValue(data,CONTACT_FIELD);
			this.customerName = getFieldValue(data,FIRST_NAME_FIELD) + ' ' + getFieldValue(data,LAST_NAME_FIELD);
			if (!this.relatedContactId) {
				this.customerName = '';
			}
		} else if (error){
			console.error('Error retrieving live chat record:', error);
			// Dispatch the ShowToastEvent
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error',
					message: 'Unexpected error encountered while retrieving Live Chat Data',
					variant: 'error'
				})
			);
		}
	}

	/**
	 * Toggle section or accordion on and off
	 */
	handleSectionToggle(event) {
		this.activeSections = event.detail.openSections;
	}

	/**
	 * Custom header of consignment section or accordion title
	 */
	get consignmentSectionTitle() {
		return `Article/Consignment ${this.consignmentNumber} (${this.numberOfArticles} articles selected)`;
	}

	/**
	 * Custom header of customer section or accordion title
	 */
	get customerNameSectionTitle() {
		return `Customer/Contact ${this.customerName}`;
	}

	/**
	 * Retrieve consignment number on handling of `trackingsearchcompleted` custom event
	 */
	handleSearchComplete(event) {
		this.consignmentNumber = event.detail.trackingId ?? '';
	}

	/**
	 * Retrieve number of articles on handling of `selectedarticles` custom event
	 */
	handleSelectedArticles(event) {
		this.numberOfArticles = event.detail.length ?? 0;
	}
}