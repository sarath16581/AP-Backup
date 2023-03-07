import { LightningElement } from "lwc";
import { validateInputComponents, validatePhone, validateEmail } from "c/utils";
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";
import invalidDescription from "@salesforce/label/c.STHSDescriptionValidationMessage";
import invalidEmail from "@salesforce/label/c.STHSEmailValidationMessage";
import invalidFeedbackTypeSelection from "@salesforce/label/c.STHSFeedbackSelectionValidationMessage";
import invalidFeedback from "@salesforce/label/c.STHSFeedbackValidationMessage";
import invalidFirstName from "@salesforce/label/c.STHSFirstnameValidationMessage";
import invalidLastName from "@salesforce/label/c.STHSLastnameValidationMessage";
import invalidPhone from "@salesforce/label/c.STHSPhoneValidationMessage";
import invalidReference from "@salesforce/label/c.STHSReferenceValidationMessage";
import invalidCallerType from "@salesforce/label/c.STHSSenderReceiverValidationMessage";
import invalidNameFieldCharacters from "@salesforce/label/c.STHSNameFieldCharactersValidationMessage";
import errorStateMessage from "@salesforce/label/c.STHSFeedbackErrorStateMessage";
import stSupportURL from "@salesforce/label/c.STHSSupportURL";
import createFeedbackFormCase from "@salesforce/apex/STHSFeedbackFormController.createFeedbackFormCase";

export default class SthsTrackingForm extends LightningElement {
	arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow
	errorIcon = STHS_ICONS + "/sths_icons/svgs/forms/error_input.svg"; //error icon
	showError = false; //flag to show/hide the error message
	referenceRequiredFeedbackTypes = [ // reference field required feedback types
		"Product & Sales",
		"Pick Up",
		"On-Road",
		"Delivery"
	];
	callerTypesDependancyOnReferences = [ // caller types displayed for these references only
		"Product & Sales",
		"Pick Up",
		"On-Road",
		"Delivery",
		"Contact Centre",
		"Other"
	];
	formData = {}; //form data to capture
	isLoading = false; //flag to show/hide the spinner
	caseNumber; //case number created for feedback form
	isCaseCreatedSuccessfully = false; //flag to show/hide the layout when case created successfully
	toggleConfig = {
		showReference: false,
		showCallerType: false,
	}

	//labels
	label = {
		invalidDescription,
		invalidEmail,
		invalidFeedbackTypeSelection, // Please select what your feedback is about
		invalidFeedback, // Please enter your feedback
		invalidFirstName,
		invalidLastName,
		invalidPhone,
		invalidReference,
		invalidCallerType,
		stSupportURL,
		errorStateMessage,
		invalidNameFieldCharacters
	};

	get enquiryOptions() {
		return [
			{ label: "Product & Sales", value: "Product & Sales" }, //
			{ label: "Account Management", value: "Account Management" },
			{ label: "Pick Up", value: "Pick Up" }, //
			{ label: "On-Road", value: "On-Road" }, //
			{ label: "Delivery", value: "Delivery" }, //
			{ label: "Contact Centre", value: "Contact Centre" },
			{ label: "Billing", value: "Billing" },
			{ label: "Other", value: "Other" }
		];
	};

	get callerTypeOptions() {
		return [
			{ label: 'Sender', value: 'Sender' },
			{ label: 'Receiver', value: 'Receiver' },
			{ label: 'Other', value: 'Other' },
		];
	}

	//handle enquiry dropdown change
	handleEnquiryChange = (event) => {
		const feedbackType = event.target.value;
		if (this.referenceRequiredFeedbackTypes.includes(feedbackType)) {
			this.toggleConfig.showReference = true;
		} else {
			this.toggleConfig.showReference = false;
		}

		if (this.callerTypesDependancyOnReferences.includes(feedbackType)) {
			this.toggleConfig.showCallerType = true;
		} else {
			this.toggleConfig.showCallerType = false;
		}
		//save to formdata
		this.handleInputChange(event);
	};

	//handler for input type fields
	handleInputChange = (event) => {
		this.formData = {
			...this.formData,
			[event.target.dataset.fieldName]: event.detail.value
		};
	};

	//handle form submit click
	handleSubmitClick = (event) => {
		this.resetForm();
		//validate the form
		let isFormValid = this.validateForm();
		if (isFormValid) {
			//submit the form
			this.isLoading = true;
			//create case and related contact
			createFeedbackFormCase({
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
						"createFeedbackFormCase call failed: " + error
					);
				});
		}
	};

	//validate the form
	validateForm = () => {
		let inputElements = this.template.querySelectorAll(
			'[data-validation="feedbackForm"]'
		);
		return validateInputComponents([...inputElements], true);
	};

	//reset the form
	resetForm = () => {
		this.showError = false;
		this.isCaseCreatedSuccessfully = false;
	};

	//handler for error close event
	handleErrorClose = (event) => {
		this.showError = false;
	};

	//validate phone number field with custom validations
	validatePhone = (event) => {
		event.target.setCustomValidity('');
		if(event.target.value && !validatePhone(event.target.value)) {
			event.target.setCustomValidity(this.label.invalidPhone);
		}
		event.target.reportValidity();
		event.target.showHelpMessageIfInvalid();
	};

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