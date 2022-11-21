/*
/* @author 
 * @date 2020-11-12
 * @group Billing Accounts
 * @tag Billing Account
 * @description: Billing Account Creation modal popup . Used for showing the attributes/ validation message if exists
 *               and triggering the billing account creation request.
 *               This component is used for creation of Auspost Billing account through SAP Integration.
 * @changelog
 * 2020-11--12 arjun.singh@auspost.com.au Created
 * 2021-05--12 seth.heang@auspost.com.au Added Modal Popup for Billing & Sub Account Request Creation
 */  
import { LightningElement, api, wire, track } from 'lwc';
import billingAccountCreationPreCheck from "@salesforce/apex/CreateBillingAccountController.billingAccountCreationPreCheck"; 
import generateExternalOnboardingRecord from "@salesforce/apex/CreateBillingAccountController.generateExternalOnboardingRecord"; 
import billingAccountCreationRequest from "@salesforce/apexContinuation/CreateBillingAccountController.billingAccountCreationRequest"; 

export default class CreateBillingAccount extends LightningElement {
    @api recordId;
    @track showValidationMessageFlag = false;
    @track showSpinner = true;
    @track fieldList=[];
    @track billingAccount;
    @track disableSubmitRequestBtn = false;
    @track submitRequestInProgress = false;
    @track submitRequestComplete ;
    @track dsrStatusAsRequested = false
    @track dsrStatusAsCompleted = false
    @track integrationComplete = false;
    @track integrationInitiated = false;
    @track billingAccountName ;
    @track billingAccountCreationSuccessful;
    @track tradingName;
    @track legalEntityName;
    @track inProgressSpinner = false;
    @track isChargeAndSubAccountFlow;
    @track subAccountCount;
    @track senderNameFromOpportunity;
    @track failedErrMsgChargeOnlyFlow = '<h3><b>There seems to be an issue while creating the billing account.<br/><br/>Please report an IT issue via the ‘Report a Fault�icon on the MyIT Service Portal and select the following details:</b><br/><br/>'+
                      '<ul><li>Please select the area this relates to: 2.Applications & Software<br/></li>'+
                      '<li>What does this relate to? Salesforce<br/></li>'+
                      '<li>What best describes your issue? Received message from Camunda stating that service is currently unavailable<br/></li>'+
                      '<li>Can you provide a short description:  SAP charge account integration not working</li><ul></h3>';
    @track failedErrMsgChargeAndSubFlow = '<h3><b>There seems to be an issue while creating the billing account and sub account.<br/><br/>Please report an IT issue via the ‘Report a Fault�icon on the MyIT Service Portal and select the following details:</b><br/><br/>'+
                      '<ul><li>Please select the area this relates to: 2.Applications & Software<br/></li>'+
                      '<li>What does this relate to? Salesforce<br/></li>'+
                      '<li>What best describes your issue? Received message from Camunda stating that service is currently unavailable<br/></li>'+
                      '<li>Can you provide a short description:  SAP Billing Account & Sub Account integration not working</li><ul></h3>';         
                      
    connectedCallback() {
        this.validateRequestHandler();
    }
    validateRequestHandler(){
        this.showSpinner = true;
        this.fieldList = [];
        billingAccountCreationPreCheck({recordId: this.recordId})
            .then(result =>{
                if(result){
                    console.log(JSON.stringify(result));
                    let emptyFields = result.emptyAttributesList;
                    emptyFields.forEach(fieldName =>{
                        this.fieldList.push(fieldName);
                    }) 

                    this.billingAccount  = result.billingAccountAttributesDetails;
                    this.isChargeAndSubAccountFlow = result.hasSubAccount;
                    this.subAccountCount = result.subAccountCount;
                    
                    this.tradingName = result.tradingName;
                    this.legalEntityName = result.legalEntityName; 
                    this.senderNameFromOpportunity = result.senderNameFromOpportunity;
                    let integrationStatus = result.integrationStatus; 
                    // Success and Partial Success status
                    if(integrationStatus == 'Success' || integrationStatus == 'Partial Success'){  
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
                        this.billingAccountName = this.senderNameFromOpportunity.substring(0,40);
                    }else if(this.tradingName != null){
                        this.billingAccountName = this.tradingName.substring(0,40);
                    }else{
                        this.billingAccountName = this.legalEntityName.substring(0,40);
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
                                this.billingAccountCreationSuccessful = true;
                            }else{
                                this.billingAccountCreationSuccessful = false;
                            }
                            this.inProgressSpinner = false;
                        })
                        .catch(err =>{
                            console.log('Error while call out', err);
                        })
                }else{
                    this.submitRequestComplete= true;
                    this.billingAccountCreationSuccessful = true;
                    this.inProgressSpinner = false;
                }
                
            })
            .catch(error =>{
                console.log('Error in ceating onboarding request:::',error);
            })
            
    }
    cancel(){
        this.dispatchEvent(new CustomEvent('close'));
    }
    billingAccountNameHandler(event){
        this.billingAccountName = event.target.value;
    }
}