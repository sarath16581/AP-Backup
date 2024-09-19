/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Direct Debit details
* @changelog
* 19/01/2021 Victor.Cheng@auspost.com.au  Created
*
*/
import { LightningElement, wire, api, track } from 'lwc';
import getDirectTC from '@salesforce/apex/BCAFormBase.getDirectTC';
import getDirectDebitTCDownloadURL from '@salesforce/apex/BCAFormBase.getDirectDebitTCDownloadURL';
import validateBSB from '@salesforce/apex/BCAFormBase.validateBSB';

import bcaStepBase from "c/bcaStepBase";
import {
    isNumericInput, isModifierKey
    , BSB_INPUT_ID, BSB_LENGTH, ACCOUNT_NUMBER_INPUT_ID, ACCOUNT_NUMBER_MIN_LENGTH, ACCOUNT_NUMBER_MAX_LENGTH
} from 'c/bcaCommonMethods'

export default class BcaStepDirectDebit extends bcaStepBase {

    bsbInputId = BSB_INPUT_ID;
    bsbLength = BSB_LENGTH + 1;
    accountInputId = ACCOUNT_NUMBER_INPUT_ID;
    accountMinLen = ACCOUNT_NUMBER_MIN_LENGTH;
    accountMaxLen = ACCOUNT_NUMBER_MAX_LENGTH;
    BSB_INVALID_MESSAGE = 'Enter a valid BSB number';


    @track _directDebit = {bsb:''};
    @api get directDebit() {return this._directDebit;}

    // this needs to be true before we continue
    @track bsbValid = false;

    @track errorWhenNotAccepted = 'You must confirm you are authorised to operate on the nominated account in order to proceed';
    @track errorWhenNotAcceptedLabel2 = 'You must agree to the direct debit request service agreement terms and conditions in order to proceed';

    termsAndConditions;
    directDebitTCDownloadURL = '';

