import { LightningElement } from "lwc";
import { validateInputComponents } from "c/utils";
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";
import invalidDescription from "@salesforce/label/c.Sths_Description_Validation_Message";
import invalidEmail from "@salesforce/label/c.Sths_Email_Validation_Message";
import invalidFeedbackTypeSelection from "@salesforce/label/c.Sths_Feedback_Selection_Validation_Message";
import invalidFeedback from "@salesforce/label/c.Sths_Feedback_Validation_Message";
import invalidFirstName from "@salesforce/label/c.Sths_Firstname_Validation_Message";
import invalidLastName from "@salesforce/label/c.Sths_Lastname_Validation_Message";
import invalidCharacters from "@salesforce/label/c.Sths_Max_Characters_Validation_Message";
import invalidPhone from "@salesforce/label/c.Sths_Phone_Validation_Message";
import invalidReference from "@salesforce/label/c.Sths_Reference_Validation_Message";
import errorStateMessage from "@salesforce/label/c.Sths_Feedback_Error_State_Message";
import stSupportURL from "@salesforce/label/c.Sths_Support_URL";
import createFeedbackFormCase from "@salesforce/apex/SthsFeedbackFormController.createFeedbackFormCase";

export default class SthsTrackingForm extends LightningElement {
	arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow
	errorIcon = STHS_ICONS + "/sths_icons/svgs/forms/error_input.svg"; //error icon
	showReference = false; //flag to show/hide the reference field
	showError = false; //flag to show/hide the error message
	referenceRequiredFeedbackTypes = [
		"Product & Sales",
		"Pick Up",
		"On-Road",
		"Delivery"
	]; // reference field required feedback types
	formData = {}; //form data to capture
	isLoading = false; //flag to show/hide the spinner
	caseNumber; //case number created for feedback form

	//labels
	label = {
		invalidDescription,
		invalidEmail,
		invalidFeedbackTypeSelection, // Please select what your feedback is about
		invalidFeedback, // Please enter your feedback
		invalidFirstName,
		invalidLastName,
		invalidCharacters,
		invalidPhone,
		invalidReference,
		stSupportURL,
		errorStateMessage
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
	}

	//handle enquiry dropdown change
	handleEnquiryChange = (event) => {
		const feedbackType = event.target.value;
		if (this.referenceRequiredFeedbackTypes.includes(feedbackType)) {
			this.showReference = true;
		} else {
			this.showReference = false;
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
						//show thank you message
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
	};

	//handler for error close event
	handleErrorClose = (event) => {
		this.showError = false;
	};
}
