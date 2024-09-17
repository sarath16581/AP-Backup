import { LightningElement,api,wire } from 'lwc';
import CONTACT_FIELD from '@salesforce/schema/VoiceCall.Contact__c';
import FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';

export default class UnifiedVoiceCallMainHub extends LightningElement {
    @api recordId;
    activeSections = ['consignment', 'customer'];
    consignmentNumber = '';
    numberOfArticles = 0;
    relatedContactId;
    customerName = '';

    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIELD] })
    voiceCallRecord({ error, data }) {
        if (data) {
            this.relatedContactId = getFieldValue(data,CONTACT_FIELD);
            if (!this.relatedContactId) {
                this.customerName = '';
            }
        }
    }

    @wire(getRecord, { recordId: '$relatedContactId', fields: [FIRST_NAME_FIELD, LAST_NAME_FIELD]})
    contactRecord({ error, data }) {
        if (data) {
            this.customerName = getFieldValue(data,FIRST_NAME_FIELD) + ' ' + getFieldValue(data,LAST_NAME_FIELD);
        }
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }

    get consignmentSectionTitle() {
        return `Article/Consignment ${this.consignmentNumber} (${this.numberOfArticles} articles selected)`;
    }

    get customerNameSectionTitle() {
        return `Customer/Contact ${this.customerName}`;
    }

    handleSearchComplete(event) {
        this.consignmentNumber = event.detail.trackingId ?? '';
    }

    handleSelectedArticles(event) {
        this.numberOfArticles = event.detail.length ?? 0;
    }
}