/*
/* @author
* @date 2022-07-01
* @group Billing Accounts
* @tag Billing Account
* @description: Rating Plan Activation Request Creation modal popup.
* 				 Used to display a prompt message and trigger a callout to Camunda for SAP Integration.
* @changelog
* 2022-07-01 seth.heang@auspost.com.au Created
* 2023-06-15 CI-613 sarath.burra@auspost.com.au Added set method to check if Service Commencement Date and Service Expiry Date have been populated
*/
import { LightningElement, api} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import activateRatingPlan from "@salesforce/apex/CreateBillingAccountController.activateRatingPlan";
import checkServiceDatesOnALI from "@salesforce/apex/CreateBillingAccountController.checkServiceDatesOnALI";
import ratingPlanActivationCreationRequest from "@salesforce/apexContinuation/CreateBillingAccountController.ratingPlanActivationCreationRequest";

export default class CreateRatingPlanActivation extends LightningElement {
	inProgressSpinner = false;
	displayPromptMsg = false;
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

	_recordId;
	@api set recordId(value) {
		// to execute only when recordId changes
		if (value!== this._recordId) {
			this._recordId = value;

			// do your thing right here with this.recordId / value
			this.displayRecordId();
		}
	}
	get recordId() {
		return this._recordId;
	}
	displayRecordId(){
		checkServiceDatesOnALI({dsrId:this.recordId})
		.then(result => {
			if(result===true){
				this.displayPromptMsg=false;
				this.submitRequestComplete=true;
				this.serviceDatesError = result;
			}else{
				this.displayPromptMsg=true;
			}

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