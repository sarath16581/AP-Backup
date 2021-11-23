/*
* @author avula.jansirani@auspost.com.au
* @date 05/02/2021
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Reusable cmp to display Terms and Conditions in 'Direct Debit' and 'Review &Summary' step
* @changelog
* 05/02/2021 avula.jansirani@auspost.com.au  Created
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML, reportAllCmpValidity, checkAllCmpValidity, checkCustomValidity,
     REVIEW_TERMS_BUSINESS_PURPOSE_TEXT} from 'c/bcaCommonMethods';
import {} from 'c/bcaCommonMethods'; 


export default class BcaTermsAndConditions extends LightningElement {

    @api label;
    @api temsAndConditions;
    @api agreeLabel;
    @api allowDownlaod;  // 'yes' or 'no'
    @api errorMessage;
    @api downloadURL;
    @api applicationSignedDate;
    showErrorMessage = false;

    @api displayLabel2;
    @api displayLabel3;
    @api displayLabel4;
    @api agreeLabel2ErrorMsg;
    @api agreeLabel3ErrorMsg;
    @api agreeLabel4ErrorMsg;
    @api displayLabel4Text;
    @api pivacyNoticeURL; 
    @api isGOVTEntityType = false;

    businessPurposeText = REVIEW_TERMS_BUSINESS_PURPOSE_TEXT;

    showImportantText = false;

    custom_checkbox_label_error_css_class;


    get temsAndConditionsText(){
        return this.temsAndConditions ? this.temsAndConditions : '';
    }

    get labelText(){
        return this.label ? this.label : '';
    }

    get agreeText(){
        return this.agreeLabel ? this.agreeLabel : '';
    }

    get checkBoxCustomClass(){
        return 'checkbox-custom-label '+ this.custom_checkbox_label_error_css_class;
    }
   
    get isAllowDownload(){
        return this.allowDownlaod == 'yes';
    }

   
    get tcDownloadURL(){
        return this.downloadURL;
    }

    get appSignedDateText(){
        return this.isGOVTEntityType == true ? 'Agreement accepted on' :  'Direct Debit Request Received and Business Credit Account Application Date:';
    }

    //change handler
    handleChange(event) {
        var datasetId = event.target.dataset.id;
        var validationMsg;
        if(datasetId == 'bcaTC')
            validationMsg = this.errorMessage;
        else if (datasetId == 'bcaBunessPurposeTC') {
            validationMsg = this.agreeLabel2ErrorMsg;
            if (datasetId, event.target.checked)
                this.showImportantText = true;
            else
                this.showImportantText = false;
        }
        else if(datasetId == 'bcaPrivacyTC')
            validationMsg = this.agreeLabel3ErrorMsg;
        else if(datasetId == 'bcaDDTC')
            validationMsg = this.agreeLabel4ErrorMsg;


        checkCustomValidity( this.template.querySelectorAll('[data-id="' + datasetId + '"]')[0], validationMsg);

       
        if ( datasetId == 'bcaPrivacyTC') {
            if (this.template.querySelectorAll('[data-id="' + datasetId + '"]')[0].validity.valueMissing)
                this.custom_checkbox_label_error_css_class = 'slds-text-color_error';
            else
                this.custom_checkbox_label_error_css_class = '';
        }
               
        this.fireEvent(datasetId, event.target.checked);
    }

    fireEvent(inputDataId, val) {
        this.dispatchEvent(new CustomEvent('changeevent', {
            detail: {
                dataId: inputDataId,
                checkboxVal: val
            }
        }));
    }

    onClickFindOutMore(){
        this.dispatchEvent(new CustomEvent('clickfindoutmoreevent'));
    }

    //validation method
    @api checkValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input');
        var isValid = checkAllCmpValidity(inputComponents);
        if (!isValid)
            this.showErrorMessage = true;
        else
           this.showErrorMessage = false;
     return isValid;
    }

    @api reportValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input');
        reportAllCmpValidity(inputComponents);
    }

    @api getHTML() {
        var tcHTML = this.template.querySelectorAll('[data-id="bcaTermAndConditions"]')[0].innerHTML;
        tcHTML = replaceHTML(tcHTML,
            this.temsAndConditionsText,
            '<lightning-formatted-rich-text', '</lightning-formatted-rich-text>');  // Replace with 'Terms and Conditions
        tcHTML = replaceHTML(tcHTML, '<input type="checkbox" id="autorize" name="authorize" checked>' + this.agreeLabel + '</input>',
            '<lightning-input', '</lightning-input>'); // Replace checkbox
        if (this.displayLabel2)
            tcHTML = replaceHTML(tcHTML, '<br><br><input type="checkbox" id="autorize2" name="authorize2" checked>'+this.businessPurposeText+'</input>',
                '<lightning-input', '</lightning-input>'); // Replace checkbox
        if (this.displayLabel2)
            tcHTML = replaceHTML(tcHTML, '<input type="checkbox" id="autorize3" name="authorize3" checked></input>',
                '<lightning-input', '</lightning-input>'); // Replace checkbox
        return tcHTML;
    }

}