/**
 * @author Naveen Rajanna
 * @date 2023-03-17
 * @description SMWD-397 - lwc to display incomingLicence, facility and outgoingLicence details,
 * 				carry out validations prior to activating incomingLicence
 * 				Invoked from PartnerInfoLicenceActivationWrapper visualforce page using lgtng:out
 * @changelog
 * 2024-06-15	Snigdha Sahu : REQ3429628 : Add validation for Incent Cred to be populated for nominated contact on parent org.
 */
import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { isUndefinedOrNull, formatDate } from 'c/utils';

// server calls
import fetchInitDetails from '@salesforce/apex/PartnerInfoLicenceActivationController.fetchInitDetails';
import updateLicences from '@salesforce/apex/PartnerInfoLicenceActivationController.updateLicences';

// custom labels
import LABEL_FACILITY_NOTFOUND_MESSAGE from '@salesforce/label/c.PartnerInfoFacilityNotFoundMessage';
import LABEL_OUTGOINGLICENCE_NOTFOUND_MESSAGE from '@salesforce/label/c.PartnerInfoOutgoingLicenceNotFoundMessage';
import LABEL_ACTIONBUTTON_DISABLED_MESSAGE from '@salesforce/label/c.PartnerInfoActionButtonDisabledMessage';
import LABEL_ACTIVATION_SUCCESS_MESSAGE from '@salesforce/label/c.PartnerInfoActivationSuccessMessage';
import LABEL_INFOBANNER_MESSAGE from '@salesforce/label/c.PartnerInfoInfoBannerMessage';
import LABEL_ACTIVATION_CONFIRM_MESSAGE from '@salesforce/label/c.PartnerInfoActivationConfirmMessage';
import LABEL_ACTIVATION_CONFIRM_LABEL from '@salesforce/label/c.PartnerInfoActivationConfirmLabel';
import LABEL_GENERIC_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoGenericErrorMessage';
import LABEL_LICENCESTATUS_INVALID_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoLicenceStatusInvalidErrorMessage';
import LABEL_ASSIGNMENTDATE_INVALID_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoAssignmentDateInvalidErrorMessage';
import LABEL_SAPVENDORIDPARENTABN_MISSING_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoSAPVendorIdParentABNMissingErrorMessage';
import LABEL_FACILITYWCC_MISSING_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoFacilityWCCMissingErrorMessage';
//REQ3429628
import LABEL_INCENTCRED_INVALID_ERROR_MESSAGE from '@salesforce/label/c.PartnerInfoIncentCrentialsInvalidErrorMessage';
// custom permission access for the logged in user
// as the lwc usage is in classic runtime via lgtng:out, OOTB Salesforce Insufficient Privileges error will be thrown if no access
// In future upon migration to lightning, below Custom Permission to be made used to perform access check.
// import CUSTOM_PERMISSION_ACCESS from '@salesforce/customPermission/PartnerInfoLicenceActivationAccess';

const CONSTANTS = {
	LICENCE_STATUS_APPROVED: 'Approved',
	LICENCE_STATUS_ACTIVE: 'Active',
	TOAST_CLASS_STYLE: 'slds-notify slds-notify_toast ',
};

export default class PartnerInfoLicenceActivation extends LightningElement {
	@api recordId; // record Id for incomingLicence
	@track data; // wrapper data retrieved from server
	isLoading = false; // flag to show/hide the spinner
	updateSuccessful = false; // flag to specify if update server call was succesful
	hasPageErrors = false; // flag to specify if any page errors
	errorMessages = []; // collection to store all validation errors
	toastMessage = {
		// custom object to show/hide toastMessage
		show: false,
		type: '',
		message: '',
	};

