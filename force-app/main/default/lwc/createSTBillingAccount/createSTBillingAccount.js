/*
/* @author
 * @date 2021-03-09
 * @group Billing Accounts
 * @tag Billing Account
 * @description: Star Track Billing Account Creation modal popup . Used for showing the attributes/ validation message if exists
 *			   and triggering the billing account creation request.
 * @changelog
 * 2021-03-09 dheeraj.mandavilli@auspost.com.au Created
 * 2023-10-31 - Ranjeewa Silva - Major refactoring of the component.
 *
 */
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { get } from 'c/utils';

// Deal Support Request field mappings
import FIELD_INTEGRATION_STATUS from '@salesforce/schema/Deal_Support_Request__c.Integration_Status__c';

// custom permission granting ability to submit billing account provisioning requests
import PERMISSION_SUBMITPROVISIONREQUESTS from '@salesforce/customPermission/Submit_Billing_Account_Provisioning_Request';

// custom labels
import LABEL_PROVISION_BILLING_ACCOUNT_TITLE from '@salesforce/label/c.StarTrackProvisionNewBillingAccountsModalTitle';
import LABEL_SUBMIT_NONTRANSIENT_ERROR_INSTRUCTIONS from '@salesforce/label/c.StarTrackNewBillingAccountSubmitNonTransientErrorAdditionalInstructions';
import LABEL_SUBMIT_TRANSIENT_ERROR_INSTRUCTIONS from '@salesforce/label/c.StarTrackNewBillingAccountSubmitTransientErrorAdditionalInstructions';
import LABEL_SUBMIT_PERMISSIONS_ERRORMESSAGE from '@salesforce/label/c.SubmitBillingAccountProvisioningRequestPermissionsError';
import LABEL_VALIDATION_FAILED_ERRORMESSAGE from '@salesforce/label/c.StarTrackProvisionNewAccountValidationFailedErrorMessage';
import LABEL_ALREADY_PROVISIONED_ERRORMESSAGE from '@salesforce/label/c.StarTrackBillingAccountsAlreadyProvisionedErrorMessage';
import LABEL_ALREADY_SUBMITTED_ERRORMESSAGE from '@salesforce/label/c.StarTrackBillingAccountRequestAlreadySubmittedErrorMessage';
import LABEL_ALREADY_FAILED_ERRORMESSAGE from '@salesforce/label/c.StarTrackBillingAccountRequestAlreadyFailedErrorMessage';
import LABEL_SUBMIT_TRANSIENT_ERROR_ERRORMESSAGE from '@salesforce/label/c.StarTrackRequestFailedTransientErrorMessage';
import LABEL_SUBMIT_NON_TRANSIENT_ERROR_ERRORMESSAGE from '@salesforce/label/c.StarTrackRequestFailedNonTransientErrorMessage';
import LABEL_SUBMITTED_SUCCESSFULLY_MESSAGE from '@salesforce/label/c.StarTrackBillingAccountRequestSubmittedSuccessfullyMessage';
import LABEL_SUBMITTED_SUCCESSFULLY_INSTRUCTIONS from '@salesforce/label/c.StarTrackBillingAccountRequestSubmittedSuccessfullyAdditionalInstructions';

// apex controller calls
import checkBillingAccountProvisioningPreconditions from '@salesforce/apex/ProvisionSTBillingAccountsController.checkBillingAccountProvisioningPreconditions';
import generateBillingAccountsProvisioningRequest from '@salesforce/apex/ProvisionSTBillingAccountsController.generateBillingAccountsProvisioningRequest';
import submitProvisioningRequest from '@salesforce/apexContinuation/ProvisionSTBillingAccountsController.submitProvisioningRequest';

export default class CreateSTBillingAccount extends LightningElement {

	// expose custom labels used by this component
	label = {
		provisionBillingAccountModalTitle: LABEL_PROVISION_BILLING_ACCOUNT_TITLE,
		submitPermissionsErrorMessage: LABEL_SUBMIT_PERMISSIONS_ERRORMESSAGE,
		validationErrorsPresentMessage : LABEL_VALIDATION_FAILED_ERRORMESSAGE,
		billingAccountsAlreadyProvisionedMessage : LABEL_ALREADY_PROVISIONED_ERRORMESSAGE,
		billingAccountsRequestAlreadySubmittedMessage : LABEL_ALREADY_SUBMITTED_ERRORMESSAGE,
		billingAccountsRequestFailedMessage : LABEL_ALREADY_FAILED_ERRORMESSAGE,
		billingAccountSubmitTransientErrorMessage : LABEL_SUBMIT_TRANSIENT_ERROR_ERRORMESSAGE,
		billingAccountSubmitNonTransientErrorMessage : LABEL_SUBMIT_NON_TRANSIENT_ERROR_ERRORMESSAGE,
		billingAccountSubmittedSuccessfullyMessage : LABEL_SUBMITTED_SUCCESSFULLY_MESSAGE,
		billingAccountSubmittedSuccessfullyAdditionalInfo : LABEL_SUBMITTED_SUCCESSFULLY_INSTRUCTIONS,
		billingAccountSubmitNonTransientErrorAdditionalInfo : LABEL_SUBMIT_NONTRANSIENT_ERROR_INSTRUCTIONS,
		billingAccountSubmitTransientErrorAdditionalInfo: LABEL_SUBMIT_TRANSIENT_ERROR_INSTRUCTIONS
	};

