/*
* @author avula.jansirani@auspost.com.au
* @date 2020-01-20
* @channel Business Credit Account
* @tag Business Credit Account
* @description: The main review cmp where user can review all the step data entered in previous steps before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api, wire, track } from 'lwc';
import bcaStepBase, { pageIds, abnTypes } from "c/bcaStepBase";
import getSummaryTC from '@salesforce/apex/BCAFormBase.getSummaryTC';
import getSummaryTCDownloadURL from '@salesforce/apex/BCAFormBase.getSummryTCDownloadURL';
import getSummaryPrivacyNoticeURL from '@salesforce/apex/BCAFormBase.getSummryPrivacyNoticeURL';
import {REVIEW_AUTHORIZE_TEXT,
        REVIEW_TERMS_CONDITIONS_ERROR_MESSAGE,
        REVIEW_BUSINESS_PURPOSE_TERMS_CONDITIONS_ERROR_MESSAGE,
        REVIEW_BUSINESS_PRIVACY_NOTICE_TERMS_CONDITIONS_ERROR_MESSAGE
} from 'c/bcaCommonMethods';


export default class BcaReviewAndSubmit extends bcaStepBase {

    PAGE_IDS = pageIds();
    termsAndConditions;
    authorizeText = REVIEW_AUTHORIZE_TEXT;
    termsAndConditionsErrorMsg = REVIEW_TERMS_CONDITIONS_ERROR_MESSAGE;
    summaryTCDownloadURL = '';
    privacyNoticeURL;
    businessPurposeErrorMsg = REVIEW_BUSINESS_PURPOSE_TERMS_CONDITIONS_ERROR_MESSAGE;
    businessPrivacyErrorMsg = REVIEW_BUSINESS_PRIVACY_NOTICE_TERMS_CONDITIONS_ERROR_MESSAGE;
    showFindMore = false;

    constructor() {
        super();
        this.template.addEventListener('editdetails', this.navigateToEditStep.bind(this));
    }

    @wire(getSummaryTC)
    wiredSummaryTC({error, data }) {
        if (data) {
            if (typeof data !== 'undefined' && typeof data.Message__c !== 'undefined')
                this.termsAndConditions = data.Message__c ? data.Message__c : '';
        }
    }

    @wire(getSummaryTCDownloadURL) 
    wiredSummaryTCURL({error, data }) {
        if (data) {
            this.summaryTCDownloadURL = data;
        }
    }

    @wire(getSummaryPrivacyNoticeURL) 
    wiredSummaryPrivacyURL({error, data }) {
        if (data) {
            this.privacyNoticeURL = data;
        }
    }

    navigateToEditStep(event) {
        if(this.creditAssessment.showSpinner){
            event.stopPropagation();
            return;
        }
        this.jumpToStep(event.detail);
        event.stopPropagation()
    }

    get tradingManualConstName() {
        return this.CONSTANTS.MANUAL_ENTRY;
    }

    get isCreditAssesment() {
        return this.creditAssessment ? true : false;
    }

    get isAbnDetails() {
        return this.creditAssessment.abnDetails ? true : false;
    }

    get isTrusteeCompanyDetails() {
        return this.creditAssessment.abnDetails.trustType &&
            this.creditAssessment.abnDetails.trustType == this.ABNTYPES.TRUSTEE_COMPANY &&
            this.creditAssessment.abnDetails.acnDetails ? true : false;
    }

    get isBusinessAddressDetails() {
        return this.creditAssessment.businessAddressDetails ? true : false;
    }

    get isBusinessTypeDetails() {
        return this.creditAssessment.businessTypeDetails ? true : false;
    }

    get isDirectorDetails() {
        return this.entityTypeGroup &&
        this.entityTypeGroup != this.ABNTYPES.GOVERNMENT && 
        this.creditAssessment.directors ? true : false;
    }

    get isBusinessContact() {
        return this.creditAssessment.businessContact ? true : false;
    }

    get isEmailAddForCorrespondence() {
        return this.creditAssessment.emailForCorrespondence ? true : false;
    }

    get isCreditAmountDetails() {
        return this.creditAssessment.creditAmount ? true : false;
    }

    get isDirectDebitDetails() {
        return this.entityTypeGroup &&
            this.entityTypeGroup != this.ABNTYPES.GOVERNMENT &&
            this.creditAssessment.directDebit ? true : false;
    }

    get isBusinessRef() {
        return this.entityTypeGroup &&
            this.entityTypeGroup != this.ABNTYPES.GOVERNMENT &&
            this.creditAssessment.businessRefs ? true : false;
    }

    get abnWithChildObjects() {
        if (this.creditAssessment2 && this.creditAssessment2.abnChilds) {
            return this.creditAssessment2.abnChilds;
        }
    }

    get isTrustDetailsExists() {
        return this.entityTypeGroup &&
        this.entityTypeGroup == this.ABNTYPES.TRUST && 
        this.creditAssessment.trustFiles && this.creditAssessment.trustFiles.length > 0 ? true : false;
    }

    get isPostalOutlets(){
        return this.creditAssessment.postalOutlets ? true : false;
    }

    get TC() {
        return this.termsAndConditions ? this.termsAndConditions : '';
    }

    get entityTypeGroup() {
        if (this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
            return this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();
        else
            return '';
    }

    get trustType() {
        if (this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.trustType)
            return this.creditAssessment.abnDetails.trustType;
        else
            return '';
    }

    get isGOVTEntityType(){
        return  this.entityTypeGroup == this.ABNTYPES.GOVERNMENT ? true : false;
    }

    
    @track selectedContact;
    @track directors = [];
    ABNTYPES = abnTypes();

    get contactPersonOptions() {
        let lContactOptions = [];
        let lodgingOptions = [];
        if (this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup &&
            this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase() != this.ABNTYPES.GOVERNMENT &&
            this.creditAssessment.directors && this.creditAssessment.directors.length > 0) {

            for (let i = 0; i < this.creditAssessment.directors.length; i++) {
                let directorName = this.creditAssessment.directors[i].firstName +
                    (this.creditAssessment.directors[i].middleName ? ' ' + this.creditAssessment.directors[i].middleName : '') + ' '
                    + this.creditAssessment.directors[i].lastName;
                lContactOptions.push({ label: directorName, value: this.creditAssessment.directors[i].index });
            }
            lodgingOptions = [...this.creditAssessment.directors];//director;

            this.selectedContact = this.creditAssessment.directors[0].index;
        } 

        //-- add someone else contact provided
        if (this.creditAssessment.businessContact && this.creditAssessment.businessContact.index == '_someoneElse') {
            let bcName = this.creditAssessment.businessContact.firstName + ' ' +this.creditAssessment.businessContact.lastName;
            lContactOptions.push({ label: bcName, value: 'businessContact' });

            let temp = Object.assign({}, this.creditAssessment.businessContact);
            temp.index = 'businessContact';
            //   if(lodgingOptions.length == 0)
            lodgingOptions.push(temp);


            //this.directors = lodgingOptions;

            if (!this.selectedContact)
                this.selectedContact = 'businessContact';
        }

        this.directors = lodgingOptions;

        lContactOptions.push({ label: 'Someone else', value: '_someoneElse' }); //this.CONSTANTS.SOMEONE_ELSE_VAL
        return lContactOptions;
    }

    @api get lodgingPersonDetails(){
        let businessContactCmp = this.template.querySelector('c-bca-step-business-contact');
       return businessContactCmp.businessContact;

    }

    //validation method
    @api checkAllValidity() {
        var isTCValid = this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="reviewTC"]'), false);
        var isPrivacyValid = this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="reviewPrivacy"]'), false);        
        return isTCValid && isPrivacyValid;
    }

    @api getHTML() {
        let abnHTML;
        let acnHTML;
        let trustDocHTML;
        let BDHTML;
        let BTHTML;
        let dirctorHTML;
        let businessContactHTML;
        let emailCorrespondenceHTML;
        let ceditAmtDetailsHTML;
        let directDebitHTML;
        let businessRefHTML;
        let postalOutletHTML;
        let tcHTML;
        let appSignedDateHTML;

        //Get ABN HTML 
        if (this.isAbnDetails)
            abnHTML = this.template.querySelectorAll('[data-id="abnSummary"]')[0].getHTML();

        //Get ACN HTML 
        if (this.isAbnDetails && this.isTrusteeCompanyDetails)
            acnHTML = this.template.querySelectorAll('[data-id="acnSummary"]')[0].getHTML();

        //Get Trust doc HTML 
        if (this.isAbnDetails && this.isTrustDetailsExists)
            trustDocHTML = this.template.querySelector('c-bca-summary-trust-details').getHTML();


        //Get Business Address HTML
        if (this.isBusinessAddressDetails)
            BDHTML = this.template.querySelector('c-bca-summary-business-address').getHTML();

        //Get Business Type Details HTML
        if (this.isBusinessTypeDetails)
            BTHTML = this.template.querySelector('c-bca-summary-business-type-details').getHTML();

        //Get Director HTML
        if (this.isDirectorDetails)
            dirctorHTML = this.template.querySelector('c-bca-summary-director-details').getHTML();

        //Get Business contact HTML
        if (this.isBusinessContact)
            businessContactHTML = this.template.querySelector('c-bca-summary-business-contact-person').getHTML();

        //Get Business contact HTML
        if (this.isEmailAddForCorrespondence)
            emailCorrespondenceHTML = this.template.querySelector('c-bca-summary-email-add-for-correspondence').getHTML();

        //Get CreditAmount Detail HTML
        if (this.isCreditAmountDetails)
            ceditAmtDetailsHTML = this.template.querySelector('c-bca-summary-credit-amount').getHTML();

        //Get Direct Debit Detail HTML
        if (this.isDirectDebitDetails)
            directDebitHTML = this.template.querySelector('c-bca-summary-direct-debit').getHTML();

        //Get Business Ref HTML
        if (this.isBusinessRef)
            businessRefHTML = this.template.querySelector('c-bca-summary-business-refs').getHTML();

        //Get postal outlet HTML
        if (this.isPostalOutlets)
            postalOutletHTML = this.template.querySelector('c-bca-summary-postal-outlets').getHTML();


        //Get Summary T&C Address HTML
        tcHTML = this.template.querySelector('c-bca-terms-and-conditions').getHTML();

        //concat in order which we want to display
        var allHTML = abnHTML;      
        if(acnHTML) allHTML = allHTML.concat(acnHTML);
        if(trustDocHTML) allHTML = allHTML.concat(trustDocHTML);
        if(BDHTML) allHTML = allHTML.concat(BDHTML);
        if(BTHTML) allHTML = allHTML.concat(BTHTML);
        if(dirctorHTML) allHTML = allHTML.concat(dirctorHTML);
        if(businessContactHTML) allHTML = allHTML.concat(businessContactHTML);
        if(emailCorrespondenceHTML) allHTML = allHTML.concat(emailCorrespondenceHTML);
        if(ceditAmtDetailsHTML) allHTML = allHTML.concat(ceditAmtDetailsHTML);
        if(directDebitHTML) allHTML = allHTML.concat(directDebitHTML);
        if(businessRefHTML) allHTML = allHTML.concat(businessRefHTML);
        if(postalOutletHTML) allHTML = allHTML.concat(postalOutletHTML);
        if(tcHTML) allHTML = allHTML.concat(tcHTML);
        if(appSignedDateHTML)  allHTML = allHTML.concat(appSignedDateHTML);

        return allHTML;
    }

    isAccepted_BCA_TC;
    isAccepted_BCA_businessConditions_TC;
    isAccepted_BCA_privacy_TC;
    applicationSignedDate;

    onChangeEvent(event) {

        if (event.detail.dataId == 'bcaTC')
            this.isAccepted_BCA_TC = event.detail.checkboxVal;

        else if (event.detail.dataId == 'bcaBunessPurposeTC')
            this.isAccepted_BCA_businessConditions_TC = event.detail.checkboxVal;

        else if (event.detail.dataId == 'bcaPrivacyTC')
            this.isAccepted_BCA_privacy_TC = event.detail.checkboxVal;

        //if TC and Privacy are accepted then show Print button
        if (this.isAccepted_BCA_TC && this.isAccepted_BCA_businessConditions_TC && this.isAccepted_BCA_privacy_TC){
            this.updateNavPrintButton(true);
            this.applicationSignedDate = this.getCurrentDate();
        } else{
            this.updateNavPrintButton(false);
            this.applicationSignedDate = '';
        }

    }

    getCurrentDate() {
        var today = new Date();
        var dd = today.getDate();

        var mm = today.getMonth()+1;
        var yyyy = today.getFullYear();
        if (dd < 10) dd = '0' + dd;
        if (mm < 10) mm = '0' + mm;

        return dd + '/' + mm + '/' + yyyy;
    }

    toggleFindOutMore(){
        this.showFindMore = !this.showFindMore;
    }

}