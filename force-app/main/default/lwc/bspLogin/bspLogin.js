/*
* --------------------------------------- History --------------------------------------------------
* 07/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
*/

import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { reportAllValidity, checkAllValidity, checkCustomValidity, topGenericErrorMessage} from 'c/bspCommonJS';
import login from '@salesforce/apex/bspLogin.login';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BspLogin extends NavigationMixin(LightningElement) {
	userName;
	password;
	@track isRegSecVisible = true;
	@track loginButtonClicked = false;
	@track errorMessage;
	@track showLoginSec = true;

	//analytics variables
	pageName = 'auspost:bsp:login';

	handleChange(event) {
		const field = event.target.dataset.id;
		if (field === 'userName') {
			this.userName = event.target.value;
		} else if (field === 'password') {
			this.password = event.target.value;
		}
		//--Checking the custom validation on change of a field value
		this.checkValidationOfField(field);
	}

	handleForgotPWD(event) {
		this.showLoginSec = false;
	}

	handleLogin(event) {
		event.preventDefault();
		this.errorMessage = null;
		const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
		const allValid = checkAllValidity(inputComponents);
		if (allValid) {
			this.loginButtonClicked = true;
			login({
					userName: this.userName,
					password: this.password
				})
				.then((result) => {
					this.isRegSecVisible = false;
					this.loginButtonClicked = false;
					location.href = result;
				})
				.catch((error) => {
					this.errorMessage = error.body.message;
					this.template.querySelector('[data-id="password"]').value = '';
					this.loginButtonClicked = false;
				});
		} else {
			this.errorMessage = topGenericErrorMessage;
		}
	}

	handleCreateNewLogin(event) {

		//event.preventDefault();
		//event.stopPropagation();

		this.navigationLinkRef = {
			type: 'comm__namedPage',
			attributes: {
				name: 'Register'
			}
		};

		// Set the link's HREF value so the user can click "open in new tab" or copy the link...
		this[NavigationMixin.Navigate](this.navigationLinkRef);

		//--[Jansi:] Added below line
		/* this[NavigationMixin.GenerateUrl](this.navigationLinkRef).then(generatedUrl => {
				window.open(generatedUrl);
			});*/

		//alert('To be implemented');
		/*this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'bspRegistration__c'
			}
		});*/
	}


	handleSecDisplay(event) {
		this.errorMessage = null;   //17-09-2020 [Jansi: emptying error when comeback from reset password]
		this.showLoginSec = event.detail.showLoginSec;
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