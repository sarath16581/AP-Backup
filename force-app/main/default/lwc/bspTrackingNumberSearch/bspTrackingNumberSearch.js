import { LightningElement, api, track, wire } from 'lwc';
import { checkAllValidity, valueMissingErrorMsg, topGenericErrorMessage } from 'c/bspCommonJS';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import validateConsignmentNumber from '@salesforce/apex/bspEnquiryUplift.validateConsignmentNumber';

export default class BspTrackingNumberSearch extends NavigationMixin(LightningElement) {

    @api slimTrackingBar = false;
    @api showIconBox = false;

    errorMessage;
    visibleErrorMsg = false;
    isConsignmentNumValid = true;
    requiredValMissingErrorMsg = valueMissingErrorMsg;
    placeHolderText = 'Enter tracking number here';
    redirectToTrackingSearch = true;
    @track consignmentNumber;
    reqFrom;
    currentPageReference;

    @wire(CurrentPageReference)setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        this.consignmentNumber = this.currentPageReference.state.trackingNumber;
        //[Jansi: added below 03-09-2020
        if (this.consignmentNumber){
            this.reqFrom = 'consignmentSearch';
        }
    }

    renderedCallback() {
        if (this.consignmentNumber) {
            this.handleGo(null);
        }
    }

    handleChange(event) {
        this.isConsignmentNumValid = null;
        this.consignmentNumber = event.target.value.trim();
        this.validateConsignmentNumber('change');
    }

    handleGo(event) {
        if (event)
            event.preventDefault();
        const allValid = checkAllValidity(this.template.querySelectorAll('lightning-input'), false);
        if (allValid && this.isConsignmentNumValid) { //&& !this.slimTrackingBar 
            if (this.reqFrom) {
                // fire event to parent
                const c = new CustomEvent('trackingsearchgo', {
                    detail: this.consignmentNumber
                });
                this.dispatchEvent(c);
            } else {
                this.navigateToTrackingSearch();
            }
        }
    }

    async validateConsignmentNumber(requestFrom) {
        await validateConsignmentNumber({
            consignmentNumber: this.consignmentNumber,
        }).then(result => {
            // alert(result);
            if (result) { // result not 'null' means number format is invalid
                this.isConsignmentNumValid = false;
                this.template.querySelectorAll('[data-id="trackingNumber"]')[0].
                setCustomValidity(result);
            } else {
                this.isConsignmentNumValid = true;
                this.template.querySelectorAll('[data-id="trackingNumber"]')[0].
                setCustomValidity('');
            }
        }).catch(error => {
            this.isConsignmentNumValid = false;
        });

    }

    navigateToTrackingSearch() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'BSP_Consignment_Search__c'
            },
            state: {
                trackingNumber: this.consignmentNumber
            }
        });
    }
}