	// getters
	get showFacilityNotFoundError() {
		return isUndefinedOrNull(this.data.facility) ? LABEL_FACILITY_NOTFOUND_MESSAGE : '';
	}
	get showOutgoingLicenceNotFoundError() {
		return this.isOutgoingLicenceNotFound() ? LABEL_OUTGOINGLICENCE_NOTFOUND_MESSAGE : '';
	}
	get showInfoBanner() { // Show Info banner - when there is no Validation Errors and there is an Active Outgoing Licence
		return this.errorMessages.length === 0 && !this.isOutgoingLicenceNotFound() && !isUndefinedOrNull(LABEL_INFOBANNER_MESSAGE);
	}
	get infoBannerText() {
		return LABEL_INFOBANNER_MESSAGE;
	}
	get showErrorMessages() {
		return this.errorMessages.length > 0;
	}
	get actionButtonDisabled() {
		return this.hasPageErrors || this.errorMessages.length > 0;
	}
	get actionButtonDisabledText() {
		return LABEL_ACTIONBUTTON_DISABLED_MESSAGE;
	}
	get toastMessageClass() {
		return CONSTANTS.TOAST_CLASS_STYLE + 'slds-theme_' + this.toastMessage.type;
	}
	get facilityNameURL() {
		return this.data.domainURL + '/' + this.data.facility.Id;
	}
	get facilityState() {
		return this.data.facility.Network_Facility__r?.State__c;
	}
	get incomingLicenceNameURL() {
		return this.data.domainURL + '/' + this.data.incomingLicence.Id;
	}
	get incomingLicenceCreatedByURL() {
		return this.data.domainURL + '/' + this.data.incomingLicence.CreatedBy?.Id;
	}
	get incomingLicenceLastModifiedByURL() {
		return this.data.domainURL + '/' + this.data.incomingLicence.LastModifiedBy?.Id;
	}
	get outgoingLicenceNameURL() {
		return this.data.domainURL + '/' + this.data.outgoingLicence.Id;
	}
	get outgoingLicenceCreatedByURL() {
		return this.data.domainURL + '/' + this.data.outgoingLicence.CreatedBy?.Id;
	}
	get outgoingLicenceLastModifiedByURL() {
		return this.data.domainURL + '/' + this.data.outgoingLicence.LastModifiedBy?.Id;
	}

	connectedCallback() {
		this.init();
	}

	renderedCallback() {
		if (this.updateSuccessful) {
			window.location.assign('/' + this.data.incomingLicence.Id); // redirect back to incomingLicence record page
		}
	}

	/**
	 * upon page load initialise by making server call to fetch request details - incomingLicence, facility and outgoingLicence
	 */
	init() {
		this.isLoading = true; // show spinner
		fetchInitDetails({ incomingLicenceId: this.recordId })
			.then((result) => {
				if (result != null) {
					console.log(result);
					this.data = result; // store the fetched wrapper data
					this.validate(); // perform validations and store errors in errorMessages
				} else {
					console.error('Server call returned null');
					this.hasPageErrors = true; // set flag to true to denote page errors
					this.setToastMessage('error', LABEL_GENERIC_ERROR_MESSAGE); // show error toast message
				}
				this.isLoading = false; // hide spinner
			})
			.catch((error) => {
				console.error('error : ', error);
				this.hasPageErrors = true; // set flag to true to denote page errors
				this.setToastMessage('error', LABEL_GENERIC_ERROR_MESSAGE); // show error toast message
				this.isLoading = false; // hide spinner
			});
	}

	/**
	 * as the lwc usage is in classic runtime using custom toast against the lightning ShowToastEvent or sforce showToast
	 */
	setToastMessage(type, message) {
		this.toastMessage = {
			show: true,
			type: type,
			message: message,
		};
	}

	/**
	 * specify outgoingLicence Not Found if either of below
	 * 1. When outgoingLicence is undefined
	 * 3. When outgoingLicence LicenceStatus is not Active
	 * 2. When outgoingLicence is same as incomingLicence
	 */
	isOutgoingLicenceNotFound() {
		return (
			isUndefinedOrNull(this.data.outgoingLicence) ||
			this.data.outgoingLicence.Id === this.data.incomingLicence.Id ||
			this.data.outgoingLicence.Licence_Status__c !== CONSTANTS.LICENCE_STATUS_ACTIVE
		);
	}

