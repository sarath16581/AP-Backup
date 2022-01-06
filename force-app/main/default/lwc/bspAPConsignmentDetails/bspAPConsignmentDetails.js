/*
14.05.2021    Madhuri Awasthi - REQ2481513 BSP redirect/recalll field name changes
*/
import { LightningElement, api, track} from 'lwc';
import {checkAllValidity, checkCustomValidity, topGenericErrorMessage, valueMissingErrorMsg, replaceAddressString} from "c/bspCommonJS";
import submitRedirect from '@salesforce/apex/BSPConsignmentSearchUplift.submitRedirect';
import {NavigationMixin} from "lightning/navigation";

const titleRedirect = 'Redirect this parcel';
const titleRecall = 'Recall this parcel';
const buttonRecall = 'Recall';
const buttonRedirect = 'Redirect';
const recallInProgressMessage = 'Recall/Redirect is already in progress';

export default class BspAPConsignmentDetails extends NavigationMixin(LightningElement) {

    @api selectedConsignmentSearchType;   //-- may not need as in parent enabling this cmp for only 'Au Post' article
    @track singleConsignment;

    @api APConsignmentLodgementDate;
    @api APConsignmentExpDeliveryDate;
    @api APConsignmentSubProduct;
    @api destination;
    @api isConsignmentAuthenticated;
    //@api consignmentEvents;
    @api consignmentNumber;

    @track showSpinner = false;

    // recall/redirect - merged here due to complexity in getting a hidden lwc to be selectable
    @api recallInProgress = false;
    @api recallAuthenticated = false;
    @track recallRedirectCreated = false;
    @track recallRedirectError;
    @track showRecallRedirectSpinner = false;
    @track showRecallRedirect = false;
    @track recallOrRedirect;
    @track recallOrRedirectButtonDisabled = false;
    //@track articleId = 'a1h1y0000005jIeAAI';
    @track articleId = '';
    recallBtnId = buttonRecall;
    redirectBtnId = buttonRedirect;
    @track recallRedirectBtnTitle;
    @track recallRedirectTitle;
    @track recallRedirectName;
    @track recallRedirectCompany;
    @track recallRedirectAddress;
    @track missingValueMessage = valueMissingErrorMsg;
    @track createdCase;
    @api submitCallback;
    //New fields to recall and redirect labels
    @track redirectLabelName;
    @track redirectLabelCompanyName;
    @track redirectLabelAddress;

    showTermsAndConditions = false;

    @api get singleCon() {return this.singleConsignment};
    set singleCon(value) {
        this.singleConsignment = value;
        this.articleId = this.singleConsignment.Id;
        //console.log('single consignment = ' + JSON.stringify(this.singleConsignment));
    }

    get isExternalTrackingURLPresent(){
        return this.singleCon ? (this.singleCon.ExternalTrackingURL__c !=null ? true : false) : false;
    }

    get recallDescription(){
        //console.log('Recall : ' + this.recallInProgress);
        if(this.recallInProgress)
        {
            this.recallOrRedirectButtonDisabled = true;
            return recallInProgressMessage;
        } else if(! this.recallAuthenticated){
            this.recallOrRedirectButtonDisabled = true;
            return 'We are unable to recall this parcel online at the moment. Please create an enquiry, select RTS and we will be in touch to confirm if we can process your request.'
        }
        return 'Have parcels that are in-transit returned to you. Your contracted return to sender charge applies';
    }

    get redirectDescription(){
        //console.log('redirect : ' + this.recallInProgress);
        if(this.recallInProgress)
        {
            this.recallOrRedirectButtonDisabled = true;
            return recallInProgressMessage;
        } else if(! this.recallAuthenticated){
            this.recallOrRedirectButtonDisabled = true;
            return 'We are unable to redirect this parcel online at the moment. Please create an enquiry, select RTS and we will be in touch to confirm if we can process your request';
        }
        return 'Update or correct the address on this parcel. This will add at least 1 day to the delivery time. Your contracted return to sender charge applies';
    }

    get formattedReceiverAddress(){
        return this.singleCon.ReceiverAddress__c ? this.singleCon.ReceiverAddress__c.replace(/,/g,', ') : '';
    }

    get formattedSenderAddress(){
        return this.singleCon.SenderAddress__c ? this.singleCon.SenderAddress__c.replace(/,/g,', ') : '';
    }
    

    // Recall Redirect
    onClickRecallRedirect(event) {
        this.showSpinner = true;

        const field = event.target.dataset.id;
        this.recallOrRedirect = field;
        this.showRecallRedirect = true;
        this.initRedirectPopup();

        //const popupCmp = this.template.querySelector('c-bsp-popup-redirect');
        //popupCmp.setRecallOrRedirect(this.recallOrRedirect);

        // set the article id
        //popupCmp.setArticleId(this.articleId);
        //popupCmp.setArticleId('a1h1y0000005jIdAAI');
       // need to show it before queryselector will find it
    }

