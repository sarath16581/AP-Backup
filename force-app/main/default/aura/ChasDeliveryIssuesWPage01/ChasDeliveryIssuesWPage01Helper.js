/**
 * Created by nmain on 31/10/2017.
 * Modified Ba: Hasantha 12/09/2019 :  added lateOrMissingRadioButtons for validations
 * 2020-10-26 hara.sahoo@auspost.com.au Modified : Prepopulate track id and options passed in the url for auto-progression of the forms
 * 2022-06-08 mahesh.parvathaneni@auspost.com.au Modified : DDS-10987 Delivery issue form network assignment fix in searchTrackingNumber
 * 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
 */
({
    searchTrackingNumber : function(cmp, event, helper) {
        // Disable button actions if still loading.
        if (cmp.get('v.isLoading')) return;
        // make Spinner attribute true for display loading spinner 
        cmp.set("v.isLoading", true);
        cmp.set('v.error500', false);
        cmp.set('v.error400', false);
        cmp.set('v.isVerified', false);
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
            action.setCallback(this, function(response) {
				// means the user will need to reverify 
				cmp.set('v.articleTrackingCaptchaToken', '');
				cmp.find("chasCaptcha").reset();
                
                var state = response.getState();                
                var trackingNumInputCmp = cmp.find("transferTrackingNumber");
                
                if (state === "SUCCESS") {
                    var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                    var returnCode = returnObj["trackingNumSerachStatusCode"];
                    //refactored the code to bind the response based on list of trackingNumberDetails
                    if (!$A.util.isUndefinedOrNull(returnObj["trackingNumberDetails"])) {
                        cmp.set('v.wizardData.latestDeliveredScanWcid', returnObj["trackingNumberDetails"][0].latestDeliveredScanWcid);
                        cmp.set('v.wizardData.previousDeliveredScanWcid', returnObj["trackingNumberDetails"][0].previousDeliveredScanWcid);
                        cmp.set('v.wizardData.duplicateCase', returnObj["trackingNumberDetails"][0].duplicateCase);
                        cmp.set('v.wizardData.isReturnToSender', returnObj["trackingNumberDetails"][0].isReturnToSender);
                        cmp.set('v.wizardData.isParcelAwaitingCollection', returnObj["trackingNumberDetails"][0].isParcelAwaitingCollection);
                        //cmp.set('v.wizardData.isVodv', lArticle["isVodv"]);
                    }
                    this.checkNetworkEligibility(cmp,event,helper);
                    // for return code other than 200 Success OK
                    if (returnObj["trackingNumSerachStatusCode"] != 200) {
                        cmp.set('v.error400', true);
                        cmp.set("v.isLoading", false);
                        trackingNumInputCmp.set("v.error", "Unconfirmed number. It may be incorrect, or not in our system yet.");
                        
                    }
                    // for return code 200 Success OK
                    else
                    {
                        cmp.set("v.isVerified", true);
                    }
                    
                } else if (state === "INCOMPLETE") {
                    cmp.set('v.error500', true);
                    cmp.set("v.isLoading", false);
                    trackingNumInputCmp.set("v.error", "Whoops, something's gone wrong.Try again later.");
                    
                } else if (state === "ERROR") {
					cmp.set('v.error500', true);
					trackingNumInputCmp.set("v.error", "Whoops, something's gone wrong.Try again later.");
				}

                cmp.set("v.isVerified", true);
                cmp.set("v.isLoading", false);
                
            });
            
            $A.enqueueAction(action);
        } else {
            cmp.set("v.isLoading", false);
        }
    },
    checkNetworkEligibility : function(cmp,event,helper) {
        var isEligibleForMyNetworkAssignment = false;
        var issueName = cmp.get('v.wizardData.IssueName');
        var duplicateCase = cmp.get("v.wizardData.duplicateCase");
        var isReturnToSender = $A.util.isUndefined(cmp.get("v.wizardData.isReturnToSender")) ? false : cmp.get("v.wizardData.isReturnToSender");
        var isParcelAwaitingCollection = $A.util.isUndefined(cmp.get("v.wizardData.isParcelAwaitingCollection")) ? false : cmp.get("v.wizardData.isParcelAwaitingCollection");
        var attemptedDeliveryScanWcid = cmp.get("v.wizardData.latestDeliveredScanWcid");
        var previousDeliveredScanWcid = cmp.get("v.wizardData.previousDeliveredScanWcid");
        // set network eligibility flag based on issue type
        if(issueName == 'Item was left in an unsafe place' || issueName == 'Postie didn\'t knock')
        {
            // check for duplicate case, RTS, delivered scan
            if(duplicateCase == '' && !isReturnToSender && !$A.util.isEmpty(attemptedDeliveryScanWcid))
            {
                isEligibleForMyNetworkAssignment = true;
            }
        }
        //--for item left in an unsafe place, if the parcel is awaiting collection, consider the previousDeliveredScanWcid for network assignment
        if(issueName == 'Item was left in an unsafe place' && isParcelAwaitingCollection)
        {
            if(duplicateCase == '' && !isReturnToSender && !$A.util.isEmpty(previousDeliveredScanWcid))
            {
                isEligibleForMyNetworkAssignment = true;
            }
        }
        
        cmp.set("v.wizardData.isEligibleForNetworkAssignmentDeliveryIssue",isEligibleForMyNetworkAssignment);
    },
    validateOptionalTrackingNumber : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError); 
            var val = cmp.get('v.value');
            if (val && !val.match(/^[a-z0-9]+$/i)) {
                isValid = false;
                cmp.set("v.error", "Enter a valid tracking number");
            } else {
                cmp.set("v.error",null); 
            }
        }
        return isValid;
    },
    validateRadioButtons: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Choose an option");
    },
    validateItemSentDate : function(cmp, showError) {
        //return this.validateNotNull(cmp, showError, "Enter date as DD/MM/YYYY");
        return this.validateDate(cmp, showError);
    },
    validateTextArea: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter enquiry details");
    },
    checkAllInputs: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('chasInput'));
        var isValid = this.checkEachInput(cmp, allInputs, showError);
        this.updateErrorSummary(cmp, allInputs);
        
        if(isValid){
            cmp.set('v.formValid', true);
        }else{
            cmp.set('v.formValid', false);
        }
        return isValid;
    },
    checkEachInput: function(cmp, inputs, showError) {
        var errors = [];
        var selectedDeliveryAddress = cmp.get('v.wizardData.selectedDeliveryAddress');
        var incorrectDeliveryAddress = cmp.get('v.wizardData.incorrectDeliveryAddress');
        var IssueName = cmp.get("v.wizardData.IssueName");
        var validationMap = this.validationMap();
        var isValid = true;
        for (var i=0; i<inputs.length; i++) {
            var inputCmp = inputs[i];
            var inputName = inputCmp.get('v.name');
            var inputRequired = inputCmp.get('v.required');
            var validationFunction = validationMap[inputName];
            if (validationFunction) validationFunction.bind(this)(inputCmp, showError);
            var inputError = inputCmp.get('v.error');
            isValid = isValid && !inputError && (!inputRequired || (inputError === null && inputRequired));
        }
        //--AME address mandatory - validation
        if ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress)) {
            isValid = false;
        }
        if(IssueName == 'Incorrect delivery address needs fixing')
        {
            if ($A.util.isEmpty(incorrectDeliveryAddress) || $A.util.isUndefined(incorrectDeliveryAddress)) {
                isValid = false;
            }
        }
        return isValid;
    },
    updateErrorSummary: function(cmp, allInputs) {
        var errors = [];
        var selectedDeliveryAddress = cmp.get('v.wizardData.selectedDeliveryAddress');
        var incorrectDeliveryAddress = cmp.get('v.wizardData.incorrectDeliveryAddress');
        var IssueName = cmp.get("v.wizardData.IssueName");
        for (var i=0; i<allInputs.length; i++) {
            var inputCmp = allInputs[i];
            var inputName = inputCmp.get('v.name');
            var inputLabel = inputCmp.get('v.label');
            var inputError = inputCmp.get('v.error');
            
            for (var j=0; j<errors; j++) {
                if (errors[j].name === inputName) {
                    errors.splice(j, 1);
                    break;
                }
            }
            if (inputError) {
                errors.push({name: inputName, label: inputLabel, error: inputError});
            }
        }
        //--AME address mandatory - validation
        if ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress)) {
            errors.push({name: 'AMEDeliveryAddress', label: 'Delivery address', error: ''});
        }
        if(IssueName == 'Incorrect delivery address needs fixing')
        {
            if ($A.util.isEmpty(incorrectDeliveryAddress) || $A.util.isUndefined(incorrectDeliveryAddress)) {
                errors.push({name: 'AMEIncorrectDeliveryAddress', label: 'Incorrect delivery address', error: ''});
            }
        }
        cmp.set('v.errors', errors);
    },
    validationMap: function() {
        return {
            'issueTypeRadioButtons': this.validateRadioButtons,
            'parcelOrLetterRadioButtons': this.validateRadioButtons,
            'parcelOrRegPostRadioButtons': this.validateRadioButtons,
            'recipientOrSenderRadioButtons': this.validateRadioButtons,
            'trackingNumberOptional': this.validateOptionalTrackingNumber,
            'trackingNumber': this.validateTrackingNumber,
            'issueDate': this.validateItemSentDate,
            'issueDetails': this.validateTextArea,
            'addressLine1': this.validateAddress,
            'city': this.validateCity,
            'state': this.validateState,
            'postcode': this.validatePostcode,
            'inCorrectAddressLine1': this.validateAddress,
            'inCorrectDeliverycity': this.validateCity,
            'inCorrectDeliverystate': this.validateState,
            'inCorrectDeliverypostcode': this.validatePostcode,
            'issueDescription':this.validateTextArea,
        };
    },
    
    removeSentTypeFromWizardData: function(cmp){
        //-- setting below to null in wizardData if user selected 'Registered Post' and choose 'Parcel' option
        if(cmp.get('v.wizardData.selectedRadio2Name') != 'Parcel'){
            cmp.set('v.wizardData.selectedRadio2', null);
            cmp.set('v.wizardData.selectedRadio2Name', null);
        }
        cmp.set('v.wizardData.selectedRadio3', null);
        cmp.set('v.wizardData.selectedRadio3Name', null);
    },
    /* Tracking Id passed from Mobile App view to the Delivery issue form. */
    parseUrlParam: function() {
        var varsObj = {},
            arr = [],
            keyVal = [];
        //Fetch the trackingId parameter appended after query string.
        if (location.search !== null) {
            //Replace '?' with blank and split by '&'
            arr = location.search.replace('?/', '').replace('?', '').split('&');
            //Looping through the parameters.
            for (var i = 0; i < arr.length; i+=1) {
                //Split by '=' and get the value.
                keyVal = arr[i].split("=");
                if (keyVal.length === 2) {
                    varsObj[keyVal[0]] = keyVal[1];
                }
            }
        }
        return varsObj; 
    },    
    
})