	// record id set by LWC framework
	_recordId;
	@api
	get recordId() { return this._recordId; }
	set recordId(value) {
		if (value && !this._recordId) {
			// received a valid record id. store the record id and initialise the component.
			this._recordId = value;
			this.init();
		}
	}

	// results from pre-conditions check
	preConditionCheckResult;

	// provisioning results. only available after submitting the request.
	provisioningResult;

	// status information displayed to the user at various points. e.g. pre-condition check, submit.
	statusInformation;

	// show spinner indicating current operation is still in progress
	showSpinner;

	/**
	 * Check all pre conditions to initialise the component.
	 */
	init() {
		this.showSpinner = true;
		checkBillingAccountProvisioningPreconditions({dealSupportRequestId: this._recordId})
			.then(result => {
				// store results from pre condition check.
				this.preConditionCheckResult = result;
				const integrationStatus = get(this.preConditionCheckResult, 'dealSupportRequest.' + FIELD_INTEGRATION_STATUS.fieldApiName, null);
				if  (integrationStatus === 'Success') {
					// deal support request had been submitted previously and billing account has already been provisioned.
					// display notification message
					this.setStatusInformation(this.label.billingAccountsAlreadyProvisionedMessage, null, 'success');
				} else if (integrationStatus === 'Requested') {
					// deal support request has been submitted previously and waiting on provisioning request to be completed.
					// display notification message
					this.setStatusInformation(this.label.billingAccountsRequestAlreadySubmittedMessage, null, 'info');
				} else if (integrationStatus === 'Error') {
					// deal support request has been submitted previously and already received an error from external service.
					// display notification message
					this.setStatusInformation(this.label.billingAccountsRequestFailedMessage, null, 'error');
				} else if (!integrationStatus && this.preConditionCheckResult.status === 'PRECONDITIONS_NOT_MET') {
					// deal support request has not met all pre conditions required to submit to external service.
					// display notification with error details
					this.setStatusInformation(this.label.validationErrorsPresentMessage, null, 'error');
				}
				this.showSpinner = false;
			}).catch(error => {
				this.showSpinner = false;
				this.setStatusInformation('Error during pre conditions check : ' + error.body.message, null, 'error');
			});
	}

	handleSubmitRequest(event) {
		this.showSpinner = true;
		generateBillingAccountsProvisioningRequest({dealSupportRequestId: this.recordId})
			.then(result => {
				submitProvisioningRequest({
					request: result.requestPayload,
					externalOnboardingRequestId: result.externalOnboardingRequestId
				}).then(resp => {
					this.provisioningResult = resp;
					if (resp.isSuccess) {
						this.setStatusInformation(this.label.billingAccountSubmittedSuccessfullyMessage, this.label.billingAccountSubmittedSuccessfullyAdditionalInfo, 'info');
					} else if (resp.isRetryable) {
						this.setStatusInformation(this.label.billingAccountSubmitTransientErrorMessage, this.label.billingAccountSubmitTransientErrorAdditionalInfo, 'error');
					} else {
						this.setStatusInformation(this.label.billingAccountSubmitNonTransientErrorMessage, this.label.billingAccountSubmitNonTransientErrorAdditionalInfo, 'error');
					}
					this.showSpinner = false;
				}).catch(error => {
					this.setStatusInformation('Unexpected Error : ' + error.body.message, null, 'error');
					this.showSpinner = false;
				});
			}).catch(error => {
				this.setStatusInformation('Unexpected Error : ' + error.body.message, null, 'error');
				this.showSpinner = false;
			});
	}

	handleCancel(event) {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	/**
	 * Set status information for display
	 */
	setStatusInformation(message, additionalInformation, category) {
		this.statusInformation = {
			message: message,
			additionalInformation: additionalInformation,
			category: category
		}
	}

	get hasPermissionsToSubmitLeaderAccountProvisioningRequests() {
		return PERMISSION_SUBMITPROVISIONREQUESTS;
	}

	get submitVisible() {
		return (!this.provisioningResult || this.provisioningResult.isRetryable);
	}

	get submitDisabled() {
		return !(this.preConditionCheckResult && this.preConditionCheckResult.status === 'READY_FOR_SUBMISSION');
	}

	get hasValidationErrors() {
		return (this.preConditionCheckResult && this.preConditionCheckResult.status === 'PRECONDITIONS_NOT_MET' && this.preConditionCheckResult.errorMessages.length > 0)
	}

	get showRequestDetails() {
		return (this.preConditionCheckResult && this.preConditionCheckResult.status !== 'PREVIOUSLY_SUBMITTED' && (!this.provisioningResult || this.provisioningResult.isRetryable));
	}

	get billingPostCodeDisplayString() {
		// billing post code in request payload is an integer, convert to a string for display
		const postcodeDisplayString = get(this.preConditionCheckResult, 'requestPayload.team.organisations.billingAddress.postcode', '');
		return postcodeDisplayString.toString();
	}

	get statusInformationStyleClass() {
		return (this.statusInformation ? ('slds-scoped-notification slds-media slds-media_center slds-theme_' + this.statusInformation.category): '');
	}

	get statusInformationIconName() {
		return (this.statusInformation ? ('utility:' + this.statusInformation.category): '');
	}

	get cancelButtonLabel() {
		return (this.provisioningResult && this.provisioningResult.isSuccess ? 'Close' : 'Cancel');
	}
}