/*
* --------------------------------------- History --------------------------------------------------
* 08/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
*/
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, checkCustomValidity, topGenericErrorMessage } from 'c/bspCommonJS';
import changePassword from '@salesforce/apex/bspProfileUplift.changePassword';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BspChangePassword extends NavigationMixin(LightningElement) {

	oldPassword;
	newPassword;
	confirmNewPassword;

	isTypedPWD = false;
	isPasswordMatch = false;
	errorMessage;
	submitButtonClicked = false;
	showSuccessSec = false;

	//analytics variables
	pageName = 'auspost:bsp:change password';		

	handleChange(event) {
		const field = event.target.dataset.id;
		if (field === 'oldPassword')
			this.oldPassword = event.target.value;
		else if (field === 'newPassword')
			this.newPassword = event.target.value;
		else if (field === 'confirmNewPasword')
			this.confirmNewPassword = event.target.value;

		//--Checking the custom validation on change of a field value
		this.checkValidationOfField(field);
	}

	checkPasswordMatch(event) {
		// if (this.template.querySelector("lightning-input[data-id=newPassword]").value &&
		//this.template.querySelector("lightning-input[data-id=confirmNewPasword]").value) {
		if (this.newPassword && this.confirmNewPassword) {
			this.isTypedPWD = true;
			if (this.newPassword == this.confirmNewPassword)
				this.isPasswordMatch = true;
			else
				this.isPasswordMatch = false;
		} else {
			this.isTypedPWD = false;
		}
	}

	navigateHome(event) {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}

	handleSubmit(event) {
		event.preventDefault();
		this.errorMessage = null;
		this.showSuccessSec = false;
		const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
		const allValid = checkAllValidity(inputComponents) && this.isPasswordMatch;
		if (allValid) {
			this.submitButtonClicked = true;
			changePassword({
					newPassword: this.newPassword,
					verifyNewPassword: this.confirmNewPassword,
					oldpassword: this.oldPassword
				})
				.then((result) => {
					this.submitButtonClicked = false;
					//location.href = result;
					this.isTypedPWD = false;
					this.showSuccessSec = true;
					this.template.querySelector('[data-id="oldPassword"]').value = '';
					this.template.querySelector('[data-id="newPassword"]').value = '';
					this.template.querySelector('[data-id="confirmNewPasword"]').value = '';
					//this.navigateHome();
				})
				.catch((error) => {
					this.errorMessage = error.body.message;
					this.submitButtonClicked = false;
					this.isTypedPWD = false;
					// this.showSuccessSec = false;
				});
		} else {
			this.errorMessage = topGenericErrorMessage;
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

	connectedCallback() {
		this.pushPageAnalyticsOnLoad();
	}

	pushPageAnalyticsOnLoad(){
		const pageData = {
			sitePrefix: 'auspost:bsp',
			pageAbort: 'true',
			pageName: this.pageName
		};
		analyticsTrackPageLoad(pageData);
	}	
}