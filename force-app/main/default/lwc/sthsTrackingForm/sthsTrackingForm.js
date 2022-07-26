import { LightningElement } from "lwc";
import { validateInputComponents } from "c/utils";
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";
import invalidDescription from "@salesforce/label/c.Sths_Description_Validation_Message";
import invalidEmail from "@salesforce/label/c.Sths_Email_Validation_Message";
import invalidEnquirySelection from "@salesforce/label/c.Sths_Enquiry_Selection_Validation_Message";
import invalidEnquiry from "@salesforce/label/c.Sths_Enquiry_Validation_Message";
import invalidFirstName from "@salesforce/label/c.Sths_Firstname_Validation_Message";
import invalidLastName from "@salesforce/label/c.Sths_Lastname_Validation_Message";
import invalidCharacters from "@salesforce/label/c.Sths_Max_Characters_Validation_Message";
import invalidPhone from "@salesforce/label/c.Sths_Phone_Validation_Message";
import invalidReference from "@salesforce/label/c.Sths_Reference_Validation_Message";
import stSupportURL from "@salesforce/label/c.Sths_Support_URL";

export default class SthsTrackingForm extends LightningElement {
	arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow
	formData = {}; //form data to capture

	//labels
	label = {
		invalidDescription,
		invalidEmail,
		invalidEnquirySelection,
		invalidEnquiry,
		invalidFirstName,
		invalidLastName,
		invalidCharacters,
		invalidPhone,
		invalidReference,
		stSupportURL
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
		let isFormValid = this.validateForm();
		if (isFormValid) {
			//submit the form
			console.log(JSON.parse(JSON.stringify(this.formData)));
		}
	}

	//validate the form
	validateForm() {
		let inputElements = this.template.querySelectorAll(
			'[data-validation="trackingForm"]'
		);
		return validateInputComponents([...inputElements], true);
	}
}