import { LightningElement, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import CONTACT_NAME_FIELD from '@salesforce/schema/User.Contact.Name';
import { navigation } from 'c/bamNavigationUtils';

import retrieveMerchantPortalCommunityURL from '@salesforce/apex/BAMUserController.retrieveMerchantPortalCommunityURL';

const fields = [CONTACT_NAME_FIELD];

export default class BamProfileMenu extends LightningElement {
    userId = Id;
    navigate // instance of the navigation utility

    @track logoutURL = 'javascript:void(0);'
    @track myAccessPageURL = 'javascript:void(0);'
    
    async connectedCallback() {
        const commURLPrefix = await retrieveMerchantPortalCommunityURL()
        this.navigate = navigation(commURLPrefix)
        this.myAccessPageURL = this.navigate.userPageURL
        this.logoutURL = this.navigate.logoutURL
    }

    @wire(getRecord, { recordId: '$userId', fields })
    user;

    get name() {
        return getFieldValue(this.user.data, CONTACT_NAME_FIELD);
    }
}