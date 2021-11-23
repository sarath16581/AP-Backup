/*
  * @changeLog : 19/06/2020: hara.sahoo@auspost.com.au reset the showErrorSummary flag.
*/
({
    doInit: function(cmp, event, helper) {
        if (!cmp.get("v.wizardData.household")) {
            cmp.set("v.wizardData.household", [{
                givenName: "",
                surname: ""
            }]);
        }
    },

    addPerson: function(cmp, event, helper) {
        var household = cmp.get("v.wizardData.household");
        if (household.length < 7) {
            household.push({
                givenName: "",
                surname: ""
            });
            cmp.set("v.wizardData.household", household);
            cmp.set('v.checkInputsOnRender', true);
        } else {
            cmp.find('addPersonError').set('v.error', "Maximum 6 people can be added");
        }

        var activeGivenName = "givenName" + (household.length -1);
        var nextExists = document.getElementById("activeGivenName");
        var checkExist = setInterval(function() {
            if (nextExists = true) {
                document.getElementById("givenName" + (household.length - 1)).focus();
                clearInterval(checkExist);
            }
        }, 100); // check every 100ms

    },

    removePerson: function(cmp, event, helper) {
        cmp.find('addPersonError').set('v.error', null);
        var household = cmp.get("v.wizardData.household");
        if (household.length > 1) {
            var allInputs = cmp.find("chasInput");
            var givenNames = [];
            var surnames = [];
            for (var i=0; i<allInputs.length; i++) {
                var input = allInputs[i];
                if (input.get('v.name').indexOf('givenName') !== -1) givenNames.push(input);
                else if (input.get('v.name').indexOf('surname') !== -1) surnames.push(input);
            }
            var isValid = (
                helper.validateNull(givenNames[givenNames.length - 1], true, "Given name must be empty to remove a person") &
                helper.validateNull(surnames[surnames.length - 1], true, "Surname must be empty to remove a person")
            )
            if (isValid) {
                household.pop();
                cmp.set("v.wizardData.household", household);
                cmp.set('v.checkInputsOnRender', true);
            }
        }
    },

    goForward: function(cmp, event, helper) {
        var isValid = helper.checkAllInputs(cmp, true);
        //reset the error flags
        cmp.set('v.error', '');

        // DDS-5880: Add validating for overseas address
        var deliveryAddressIsValid = cmp.get('v.wizardData.selectedRadio4Name') == 'Overseas'? helper.validateOverseaAddress(cmp) : helper.validateAddressNotNull(cmp, true);
        
        //Check if address selected from the AME service is valid

        //-- If all validations are completed then move to next screen
        if (isValid && deliveryAddressIsValid) {
            helper.gotoNextPage(cmp);
        } else {
            helper.showErrorSummary(cmp);
        }
    },

    onchange: function(cmp, event, helper) {
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        var household = cmp.get("v.wizardData.household");
        for (var i=0; i<household.length; i++) {
            if (fieldName === 'givenName' + i) helper.validateGivenName(srcCmp, true);
            else if (fieldName === 'surname' + i) helper.validateSurname(srcCmp, true);
        }
        if (fieldName === 'enquiryTypeRadioButtons') {
            helper.setRadioName(cmp, 'v.enquiryTypeRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        } else if (fieldName === 'emailOrPhoneRadioButtons') {
            helper.setRadioName(cmp, 'v.emailOrPhoneRadioGroup', 'v.wizardData.selectedRadio2', 'v.wizardData.selectedRadio2Name');
        } else if (fieldName === 'parcelsOrLettersRadioButtons') {
            helper.setRadioName(cmp, 'v.parcelsOrLettersRadioGroup', 'v.wizardData.selectedRadio3', 'v.wizardData.selectedRadio3Name');
        } else if (fieldName === 'withinAusOrOverseasRadioButtons') {
            helper.setRadioName(cmp, 'v.withinAusOrOverseasRadioGroup', 'v.wizardData.selectedRadio4', 'v.wizardData.selectedRadio4Name');
        }
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);
    },
    displaymyPostLoginForm : function (cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    getAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock');
    },    
    getSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock');
    },
    getOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock');
    },
    getIncorrectAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, 'AMEAddressBlock1');
    },
    getIncorrectShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.incorrectShowError",showerror);
    },
    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
    },
    //     else if (fieldName === 'emailAddress') helper.validateEmail(srcCmp, true);
    //     else if (fieldName === 'phoneNumber') helper.validatePhone(srcCmp, true);
    //     else if (fieldName === 'addressLine1') helper.validateAddress(srcCmp, true);
    //     else if (fieldName === 'city') helper.validateCity(srcCmp, true);
    //     else if (fieldName === 'state') helper.validateState(srcCmp, true);
    //     else if (fieldName === 'postcode') helper.validatePostcode(srcCmp, true);
    //     else if (fieldName === 'newCountry') helper.validateCountry(srcCmp, true);
    //     else if (fieldName === 'newAddressLine1') helper.validateAddress(srcCmp, true);
    //     else if (fieldName === 'newCityAU') helper.validateCity(srcCmp, true);
    //     else if (fieldName === 'newStateAU') helper.validateState(srcCmp, true);
    //     else if (fieldName === 'newPostcodeAU') helper.validatePostcode(srcCmp, true);
    //     else if (fieldName === 'enquiryDetails') helper.validateEnquiryDetails(srcCmp, true);
    //     else if (fieldName === 'conditionCheckbox') helper.validateCondition(srcCmp, true);


    //     helper.checkAllValid(cmp, false);
    // }

})