	termsAndConditionsHardcoded = '(Knowledge Uplift Test)<table border="1" style="width: 100%; margin-left: -8.8pt; border: none;"> <tbody> <tr> <td colspan="2" rowspan="1" style="width: 239.85pt; height: 70.9pt;"> <p><strong><span> </span></strong></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><span style="">Australia Post Credit Management</span></strong></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><span style="">GPO Box 2137</span></strong></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><span style="">Melbourne VIC 3001</span></strong></p> <p><strong><span> </span></strong></p> </td> <td colspan="1" rowspan="1" style="width: 300.3pt; height: 70.9pt;"> <p><span> </span></p> <p style="margin-left: 0cm;"><strong><span style="font-size: 19px;">Direct Debit Request Service Agreement</span></strong></p> <p><span> </span></p> <p><span> </span></p> </td> </tr> <tr> <td colspan="3" rowspan="1" style="width: 540.15pt;"> <p style="margin-left: 0cm;"><span style="font-size: 12px;">This is your Direct Debit Service Agreement with Australian Postal Corporation, User ID 063802, ABN 28864970579 (the Debit User). It explains what your obligations are when undertaking a Direct Debit arrangement with us. It also details what our obligations are to you as your Direct Debit provider.  </span></p> <p style="margin-left: 0cm;"><span style="font-size: 12px;">Please keep this agreement for future reference. It forms part of the terms and conditions of your Direct Debit Request (DDR) and should be read in conjunction with your DDR authorisation.      </span></p> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <p style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">Definitions</span></p> </td> <td colspan="2" rowspan="1" style="width: 419.6pt;"> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">account</span></em></strong><span style="font-size: 12px;"> means the account held at <em>your financial institution</em> from which <em>we</em> are authorised to arrange for funds to be debited.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">agreement</span></em></strong><span style="font-size: 12px;"> means this Direct Debit Request Service Agreement between <em>you</em> and <em>us</em>.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">banking day</span></em></strong><span style="font-size: 12px;"> means a day other than a Saturday or a Sunday or a public holiday listed throughout Australia.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">debit day</span></em></strong><span style="font-size: 12px;"> means the day that payment by <em>you</em> to <em>us</em> is due.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">debit payment</span></em></strong><span style="font-size: 12px;"> means a particular transaction where a debit is made.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">Direct Debit Request</span></em></strong><span style="font-size: 12px;"> means the written, verbal or online request between <em>us</em> and <em>you</em> to debit funds from your account.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">us </span></em></strong><span style="font-size: 12px;">or <strong><em>we</em></strong> means Australian Postal Corporation, (the Debit User) <em>you</em> have authorised by requesting a <em>Direct Debit Request</em>.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">you</span></em></strong><span style="font-size: 12px;"> means the customer who has authorised the <em>Direct Debit Request</em>.</span></p> <p style="margin-left: 0cm; font-size: 15px;"><strong><em><span style="font-size: 12px;">your financial institution</span></em></strong><span style="font-size: 12px;"> means the financial institution at which you hold the <em>account</em> you have authorised us to debit.</span></p> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm;"><span style="font-size: 12px;">1. Debiting your account</span></div> </td> <td colspan="2" rowspan="1" style="width: 419.6pt;"> <div style="margin-left: 0cm;"> <ol style="list-style-type: decimal;"> <li style="margin-left: 0cm;"><span style="font-size: 12px;">By submitting a Direct Debit Request or by agreeing to the Direct Debit Request by the method presented, you authorise us to arrange for funds to be debited from your account.  The Direct Debit Request and this agreement set out the arrangement between us and you.   </span><br /> <br /> <em><span style="font-size: 12px;">We</span></em><span style="font-size: 12px;"> will only arrange for funds to be debited from <em>your account</em> if <em>we</em> have sent to the address nominated by <em>you</em> in the <em>Direct Debit Request</em>, a billing advice which specifies the amount payable by <em>you</em> to <em>us</em> and when it is due.</span></li> <li style="margin-left: 0cm;"><span style="font-size: 12px;">If the <em>debit day</em> falls on a day that is not a <em>banking day</em>, we may direct <em>your financial institution</em> to debit <em>your account</em> on the following <em>banking day</em>.  If <em>you</em> are unsure about which day <em>your account</em> has or will be debited you should ask <em>your financial institution</em>.</span><span style="font-size: 13px;"> </span></li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">2. Amendments by <em>us</em></span></div> </td> <td colspan="2" rowspan="1" style="width: 419.6pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm;"><em><span style="font-size: 12px;">We</span></em><span style="font-size: 12px;"> may vary any details of this <em>agreement</em> or a <em>Direct Debit Request</em> at any time by giving <em>you</em> at least fourteen <strong>(14) days</strong> written notice sent to the preferred email or address you have given us in the Direct Debit Request.</span></li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">3. How to cancel or change direct debits</span></div> </td> <td colspan="2" rowspan="1" style="width: 419.6pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">You can:</span> <ol start="1" style="list-style-type: lower-alpha; margin-left: 26px;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">Cancel or suspend the Direct Debit Request; or</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">change, stop or defer an individual payment, or at any time by giving us at least </span>two banking <span style="font-size: 12px;">days’ notice.</span></li> </ol> </li> </ol> </div> <p style="margin-left: 18.0pt; font-size: 15px;"><span style="font-size: 12px;">To do so, contact us at</span></p> <p class="MsoListParagraph" style="margin-left: 17.85pt;"><span style="font-size: 12px;">directdebitrequests@auspost.com.au</span></p> <p style="margin-left: 17.85pt; font-size: 15px;"><strong><em><span style="font-size: 12px;">or</span></em></strong></p> <p style="margin-left: 17.85pt; font-size: 15px;"><span style="font-size: 12px;">by telephoning us on 131118 (follow the prompts to Credit Management) during business hours;</span></p> <p style="margin-left: 17.85pt; font-size: 15px;"><strong><em><span style="font-size: 12px;">or </span></em></strong></p> <p style="margin-left: 17.85pt; font-size: 15px;"><span style="font-size: 12px;">You can also contact your own financial institution, which act promptly on your instructions.</span></p> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">4. Your</span></em><span style="font-size: 12px;"> obligations</span></div> </td> <td colspan="2" rowspan="1" style="width: 439.4pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">It is <em>your</em> responsibility to ensure that there are sufficient clear funds available in <em>your</em> account to allow a <em>debit payment</em> to be made in accordance with the <em>Direct Debit Request</em>.</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">If there are insufficient clear funds in <em>your account</em> to meet a <em>debit payment</em>:</span> <ol style="list-style-type: lower-alpha;"> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">you</span></em><span style="font-size: 12px;"> may be charged a fee and/or interest by <em>your financial institution</em>;</span></li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">we may charge you reasonable costs</span></em><span style="font-size: 12px;"> incurred by <em>us on account of there being insufficient funds</em>; and</span></li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">you</span></em><span style="font-size: 12px;"> must arrange for the <em>debit payment</em> to be made by another method or arrange for sufficient clear funds to be in <em>your account</em> by an agreed time so that <em>we</em> can process the <em>debit payment</em>.</span></li> </ol> </li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">You</span></em><span style="font-size: 12px;"> should check <em>your account</em> statement to verify that the amounts debited from <em>your account</em> are correct.</span></li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm;"><span style="font-size: 12px;">5. Dispute</span></div> </td> <td colspan="2" rowspan="1" style="width: 439.4pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">If you believe there has been an error in debiting <em>your account</em>, <em>you</em> should notify us directly on <span style="color: red;"><span style="color: windowtext;">directdebitrequests@auspost.com.au</span></span><strong> </strong>or ph 131118 (please follow the prompts to Credit Management. Alternatively, you can contact your financial institution for assistance.</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">If <em>we</em> conclude as a result of our investigations that <em>your</em> account has been incorrectly debited, <em>we</em> will respond to <em>your</em> query by arranging within a reasonable period for <em>your financial institution</em> to adjust <em>your</em> account (including interest and charges) accordingly.  <em>We</em> will also notify you in writing of the amount by which <em>your account</em> has been adjusted.</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">If <em>we</em> conclude as a result of our investigations that <em>your account</em> has not been incorrectly debited, <em>we</em> will respond to <em>your</em> query by providing <em>you</em> with reasons and any evidence for this finding in writing.</span></li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">6. Accounts</span></div> </td> <td colspan="2" rowspan="1" style="width: 439.4pt;"> <p style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">You</span></em><span style="font-size: 12px;"> should check:</span></p> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: lower-alpha;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">with <em>your financial institution</em> whether direct debiting is available from <em>your account</em> as direct debiting is not available through BECS on all accounts offered by financial institutions.</span></li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">your</span></em><span style="font-size: 12px;"> account details which <em>you</em> have provided to <em>us</em> are correct by checking them against a recent <em>account</em> statement; and</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">with <em>your financial institution</em> before completing the <em>Direct Debit Request</em> if <em>you</em> have any queries about how to complete the <em>Direct Debit Request</em>.</span></li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">7. Confidentiality</span></div> </td> <td colspan="2" rowspan="1" style="width: 439.4pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">We</span></em><span style="font-size: 12px;"> will keep any information (including <em>your account</em> details) in <em>your Direct Debit Request</em> confidential.  <em>We</em> will make reasonable efforts to keep any such information that <em>we</em> have about <em>you</em> secure and to ensure that any of <em>our</em> employees or agents who have access to information about <em>you</em> do not make any unauthorised use, modification, reproduction or disclosure of that information.</span></li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">We</span></em><span style="font-size: 12px;"> will only disclose information that <em>we</em> have about <em>you</em>:</span> <ol style="list-style-type: lower-alpha;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">to the extent specifically required by law; or</span></li> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">for the purposes of this <em>agreement</em> (including disclosing information in connection with any query or claim).</span></li> </ol> </li> </ol> </div> </td> </tr> <tr> <td colspan="1" rowspan="1" style="width: 120.55pt;"> <div style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">8. Contacting each other </span></div> </td> <td colspan="2" rowspan="1" style="width: 439.4pt;"> <div style="margin-left: 0cm; font-size: 15px;"> <ol style="list-style-type: undefined;"> <li style="margin-left: 0cm; font-size: 15px;"><span style="font-size: 12px;">If <em>you</em> wish to notify <em>us</em> in writing about anything relating to this <em>agreement</em>, you should write to:</span> <p style="margin-left: 17.85pt; font-size: 15px;"><span style="font-size: 12px;">directdebitrequests@auspost.com.au</span></p> </li> <li style="margin-left: 0cm; font-size: 15px;"><em><span style="font-size: 12px;">We</span></em><span style="font-size: 12px;"> will notify <em>you</em> by sending a notice to the preferred address or email <em>you</em> have given us in the <em>Direct Debit Request.</em> Any notice will be deemed to have been received on the second <em>banking day</em> after sending.</span></li> </ol> </div> </td> </tr> </tbody> </table> <p style="margin-left: 0cm; font-size: 15px;"><span style=""> </span></p>';

