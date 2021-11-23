import { api, LightningElement } from 'lwc';
import confirmationMessage from '@salesforce/label/c.APT_Use_Offline_Rates_Confirmation_Message';
import missingConfigMessage from '@salesforce/label/c.APT_Use_Offline_Rates_MissingConfig_Message';
import save from '@salesforce/apex/APT_UseOfflineRatesController.save';

export default class Apt_UseOfflineRatesLWC extends LightningElement {
    @api proposalId;
    @api configId;
    @api configRequestId;
    @api flow;
    @api currentUrl;
    proposal = {};
    isLoadingSpinner = false;
    toastMessage = {
        show: false,
        type: '',
        message: ''
    };

    get showToastMessage() {
        return this.toastMessage.show;
    }
    get toastMessageClass() {
        let TOAST_CLASS_STYLE = 'slds-notify slds-notify_toast ';
        if(this.toastMessage.type == 'success') {
            TOAST_CLASS_STYLE += 'slds-theme_success';
        } else if(this.toastMessage.type == 'error') {
            TOAST_CLASS_STYLE += 'slds-theme_error';
        } else if(this.toastMessage.type == 'warning') {
            TOAST_CLASS_STYLE += 'slds-theme_warning';
        } 
        return TOAST_CLASS_STYLE;
    }

    label = { confirmationMessage, missingConfigMessage }; // Expose the labels to use in the template.

    setToastMessage(show, type, message) {
        this.toastMessage = {
            show: show,
            type: type,
            message: message
        };
    }

    isUndefinedOrNull(field) {
        return (typeof field === 'undefined' || field === null);
    }

    handleToastClose() {
        this.setToastMessage(false, '', '');
    }

    handleNext(event){
        let fields = event.detail.fields;
        if(this.isUndefinedOrNull(this.configId) || this.isUndefinedOrNull(this.proposalId) || this.isUndefinedOrNull(fields)) {
            this.setToastMessage(true, 'error', label.missingConfigMessage);
        } else {
            let proposal = {
                Id: this.proposalId,
                APT_Use_Offline_Rates_Reason__c: fields.APT_Use_Offline_Rates_Reason__c,
                APT_Use_Offline_Rates_Comments__c: fields.APT_Use_Offline_Rates_Comments__c
            };

            // make server call to save
            this.isLoadingSpinner = true; // start spinner
            save({
                configId: this.configId,
                proposal: proposal
            })
            .then(response => {
                this.isLoadingSpinner = false; // stop spinner
                let retVal = response;
                this.setToastMessage(true, retVal.result, retVal.message);
                if(retVal.result == 'success'){
                    window.location.assign('/'+this.proposalId);
                }
            })
            .catch(error =>{
                this.isLoadingSpinner = false; // stop spinner
                this.setToastMessage(true, 'error', 'Something went wrong. Please contact support team.');
                console.error(error);
            })
        }
    }

    handleCancel(){
        history.back();
    }
}