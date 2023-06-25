/*
/* @author
* @date 2022-07-01
* @group Billing Accounts
* @tag Billing Account
* @description: Rating Plan Activation Request Retry modal popup.
* 				 Used to display a prompt message and retry a callout to Camunda for SAP Integration.
* @changelog
* 2022-07-01 seth.heang@auspost.com.au Created
* 2023-06-15 CI-613arath.burra@auspost.com.au Added ConnectedCallBack to check if Service Commencement Date and Service Expiry Date have been populated
*/
import { LightningElement, api, wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import activateRatingPlan from "@salesforce/apex/CreateBillingAccountController.activateRatingPlan";
import ratingPlanActivationCreationRequest from "@salesforce/apexContinuation/CreateBillingAccountController.ratingPlanActivationCreationRequest";
import checkServiceDatesOnALI from "@salesforce/apex/CreateBillingAccountController.checkServiceDatesOnALI";
import RATING_PLAN_INTEGRATION_STATUS from "@salesforce/schema/Deal_Support_Request__c.Rating_Integration_Status__c";
import RATING_PLAN_INTEGRATION_NOT_CLEAR_ERROR_MSG from '@salesforce/label/c.RatingPlanIntegrationStatusNotClear';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class RetryRatingPlanActivation extends LightningElement {
	@api recordId;
	inProgressSpinner = false;
	displayPromptMsg = true;
	submitRequestInProgress = false;
	submitRequestComplete = false;
	ratingPlanCreationSuccessful = false;
	ratingPlanCalloutFailure = false;
	serviceDatesError=false;
	failedErrMsg = '<h3><b>There seems to be an issue while creating the rating plan activation request.<br/><br/>Please report an IT issue via the \'Report a Fault\' icon on the MyIT Service Portal and select the following details:</b><br/><br/>'+
					'<ul><li>Please select the area this relates to: 2.Applications & Software<br/></li>'+
					'<li>What does this relate to? Salesforce<br/></li>'+
					'<li>What best describes your issue? Received message from Camunda stating that service is currently unavailable<br/></li>'+
					'<li>Can you provide a short description:  SAP Rating Plan Activation integration is not working</li><ul></h3>';
	integrationStatusIsNotCleared = null;
	integrationStausRetryErrorMsg = RATING_PLAN_INTEGRATION_NOT_CLEAR_ERROR_MSG;
	passIntegrationStatusValidation = false;

	/**
	 * @description	wire method to retrieve the DSR record and rating plan integration status field, to be used for validation
	 *  */
	@wire(getRecord, { recordId: '$recordId', fields: [RATING_PLAN_INTEGRATION_STATUS] })
	wiredRatePlanIntegrationStatus({error, data}){
		if(error){
			this.validateIntegrationStatus = false;
		}else if (data) {
			// get rating plan integration status field
			let status = getFieldValue(data, RATING_PLAN_INTEGRATION_STATUS);
			// check status value, if blank then display prompting message and can proceed with trigger a callout
			if(status === null || status === undefined || status === ''){
				this.integrationStatusIsNotCleared = false;
				this.passIntegrationStatusValidation = true;
			}
			// if status value not clear, display validation message and user cannot proceed
			else {
				this.integrationStatusIsNotCleared = true;
				this.passIntegrationStatusValidation = false;
			}
		}
	}

	@api
	connectedCallback(){
		checkServiceDatesOnALI({ dsrId: this.recordId})
		.then(result => {
			this.serviceDatesError = result;
		})
		.catch(error => {
			console.log('Error is: '+error);
		});
	}
	/**
	 * @description	this fuction imperatively call apex methods to generate a request payload with all required mappings, create BAM external onboarding request
	 * 				and finally trigger a callout to Camunda
	 */
	submitRatingPlanActivationRequest(){
		this.displayPromptMsg = false;
		this.submitRequestInProgress = true;
		this.submitRequestComplete= false;
		this.inProgressSpinner = true;
		// imperatively call apex method to generate a request payload
		activateRatingPlan({ recordId: this.recordId })
			.then(result =>{
				let responseVar = result;
				if(responseVar.connected){
					// imperatively call a continuation apex method to trigger a callout with the payload to Camunda
					ratingPlanActivationCreationRequest({externalOnboardingRequestWithConnectionDetailsVar : JSON.stringify(responseVar), dsrId : this.recordId})
						.then(res =>{
							this.submitRequestComplete= true;
							if(res){
								this.ratingPlanCreationSuccessful = true;
							}else{
								this.ratingPlanCreationSuccessful = false;
								this.ratingPlanCalloutFailure = true;
							}
							this.inProgressSpinner = false;
							this.submitRequestInProgress = false;
						})
						.catch(err =>{
							console.log('Error while making call out:::', err);
						})
				}else{
					// mock connection
					this.submitRequestInProgress = false;
					this.submitRequestComplete= true;
					this.ratingPlanCreationSuccessful = true;
					this.inProgressSpinner = false;
				}
			})
			.catch(error =>{
				console.log('Error in creating onboarding request:::',error);
			})
	}

	/**
	 * @description handle the closing action of the pop-up modal and revert changes on UI.
	 */
	handleCloseModal(){
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}