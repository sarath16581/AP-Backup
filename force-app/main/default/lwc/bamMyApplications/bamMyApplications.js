/* eslint-disable no-extra-boolean-cast */

import { LightningElement, track } from 'lwc';
import ASSETS_URL from '@salesforce/resourceUrl/MerchantPortalAssets';
import retrieveCurrentUserContactApplications from '@salesforce/apex/BAMMyApplicationsController.retrieveCurrentUserContactApplications';
import retrieveUserContactInfo from '@salesforce/apex/BAMMyApplicationsController.retrieveUserContactInfo'
import { poll, isEmpty } from 'c/bamUtils';

export default class BamHomePage extends LightningElement {

    assetsUrl = ASSETS_URL;

    @track contactApplications = [];
    @track contactName = '';

    connectedCallback() {
        this.loadApplicationData();
        this.loadContactInfo();
        poll(this.loadApplicationData.bind(this));
    }

    get pageHeader() {
        return this.contactName ? `Hi ${this.contactName}, welcome to Merchant Portal` : ''
    }

    // Identify if being loaded on IE11, to handle how we render SVGs
    get ie11() {
        return !!window.MSInputMethodContext && !!document.documentMode;
    }

    async loadApplicationData() {
        // force waiting before the interface loads
        let contactApplications = await retrieveCurrentUserContactApplications()
        contactApplications = JSON.parse(contactApplications);
        contactApplications = contactApplications.map(application => {
            let app = {...application};
            app.iconUrl = false;
            app.cssClass = 'app-launcher ' + (app.isPending ? 'pending' : '');
            if(app.iconRef) {
                app.iconUrl = this.assetsUrl + '/svg/symbols.svg#' + app.iconRef;
                app.iconUrl_IE11 = this.assetsUrl + '/svg/' + app.iconRef + '.svg';
            }
            return app;
        });

        this.contactApplications = isEmpty(contactApplications) ? null : contactApplications;
    }

    async loadContactInfo() {
        const contactInfoStr = await retrieveUserContactInfo()
        const contactData = JSON.parse(contactInfoStr)
        this.contactName = contactData && (contactData.FirstName || contactData.LastName)
    }

    /**
     * When user clicks on app launcher button in tile list, we need to find the application they selected and launch the app
     */
    launchApp(event) {
        let applicationId = event.target.dataset.id;
        let application = this.contactApplications.filter(app => app.applicationId === applicationId );
        if(Array.isArray(application) && application.length > 0) {
            // some applications require to be opened int he same window. Example: Access Management.
            // These apps will be apps that already exist in the Salesforce community
            if(application[0].launchInNewWindow) {
                window.open(application[0].accessUrl,'_blank');
            } else {
                location.href = application[0].accessUrl;
            }
        }
    }

}