import { LightningElement, wire } from 'lwc';
import getLoggedInUserInfo from '@salesforce/apex/bspBaseUplift.getLoggedInUserInfo';

export default class BspFooter extends LightningElement {
    loggedInUserInfo;
    isCongnitionUser = false;

    @wire(getLoggedInUserInfo)
    wiredUserInfo({ error, data }) {
        if (data) {
            this.loggedInUserInfo = data;
            this.isCongnitionUser = this.loggedInUserInfo.isCognitionUser;
        } else if (error) {
            this.isCongnitionUser = false;
        }
    }

}