    @wire(getDirectTC)
    wiredDirectTC({ error, data }) {
        if (data) {
            // this.header = data.Header__c;
            this.termsAndConditions = data.Message__c;
        }
    }

    @wire(getDirectDebitTCDownloadURL)
    wiredDirectDebitTCURL({ error, data }) {
        if (data) {
            // this.header = data.Header__c;
            this.directDebitTCDownloadURL = data;
        }
    }

    connectedCallback() {
        if(this.creditAssessment && this.creditAssessment.directDebit)
        {
            this._directDebit = this.creditAssessment.directDebit;
        }
    }

    get applicantOptions() {
        let directorOptions = [];
        if(this.creditAssessment.directors)
        {
             directorOptions = Array.prototype.map.call(this.creditAssessment.directors, (director, index) => {
                let directorName = director.firstName + (director.middleName ? ' ' + director.middleName : '') + ' ' + director.lastName;
                let directorOption = {
                    label: directorName + ' (director)',
                    // forcing it to be a string, lwc radio bug
                    value: this.CONSTANTS.DIRECTOR_PREFIX +  director.index
                };
                return directorOption;
            });
        }

        if(this.creditAssessment.businessContact && this.CONSTANTS.SOMEONE_ELSE_VAL == this.creditAssessment.businessContact.index)
        {
            let contact = this.creditAssessment.businessContact;
            directorOptions.push({
                label: contact.firstName + (contact.lastName ? ' ' + contact.lastName : '') + ' (' + contact.positionTitle + ')',
                value: contact.index
            })
        }

        return directorOptions;
    }


    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;