    initRedirectPopup() {
        this.createdCase = null;
        this.recallRedirectCreated = false;
        this.recallRedirectError = '';
       // this.recallRedirectName = this.singleConsignment.SenderName__c;
       // this.recallRedirectCompany = this.singleConsignment.SenderCompany__c;

        if(this.recallOrRedirect == buttonRedirect)
        {
            // redirect
            this.recallRedirectTitle = titleRedirect;
            this.recallRedirectBtnTitle = buttonRedirect;

            //redirect label
            this.recallRedirectName = this.singleConsignment.ReceiverName__c;
            this.recallRedirectCompany = this.singleConsignment.ReceiverCompany__c;
            this.redirectLabelName = 'Recievers Name';
            this.redirectLabelCompanyName = 'Recievers Business Name';
            this.redirectLabelAddress = 'Recievers Address';

            // blank for redirect
            this.recallRedirectAddress = null;
        }
        else
        {
            // recall
            this.recallRedirectTitle = titleRecall;
            this.recallRedirectBtnTitle = buttonRecall;

            this.recallRedirectName = this.singleConsignment.SenderName__c;
            this.recallRedirectCompany = this.singleConsignment.SenderCompany__c;
            this.redirectLabelName = 'Senders Name';
            this.redirectLabelCompanyName = 'Senders Business Name';
            this.redirectLabelAddress = 'Senders Address';

            // if recall, prepopulate with the sender address
            this.recallRedirectAddress = {
                addressLine1: this.singleConsignment.SenderAddressLine1__c,
                addressLine2: this.singleConsignment.SenderAddressLine2__c,
                city: this.singleConsignment.SenderCity__c,
                state: this.singleConsignment.SenderState__c,
                postcode: this.singleConsignment.SenderPostcode__c,
                countryCode: this.singleConsignment.SenderCountry__c
            };
        }

        // cannot call queryselector to get the address search, due to rendering times
    }

    getAddressComp() {
        return this.template.querySelectorAll('c-bsp-address-search')[0];
    }

    handleManualChange(event) {}
    handleAddressChange(event) {}

    onChangeRecallRedirectField(event) {
        const field = event.target.dataset.id;
        switch(field)
        {
            case 'recallRedirectName':
                this.recallRedirectName = event.detail.value;
                break;
            case 'recallRedirectCompany':
                this.recallRedirectCompany = event.detail.value;
                break;
        }
    }

    handleFocusOut(event) {
        this.checkValidationOfField(event.target.dataset.id);
    }

    checkValidationOfField(datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        //--Checking the custom validation on change of a field value
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0]);
        }
    }

    onCancelRecallRedirect (event){
        this.showRecallRedirect = false;
        this.showSpinner = false;
    }

    onSubmitRecallRedirect(event){
        this.showRecallRedirectSpinner = true;

        // form validation
        const inputComponents = this.template.querySelectorAll('[data-validate="recallRedirect"]');
        const addressCmp = this.template.querySelectorAll('[data-validate="doAddressValidate"]');
        //console.log('input check ' + checkAllValidity(addressCmp, false));
        const allValid = checkAllValidity(inputComponents) & checkAllValidity(addressCmp, false);

        this.recallRedirectError = '';
        if (!allValid) {
            //alert('Please update the invalid form entries and try again.');
            this.showRecallRedirectSpinner = false;
            this.recallRedirectError = topGenericErrorMessage;
            return;
        }

        let boolRecall = false;
        if(this.recallOrRedirect == buttonRecall)
            boolRecall = true;

        const addressSearch = this.getAddressComp();
        let addressObj = addressSearch.address;
        console.log(JSON.stringify(addressObj));

        // pass the correct format to apex
        let redirectDetails = {
            Name: this.recallRedirectName,
            Company: this.recallRedirectCompany,
            AddressLine1:addressObj.addressLine1,
            AddressLine2:addressObj.addressLine2? addressObj.addressLine2:'',
            City:addressObj.city,
            State:addressObj.state,
            Postcode:addressObj.postcode,
            Country:addressObj.countryCode
        };

        console.log('sending to apex');
        console.log(redirectDetails);

        submitRedirect({
            articleId: this.articleId,
            isRecall: boolRecall,
            redirectDetails: redirectDetails
        }).then(result =>{
            console.log('on submitRedirect return')
            console.log(JSON.stringify(result));


            // success
            this.showRecallRedirectSpinner = false;
            this.recallRedirectCreated = true;
            this.createdCase = result.Enquiry;
        }).catch(error => {
            console.error(error);
            this.showRecallRedirectSpinner = false;
            this.recallRedirectError = error.body.message;
            
        });

    }

    onCloseCaseCreated(event)
    {
        if(this.submitCallback)
        {
            console.log('submit callback');
            this.submitCallback();
        }
    }


    // on successfult creation
    navigateToCaseDetails(event)
    {
        this[NavigationMixin.GenerateUrl]({
            type: 'comm__namedPage',
            attributes: {
                name: 'BSP_Enquiry_Details__c'
            },
            state: {
                enquiryNumber: this.createdCase.CaseNumber
            }
        }).then(generatedUrl => {
            window.open(generatedUrl, "_blank");
        });
    }

    onclickTermsAndConditions(){
        this.showTermsAndConditions = true;

    }

    closeTermsAndConditions(){
        this.showTermsAndConditions = false;
    }

}