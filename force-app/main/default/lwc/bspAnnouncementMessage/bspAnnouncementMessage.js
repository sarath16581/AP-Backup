import { LightningElement, wire } from 'lwc';
import getAnnouncementMessage from '@salesforce/apex/bspBaseUplift.getAnnouncementMessage';

export default class BspAnnouncementMessage extends LightningElement {
  announcementMessage;

    @wire(getAnnouncementMessage)
    wiredAnnouncementMessage({ error, data }) {
        if (data) {
            this.announcementMessage = data;
        } 
    }

    get isShowAnnouncementMsg(){
        return this.announcementMessage ? (this.announcementMessage.trim().length > 0 ? true : false): false;
    }
}