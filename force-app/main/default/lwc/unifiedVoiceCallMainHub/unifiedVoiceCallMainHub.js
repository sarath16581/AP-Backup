import { LightningElement,api } from 'lwc';

export default class UnifiedVoiceCallMainHub extends LightningElement {
    @api recordId;
    consignmentNumber = '';
    numberOfArticles = 0;
    customerName = 'John Doe';

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
        console.log('handleSelectedArticles');
        console.log(JSON.stringify(event.detail));
        this.numberOfArticles = event.detail.length ?? 0;
    }
}