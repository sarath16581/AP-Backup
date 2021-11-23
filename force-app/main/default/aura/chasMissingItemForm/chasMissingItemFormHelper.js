({
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
        var recipientOrSender = cmp.get("v.wizardData.selectedRadio1Name");
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
        if (recipientOrSender == 'Sender' && ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress))) {
            isValid = false;
            //errors.push({name: 'AMEDeliveryAddress', label: 'Delivery address', error: ''});
        }
        return isValid;
    },
    updateErrorSummary: function(cmp, allInputs) {
        var errors = [];
        var selectedDeliveryAddress = cmp.get('v.wizardData.selectedDeliveryAddress');
        var recipientOrSender = cmp.get("v.wizardData.selectedRadio1Name");
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
        if (recipientOrSender == 'Sender' && ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress))) {
            errors.push({name: 'AMEDeliveryAddress', label: 'Delivery address', error: ''});
        }
        cmp.set('v.errors', errors);
    },
    removeSentTypeFromWizardData: function(cmp){
        //-- setting below to null in wizardData if user selected 'Registered Post' and choose 'Parcel' option
        if(cmp.get('v.wizardData.selectedRadio3Name') == 'Registered Post' && cmp.get('v.wizardData.selectedRadio2Name') == 'Parcel'){
            cmp.set('v.wizardData.selectedRadio3', null);
            cmp.set('v.wizardData.selectedRadio3Name', null);
        }
    },
    validateRadioButtons: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Choose an option");
    },
    validateItemSentDate : function(cmp, showError) {
        //return this.validateNotNull(cmp, showError, "Enter date as DD/MM/YYYY");
        return this.validateDate(cmp, showError);
    },
    validateTextArea: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter a detailed item description");
    },
    validateItemValue: function(cmp, showError) {
        return this.validateCurrency(cmp, showError);
    },
    validationMap: function() {
        return {
            'recipientOrSenderRadioButtons': this.validateRadioButtons,
            'reasonForEnquiry':this.validateRadioButtons,
            'parcelOrLetterRadioButtons': this.validateRadioButtons,
            'domesticLetterSentTypeRadioButtons': this.validateRadioButtons,
            'domesticParcelSentTypeRadioButtons': this.validateRadioButtons,
            'internationalParcelSentTypeRadioButtons': this.validateRadioButtons,
            'pharmaRadioButtons': this.validateRadioButtons,
            'sentimentalValueRadioButtons': this.validateRadioButtons,
            'ChasItemSentDate': this.validateItemSentDate,
            'chasContentDescription': this.validateTextArea,
            'senderCountry': this.validateCountry,
            'senderAddressLine1': this.validateAddress,
            'senderCityAU': this.validateCity,
            'senderStateAU': this.validateState,
            'senderPostcodeAU': this.validatePostcode,
            'recipientGivenName': this.validateGivenName,
            'recipientSurname': this.validateSurname,
            'recipientCountry': this.validateCountry,
            'recipientAddressLine1': this.validateAddress,
            'recipientCityAU': this.validateCity,
            'recipientStateAU': this.validateState,
            'recipientPostcodeAU': this.validatePostcode,
        };
    },
    pushAnalytics : function(cmp, step) {
        // we expect something to be returned here, if nothing returned means a technical issue
        if(cmp.get('v.wizardData.eddStatus') != '') {
            var duplicateCaseText = 'new';
            if(cmp.get('v.wizardData.duplicateCase') != '') {
                duplicateCaseText = 'duplicate';
            }
            var latestEventLocationMessage = cmp.get('v.wizardData.latestEventLocationMessage');
            var alertMessage=cmp.get('v.wizardData.trackStatusValue');
            if(!$A.util.isEmpty(latestEventLocationMessage) || !$A.util.isUndefined(latestEventLocationMessage))
            {
                var alertMessage = latestEventLocationMessage;
                
            }
            
            var isEligibleForMyNetworkAssignment = cmp.get('v.wizardData.isEligibleForMyNetworkAssignment') ? 'yes' : 'no';
            
            // building the analytics params object
            var analyticsObject = {
                form: {
                    name: 'form:' + cmp.get('v.pageTitle'),
                    step: step,
                    stage: '',
                    detail: 'article status='+alertMessage+'|case='+duplicateCaseText + '|network eligibility='+isEligibleForMyNetworkAssignment,
                    product: cmp.get('v.wizardData.trackingId')
                }
            };
            
            // calling the analytics API methods
            window.AP_ANALYTICS_HELPER.trackByObject({
                trackingType: 'helpsupport-form-navigate',
                componentAttributes: analyticsObject
            });
            
        } else {
            console.log("ERROR : Status didn't receive!");
        }
    },
})