	/**
	 * perform all the business validation checks required and store all errors in errorMessages
	 */
	validate() {
		// incomingLicence Licence Status is not in approved status - show error and no need to perform further checks
		if (this.data.incomingLicence.Licence_Status__c !== CONSTANTS.LICENCE_STATUS_APPROVED) {
			this.errorMessages.push(LABEL_LICENCESTATUS_INVALID_ERROR_MESSAGE);
			return false;
		}

		let isValid = true;
		// incomingLicence Assignment Effective From Date is not Today
		if (
			isUndefinedOrNull(this.data.incomingLicence.Assignment_Effective_From_Date__c) ||
			formatDate(this.data.incomingLicence.Assignment_Effective_From_Date__c) !== formatDate(new Date())
		) {
			isValid = false;
			this.errorMessages.push(LABEL_ASSIGNMENTDATE_INVALID_ERROR_MESSAGE);
		}
		// incomingLicence SAP Vendor Id or Parent ABN are not populated
		if (isUndefinedOrNull(this.data.incomingLicence.SAP_Vendor_ID__c) || isUndefinedOrNull(this.data.incomingLicence.ParentABN__c)) {
			isValid = false;
			this.errorMessages.push(LABEL_SAPVENDORIDPARENTABN_MISSING_ERROR_MESSAGE);
		}
		// incomingLicence facility WCC is not populated
		if (isUndefinedOrNull(this.data.facility.WCIS_Code__c)) {
			isValid = false;
			this.errorMessages.push(LABEL_FACILITYWCC_MISSING_ERROR_MESSAGE);
		}
		//REQ3429628 : if incent credentials for Nominated Partner is not populated
		if (isUndefinedOrNull(this.data.incentCred)) {
			isValid = false;
			this.errorMessages.push(LABEL_INCENTCRED_INVALID_ERROR_MESSAGE);
		}
		return isValid;
	}

	/**
	 * make server call to activate incomingLicence
	 */
	activateLicence() {
		this.isLoading = true; // show spinner
		let outgoingLicenceId = this.isOutgoingLicenceNotFound() ? null : this.data.outgoingLicence.Id;
		updateLicences({ incomingLicenceId: this.recordId, outgoingLicenceId: outgoingLicenceId })
			.then((result) => {
				if (result) {
					this.updateSuccessful = true; // set flag later used in rendered callback to navigate back
					this.setToastMessage('success', LABEL_ACTIVATION_SUCCESS_MESSAGE); // show success toast message
				} else {
					console.error('Server call returned false');
					this.hasPageErrors = true; // set flag to true to denote page errors
					this.setToastMessage('error', LABEL_GENERIC_ERROR_MESSAGE); // show error toast message
				}
				this.isLoading = false; // hide spinner
			})
			.catch((error) => {
				console.error('error : ', error);
				this.hasPageErrors = true; // set flag to true to denote page errors
				this.setToastMessage('error', LABEL_GENERIC_ERROR_MESSAGE); // show error toast message
				this.isLoading = false; // hide spinner
			});
	}

	/**
	 * handler which gets called upon User clicking on Cancel button on UI
	 * It further redirects to the previous page in history
	 */
	handleCancel() {
		history.back();
	}

	/**
	 * handler which gets called upon User clicking on Confirm button on UI
	 * it will be disabled if validationchecks fail, when enabled it performs Licence Activation
	 */
	async handleNext() {
		let modalHeader = LABEL_ACTIVATION_CONFIRM_LABEL.replace('LICENCE_NAME_PLACEHOLDER', this.data.incomingLicence.Name);
		let modalBody = (LABEL_ACTIVATION_CONFIRM_MESSAGE.replace('LICENCEE_NAME_PLACEHOLDER', this.data.incomingLicence.Parent.Name))
			.replace('FACILITY_NAME_PLACEHOLDER', this.data.facility.Name);
		const result = await LightningConfirm.open({
			message: modalBody,
			variant: 'header',
			label: modalHeader,
			theme: 'alt-inverse',
		});
		if (result) {
			this.activateLicence();
		}
	}
}