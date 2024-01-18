import { LightningElement,api,wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { NavigationMixin } from 'lightning/navigation';
import APCN_FIELD from "@salesforce/schema/Account.APCN__c";

const fields = [APCN_FIELD];
const baseUrl = 'http://hxaix23.hq.auspost.com.au:50000/irj/go/km/docs/SAP_AusPost_Web_Content/Enterprise/Display/PortalUniqueRedirectSecure.html?URL=sapfes.hq.auspost.com.au/sap/bc/ui5_ui5/sap/zcs_cac/index.html#/apcn/';
export default class CloseAccount extends NavigationMixin(LightningElement) {
    @api recordId

    @wire(getRecord, { recordId:'$recordId', fields})
    loadFields({error, data}){
        if(data){
            const apcn = getFieldValue(data, APCN_FIELD);

            let url = baseUrl + apcn;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        }
    }
}