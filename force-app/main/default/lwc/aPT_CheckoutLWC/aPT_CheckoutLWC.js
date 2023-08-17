/**
*@author	Yatika Bansal
*@date	2023-06-03
*@description	LWC component used within the Lightning-out framework, and is embedded in a VF Page (APT_CheckOut), to be used in the Apttus Shopping cart
*			It is used to create a custom checkout button with multiple actions.
*Change log:9-04-2023 : Nasir Jawed: Added method checkWorkVerification to check work Verification product added on the cart
*			9-04-2023 : Nasir Jawed: Added Getter workForceWithManualAgreement for checkWorkVerification
*			27-07-2023 : Yatika Bansal : Included logic for amend/renew
*			08-08-2023 : Yatika Bansal : Modified checkout only action to redirect to opportunity
*			08-08-2023 : Yatika Bansal : Added delay between operations to avoid locking
*/
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import PROPOSAL_OBJECT from '@salesforce/schema/Apttus_Proposal__Proposal__c';
import Id from '@salesforce/user/Id';
import UserProfileField from '@salesforce/schema/User.Profile.Name';
import LightningAlert from 'lightning/alert';
import viewRateCardControllerError from '@salesforce/label/c.viewRateCardControllerError';
import checkoutOnly from '@salesforce/apex/APT_CheckoutController.checkoutOnly';
import validateConfiguration from '@salesforce/apex/APT_CheckoutController.validateConfiguration';
import creditAndRateCardLogic from '@salesforce/apex/APT_CheckoutController.checkCreditAssessmentAndExecuteRateCardLogic';
import checkWorkVerification from '@salesforce/apex/APT_CheckoutController.checkWorkVerification';
import initiateRateCardGeneration from '@salesforce/apex/APT_CheckoutController.initiateRateCardGeneration';
import docGenerationRequired from '@salesforce/apex/APT_CheckoutController.docGenerationRequired';

import PROP_OPP_FIELD from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c';
import PROP_IS_ST_FIELD from '@salesforce/schema/Apttus_Proposal__Proposal__c.Is_Startrack_Proposal__c';
import PROP_APPROVAL_REQ_STATUS from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_Proposal__Approval_Stage__c';
import PROP_ACCOUNT_ROLE_TYPE from '@salesforce/schema/Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__r.Role_Type_Roll_Up__c';
import PROP_RT_ID from '@salesforce/schema/Apttus_Proposal__Proposal__c.RecordTypeId';

export default class APT_CheckoutLWC extends LightningElement {

	@api configId;	//receive as paramenters from VF Page
	@api proposalId;	//receive as paramenters from VF Page
	@api workVerification;

	isLoading;
	error;
	isST;
	oppId;
	accountRoleType;
	showManualAggBtn;
	manualContract = false;
	approvalReqStage = 'Approval Required';
	inReviewStage = 'In Review';
	customerOnboardingUserProfile = 'Enterprise Onboarding';
	validateConfigMsg = 'The product(s) in this shopping cart requires pricing to be configured before you can checkout.';
	rateCardBatchUrl = '/apex/c__APT_ViewRatecardBatchExecute?id=';
	contractServiceDetailsUrl = '/lightning/cmp/c__APT_ContractServiceDetailsWrapper?c__proposalId=';
	credAssessPromptMsg = 'Prospect customer requires credit assessment to be completed and approved prior generating contract document. Click "OK" to submit credit assessment.';
	approvalReqErrorMsg = 'You can checkout after the approval request is approved';
	waitTime = 10000;
	amendRecordType = 'Amendment Quote';
	amendRecordTypeId;
	isAmend;
	isRenew;
	renewRecordType = 'Renewal Quote';
	renewRecordTypeId;

	@api
	get errorMsg() {
		//Disable Buttons in case of error
		if (this.error) {
			this.template.querySelector('[data-id = "disableSection"]').classList.add('disableSection');
		}
		return this.error;
	}

	set errorMsg(value) {
		this.error = value;
	}

	get workForceWithManualAgreement(){
		return (this.workVerification && this.showManualAggBtn);
	}

	connectedCallback(){
		this.isLoading = true;

		//function to show error if the cart's configuration is pending
		validateConfiguration({ configId: this.configId })
		.then((result) => {
			if (result !== 'success') {
				this.error = this.validateConfigMsg ;
			}

			this.isLoading = false;
		})
		.catch((error) => {
			this.error = error;
			this.isLoading = false;
		});


		checkWorkVerification({configId : this.configId})
		.then((result) => {
			if(result === true){
				this.workVerification = false;
			} else
			{
				this.workVerification = true;
			}
		})
		.catch((error) => {
			this.error = error;
		});
	}

	/**
	*Wire function to retrieve proposal record fields
	*/
	@wire(getRecord, { recordId: '$proposalId', fields: [PROP_OPP_FIELD, PROP_IS_ST_FIELD, PROP_APPROVAL_REQ_STATUS, PROP_ACCOUNT_ROLE_TYPE, PROP_RT_ID] })
	getProposal({data, error}){
		if(data){
			if(getFieldValue(data, PROP_RT_ID) === this.amendRecordTypeId){
				this.isAmend = true;
			}else if(getFieldValue(data, PROP_RT_ID) === this.renewRecordTypeId){
				this.isRenew = true;
			}
			let approvalStage = getFieldValue(data, PROP_APPROVAL_REQ_STATUS);
			if(approvalStage === this.approvalReqStage || approvalStage === this.inReviewStage){
				this.error = this.approvalReqErrorMsg;
			}
			else {
				this.isST = getFieldValue(data, PROP_IS_ST_FIELD);
				this.oppId = getFieldValue(data, PROP_OPP_FIELD);
				this.accountRoleType = getFieldValue(data, PROP_ACCOUNT_ROLE_TYPE);
			}
		} else if(error){
			this.error = error;
		}
	}

