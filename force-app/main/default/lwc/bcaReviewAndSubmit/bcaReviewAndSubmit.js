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

	termsAndConditionsHardCoded = '(Knowledge uplift test)<b>Australia Post Business Credit Account Terms and Conditions</b> <p>1. The contract</p> <p style="margin-left: 40px;">1.1 The Customer acknowledges and agrees that it has read and understood, and agrees to, these terms and conditions for the operation, establishment and use of a business credit account (“Account”).</p> <p style="margin-left: 40px;">1.2 The execution of the application for an Account (“Application”) constitutes an offer by the Customer to acquire and use an Account on the terms and conditions set out in this document.</p> <p style="margin-left: 40px;">1.3 If Australia Post approves the Application, such approval will constitute acceptance of the offer and will create a contract between Australia Post and the Customer on these terms and conditions (“Contract”).</p> <p style="margin-left: 40px;">1.4 The parties acknowledge and agree that the Account may be used as a means for transacting payments and other amounts payable by the Customer to Australia Post for the provision of a range of goods or services provided by Australia Post under separate terms and conditions (each, an “AP Product”).</p> <p>2. Credit enquiries</p> <p style="margin-left: 40px;">For the purpose of considering the Application, and at any time during the term of the Contract, the Customer authorizes Australia Post to make such enquiries as Australia Post may require to be satisfied as to the creditworthiness of the Customer. The Customer agrees to provide signed written authorities addressed to the Customer’s banker or other credit providers, credit bureaux or mercantile agencies as Australia Post requires from time to time.</p> <p>3. Minimum Spend Threshold</p> <p style="margin-left: 40px;">Australia Post reserves the right to require the Customer to spend a minimum dollar amount per year to obtain products or services on credit (charged to the Account).</p> <p>4. Credit limit</p> <p style="margin-left: 40px;">Australia Post specifies the maximum (GST inclusive) amount that may be charged to the Account over a particular period (“Credit Limit”). The Customer’s Credit Limit is subject to review at any time by Australia Post. Australia Post may, on request in writing by the Customer, agree in writing to increase or decrease the Credit Limit. The balance of the Account at any time must not exceed the Credit Limit. Australia Post is not responsible for any loss or damage whatsoever or howsoever caused arising from the refusal by Australia Post to supply the Customer with any products or services on credit because the Credit Limit has been exceeded. The Customer agrees to immediately pay the amounts charged to the Account for any products or services supplied by Australia Post in excess of the Credit Limit, whether or not demand for payment has been made by Australia Post.</p> <p>5. Authorised and unauthorised transactions</p> <p style="margin-left: 40px;">The Customer is responsible for and indemnifies Australia Post against any unauthorised use of the Account. The Customer must notify Australia Post in writing of any unauthorised transactions on the Account immediately after the Customer becomes aware of them. The Customer is not responsible for any unauthorised use of the Account after Australia Post receives written notification of the unauthorised use.</p> <p>6. Terms of payment</p> <p style="margin-left: 40px;">6.1 The Customer agrees to pay Australia Post no later than 14 days by Electronic Funds transfer or 21 days by Direct Debit from the date of issue of the tax invoice/adjustment note of the amounts set out therein.</p> <p style="margin-left: 40px;">6.2 Payment of the amount specified in 6.1 will be in Australian Dollars (AUD).</p> <p style="margin-left: 40px;">6.3 Payments may not be made by franking machine imprint.</p> <p style="margin-left: 40px;">6.4 Tax invoices/adjustment notes are posted to the Customer at the address specified by the Customer for that purpose in the Application.</p> <p style="margin-left: 40px;">6.5 Where the Customer has defaulted in its payment obligations under this Contract, any amounts owing by the Customer to Australia Post in connection with this Contract may be deducted from any fee payable by Australia Post to the Customer under any other contract.</p> <p style="margin-left: 40px;">6.6 Australia Post will charge certain fees (if applicable) which are detailed under <span class="ft7">Things to know section at <a href="https://auspost.com.au/business/business-admin/business-credit-accounts-postage-meters/business-credit-account" target="_blank">https://auspost.com.au/business/business-admin/business-credit-accounts-postage-meters/business-credit-account</a> or on request from Australia Post.</span></p> <p>7. Proof of supply of products or services</p> <p style="margin-left: 40px;">A certificate setting out details of the amount owing and any other matters relating to the Account signed by an officer of Australia Post is sufficient evidence (in the absence of manifest error) of the supply of products or services by Australia Post to the Customer. This certificate may be used in court proceedings.</p> <p>8. Transaction errors</p> <p style="margin-left: 40px;">Any complaint made by the Customer that a transaction recorded on the Customer’s tax invoice / adjustment note is incorrect must be advised to Australia Post in writing within seven days of the issue of the tax invoice / adjustment note. If this does not occur, the Customer will be assumed to have accepted the transactions recorded in the tax invoice/adjustment as correct (absent any manifest error). If part of the amount set out in the tax invoice / adjustment note is in dispute, the Customer agrees to pay the undisputed and disputed amount within the time period specified in clause 6.1, where a dispute is assessed and upheld, any late payment charges associated with the disputed amount will be credited back to the customer.</p> <p>9. If the Account is used for postage</p> <p style="margin-left: 40px;">If the Account is used for payment of postage on postal articles, those postal articles must be lodged at official post offices, mail centres or other postal centres as specified by Australia Post. Customers must provide a correctly completed mailing statement when lodging their mail. If there is a discrepancy of less than $50 between the number or nature of postal articles lodged and the number or nature shown on the accompanying mailing statement, Australia Post may make a corresponding adjustment to the Account without recourse to the Customer. Australia Post will discuss with the Customer any discrepancies of $50 or more.</p> <p>10. Security for performance of the Contract</p> <p style="margin-left: 40px;">10.1 Bank guarantee</p> <p style="margin-left: 40px;">The Customer may be required to provide to Australia Post (either prior to the approval of the Application or during the term of the Contract), a bank guarantee (in a form acceptable to Australia Post) to secure the Customer’s performance of the Contract.</p> <p style="margin-left: 40px;">10.2 Personal Property Securities Act (“PPSA”)</p> <p style="margin-left: 40px;">If Australia Post determines that this Contract (or a transaction in connection with it) is or creates a security interest for the purposes of the PPSA, the Customer agrees to do all things which Australia Post considers necessary for the purposes of registering its security interest, including providing consents, signing and producing documents, or supplying information.</p> <p style="margin-left: 40px;">10.3 Other forms of security</p> <p style="margin-left: 40px;">As a term of its approval of the Application (or at any time during the term of the Contract), Australia Post may require the Customer to provide other security for performance under the Contract. For example, if the Customer is a company, a guarantee (in a form acceptable to Australia Post) may be required from each director or shareholder of the Customer or any other person including the spouse or relative of that director or shareholder or from any associated or related entity of the Customer.</p> <p>11. Warranties</p> <p style="margin-left: 40px;">11.1 The Customer warrants that:</p> <p style="margin-left: 40px;">(a) all statements made, and documents provided in connection with the Application and all representations that the Customer has made or may make during the term of the Contract to Australia Post are true and correct; and</p> <p style="margin-left: 40px;">(b) the Account is required for the Customer’s business or commercial purposes and will not be used for personal, domestic or household purposes.</p> <p style="margin-left: 40px;">11.2 The Customer acknowledges that Australia Post relies on the correctness of these warranties in approving the Application and continues to rely on these warranties in its further dealings with the Customer.</p> <p>12. Indemnity</p> <p style="margin-left: 40px;">The Customer indemnifies Australia Post against any liability, loss, costs, charges and expenses Australia Post suffers in connection with the Contract or the Account, except to the extent arising directly as a result of fraud or wilful misconduct on the part of Australia Post.</p> <p>13. Changes in address and other particulars</p> <p style="margin-left: 40px;">The Customer must notify Australia Post within seven days of any change in the constitution, ownership, membership or control of the Customer, or any change or proposed change in the Customer’s address. Despite the occurrence of any of these changes, the Customer’s obligations under the Contract continue. However, Australia Post may require a new application to be executed.</p> <p>14. Termination / Suspension</p> <p style="margin-left: 40px;">14.1 Australia Post may, acting reasonably, at any time suspend or terminate the Customer’s Account on seven days’ written notice to theCustomer.</p> <p style="margin-left: 40px;">14.2 Australia Post may suspend or terminate the Contract immediately by written notice to the Customer where: (a) Australia Post was induced by fraudulent misrepresentation on the Customer’s part to approve an application for any account with the Customer; or (b) the amount charged to a Customer’s Account exceeds the Credit Limit at any time without the prior written approval of Australia Post; or (c) any amount charged to the Account is due and unpaid (amounts disputed in accordance with clause 8 are not considered due until the dispute is rectified); or (d) in the reasonable opinion of Australia Post any change in circumstances, including, without limitation, changes in the Customer’s constitution, ownership, membership, control status or ability to provide security for payment of amounts which have or are likely to be charged to the Account, makes the continuance of the Contract undesirable or unsatisfactory; or (e) the Customer becomes, threatens or resolves to become or is in jeopardy of becoming subject to any form of insolvency administration; (f) the Customer being a partnership dissolves, threatens or resolves to dissolve or is in jeopardy of dissolving; the Customer being a natural person, dies; or the Customer ceases or threatens to cease conducting business in the normal manner; or (g) the Customer uses the Account for any non-commercial purposes including, without limitation, for personal, domestic or household purposes; or (h) the Customer is otherwise in default under this Contract.</p> <p style="margin-left: 40px;">14.3 The Customer may terminate this Contract by not less than seven days’ prior written notice to Australia Post.</p> <p style="margin-left: 40px;">14.4 If Australia Post suspends or terminates the Account under either clauses 14.1 or 14.2, or the Customer terminates this Contract under clause 14.3, the balance of the Account and any amounts incurred but not then billed shall become due and payable by the Customer to Australia Post.</p> <p style="margin-left: 40px;">14.5 (a) If Australia Post suspends or terminates the Account under clauses 14.2(a), (b), (c), (e), (f) or (g), or the Customer terminates this Contract under clause 14.3, the Customer must also pay to Australia Post any amounts reasonably incurred or expended by Australia Post in exercising its rights under the Contract; (b) If Australia Post suspends or terminates the Account under clauses 14.1 or 14.2(d), the Customer must also pay to Australia Post any amounts directly and necessarily incurred by Australia Post in connection with the suspension or termination. For the purposes of this clause 14.5(b), the Customer may request a written summary of the amounts incurred by Australia Post.</p> <p>15. Notice</p> <p style="margin-left: 40px;">15.1 Notices served under the Contract may be delivered by post, or by facsimile to: (a) the Customer – at the postal or facsimile address provided in the Application or notified in writing by the Customer to Australia Post in accordance with clause 13; (b) Australia Post - at its state head office as advised to the Customer in the approval.</p> <p style="margin-left: 40px;">15.2 Notice is taken to be given: (a) in the case of ordinary post, in accordance with Australia Post’s published delivery standards for postal articles between the place of posting and the place of receipt; or (b) in the case of facsimile, the business day following the date of transmission provided that the sender has received confirmation receipt.</p> <p>16. Variation</p> <p style="margin-left: 40px;">16.1 Australia Post may vary the terms and conditions of the Account with respect to future transactions between Australia Post and the Customer: (a) by agreement between Australia Post and the Customer; or (b) unilaterally by Australia Post giving to the Customer not less than seven days’ prior written notice specifying the variation and the date on which the variation becomes effective.</p> <p style="margin-left: 40px;">16.2 Notice of the variation under this clause need not be sent separately and may be sent with the Customer’s statement of account or as part of any other correspondence.</p> <p>17. Assignment</p> <p style="margin-left: 40px;">The Customer must not assign the Contract without the consent in writing of Australia Post, which shall not be unreasonably withheld.</p> <p>18. Waiver</p> <p style="margin-left: 40px;">Failure by either party to enforce its obligations under the Contract does not constitute waiver of that party’s rights unless it is in writing, nor does it affect any other obligation of the other party, including obligations to make any further payments as and when they fall due.</p> <p>19. Governing law</p> <p style="margin-left: 40px;">The Contract is made in the state of Victoria and is governed by the laws in force in that state.</p>';

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
        //return this.termsAndConditions ? this.termsAndConditions : '';
		return this.termsAndConditionsHardCoded;
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