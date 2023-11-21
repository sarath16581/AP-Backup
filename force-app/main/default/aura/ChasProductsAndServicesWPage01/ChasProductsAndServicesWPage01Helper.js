/**
 * Created by nmain on 31/10/2017.
 * 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
 */
({
	setRadioName: function (
		cmp,
		radioGroupName,
		selectedRadioId,
		selectedRadioName
	) {
		var selectedRadio = cmp.get(selectedRadioId);
		var radioList = cmp.get(radioGroupName);
		for (var i = 0; i < radioList.length; i++) {
			var item = radioList[i];
			if (item.id === selectedRadio) {
				cmp.set(selectedRadioName, item.label);
				return;
			}
		}
	},
	validateTrackingNumber: function (cmp, showError) {
		var isValid = true;
		if (cmp) {
			if (showError) cmp.set("v.showError", showError);
			var val = cmp.get("v.value");
			if (val && !val.match(/^[a-z0-9]+$/i)) {
				isValid = false;
				cmp.set("v.error", "Enter a valid tracking number");
			} else {
				cmp.set("v.error", null);
			}
		}
		return isValid;
	},
	checkAllInputs: function (cmp, showError) {
		var allInputs = this.asArray(cmp.find("chasInput"));
		var isValid = this.checkEachInput(cmp, allInputs, showError);
		this.updateErrorSummary(cmp, allInputs);

		if (isValid) {
			cmp.set("v.formValid", true);
		} else {
			cmp.set("v.formValid", false);
		}
		return isValid;
	},

	checkEachInput: function (cmp, inputs, showError) {
		var errors = [];
		var selectedPostOffice = cmp.get("v.wizardData.selectedPostOffice");
		var selectedDeliveryAddress = cmp.get(
			"v.wizardData.selectedDeliveryAddress"
		);
		var validationMap = this.validationMap();
		var isValid = true;
		for (var i = 0; i < inputs.length; i++) {
			var inputCmp = inputs[i];
			var inputName = inputCmp.get("v.name");
			var inputRequired = inputCmp.get("v.required");
			var validationFunction = validationMap[inputName];
			if (validationFunction)
				validationFunction.bind(this)(inputCmp, showError);
			var inputError = inputCmp.get("v.error");
			isValid =
				isValid &&
				!inputError &&
				(!inputRequired || (inputError === null && inputRequired));
		}
		//--post office mandatory - validation
		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Mail products" &&
			cmp.get("v.wizardData.mailProductsEnquiryType") ===
				"Transfer to another post office"
		) {
			if (
				$A.util.isEmpty(selectedPostOffice) ||
				$A.util.isUndefined(selectedPostOffice)
			) {
				isValid = false;
				errors.push({
					name: "preferredLocation",
					label: "Preferred post office for collection",
					error: ""
				});
			}
		}
		//--AME address mandatory - validation
		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Mail products" &&
			cmp.get("v.wizardData.mailProductsEnquiryType") ===
				"Transfer to another post office"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				isValid = false;
			}
		}

		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Online Shop" &&
			cmp.get("v.wizardData.selectedRadio2Name") === "Yes"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				isValid = false;
			}
		}

		if (
			cmp.get("v.wizardData.selectedRadio1Name") ===
				"Accessibility and disability" &&
			cmp.get("v.wizardData.accessibilityIssueTypeName") === "Delivery"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				isValid = false;
			}
		}
		return isValid;
	},

	updateErrorSummary: function (cmp, allInputs) {
		var errors = [];
		var selectedPostOffice = cmp.get("v.wizardData.selectedPostOffice");
		var selectedDeliveryAddress = cmp.get(
			"v.wizardData.selectedDeliveryAddress"
		);
		for (var i = 0; i < allInputs.length; i++) {
			var inputCmp = allInputs[i];
			var inputName = inputCmp.get("v.name");
			var inputLabel = inputCmp.get("v.label");
			var inputError = inputCmp.get("v.error");

			for (var j = 0; j < errors; j++) {
				if (errors[j].name === inputName) {
					errors.splice(j, 1);
					break;
				}
			}
			if (inputError) {
				errors.push({
					name: inputName,
					label: inputLabel,
					error: inputError
				});
			}
		}
		//--post office mandatory - validation
		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Mail products" &&
			cmp.get("v.wizardData.mailProductsEnquiryType") ===
				"Transfer to another post office"
		) {
			if (
				$A.util.isEmpty(selectedPostOffice) ||
				$A.util.isUndefined(selectedPostOffice)
			) {
				errors.push({
					name: "preferredLocation",
					label: "Preferred post office for collection",
					error: ""
				});
			}
		}
		//--AME address mandatory - validation
		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Mail products" &&
			cmp.get("v.wizardData.mailProductsEnquiryType") ===
				"Transfer to another post office"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				errors.push({
					name: "AMEOriginalDeliveryAddress",
					label: "Original delivery address",
					error: ""
				});
			}
		}
		if (
			cmp.get("v.wizardData.selectedRadio1Name") === "Online Shop" &&
			cmp.get("v.wizardData.selectedRadio2Name") === "Yes"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				errors.push({
					name: "AMEOnlineDeliveryAddress",
					label: "Delivery address",
					error: ""
				});
			}
		}

		if (
			cmp.get("v.wizardData.selectedRadio1Name") ===
				"Accessibility and disability" &&
			cmp.get("v.wizardData.accessibilityIssueTypeName") === "Delivery"
		) {
			if (
				$A.util.isEmpty(selectedDeliveryAddress) ||
				$A.util.isUndefined(selectedDeliveryAddress)
			) {
				errors.push({
					name: "AMEOnlineDeliveryAddress",
					label: "Delivery address",
					error: ""
				});
			}
		}
		cmp.set("v.errors", errors);
	},
	validateRadioButtons: function (cmp, showError) {
		return this.validateNotNull(cmp, showError, "Choose an option");
	},
	validateOrderNumber: function (cmp, showError) {
		return this.validateNotNull(cmp, showError, "Enter order number");
	},
	validateTextArea: function (cmp, showError) {
		return this.validateNotNull(cmp, showError, "Enter enquiry details");
	},
	validatePostOffice: function (cmp, showError) {
		return this.validateNotNull(
			cmp,
			showError,
			"Enter preferred post office for collection"
		);
	},
	validateAccessibilityPostOffice: function (cmp, showError) {
		return this.validateNotNull(
			cmp,
			showError,
			"Enter post office details"
		);
	},
	validateWebpageURL: function (cmp, showError) {
		return this.validateNotNull(
			cmp,
			showError,
			"Enter a valid webpage URL or app name"
		);
	},
	validateWebpageIssue: function (cmp, showError) {
		return this.validateNotNull(
			cmp,
			showError,
			"Enter a valid location for webpage or app"
		);
	},
	validateAssistiveTechnology: function (cmp, showError) {
		return this.validateNotNull(
			cmp,
			showError,
			"Enter a valid assistive technology"
		);
	},
	validationMap: function () {
		return {
			enquiryDetailsRadioButtons: this.validateRadioButtons,
			mailProductsEnquiryType: this.validateSelect,
			transferTrackingNumber: this.validateTrackingNumber,
			idDocumentsAccountsEnquiryTypes: this.validateSelect,
			madeAnOrderRadioButtons: this.validateRadioButtons,
			orderNumber: this.validateOrderNumber,
			orderTrackingNumber: this.validateTrackingNumber,
			moneyEnquiryTypeRadioButtons: this.validateRadioButtons,
			enquiryDetails: this.validateTextArea,
			addressLine1: this.validateAddress,
			city: this.validateCity,
			state: this.validateState,
			postcode: this.validatePostcode,
			issueType: this.validateSelect,
			accessibilityIssueTypeRadioButtons: this.validateRadioButtons,
			parcelOrLetterRadioButtons: this.validateRadioButtons,
			medicationRadioButtons: this.validateRadioButtons,
			issueRadioButtons: this.validateRadioButtons,
			issueDate: this.validateDate,
			poIssueType: this.validateSelect,
			postOffice: this.validateAccessibilityPostOffice,
			webpageURL: this.validateWebpageURL,
			webpageIssue: this.validateWebpageIssue,
			assistiveRadioButtons: this.validateRadioButtons,
			assistiveTechnology: this.validateAssistiveTechnology
		};
	},
	searchTrackingNumber: function (cmp, event, helper) {
		// Disable button actions if still loading.
		if (cmp.get("v.isLoading")) return;
		// make Spinner attribute true for display loading spinner
		cmp.set("v.isLoading", true);
		cmp.set("v.error500", false);
		cmp.set("v.isVerified", false);
		cmp.set('v.articleTrackingCaptchaEmptyError', false);

		//-- checking if Tracking Number is entered
		var trackingId = cmp.get("v.wizardData.trackingId");
		if (trackingId) {

			let controllerMethod = 'c.searchTrackingNumber';
			let trackingParams = {trackingNumber: cmp.get("v.wizardData.trackingId")}
			const authUserData = cmp.get('v.authUserData');
			// force the user to enter a captcha value if they aren't logged in
			if(!authUserData || !authUserData.isUserAuthenticated) {

				controllerMethod = 'c.searchTrackingNumberWithCaptcha';

				const captchaToken = cmp.get('v.articleTrackingCaptchaToken');
				trackingParams.captchaToken = captchaToken;
				
				if(!captchaToken) {
					cmp.set('v.articleTrackingCaptchaEmptyError', true);
					cmp.set('v.isLoading', false);
					return;
				}
			}

			var action = cmp.get(controllerMethod);
            action.setParams(trackingParams);
			action.setCallback(this, function (response) {

				var state = response.getState();
				var trackingNumInputCmp = cmp.find("transferTrackingNumber");

				if (state === "SUCCESS") {

					var returnObj = JSON.parse(
						JSON.stringify(response.getReturnValue())
					);
					var returnCode = returnObj["trackingNumSerachStatusCode"];
					//refactored the code to bind the response based on list of trackingNumberDetails
					if (
						!$A.util.isUndefinedOrNull(
							returnObj["trackingNumberDetails"]
						)
					) {
						cmp.set(
							"v.wizardData.wcid",
							returnObj["trackingNumberDetails"][0].wcid
						);
						cmp.set(
							"v.wizardData.isParcelAwaitingCollection",
							returnObj["trackingNumberDetails"][0]
								.isParcelAwaitingCollection
						);
						cmp.set(
							"v.wizardData.subProductId",
							returnObj["trackingNumberDetails"][0].subProductId
						);
					}
					// for return code other than 200 Success OK
					if (returnObj["trackingNumSerachStatusCode"] != 200) {
						trackingNumInputCmp.set(
							"v.error",
							"Unconfirmed number. It may be incorrect, or not in our system yet."
						);
						cmp.set("v.error400", true);
					}
					// for return code 200 Success OK
					else {
						cmp.set("v.isVerified", true);
					}
				} else if (state === "INCOMPLETE") {
					cmp.set("v.error500", true);
					cmp.set("v.isLoading", false);
					trackingNumInputCmp.set(
						"v.error",
						"Whoops, something's gone wrong.Try again later."
					);
				} else if (state === "ERROR") {
					cmp.set("v.error500", true);
					trackingNumInputCmp.set(
						"v.error",
						"Whoops, something's gone wrong.Try again later."
					);
				}
				cmp.set("v.isLoading", false);
			});

			$A.enqueueAction(action);
		} else {
			cmp.set("v.isLoading", false);
		}
	},
	pushFormAnalytics: function (cmp, selectedValue) {
		var analyticsObject = {
			form: {
				name: "form:" + cmp.get("v.pageTitle"),
				step: "enquiry details:type",
				stage: "",
				detail: "enquiry=" + selectedValue
			}
		};
		// calling the analytics API methods for trackingtype = "helpsupport-form-navigate"
		window.AP_ANALYTICS_HELPER.trackByObject({
			trackingType: "helpsupport-form-navigate",
			componentAttributes: analyticsObject
		});
	},
	pushInteractionAnalytics: function (cmp, selectedValue, helper) {
		// calling the analytics API methods for trackingtype = "site-interact", for all of the issueType options selected
		window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
			"site-interact",
			"form:" + cmp.get("v.pageTitle"),
			"enquiry details: " + selectedValue
		);
	}
});