	/**
	*Wire function to retrieve proposal record types
	*/
	@wire(getObjectInfo, { objectApiName: PROPOSAL_OBJECT })
	objectInfo({ error, data }) {
		if (data) {
			const rtis = data.recordTypeInfos;
			this.amendRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === this.amendRecordType);
			this.renewRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === this.renewRecordType);
		} else if (error) {
			this.error = error;
		}
	}

	/**
	*function to show Manual Agreement button for user profile Customer Onboarding
	*/
	@wire(getRecord, { recordId: Id, fields: [UserProfileField] })
	currentUserInfo({ error, data }) {
		if (data) {
			if (getFieldValue(data, UserProfileField) === this.customerOnboardingUserProfile) {
				this.showManualAggBtn = true;
			}

		} else if (error) {
			this.error = error;
		}
	}

	/**
	*function to finalize cart and generate proposal document
	*@param configId
	*@param proposalId
	*/
	genProposal() {
		this.isLoading = true;
		checkoutOnly({ configId: this.configId })
			.then((result) => {
				if (result === 'success') {
					//some delay before proposal generation to avoid lock error
						this._interval = setTimeout(() => {
						this.isLoading = false;
						this.navigateToUrl( this.rateCardBatchUrl + this.proposalId + '&isRCCall=false');
					}, this.waitTime);
				} else {
					this.error = result;
					this.isLoading = false;
				}
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
			});
	}

	/**
	*function will request to initiate proposal document generation
	*@param proposalId
	*/
	initiateProposalDocGeneration(proposalIdValue) {
		this.isLoading = true;
		initiateRateCardGeneration({ proposalId: proposalIdValue })
			.then((result) => {
				if(result === true){
					//some delay before proposal generation to avoid lock error on proposal
					this._interval = setTimeout(() => {
						this.isLoading = false;

						//Show contract and service section		
						this.navigateToUrl(this.contractServiceDetailsUrl + this.proposalId + '&c__isST=' + this.isST + '&c__isManualContract=' + this.manualContract + '&c__isAmend=' + this.isAmend + '&c__isRenew=' + this.isRenew);
						this.error = viewRateCardControllerError;
						this.isLoading = false;
					}, this.waitTime);
				}

			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
		});
	}

	/**
	*function will check if document generation is required
	*/
	docGenerationRequired() {
		this.isLoading = true;
		docGenerationRequired({ configId : this.configId })
			.then((result) => {
				//some delay to ensure creation of proposal line items
				this._interval = setTimeout(() => {
					if(result === true){
						//request proposal doc generation request
						this.initiateProposalDocGeneration(this.proposalId);
					}else{
						//Show contract and service section			
						this.navigateToUrl(this.contractServiceDetailsUrl + this.proposalId + '&c__isST=' + this.isST + '&c__isManualContract=' + this.manualContract + '&c__isAmend=' + this.isAmend + '&c__isRenew=' + this.isRenew);
						this.isLoading = false;
					}
				}, this.waitTime);
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
		});
	}

	/**
	*function to finalize cart and generate agreement document
	*@param proposalId
	*/
	genAgreement() {
		this.isLoading = true;
		checkoutOnly({ configId: this.configId })
			.then((result) => {
				if (result === 'success') {
					//if respcted organization account role type 'Prospect'; i.e. need to go through with creditAssessment check
					if(this.accountRoleType === 'Prospect') {
						this.creditAssessAndRateCardLogic();
					}
					else {
						//checks if doc generation is required
						this.docGenerationRequired();
					}

				} else {
					this.error = result;
				}
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
			});
	}

	/**
	*function to check credit assessment status and execute rate card logic
	*@param proposalId
	*/
	creditAssessAndRateCardLogic() {
		creditAndRateCardLogic({ proposalId: this.proposalId })
			.then((result) => {
				if (result === 'Incomplete') {
					//prompt to complete cred assess
					LightningAlert.open({
						message: this.credAssessPromptMsg,
						theme: 'info',
						label: "Credit Assessment"
					}).then(() => {
						//navigate to opp to complete cred assess
						this.navigateToUrl('/' + this.oppId);
					});
				}
				else if (result === 'Complete') {

					//Show contract and service section
					this.navigateToUrl(this.contractServiceDetailsUrl + this.proposalId + '&c__isST=' + this.isST + '&c__isManualContract=' + this.manualContract + '&c__isAmend=' + this.isAmend + '&c__isRenew=' + this.isRenew);
				}
				else {
					this.error = result;
				}

				this.isLoading = false;
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
			});
	}

	/**
	*function to redirect to contract record page for manual process
	*/
	genManualAgreement() {
		this.manualContract = true;
		this.genAgreement();
	}

	/**
	*function to finalize cart and redirect to proposal record page
	*@param configId
	*/
	checkoutOnly() {
		this.isLoading = true;

		checkoutOnly({ configId: this.configId })
			.then((result) => {
				if (result === 'success') {
					this.navigateToUrl('/' + this.oppId);
				} else {
					this.error = result;
				}

				this.isLoading = false;
			})
			.catch((error) => {
				this.error = error;
				this.isLoading = false;
			});
	}

	/*
	*function to navigate to any url passed by sending an event to VF page
	*@param targetUrl
	*/
	navigateToUrl(targetUrl) {
		const detail = {
			url: 'https://' + window.location.host + targetUrl
		};
		this.dispatchEvent(new CustomEvent(
			'navigateToUrl',
			{
				detail: detail,
				bubbles: true,
				composed: true,
			}
		));
	}
}