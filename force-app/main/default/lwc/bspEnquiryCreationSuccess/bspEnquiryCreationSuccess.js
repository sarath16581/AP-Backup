import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSTEnquiryCreationSuccessBodyText from '@salesforce/apex/bspEnquiryUplift.getSTEnquiryCreationSuccessBodyText';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

export default class BspEnquiryCreationSuccess extends NavigationMixin(LightningElement) {
    @api enquiyType;
    @api caseNumber;
    stBodyText;
    communityURL = '';

    @wire(getSTEnquiryCreationSuccessBodyText) wiredSTSuccessText({ data, error }) {
        if (data)
            this.stBodyText = data;
    }

    async connectedCallback() {
        try {
            this.communityURL = await retrieveBspCommunityURL();
        } catch (er) {
            console.error(er)
        }
    }

    get isAPType() {
        return this.enquiyType ? (this.enquiyType == 'Auspost' ? true : false) : false;
    }

    get isSType() {
        return this.enquiyType ? (this.enquiyType == 'Startrack' ? true : false) : false;
    }

    get headerText() {
        if (this.isAPType)
            return 'Thank you, your enquiry has been sent.';
        else if (this.isSType)
            return 'Thank you, your enquiry has been created.';
        else
            return '';
    }

    get bodyText() {
        if (this.isAPType)
            return 'Your reference number is ' +
                '<a href="' + this.communityURL + '/s/EnquiryDetail?enquiryNumber=' + this.caseNumber + '" target="_blank" ><b>' + this.caseNumber + ' </b></a>' +
                ' and we’ve' +
                ' emailed you a copy for your records.' +
                ' A Business Customer Representative will be in touch shortly, usually within one to two business days.';
        else if (this.isSType)
            return this.stBodyText ? this.stBodyText : '';
        else
            return '';
    }

    get note() {
        if (this.isAPType)
            return 'Please note: This excludes weekends and national public holidays.';
        else if (this.isSType)
            return 'You can check your enquiry here: ' +
                '<a href="' + this.communityURL + '/s/EnquiryDetail?enquiryNumber=' + this.caseNumber + '" target="_blank" ><b>' + this.caseNumber + '</b> </a>';
        else
            return '';
    }

    onClickCancel() {
        this.navigateHome();
    }

    //[To check, can move this to common JS]
    navigateHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    /**
 * navigate to case details
 */
    /* navigateToCaseDetails(event)
     {
         event.preventDefault();
         this[NavigationMixin.GenerateUrl]({
             type: 'comm__namedPage',
             attributes: {
                 name: 'BSP_Enquiry_Details__c'
             },
             state: {
                 enquiryNumber: this.caseNumber
             }
         }).then(generatedUrl => {
             window.open(generatedUrl, "_blank");
         });
     }*/


}