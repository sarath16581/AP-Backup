import { api, LightningElement } from 'lwc';
import confirmationMessage from '@salesforce/label/c.APT_Use_Offline_Rates_Confirmation_Message';
import missingConfigMessage from '@salesforce/label/c.APT_Use_Offline_Rates_MissingConfig_Message';
import save from '@salesforce/apex/APT_UseOfflineRatesController.save';
import finalizeCart from '@salesforce/apex/APT_UseOfflineRatesController.finalizeCart';

export default class Apt_UseOfflineRatesLWC extends LightningElement {
	@api proposalId;
	@api configId;
	@api configRequestId;
	@api flow;
	@api currentUrl;
	proposal = {};
	isLoadingSpinner = false;
	toastMessage = {
		show: false,
		type: '',
		message: ''
	};

	get showToastMessage() {
		return this.toastMessage.show;
	}
	get toastMessageClass() {
		let TOAST_CLASS_STYLE = 'slds-notify slds-notify_toast ';
		if(this.toastMessage.type == 'success') {
			TOAST_CLASS_STYLE += 'slds-theme_success';
		} else if(this.toastMessage.type == 'error') {
			TOAST_CLASS_STYLE += 'slds-theme_error';
		} else if(this.toastMessage.type == 'warning') {
			TOAST_CLASS_STYLE += 'slds-theme_warning';
		}
		return TOAST_CLASS_STYLE;
	}

	label = { confirmationMessage, missingConfigMessage }; // Expose the labels to use in the template.

	setToastMessage(show, type, message) {
		this.toastMessage = {
			show: show,
			type: type,
			message: message
		};
	}

	isUndefinedOrNull(field) {
		return (typeof field === 'undefined' || field === null);
	}

	handleToastClose() {
		this.setToastMessage(false, '', '');
	}

	handleNext(event){
		let fields = event.detail.fields;
		if(this.isUndefinedOrNull(this.configId) || this.isUndefinedOrNull(this.proposalId) || this.isUndefinedOrNull(fields)) {
			this.setToastMessage(true, 'error', label.missingConfigMessage);
		} else {
			let proposal = {
				Id: this.proposalId,
				APT_Use_Offline_Rates_Reason__c: fields.APT_Use_Offline_Rates_Reason__c,
				APT_Use_Offline_Rates_Comments__c: fields.APT_Use_Offline_Rates_Comments__c
			};

			// make server call to save
			this.isLoadingSpinner = true; // start spinner

			setTimeout(() => {

				//finalize shopping cart
				let that = this;
				finalizeCart({
					configId: this.configId
				})
				.then(response => {

					let retVal = response;
					if(retVal.result == 'success'){
						setTimeout(() => {

							//update proposal record
								save({
									configId: that.configId,
									proposal: proposal
								})
								.then(responseValue => {
									that.isLoadingSpinner = false; // stop spinner
									let retValUpdate = responseValue;
									that.setToastMessage(true, retValUpdate.result, retValUpdate.message);
									if(retValUpdate.result == 'success'){
										window.location.assign('/'+that.proposalId);
									}
								})
								.catch(error =>{
									that.isLoadingSpinner = false; // stop spinner
									that.setToastMessage(true, 'error', 'Something went wrong. Please contact support team.');

								})
								//update proposal record end
						}, 4000);

					}
					else {
						this.setToastMessage(true, retVal.result, retVal.message);
					}
				})
				.catch(error =>{
					this.isLoadingSpinner = false; // stop spinner
					this.setToastMessage(true, 'error', 'Something went wrong. Please contact support team.');

				})
			}, 7000);

		}
	}

	handleCancel(){
		history.back();
	}
}