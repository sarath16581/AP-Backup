/**
 * Created by nmain on 28/05/2018.
 */
({
    setRadioName: function(cmp, radioGroupName, selectedRadioId, selectedRadioName) { 
        var selectedRadio = cmp.get(selectedRadioId)
        var radioList = cmp.get(radioGroupName)
        for (var i=0; i<radioList.length; i++) {
            var item = radioList[i];
            if (item.id === selectedRadio) {
                cmp.set(selectedRadioName, item.label)
                return;
            }
        }        
    },
    validateRadioButtons: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Choose an option");
    },
    validateEnquiryDetails: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter equiry details")
    },
    validateCondition: function(cmp, showError) {
        return this.validateNotFalse(cmp, showError, "Tick box to proceed")
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
        var mailRedirectionType = cmp.get('v.wizardData.selectedRadio1Name');
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
        if(mailRedirectionType == 'Mail redirection')
        {
            // DDS-5880: separate the address validation for 'Within Australia' & 'Overseas'
            let serviceDomain = cmp.get('v.wizardData.selectedRadio4Name');
            if (serviceDomain == 'Within Australia')
            {
                if ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress)) {
                    isValid = false;
                }
            } else if (serviceDomain == 'Overseas')
            {
                !this.validateOverseaAddress(cmp) && (isValid = false);
            }
        }
        if ($A.util.isEmpty(incorrectDeliveryAddress) || $A.util.isUndefined(incorrectDeliveryAddress)) {
            isValid = false;
        }
        return isValid;
    },
    updateErrorSummary: function(cmp, allInputs) {
        var errors = [];
        var selectedDeliveryAddress = cmp.get('v.wizardData.selectedDeliveryAddress');
        var incorrectDeliveryAddress = cmp.get('v.wizardData.incorrectDeliveryAddress');
        var IssueName = cmp.get("v.wizardData.IssueName");
        var mailRedirectionType = cmp.get('v.wizardData.selectedRadio1Name');
        var errorMessage = (mailRedirectionType == 'Mail redirection' ? 'Old address' : 'Hold address');
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
        if(mailRedirectionType == 'Mail redirection')
        {
            // DDS-5880: separate the address validation for 'Within Australia' & 'Overseas'
            let serviceDomain = cmp.get('v.wizardData.selectedRadio4Name');
            if (serviceDomain == 'Within Australia')
            {
                if ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress)) {
                    errors.push({name: 'AMENewDeliveryAddress', label: 'New address', error: ''});
                }
            } else if (serviceDomain == 'Overseas')
            {
                !this.validateOverseaAddress(cmp) && errors.push({name: 'AMENewDeliveryAddress', label: 'New address', error: ''});
            }
        }
        if ($A.util.isEmpty(incorrectDeliveryAddress) || $A.util.isUndefined(incorrectDeliveryAddress)) {
            errors.push({name: 'AMEOldDeliveryAddress', label: errorMessage , error: ''});
        }
        cmp.set('v.errors', errors);
    },
    validationMap: function() {
        return {
            'givenName0': this.validateGivenName, 
            'givenName1': this.validateGivenName, 
            'givenName2': this.validateGivenName, 
            'givenName3': this.validateGivenName, 
            'givenName4': this.validateGivenName, 
            'givenName5': this.validateGivenName, 
            'givenName6': this.validateGivenName,
            'givenName7': this.validateGivenName,
            'givenName8': this.validateGivenName,
            'surname0': this.validateSurname,
            'surname1': this.validateSurname,
            'surname2': this.validateSurname,
            'surname3': this.validateSurname,
            'surname4': this.validateSurname,
            'surname5': this.validateSurname,
            'surname6': this.validateSurname,
            'surname7': this.validateSurname,
            'surname8': this.validateSurname,
            'enquiryTypeRadioButtons': this.validateRadioButtons, 
            'emailOrPhoneRadioButtons': this.validateRadioButtons, 
            'parcelsOrLettersRadioButtons': this.validateRadioButtons, 
            'withinAusOrOverseasRadioButtons': this.validateRadioButtons, 
            'emailAddress': this.validateEmail, 
            'phoneNumber': this.validatePhone, 
            'addressLine1': this.validateAddress, 
            'city': this.validateCity, 
            'state': this.validateState, 
            'postcode': this.validatePostcode, 
            'newCountry': this.validateCountry, 
            'newAddressLine1': this.validateAddress, 
            'newCityAU': this.validateCity, 
            'newStateAU': this.validateState, 
            'newPostcodeAU': this.validatePostcode, 
            'enquiryDetails': this.validateEnquiryDetails, 
            'conditionCheckbox': this.validateCondition, 
        };
    },

    /**
     * Validating method for overseas address
     * @param {*} component 
     * @return return false if no information is filled in else true
     */
    validateOverseaAddress : function(component)
    {
        let newCountry = component.get('v.wizardData.newCountry') || '';
        let newAddressLine1 = component.get('v.wizardData.newAddressLine1') || '';
        let newAddressLine2 = component.get('v.wizardData.newAddressLine2') || '';
        let newCity = component.get('v.wizardData.newCity') || '';
        let newState = component.get('v.wizardData.newState') || '';
        let newPostcode = component.get('v.wizardData.newPostcode') || '';
        let newAddress = newCountry + newAddressLine1 + newAddressLine2 + newCity + newState + newPostcode; // no separator to ensure the empty checking
        return (!$A.util.isEmpty(newAddress) && !$A.util.isUndefined(newAddress));
    }
})