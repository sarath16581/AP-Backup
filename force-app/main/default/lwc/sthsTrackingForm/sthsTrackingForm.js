import { LightningElement } from "lwc";
import { validateInputComponents, validatePhone, validateEmail } from "c/utils";
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";
import invalidDescription from "@salesforce/label/c.STHSDescriptionValidationMessage";
import invalidEmail from "@salesforce/label/c.STHSEmailValidationMessage";
import invalidEnquirySelection from "@salesforce/label/c.STHSEnquirySelectionValidationMessage";
import invalidEnquiry from "@salesforce/label/c.STHSEnquiryValidationMessage";
import invalidFirstName from "@salesforce/label/c.STHSFirstnameValidationMessage";
import invalidLastName from "@salesforce/label/c.STHSLastnameValidationMessage";
import invalidPhone from "@salesforce/label/c.STHSPhoneValidationMessage";
import invalidReference from "@salesforce/label/c.STHSReferenceValidationMessage";
import stSupportURL from "@salesforce/label/c.STHSSupportURL";
import invalidNameFieldCharacters from "@salesforce/label/c.STHSNameFieldCharactersValidationMessage";
import createTrackingFormCase from "@salesforce/apex/STHSTrackingFormController.createTrackingFormCase";

export default class SthsTrackingForm extends LightningElement {
	arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow
	formData = {}; //form data to capture
	isLoading = false; //flag to show/hide the spinner
	caseNumber; //case number created for feedback form
	showError = false; //flag to show/hide the error message
	isCaseCreatedSuccessfully = false; //flag to show/hide the layout when case created successfully

	//labels
	label = {
		invalidDescription,
		invalidEmail,
		invalidEnquirySelection,
		invalidEnquiry,
		invalidFirstName,
		invalidLastName,
		invalidPhone,
		invalidReference,
		stSupportURL,
		invalidNameFieldCharacters
	};

	get enquiryOptions() {
		return [
			{ label: "Track & Trace", value: "Track & Trace" },
			{ label: "Pick-ups", value: "Pick-ups" },
			{ label: "Missed delivery", value: "Missed delivery" },
			{ label: "Other", value: "Other" }
		];
	}

	//handler for input type fields
	handleInputChange(event) {
		this.formData = {
			...this.formData,
			[event.target.dataset.fieldName]: event.detail.value
		};
	}

	//handle form submit click
	handleSubmitClick(event) {
		this.resetForm();
		//validate the form
		let isFormValid = this.validateForm();
		if (isFormValid) {
			//submit the form
			this.isLoading = true;
			//create case and related contact
			createTrackingFormCase({
				formData: this.formData
			})
				.then((response) => {
					if (response !== null) {
						this.caseNumber = response;
						//show confirmation message
						this.isCaseCreatedSuccessfully = true;
					} else {
						this.showError = true;
						window.scrollTo(0, 0); //scroll to top
					}
					this.isLoading = false;
				})
				.catch((error) => {
					this.isLoading = false;
					this.showError = true;
					window.scrollTo(0, 0); //scroll to top
					console.error(
						"createTrackingFormCase call failed: " + error
					);
				});
		}
	}

	//validate the form
	validateForm() {
		let inputElements = this.template.querySelectorAll(
			'[data-validation="trackingForm"]'
		);
		return validateInputComponents([...inputElements], true);
	}

	//reset the form
	resetForm = () => {
		this.showError = false;
		this.isCaseCreatedSuccessfully = false;
	};

	//validate phone number field with custom validations
	validatePhone = (event) => {
		event.target.setCustomValidity('');
		if(event.target.value && !validatePhone(event.target.value)) {
			event.target.setCustomValidity(this.label.invalidPhone);
		}
		event.target.reportValidity();
		event.target.showHelpMessageIfInvalid();
	}

	//validate email field with custom validations
	validateEmail = (event) => {
		event.target.setCustomValidity('');
		if(event.target.value && !validateEmail(event.target.value)) {
			event.target.setCustomValidity(this.label.invalidEmail);
		}
		event.target.reportValidity();
		event.target.showHelpMessageIfInvalid();
	};
}