        switch (field) {
            case this.bsbInputId:
                this.checkBSB(event.target.value);
                event.target.value = this.formatBSB(newValue);
                this._directDebit[field] = this.formatBSB(newValue);
                break;
            case this.accountInputId:
                let sTrimmed = newValue.replace(/\D/g,'');
                event.target.value = sTrimmed.substring(0, this.accountMaxLen);
                this._directDebit[field] = event.target.value;
                break;
            default:
                this._directDebit[field] = newValue;
                break;
        }
    }

    formatBSB = (inputRaw) => {
        let sFormat = inputRaw.replace(/\D/g,'');
        if(sFormat.length > 3)
        {
            let sHead = sFormat.substring(0, 3);
            let sTail = sFormat.substring(3, this.bsbLength - 1);
            sFormat = sHead + '-' + sTail;
        }
        return sFormat;
    }

    checkBSB = (bsbInput) => {
        // set to false, to re-validate
        this.bsbValid = false;

        const bsbTrimmed = bsbInput.replace(/\D/g,'');

        if(bsbTrimmed.length != BSB_LENGTH){
            // bsb incorrect length, don't check
            return;
        }

        validateBSB({bsb: bsbTrimmed})
            .then(result => {
                //console.log('validate bsb:' + bsbTrimmed + ', result = ' + JSON.stringify(result));
                if(result){
                    this.bsbValid = true;
                }
                this.bsbReportValidity();
            })
            .catch(error => {
            });

        return this.bsbValid;
    }

    bsbReportValidity = () => {
        const bsbInput = this.template.querySelector('[data-id="'+ this.bsbInputId + '"]');
        if(!this.bsbValid){
            bsbInput.setCustomValidity(this.BSB_INVALID_MESSAGE);
        }
        else{
            bsbInput.setCustomValidity('');
        }

        //console.log('bsb on blur:' + this.bsbValid);
        bsbInput.reportValidity();
    }

    enforceFormat = (event) => {
        // Input must be of a valid number format or a modifier key
        if (!isNumericInput(event) && !isModifierKey(event)) {
            event.preventDefault();
        }
    };


    get TC() {
        //return this.termsAndConditions ? this.termsAndConditions : '';
		return this.termsAndConditionsHardcoded;
    }


    @api checkAllValidity() {
        //console.log('bsb valid:' + this.bsbValid);
        // update the message separately for BSB
        this.bsbReportValidity();

        return this.checkAllInputCmpValidity(this.template.querySelectorAll('lightning-input:not([data-id="'+ this.bsbInputId + '"])')) &&
        this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="reviewTC"]'), false)
            && this.bsbValid;
    }

}