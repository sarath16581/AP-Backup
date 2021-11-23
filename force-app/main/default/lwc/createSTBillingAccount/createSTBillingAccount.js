/*
/* @author
 * @date 2021-03-09
 * @group Billing Accounts
 * @tag Billing Account
 * @description: Star Track Billing Account Creation modal popup . Used for showing the attributes/ validation message if exists
 *               and triggering the billing account creation request.
 * @changelog
 * 2021-03-09 dheeraj.mandavilli@auspost.com.au Created
 *
 */
import { LightningElement, api, wire, track } from 'lwc';
import billingAccountCreationPreCheck from "@salesforce/apex/CreateBillingAccountControllerForTeams.billingAccountCreationPreCheck";
import generateExternalOnboardingRecord from "@salesforce/apex/CreateBillingAccountControllerForTeams.generateExternalOnboardingRecord";
import billingAccountCreationRequest from "@salesforce/apexContinuation/CreateBillingAccountControllerForTeams.billingAccountCreationRequest";

export default class CreateSTBillingAccount extends LightningElement {
@api recordId;
@track showValidationMessageFlag = false;
@track showSpinner = true;
@track fieldList=[];
@track billingAccount;
@track disableSubmitRequestBtn = false;
@track submitRequestInProgress = false;
@track submitRequestComplete ;
@track dsrStatusAsRequested = false;
@track dsrStatusAsCompleted = false;
@track integrationComplete = false;
@track integrationInitiated = false;
@track billingAccountName ;
@track billingAccountCreationSuccessful;
@track tradingName;
@track legalEntityName;
@track inProgressSpinner = false;
@track senderNameFromOpportunity;
@track failedErrMsg = '<h3><b>Please report an IT issue via the ‘Report a Fault�icon on the MyIT Service Portal and select the following details:</b><br/><br/>'+
        '<ul><li>Please select the area this relates to: 2.Applications & Software<br/></li>'+
        '<li>What does this relate to? Salesforce<br/></li>'+
        '<li>What best describes your issue? Issues with Sales Cloud<br/></li>'+
        '<li>Can you provide a short description: TEAM Charge Account Integration not working </li><ul></h3>';

    connectedCallback() {
        this.validateRequestHandler();
    }
    validateRequestHandler(){
        this.showSpinner = true;
        this.fieldList = [];
        billingAccountCreationPreCheck({recordId: this.recordId})
            .then(result =>{
            if(result){
                let emptyFields = result.emptyAttributesList;
                emptyFields.forEach(fieldName =>{
                    this.fieldList.push(fieldName);
                })
                this.billingAccount  = result.billingAccountAttributesDetails ;
                this.tradingName = result.tradingName;
                this.legalEntityName = result.legalEntityName;
                this.senderNameFromOpportunity = result.senderNameFromOpportunity;
                let integrationStatus = result.integrationStatus;
                if(integrationStatus == 'Success'){
                    this.integrationComplete = true;
                    this.dsrStatusAsCompleted = true;
                    this.submitRequestInProgress = true;
                }else if(integrationStatus == 'Requested'){
                    this.dsrStatusAsRequested = true;
                    this.submitRequestInProgress = true;

                }else if(integrationStatus == 'Error'){
                    this.billingAccountCreationSuccessful = false;
                    this.integrationInitiated = true;
                    this.submitRequestComplete = true;
                    this.submitRequestInProgress = true;
                }
                if(this.senderNameFromOpportunity != null){
                    this.billingAccountName = this.senderNameFromOpportunity.substring(0,25);
                }else if(this.tradingName != null){
                    this.billingAccountName = this.tradingName.substring(0,25);
                }else{
                    this.billingAccountName = this.legalEntityName.substring(0,25);
                }
            }
            if(this.fieldList.length){
            this.showValidationMessageFlag = true;
            this.disableSubmitRequestBtn = true;
        }else{
            this.showValidationMessageFlag = false;
            this.disableSubmitRequestBtn = false;
        }
        this.showSpinner = false;
    })
    .catch(error =>{
            console.log('Error in validating request:::',error);
    })
    }
    submitRequestHandler(){
        this.submitRequestInProgress = true;
        this.submitRequestComplete= false;
        this.integrationInitiated = true;
        this.inProgressSpinner = true;
        generateExternalOnboardingRecord({recordId: this.recordId, billingAccountName: this.billingAccountName})
            .then(result =>{
            let responseVar = result;
        if(responseVar.connected){
            billingAccountCreationRequest({externalOnboardingRequestWithConnectionDetailsVar : JSON.stringify(responseVar)})
                .then(res =>{
                this.submitRequestComplete= true;
            if(res){
                console.log('Inside 1'+res);
                this.billingAccountCreationSuccessful = true;
            }else{
                console.log('Inside 2');
                this.billingAccountCreationSuccessful = false;
            }
            this.inProgressSpinner = false;
        })
        .catch(err =>{
                console.log('Error while call out', err);
        })
        }
        else{
            this.submitRequestComplete= true;
            this.billingAccountCreationSuccessful = true;
            this.inProgressSpinner = false;
        }

    })
    .catch(error =>{
            console.log('Error in creating onboarding request:::',error);
    })

    }
    cancel(){
        this.dispatchEvent(new CustomEvent('close'));
    }
    billingAccountNameHandler(event){
        this.billingAccountName = event.target.value;

    }
}