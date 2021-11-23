import {LightningElement, track} from 'lwc';
import retrieveUserContactInfo from '@salesforce/apex/BAMMyApplicationsController.retrieveUserContactInfo';
import { loadScript } from 'lightning/platformResourceLoader';
import GLOBAL_ASSETS_URL from '@salesforce/resourceUrl/GlobalAssets';
import { get } from 'c/bamUtils';

export default class BamMerchantPortalContainer extends LightningElement {

    @track contactIsActive;
    @track loaded;

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        //loadScript(this, GLOBAL_ASSETS_URL + '/js/svg4everybody/svg4everybody.js');

        const userDetails = await retrieveUserContactInfo();
        const contactData = JSON.parse(userDetails);
        this.contactIsActive = (get(contactData, 'Status__c', '').toLowerCase() === 'active');

        // // for ie 11 support
        // svg4everybody();

        this.loaded = true;
    }

}