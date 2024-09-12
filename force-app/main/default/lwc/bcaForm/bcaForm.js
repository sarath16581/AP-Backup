/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-10-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business Creidit Application Main Form
* @changelog
* 2020-10-12 Victor.Cheng@auspost.com.au  Created
*
*/
import {LightningElement, track, wire, api} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";

import skipValidationSetting from '@salesforce/apex/BCAFormController.skipValidationSetting';
import {pageIds,  abnTypes, getDirectorLabel} from 'c/bcaStepBase';
import saveAssessment from '@salesforce/apex/BCAFormController.saveAssessment';
import checkUserAccessToBCACreation from '@salesforce/apex/BCAFormBase.checkUserAccessToBCACreation';
import getWelcomeMessage from '@salesforce/apex/BCAFormBase.getWelcomeMessage';
import getMinimumCreditLimit from '@salesforce/apex/BCAFormBase.getMinimumCreditLimit';
import doEquifaxValidations from '@salesforce/apexContinuation/BCAFormController.doEquifaxValidations';
import createPDFSummary from '@salesforce/apex/BCAFormController.createPDFSummary';

export default class BcaForm extends LightningElement {

    SECTION1 = 'Business Details';
    SECTION2 = 'Director Details';
    SECTION3 = 'Credit Amount';
    SECTION4 = 'Postal Outlets';
    SECTION5 = 'Review & Submit';

    currentPageReference;
    finishLabel = 'Submit';
    @track assessmentId;
    @track creditAssessment = {
        directors : []
    };
    @track errorMessages = '';
    @track standardBlurb = 'All fields are required unless marked as (optional)';

    @track showWizard;
   
    msgHeaderForExistingBillingAccOrInprogressCA;
    msgBodyForExistingBillingAccOrInprogressCA;

    @track welcomeText;

	welcomeTextHardcoded = '(Knowledge uplift test) If your business is spending over $1,000 each month on postage, then you&rsquo;re eligible to apply for a Business Credit Account with Australia Post.<br /><br />To complete this online application you&rsquo;ll need:<ul><li>Business details, including your ABN, registered address and business type</li><li>Director details, including name, address and date of birth</li><li>Bank account details to set up direct debit</li><li>Details of other suppliers you currently have credit terms with to provide as references</li></ul>Make sure the person completing this application is over 18 and is a director of the business, or has authorisation to complete it on a director&rsquo;s behalf.<br /><br />If you&rsquo;ve got everything listed above ready, the online form should take 5-10 minutes to complete.';

    skipValidation = false;

    showCreditAmount;
    // page ids for hide/show
    PAGE_IDS = pageIds();
    ABNTYPES = abnTypes();
    @track lowerCreditLimitVal;

    @track underMaintenance;

    get showCreateBCAForm(){
        if(this.underMaintenance)
            return false;
        return this.showWizard == true ? true : false;
    }

    get showExistingUserForm(){
        if(this.underMaintenance)
            return false;
        return this.showWizard == false ? true : false;
    }

    connectedCallback() {
        // check if user is having access to BCA
        checkUserAccessToBCACreation({ loggedInUserId: '' }).then(data => {
            try {
                this.underMaintenance = data.underMaintenance;
                this.showWizard = data.allowBCACreation;
                this.msgHeaderForExistingBillingAccOrInprogressCA = data.header;
                this.msgBodyForExistingBillingAccOrInprogressCA = data.message;
                this.creditAssessment.userOrgId = data.userOrgId;
            } catch (err) {
            }
            if (this.showWizard) {
                // get welcome text
				/*
                getWelcomeMessage().then(data => {
                    this.welcomeText = data.Message__c;
                }).catch(error => {
                });
				*/
				this.welcomeText = this.welcomeTextHardcoded;
                // get skipvalidations
                skipValidationSetting().then(result => {
                    this.skipValidation = result;
                    this.creditAssessment.skipValidation = this.skipValidation;
                }).catch(error => {
                });

                // get minimum credit Limit
                getMinimumCreditLimit().then(result => {
                    this.creditAssessment.lowerCreditLimitVal = result;
                }).catch(error => {
                });

            }
        }).catch(error => {
        });

    }

