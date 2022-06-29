/**
 * Created by nmain on 31/10/2017.
 * History :
 * --------------------------------------------------
 * 2020-04-03 rufus.solomon@auspost.com.au Added support for essential pharma
 * 2021-07-20 hara.sahoo@auspost.com.au Added validation for sentimental value field
 * 2022-06-29 hasantha.liyanage@auspost.com.au Modified : DDS-11414 changed method params for getEDDEstimates
 *                                                        method only requires 2 params, no need to pass whole wizard data
 */
({
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

    checkAllInputs: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('chasInput'));
        var isValid = this.checkEachInput(cmp, allInputs, showError);
        this.updateErrorSummary(cmp, allInputs);
        /* Commented below code on 4/10/2018 for International Missing Item Changes.
           When user enters International tracking number and selects Recipient, next button is enabled to proceed further. */
        /*if(cmp.get('v.wizardData.senderOrRecipientType') === 'International' && cmp.get('v.wizardData.selectedRadio1Name') === 'Recipient'){
            isValid = false;
        }*/

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
        var recipientDeliveryAddress = cmp.get('v.wizardData.recipientDeliveryAddress');
        var recipientOrSender = cmp.get("v.wizardData.selectedRadio1Name");
        var senderOrRecipientType = cmp.get('v.wizardData.senderOrRecipientType');
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
        if (senderOrRecipientType == 'Domestic' && ( $A.util.isEmpty(recipientDeliveryAddress) || $A.util.isUndefined(recipientDeliveryAddress)) ){
            isValid = false;
        }
        if (recipientOrSender == 'Sender' && ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress))) {
            isValid = false;
        }
        return isValid;
    },
    updateErrorSummary: function(cmp, allInputs) {
        var errors = [];
        var selectedDeliveryAddress = cmp.get('v.wizardData.selectedDeliveryAddress');
        var recipientDeliveryAddress = cmp.get('v.wizardData.recipientDeliveryAddress');
        var recipientOrSender = cmp.get("v.wizardData.selectedRadio1Name");
        var senderOrRecipientType = cmp.get('v.wizardData.senderOrRecipientType');
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
        if (senderOrRecipientType == 'Domestic' && ( $A.util.isEmpty(recipientDeliveryAddress) || $A.util.isUndefined(recipientDeliveryAddress)) ) {
            errors.push({name: 'AMERecipientAddress', label: 'Delivery address', error: ''});
        }
        if (recipientOrSender == 'Sender' && ($A.util.isEmpty(selectedDeliveryAddress) || $A.util.isUndefined(selectedDeliveryAddress))) {
            errors.push({name: 'AMEDeliveryAddress', label: 'Sender address', error: ''});
        }
        cmp.set('v.errors', errors);
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
    getEDDServiceEstimates : function (component,event, helper)
    {
        try {
            // call server method to invoke the EDD service
            var action = component.get("c.getEDDEstimates");
            // set method parameters
            var objParams = {
                'articleId': component.get('v.wizardData.trackingId'),
                'recipientPostcode': component.get('v.wizardData.recipientPostcode')
            };
            action.setParams(objParams);
            // server side return
            action.setCallback(this, function (response) {
                let status = response.getState();
                if (status === 'SUCCESS') {
                    var returnObj = JSON.parse((JSON.stringify(response.getReturnValue())));
                    // update the wizard with the response data, else use the previous copy of the wizard data
                    component.set('v.wizardData.deliveredByDateOrEDD', $A.util.isEmpty(returnObj["deliveredByDateOrEDD"]) ? component.get('v.wizardData.deliveredByDateOrEDD') : returnObj["deliveredByDateOrEDD"]);
                    component.set('v.wizardData.deliveredByDateFrom', $A.util.isEmpty(returnObj["deliveredByDateFrom"]) ? component.get('v.wizardData.deliveredByDateFrom') : returnObj["deliveredByDateFrom"]);
                    component.set('v.wizardData.deliveredByDateTo', $A.util.isEmpty(returnObj["deliveredByDateTo"]) ? component.get('v.wizardData.deliveredByDateTo') : returnObj["deliveredByDateTo"]);
                    component.set('v.wizardData.deliveredByDateToUntil', $A.util.isEmpty(returnObj["deliveredByDateToUntil"]) ? component.get('v.wizardData.deliveredByDateToUntil') : returnObj["deliveredByDateToUntil"]);
                    component.set('v.wizardData.isEnquiryDateWithinEDD', $A.util.isEmpty(returnObj["isEnquiryDateWithinEDD"]) ? component.get('v.wizardData.isEnquiryDateWithinEDD') : returnObj["isEnquiryDateWithinEDD"]);
                    component.set('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays', $A.util.isEmpty(returnObj["isEnquiryDateWithinEDDPlusBusinessdays"]) ? component.get('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays') : returnObj["isEnquiryDateWithinEDDPlusBusinessdays"]);
                    component.set('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays', $A.util.isEmpty(returnObj["isEnquiryDatePastEDDPlusBusinessdays"]) ? component.get('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays') : returnObj["isEnquiryDatePastEDDPlusBusinessdays"]);
                    component.set('v.wizardData.deliveredByDatePlusBusinessDays', $A.util.isEmpty(returnObj["deliveredByDatePlusBusinessDays"]) ? component.get('v.wizardData.deliveredByDatePlusBusinessDays') : returnObj["deliveredByDatePlusBusinessDays"]);
                    component.set('v.wizardData.isEDDEstimated', $A.util.isEmpty(returnObj["isEDDEstimated"]) ? component.get('v.wizardData.isEDDEstimated') : returnObj["isEDDEstimated"]);
                    component.set('v.wizardData.isNoEddReturned', $A.util.isEmpty(returnObj["isNoEddReturned"]) ? component.get('v.wizardData.isNoEddReturned') : returnObj["isNoEddReturned"]);
                } else if (state === "INCOMPLETE") {
                    // Enable debugging if required
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            // Enable debugging if required
                        }
                    }
                }
            })

            $A.enqueueAction(action);
        } catch (err) {
            console.log('ERROR EDD service estimates: '+err);
        }
    },

        // Must use single '&' so that it runs through all functions.
        // var isValid = false;
        //-- Item Type is International
        // if(cmp.get('v.wizardData.senderOrRecipientType') == 'International'){
        //     isValid =  (
        //         this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError) & 
        //         this.validateRadioButtons(cmp.find("parcelOrLetterRadioButtons"), showError)& 
        //         this.validateRadioButtons(cmp.find("internationalParcelSentTypeRadioButtons"), showError)& 
        //         this.validateItemSentDate(cmp.find("ChasItemSentDate"), showError)& 
        //         this.validateTextArea(cmp.find("chasPlsProvideDetailsTxtArea"), showError)& 
        //         this.validateCountry(cmp.find("senderCountry"), showError)& 
        //         this.validateAddress(cmp.find("senderAddressLine1"), showError)& 
        //         this.validateGivenName(cmp.find("recipientGivenName"), showError)& 
        //         this.validateSurname(cmp.find("recipientSurname"), showError)& 
        //         this.validateCountry(cmp.find("recipientCountry"), showError)&
        //         this.validateAddress(cmp.find("recipientAddressLine1"), showError)&
        //         this.validateItemValue(cmp.find("ChasItemValue"), showError)
        //     );
        // } //-- Item Type is Domestic
        // else if(cmp.get('v.wizardData.senderOrRecipientType') == 'Domestic'){
            
        //     //- Recipient
        //     if(cmp.get('v.wizardData.selectedRadio1Name') == 'Recipient'){
        //         //-- 'Letter' is selected
        //         if(cmp.get('v.wizardData.selectedRadio2Name')== 'Letter'){
        //             isValid =  (
        //                 this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError) & 
        //                 this.validateRadioButtons(cmp.find("parcelOrLetterRadioButtons"), showError)& 
        //                 this.validateRadioButtons(cmp.find("domesticLetterSentTypeRadioButtons"), showError)&
        //                 this.validateItemSentDate(cmp.find("ChasItemSentDate"), showError)& 
        //                 this.validateTextArea(cmp.find("chasPlsProvideDetailsTxtArea"), showError)& 
        //                 this.validateAddress(cmp.find("recipientAddressLine1"), showError)&
        //                 this.validateCity(cmp.find("recipientCityAU"), showError)&
        //                 this.validateState(cmp.find("recipientStateAU"), showError)&
        //                 this.validatePostcode(cmp.find("recipientPostcodeAU"), showError)
        //             );
        //         }//-- 'Parcel' is selected or nothing is selected
        //         else if(cmp.get('v.wizardData.selectedRadio2Name') == null || cmp.get('v.wizardData.selectedRadio2Name') == '' 
        //                 || cmp.get('v.wizardData.selectedRadio2Name') == 'Parcel'){
        //             isValid =  (
        //                 this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError) & 
        //                 this.validateRadioButtons(cmp.find("parcelOrLetterRadioButtons"), showError)& 
        //                 this.validateRadioButtons(cmp.find("domesticParcelSentTypeRadioButtons"), showError)&
        //                 this.validateItemSentDate(cmp.find("ChasItemSentDate"), showError)& 
        //                 this.validateTextArea(cmp.find("chasPlsProvideDetailsTxtArea"), showError)&
        //                 this.validateAddress(cmp.find("recipientAddressLine1"), showError)&
        //                 this.validateCity(cmp.find("recipientCityAU"), showError)&
        //                 this.validateState(cmp.find("recipientStateAU"), showError)&
        //                 this.validatePostcode(cmp.find("recipientPostcodeAU"), showError)
        //             );
        //         }
               
        //     }else if(cmp.get('v.wizardData.selectedRadio1Name') == 'Sender'){
        //         if(cmp.get('v.wizardData.selectedRadio2Name')== 'Letter'){
        //             isValid =  (
        //                 this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError) & 
        //                 this.validateRadioButtons(cmp.find("parcelOrLetterRadioButtons"), showError)& 
        //                 this.validateRadioButtons(cmp.find("domesticLetterSentTypeRadioButtons"), showError)&
        //                 this.validateItemSentDate(cmp.find("ChasItemSentDate"), showError)& 
        //                 this.validateTextArea(cmp.find("chasPlsProvideDetailsTxtArea"), showError)& 
        //                 this.validateAddress(cmp.find("senderAddressLine1"), showError)& 
        //                 this.validateCity(cmp.find("senderCityAU"), showError)&
        //                 this.validateState(cmp.find("senderStateAU"), showError)& 
        //                 this.validatePostcode(cmp.find("senderPostcodeAU"), showError)& 
        //                 this.validateGivenName(cmp.find("recipientGivenName"), showError)&
        //                 this.validateSurname(cmp.find("recipientSurname"), showError)&
        //                 this.validateAddress(cmp.find("recipientAddressLine1"), showError)&
        //                 this.validateCity(cmp.find("recipientCityAU"), showError)&
        //                 this.validateState(cmp.find("recipientStateAU"), showError)&
        //                 this.validatePostcode(cmp.find("recipientPostcodeAU"), showError)&
        //                 this.validateItemValue(cmp.find("ChasItemValue"), showError)
        //             );
        //         }else if(cmp.get('v.wizardData.selectedRadio2Name') == null || cmp.get('v.wizardData.selectedRadio2Name') ==''
        //                  ||cmp.get('v.wizardData.selectedRadio2Name') == 'Parcel'){
        //             isValid =  (
        //                 this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError) & 
        //                 this.validateRadioButtons(cmp.find("parcelOrLetterRadioButtons"), showError)& 
        //                 this.validateRadioButtons(cmp.find("domesticParcelSentTypeRadioButtons"), showError)&
        //                 this.validateItemSentDate(cmp.find("ChasItemSentDate"), showError)& 
        //                 this.validateTextArea(cmp.find("chasPlsProvideDetailsTxtArea"), showError)& 
        //                 this.validateAddress(cmp.find("senderAddressLine1"), showError)& 
        //                 this.validateCity(cmp.find("senderCityAU"), showError)&
        //                 this.validateState(cmp.find("senderStateAU"), showError)& 
        //                 this.validatePostcode(cmp.find("senderPostcodeAU"), showError)& 
        //                 this.validateGivenName(cmp.find("recipientGivenName"), showError)&
        //                 this.validateSurname(cmp.find("recipientSurname"), showError)&
        //                 this.validateAddress(cmp.find("recipientAddressLine1"), showError)&
        //                 this.validateCity(cmp.find("recipientCityAU"), showError)&
        //                 this.validateState(cmp.find("recipientStateAU"), showError)&
        //                 this.validatePostcode(cmp.find("recipientPostcodeAU"), showError)&
        //                 this.validateItemValue(cmp.find("ChasItemValue"), showError)
        //             );
        //         }
                
        //     }else{
        //         //-- Not selected Sender/Recipient so validate
        //         isValid =  (
        //                 this.validateRadioButtons(cmp.find("recipientOrSenderRadioButtons"), showError)
        //             );
        //     }
        // } 
        //console.log('All field Validations='+isValid);
    
    removeSentTypeFromWizardData: function(cmp){
        //-- setting below to null in wizardData if user selected 'Registered Post' and choose 'Parcel' option
        if(cmp.get('v.wizardData.selectedRadio3Name') == 'Registered Post' && cmp.get('v.wizardData.selectedRadio2Name') == 'Parcel'){
            cmp.set('v.wizardData.selectedRadio3', null);
            cmp.set('v.wizardData.selectedRadio3Name', null);
        }
    }
    
    // setSelectedRadioName1: function(cmp) { 
    //     //console.log('setSelectedRadioName1 helper');
    //     if(cmp.get('v.wizardData.selectedRadio1') == 'firstRadio'){
    //         cmp.set('v.wizardData.selectedRadio1Name','Recipient')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio1') == 'secondRadio'){
    //         cmp.set('v.wizardData.selectedRadio1Name','Sender')
    //     }
        
    // },
    
    // setSelectedRadioName2: function(cmp) { 
    //     console.log('setSelectedRadioName2 helper');
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'thirdRadio'){
    //         cmp.set('v.wizardData.selectedRadio2Name','Parcel')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'fourthRadio'){
    //         cmp.set('v.wizardData.selectedRadio2Name','Letter')
    //     }
        
    // },
    
    // setSelectedRadioName3_1: function(cmp) { 
    //     console.log('setSelectedRadioName3_1 helper');
    //     if(cmp.get('v.wizardData.selectedRadio3') == 'fifthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Regular Post')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'sixthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Express Post')
    //     }
        
    // },
    
    // setSelectedRadioName3_2: function(cmp) { 
    //     //console.log('setSelectedRadioName3_2 helper='+cmp.get('v.wizardData.selectedRadio3'));
    //     if(cmp.get('v.wizardData.selectedRadio3') == 'fifthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Regular Post')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio3') == 'sixthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Express Post')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio3') == 'seventhRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Registered Post')
    //     }
    //    // console.log('setSelectedRadioName3_2 helper...='+cmp.get('v.wizardData.selectedRadio3Name'));
    // },
    
    // setSelectedRadioName3_3: function(cmp) { 
    //     console.log('setSelectedRadioName3_3 helper');
    //     if(cmp.get('v.wizardData.selectedRadio3') == 'tenthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Courier')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'eleventhRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Express')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'twelthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Standard')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'thirteenthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Economy Air')
    //     }
    //     if(cmp.get('v.wizardData.selectedRadio2') == 'fourteenthRadio'){
    //         cmp.set('v.wizardData.selectedRadio3Name','Economy Sea')
    //     }
        
    // }, 
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    // validateFormAndShowErrors: function(component){
    
    //     console.log('validateFormAndShowErrors........ START');
    //     var self = this;
    //     var showOrHideAllFieldVlidationError =  component.get('v.showOrHideAllFieldVlidationError');
    //     console.log('showOrHideAllFieldVlidationError='+showOrHideAllFieldVlidationError);
    //     var isValid = true;
    
    //     //-- 1. Checking if Sender/Recipient is selected or not
    //     if(component.get('v.wizardData.selectedRadio1') == null){
    //         isValid = false;
    //         //-- Showing  error message Div
    //         if(showOrHideAllFieldVlidationError){
    //             var inputCmp = component.find("recipientOrSenderErrorMsg");
    //             $A.util.removeClass(inputCmp, "slds-hide");
    //         }else{  //IF this validation function is calling from on change of any wizard field and not from 'Next' button
    //             //then if any field validation is fail returning back as there is no need to check other fields
    //             self.disableNextButton(component); 
    //             return isValid;
    //         }
    
    //     }else{
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Hiding  error message Div
    //             var inputCmp = component.find("recipientOrSenderErrorMsg");
    //             $A.util.addClass(inputCmp, "slds-hide");
    //         }
    //     }
    
    //     //-- 2. Checking if Parcel/Letter is selected or not
    //     if(component.get('v.wizardData.selectedRadio2') == null){
    //         isValid = false;
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Showing  error message Div
    //             var inputCmp = component.find("parcelOrLetterErrorMsg");
    //             $A.util.removeClass(inputCmp, "slds-hide");
    //         }else{
    //             self.disableNextButton(component); 
    //             return isValid;
    //         }
    
    //     }else{
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Hiding error message Div
    //             var inputCmp = component.find("parcelOrLetterErrorMsg");
    //             $A.util.addClass(inputCmp, "slds-hide");
    //         }
    //     }
    
    //     //--3.  Checking if sentType is selected or not
    //     if(component.get('v.wizardData.selectedRadio3') == null){
    //         isValid = false;
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Showing  error message Div
    //             var inputCmp = component.find("sentTypeErrorMsg");
    //             $A.util.removeClass(inputCmp, "slds-hide");
    //         }
    //         else{
    //             self.disableNextButton(component); 
    //             return isValid;
    //         }
    
    //     }else{
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Hiding  error message Div
    //             var inputCmp = component.find("sentTypeErrorMsg");
    //             $A.util.addClass(inputCmp, "slds-hide");
    //         }
    //     }
    //     console.log('777');
    
    //     //--4. validating itemSentDate
    //     var itemSentDate = component.find('itemSentDate');
    //     console.log('itemSentDate='+itemSentDate);
    //     if(itemSentDate){
    //         console.log('itemSentDate000');
    //         var itemSentDateVal     = itemSentDate.get('v.value');
    
    //         if(( (!itemSentDateVal || itemSentDateVal.trim().length === 0 ))){
    //             isValid = false;
    //             if(showOrHideAllFieldVlidationError){
    //                 itemSentDate.set("v.errors", [{message:"Enter Date as DD/MM/YY"}]);
    //             }else{
    //                 self.disableNextButton(component); 
    //                 return isValid;
    //             }
    
    //         }else{
    //             if(showOrHideAllFieldVlidationError){
    //                 itemSentDate.set("v.errors", null);
    //             }
    //         } 
    //     }
    //     //}
    //     //-- 5. validating details (textArea)
    //     if(component.get('v.wizardData.complaintDetails') == null){
    //         isValid = false;
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Showing  error message Div
    //             var inputCmp = component.find("detailErrorMsg");
    //             $A.util.removeClass(inputCmp, "slds-hide");
    //         }else{
    //             self.disableNextButton(component); 
    //             return isValid;
    //         }
    
    //     }else{
    //         if(showOrHideAllFieldVlidationError){
    //             //-- Hiding error message Div
    //             var inputCmp = component.find("detailErrorMsg");
    //             $A.util.addClass(inputCmp, "slds-hide");
    //         }
    //     }
    //     console.log('pp'+component.get('v.wizardData.senderOrRecipientType'));
    
    //     //-- 6. Validating of Domestic sender type address
    //     if(component.get('v.wizardData.senderOrRecipientType')!=null && component.get('v.wizardData.senderOrRecipientType') =='Domestic'){
    //         //-- Validate Recipient or Sender Address
    //         var recipientOrSender = 'Recipient';
    //         var validateGivenNameNSurname = false;
    //         var childCmp = null;
    
    //         if(component.get('v.wizardData.selectedRadio1Name') =='Sender')  {
    //             childCmp =  component.find('domesticSenderAddressChildCmp');
    //             recipientOrSender= 'Sender';
    //         } else{
    //             childCmp =  component.find('domesticRecipientChildCmp');
    //         }  
    //         console.log('ii');
    //         if(childCmp){
    //             var isDomesticAddressIsValidated = childCmp.handleAddressValidationCompEvnt('Domestic', recipientOrSender, true, validateGivenNameNSurname, showOrHideAllFieldVlidationError);
    //             console.log('isDomesticRecipientAddressIsValidated=='+isDomesticAddressIsValidated);
    //             if(!isDomesticAddressIsValidated){
    //                 isValid = false;
    //             }
    //         }
    //         if(component.get('v.wizardData.selectedRadio1Name') =='Sender'){
    //             var validateGivenNameNSurname = true;
    //             //--Validate Domestic Sender's Recipient Address
    //             var childCmp = component.find('domesticSenderRecipientAddressChildCmp');
    //             console.log('childCmp=='+childCmp);
    //             if(childCmp){
    //                 var isDomesticAddressIsValidated = childCmp.handleAddressValidationCompEvnt('Domestic', 'Recipient', true, validateGivenNameNSurname, showOrHideAllFieldVlidationError);
    //                 console.log('isDomesticSenderAddressIsValidated=='+isDomesticAddressIsValidated);
    //                 if(!isDomesticAddressIsValidated){
    //                     isValid = false;
    //                 }
    //             }
    //         }
    
    //     }
    //     //-- 6. Validating of International sender type address
    //     if(component.get('v.wizardData.senderOrRecipientType') =='International'){
    //         //if(component.get('v.wizardData.selectedRadio1Name') =='Sender'){
    //         // var validateGivenNameNSurname = true;
    //         //--Validate Domestic Sender's Recipient Address
    //         var childCmp = component.find('internationalSenderAddressChildCmp');
    //         console.log('childCmp=='+childCmp);
    //         if(childCmp){
    //             var isInternationalAddressSenderIsValidated = childCmp.handleAddressValidationCompEvnt('International', 'Sender', true, false, showOrHideAllFieldVlidationError);
    //             console.log('isInternationalAddressSenderIsValidated=='+isInternationalAddressSenderIsValidated);
    //             if(!isInternationalAddressSenderIsValidated){
    //                 isValid = false;
    //             }
    //         }
    //         if(childCmp){
    //             var childCmp2 = component.find('internationalSenderRecipientAddressChildCmp');
    //             console.log('childCmp2=='+childCmp2);
    //             var isInternationalAddressSenderIsValidated2= childCmp2.handleAddressValidationCompEvnt('International', 'Recipient',true, true, showOrHideAllFieldVlidationError);
    //             console.log('isInternationalAddressSenderIsValidated2=='+isInternationalAddressSenderIsValidated2);
    //             if(!isInternationalAddressSenderIsValidated2){
    //                 isValid = false;
    //             }
    //         }
    //         //}
    
    //     }
    //     console.log('All Page Fields are Valid?isValid='+isValid);
    
    //     if(isValid){
    //         self.enableNextButton(component);
    //     }else{
    //         self.disableNextButton(component);
    //     }
    //     console.log('validateFormAndShowErrors........ END');
    //     return isValid;
    // },
    
    // enableNextButton: function(component){
    //     component.set('v.enableOrDisableNextBtnVal', 'Enable');
    //     console.log('Enabled Next Button');
    // },
    
    // disableNextButton: function(component){
    //     component.set('v.enableOrDisableNextBtnVal', 'Disable');
    //     console.log('Disabled Next Button');
    // }
    
})