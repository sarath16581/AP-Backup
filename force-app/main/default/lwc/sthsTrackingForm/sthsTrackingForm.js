import { LightningElement } from "lwc";
import { validateInputComponents } from "c/utils";
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";
import invalidDescription from "@salesforce/label/c.STHSDescriptionValidationMessage";
import invalidEmail from "@salesforce/label/c.STHSEmailValidationMessage";
import invalidEnquirySelection from "@salesforce/label/c.STHSEnquirySelectionValidationMessage";
import invalidEnquiry from "@salesforce/label/c.STHSEnquiryValidationMessage";
import invalidFirstName from "@salesforce/label/c.STHSFirstnameValidationMessage";
import invalidLastName from "@salesforce/label/c.STHSLastnameValidationMessage";
import invalidCharacters from "@salesforce/label/c.STHSMaxCharactersValidationMessage";
import invalidPhone from "@salesforce/label/c.STHSPhoneValidationMessage";
import invalidReference from "@salesforce/label/c.STHSReferenceValidationMessage";
import stSupportURL from "@salesforce/label/c.STHSSupportURL";

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