    get hideNextButton () {
        return !this.skipValidation;
    }

    get hidePrevButton () {
        return !this.skipValidation;
    }

    // placeholder
    onNextStep = (event) => {
        return true;
    }

    onCompleteForm = (event) => {
    }

    /**
     * Update the number of directors given the ABN Entity Type
     */
    updateDirectorState = () => {
        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup) {
            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();
            if(entityTypeGroup !== this.ABNTYPES.PARTNERSHIP
                && this.creditAssessment.directors && this.creditAssessment.directors.length > 0)
            {
                this.creditAssessment.directors = [this.creditAssessment.directors[0]];
            }
        }
    }

    /**
     * Update the page visibility based on ABN Entity Type
     */
    updatePageVisibility = () => {
        // centralize page visibility updates
        let arrToSkip = [];

        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
        {
            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();

            switch(entityTypeGroup)
            {
                case this.ABNTYPES.GOVERNMENT:
                    // no digital ID required
                    arrToSkip.push(this.PAGE_IDS.digitalId);
                    arrToSkip.push(this.PAGE_IDS.notVerified);

                    // hide all
                    arrToSkip = arrToSkip.concat(this.businessPagesToHide(0, false));
                    arrToSkip.push(this.PAGE_IDS.trust);
                    arrToSkip.push(this.PAGE_IDS.directDebit);
                    arrToSkip.push('businessReference1');
                    arrToSkip.push('businessReference2');
                    arrToSkip.push('businessReference3');
                    arrToSkip.push(this.PAGE_IDS.businessReferenceList);
                    break;
                case this.ABNTYPES.PARTNERSHIP:
                    // hide the trust page if it's NOT a trust
                    arrToSkip.push(this.PAGE_IDS.trust);

                    // no need to hide, just show both pages
                    break;
                case this.ABNTYPES.TRUST:
                    // show 1
                    arrToSkip = arrToSkip.concat(this.businessPagesToHide(1, false));
                    break;
                default:
                    // hide the trust page if it's NOT a trust
                    arrToSkip.push(this.PAGE_IDS.trust);
                    // show 1
                    arrToSkip = arrToSkip.concat(this.businessPagesToHide(1, false));
                    break;
            }
        }

        if(this.creditAssessment.directors && this.creditAssessment.digitalIdVerified === true)
        {
            // remove the verification page too, because there is no next button if they move back
            arrToSkip.push(this.PAGE_IDS.digitalId);

            // remove the not verified page
            arrToSkip.push(this.PAGE_IDS.notVerified);
        }

        if (this.creditAssessment.creditAmount && this.creditAssessment.creditAmount.recommendedAmount) {
            // if recommended amount is within, skip the end page
            if (this.creditAssessment.creditAmount.recommendedAmount &&
                (this.creditAssessment.creditAmount.recommendedAmount >= this.creditAssessment.lowerCreditLimitVal)){
                arrToSkip.push(this.PAGE_IDS.creditEnd);
            }
        }

        // skip
        this.wizardComponent.skipPageIds(arrToSkip);
    }

    businessPagesToHide(numToShow, showSummary)
    {
        let personPageIds = ['businessPerson1','businessPerson2','businessPerson3','businessPerson4','businessPerson5','businessPerson6'];
        personPageIds = personPageIds.splice(numToShow, personPageIds.length - numToShow);
        if(!showSummary){
            personPageIds.push(this.PAGE_IDS.businessPersonsList);
        }
        return personPageIds;
    }


    // #region validate/save each step
    validateABN = () => {
        // get values from abn cmp
        let  abnCmp = this.template.querySelector('c-bca-step-abn');
        this.creditAssessment.abnDetails = abnCmp.abnDetails;
        let isValid = abnCmp.checkAllValidity();

        this.updateDirectorState();
        this.updatePageVisibility();
        return isValid || this.skipValidation;
    }

    validateTrustDetails = () => {
        let trustCmp = this.template.querySelector('c-bca-step-trust-details');
        this.creditAssessment.trustFiles = trustCmp.trustFiles;
        let isValid = trustCmp.checkAllValidity();

        this.updatePageVisibility();
        return isValid || this.skipValidation;
    }

    get showTrustDeed() {
        if(!this.creditAssessment.abnDetails)
        {
            return true;
        }

        if(this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase() !== 'trust')
        {
            return false;
        }
        return true;
    }


    // display a different message for the director step
    get directorTitle() {
        let sTitle = 'Director details';
        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
        {
            sTitle = getDirectorLabel(this.creditAssessment.abnDetails.EntityTypeGroup, this.creditAssessment.abnDetails.trustType) + ' details';

            if(this.ABNTYPES.PARTNERSHIP === this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase())
            {
                sTitle += ' (1 of 2)';
            }
        }
        return sTitle;
    }

    get directorBlurb() {
        let blurb = 'We need to verify the details of one of your company’s directors in order to complete this application. If your company has multiple directors, choose one to submit as a representative.';
        if(this.creditAssessment.abnDetails
            && this.creditAssessment.abnDetails.EntityTypeGroup
        )
        {
            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();
            switch (entityTypeGroup) {
                case this.ABNTYPES.PARTNERSHIP:
                    blurb = 'We require the details of two partners in order to complete this application. Whoever you choose as Partner One will have their details automatically verified by the Digital ID app.';
                    break;
                case this.ABNTYPES.INDIVIDUAL:
                    blurb = 'As a sole trader, we need a few personal details to complete this application.';
                    break;
                case this.ABNTYPES.TRUST:
                    switch (this.creditAssessment.abnDetails.trustType.toLowerCase()) {
                        case this.ABNTYPES.TRUSTEE_PERSON:
                            blurb = 'As a trustee, we need a few personal details to complete this application.';
                            break;
                        case this.ABNTYPES.TRUSTEE_COMPANY:
                        default:
                            // director
                            break;
                    }
                    break;
                case 'government':
                    blurb = '';
                    break;
                default:
                    break;
            }
        }

        return blurb + '<br/>';
    }

    validateDigitalId = () => {
        let isValid = false || this.skipValidation;
        let digitalIdCmp = this.template.querySelector('c-bca-step-digital-id');

        this.creditAssessment.directors = [...this.creditAssessment.directors];
        this.creditAssessment.digitalIdVerified = digitalIdCmp.verified;
        this.creditAssessment.directors[0] = digitalIdCmp.digitalIdResult;

        // no validation for digital ID, it either verifies and moves automatically, or fails and ends.

        this.updatePageVisibility();
        return true;
    }

    validatePerson1 = () => { return this.validatePersonByIndex(1); }
    validatePerson2 = () => { return this.validatePersonByIndex(2); }

    showBusinessContact;

    validatePersonByIndex = (index) => {
        let cmp = this.template.querySelector('c-bca-step-business-person[data-index="' + index + '"]')
        let isValid = cmp.checkAllValidity();
        if(!this.creditAssessment.directors)
        {
            this.creditAssessment.directors = [];
        }
        this.creditAssessment.directors = [...this.creditAssessment.directors];
        this.creditAssessment.directors[index - 1] = cmp.director;

        this.updatePageVisibility();
        //let businessContactCmp = this.template.querySelector('c-bca-step-business-contact');
        //businessContactCmp.triggerRenderCallback();
        this.showBusinessContact = true;
        return isValid || this.skipValidation;
    }

    validateDirectors = () => {
        let directorsCmp = this.template.querySelector('c-bca-step-directors');

        let isValid = directorsCmp.checkAllValidity();

        if(isValid)
        {
            this.creditAssessment.directors = directorsCmp.directors;
        }

        this.updatePageVisibility();
        return isValid;
    }

    validateBusinessContact = () => {
        let isValid = false || this.skipValidation;
        let businessContactCmp = this.template.querySelector('c-bca-step-business-contact');
        this.creditAssessment.businessContact = businessContactCmp.businessContact;
        if (this.template.querySelector("c-bca-step-business-contact").checkValidity ()) {
            isValid = true;
        }
        this.updatePageVisibility();
        return isValid;
    }

    validateBusinessAddressDetails = () => {
        let isValid = false || this.skipValidation;
        let busAddressDetailsCmp = this.template.querySelector('c-bca-step-business-address-details');
        this.creditAssessment.businessAddressDetails = {};
        this.creditAssessment.businessAddressDetails = busAddressDetailsCmp.businessAddressStepDetails;

        if (this.template.querySelector("c-bca-step-business-address-details").checkAllValidity()) {
            isValid = true;
        }
        this.updatePageVisibility();
        return isValid;
    }

    validateBusinessTypeDetails = () => {
        var isValid = false || this.skipValidation;
        let busTypeDetailsCmp = this.template.querySelector('c-bca-step-business-type-details');
        this.creditAssessment.businessTypeDetails = busTypeDetailsCmp.businessTypeStepDetails;
        if (this.template.querySelector("c-bca-step-business-type-details").checkAllValidity()) {
            isValid = true;
        }
        this.updatePageVisibility();

        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup
            && this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase() === this.ABNTYPES.GOVERNMENT){
            this.showBusinessContact = true;
        }
        return isValid;
    }

    get wizardComponent() {
        return this.template.querySelector('c-bca-wizard');
    }

    showPostalOutlets;
    validateCreditAmount = () => {
        var isValid = false || this.skipValidation;
        let creditAmountCmp = this.template.querySelector('c-bca-step-credit-amount');
        this.creditAssessment.creditAmount = creditAmountCmp.creditAmount;
        if (this.template.querySelector("c-bca-step-credit-amount").checkAllValidity()) {
            isValid = true;
        }
        this.updatePageVisibility();
        this.showPostalOutlets = true;
        return isValid;
    }

    showReview;
    validateReference1 = () => { return this.validateReferenceByIndex(1); }
    validateReference2 = () => { return this.validateReferenceByIndex(2); }
    validateReference3 = () => { return this.validateReferenceByIndex(3); }
    validateReferenceByIndex(index)
    {
        let cmp = this.template.querySelector('c-bca-step-reference[data-index="' + index + '"]')
        let isValid = cmp.checkAllValidity();
        if(!this.creditAssessment.businessRefs)
        {
            this.creditAssessment.businessRefs = [];
        }
        this.creditAssessment.businessRefs = [...this.creditAssessment.businessRefs];
        this.creditAssessment.businessRefs[index - 1] = cmp.businessReference;
        this.updatePageVisibility();
        return isValid || this.skipValidation;
    }
    validateReferences = () => {
        let refsCmp = this.template.querySelector('c-bca-step-business-refs');
        this.creditAssessment.businessRefs = refsCmp.businessRefs;
        this.updatePageVisibility();
        return true;
    }

    validateEmailAddForCorrespondence= () => {
        var isValid = false || this.skipValidation;
        let refsCmp = this.template.querySelector('c-bca-step-email-add-for-correspondence');
        this.creditAssessment.emailForCorrespondence = refsCmp.emailForCorrespondence;
        if (this.template.querySelector("c-bca-step-email-add-for-correspondence").checkAllValidity()) {
            isValid = true;
        }
        this.updatePageVisibility();
        this.showCreditAmount = true;
        return isValid;
    }

    validateDirectDebit= () => {
        var isValid = false || this.skipValidation;
        let directDebitCmp = this.template.querySelector('c-bca-step-direct-debit');
        this.creditAssessment.directDebit = directDebitCmp.directDebit;
        if (this.template.querySelector("c-bca-step-direct-debit").checkAllValidity()) {
            isValid = true;
        }
        this.updatePageVisibility();
        return isValid;
    }

    validatePostalOutlets= () => {
        let postalOutletCmp = this.template.querySelector('c-bca-step-postal-outlets');
        this.creditAssessment.postalOutlets = postalOutletCmp.postalOutlets;

        let isValid = postalOutletCmp.checkAllValidity();
        this.updatePageVisibility();
        this.showReview = true;
        return isValid || this.skipValidation;
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

    //-- for Business Contact person Step -- START
    // Sending the radio group here with selected contact here, because 

    @track selectedContact;
    @track directors = [];

    get contactPersonOptions() {
        if (this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup &&
            this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase() != this.ABNTYPES.GOVERNMENT &&
            this.creditAssessment.directors && this.creditAssessment.directors.length > 0) {
            let lContactOptions = [];
            for (let i = 0; i < this.creditAssessment.directors.length; i++) {
                let directorName =  this.creditAssessment.directors[i].firstName +
                                    ( this.creditAssessment.directors[i].middleName ? ' ' +  this.creditAssessment.directors[i].middleName : '') + ' ' 
                                    +  this.creditAssessment.directors[i].lastName;
                lContactOptions.push({ label: directorName, value: this.creditAssessment.directors[i].index });
            }
            lContactOptions.push({ label: 'Someone else', value: '_someoneElse' });
            this.selectedContact = this.creditAssessment.directors[0].index;
            this.directors = this.creditAssessment.directors;//director;
            return lContactOptions;
        } else {
            this.selectedContact = '_someoneElse';
            return null;
        }

    }

    //-- for Business Contact person Step -- END
    // #endregion
    @track caSubmitResults;
    showSubmitResults = false;    
    showSpinner = false;
    onSubmit = async () => {
        this.showSubmitResults = false;
        var isValid = false || this.skipValidation;
        let reviewCmp = this.template.querySelector('c-bca-review-and-submit');
        
        isValid = reviewCmp.checkAllValidity();
    
        if (isValid) {
            this.creditAssessment.appSummaryHTML = reviewCmp.getHTML();
            this.showSpinner = true;
            this.creditAssessment.showSpinner = true;
            var needEquifaxValidation = false;
            var creditAssId;
            await saveAssessment({ creditAssessmentStr:  JSON.stringify(this.creditAssessment)})
                .then(result => {
                   
                    //create PDF
                    this.createPDFSummary(result.caId);
                                    
                    if(result && result.isEquifaxValidationRequired){
                        needEquifaxValidation = true;
                        creditAssId = result.caId;
                    }else{
                        this.caSubmitResults = result;
                        this.showSubmitResults = true;
                        this.showSpinner = false;
                        this.creditAssessment.showSpinner = false;
                        this.updatePageVisibility();
                    }
                })
                .catch(error => {
                    isValid = false;
                    this.showSpinner = false;
                    this.creditAssessment.showSpinner = false;
                });
        }

        //Do equifax validations    
        if (needEquifaxValidation)
            await this.doEquifaxValidations(creditAssId);

        return isValid;
    }

    get hidePrevButtonForSubmitResults(){
        return !this.skipValidation;
    }

    createPDFSummary(creditAssesmentId) {
        createPDFSummary({
            caId: creditAssesmentId
        }).then(result => {
            if (result) {
            }
        }).catch(error => {
        });
    }

     async doEquifaxValidations(creditAssesmentId) {
         await doEquifaxValidations({
            caId: creditAssesmentId
        }).then(result => {
            if (result) {
                this.caSubmitResults = result;
                this.showSubmitResults = true;
                this.showSpinner = false;
                this.creditAssessment.showSpinner = false;
                this.updatePageVisibility();
            }
        }).catch(error => {
            this.showSpinner = false;
            this.creditAssessment.showSpinner = false;
        });
    }
}