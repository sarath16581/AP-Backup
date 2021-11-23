import { LightningElement, api, track, wire } from 'lwc';
import getFeedElements from '@salesforce/apex/myNetworkGetChatterFeeds.getFeedElements';
import postNotification from '@salesforce/apex/myNetworkGetChatterFeeds.postNotification';
import {refreshApex} from '@salesforce/apex';
export default class MyNetworkChatterPublisher extends LightningElement {
    @api recordId;
    @api recordCount;
    @api isRequired = false;
    
    @track feed;
    @track error;
    @track chatterComment;
    @track showLoadingSpinner;
    @track isButtonDisabled;
    @track activeSections = ['A']; 
    wiredFeedElements;
    postNotification;
   
    @wire(getFeedElements,{noOfRecordsToFetch: '$recordCount', recordId: '$recordId'}) 
    feedElements(result) {
        this.wiredFeedElements = result;
        if (result.data) {
            this.feed = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.feed = undefined;
        }
    };

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;        
    }
    handleChangeEvent(event) {
       //this.chatterComment=event.target.value;
       this.chatterComment = event.detail;
    }
    handleOnPost(event) {
        this.isButtonDisabled = true;
        this.showLoadingSpinner = true;
        if(!this.chatterComment) {
            this.isRequired = true;
            this.showLoadingSpinner = false;
            this.isButtonDisabled = false;
        }
        else{
            postNotification({
                recordId: event.currentTarget.dataset.key , 
                messageBody: this.chatterComment})
                .then(result => {
                    if(result) {
                        console.log('i am here in postNotification');
                        }
                        //refresh apex and set the html properties
                        refreshApex(this.wiredFeedElements);
                        this.showLoadingSpinner = false;
                        this.isButtonDisabled = false;
                        this.chatterComment="";
                        this.isRequired = false;
                })
                .catch(error => {
                    console.log(error);
                });
        }
        
    }
    
}