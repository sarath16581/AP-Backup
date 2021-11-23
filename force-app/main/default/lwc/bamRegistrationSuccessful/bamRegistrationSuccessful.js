/* eslint-disable no-extra-boolean-cast */
import { LightningElement } from 'lwc';
import ASSETS_URL from '@salesforce/resourceUrl/MerchantPortalAssets';
import triggerRegistrationCompleteIntegration from '@salesforce/apex/BAMRegistrationSuccessfulController.triggerRegistrationCompleteIntegration';

export default class BamRegistrationSuccessful extends LightningElement {

    assetsUrl = ASSETS_URL;

    connectedCallback() {
        // call camunda to trigger CSSO flow completion
        let correlationId = this.getParam('id');
        if(correlationId) {
            console.log(correlationId);
            this.triggerCall(correlationId);
        }
    }

    // invoke a call to camunda to trigger the CSSO completion flow
    // it's assumed the flow was completed successfully if the page this component resides on is invoke
    // we only trigger if a correlation id is passed to the page.
    async triggerCall(correlationId) {

        // force waiting before the interface loads
        console.log('here');
        triggerRegistrationCompleteIntegration({correlationId}).then((result) => {
            console.log('here1');
        }).catch((error) => {
            console.log('ERROR', error);
        });

    }

    getParam(name) {
        var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
        if (results==null) {
            return null;
        } else {
            return decodeURIComponent(results[1].replace(new RegExp('\\+', 'g'), ' ')) || 0;
        }
    }

    get successIconUrl() {
        return this.assetsUrl + '/svg/symbols.svg#app-registration-success';
    }

    // Identify if being loaded on IE11, to handle how we render SVGs
    get ie11() {
        return !!window.MSInputMethodContext && !!document.documentMode;
    }

    get successIconUrl_IE11() {
        return this.assetsUrl + '/svg/app-registration-success.svg';
    }

}