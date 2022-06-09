/*
 * @changelog : 
    * Modified by   : 2020-07-06 : Modified the JS file for additional logic to the navigation screens in gotoNextPage() and gotoPrevPage() method.
    * Modified by   : 2020-08-31 : Catered for the safari browser date format issue
    * Modified by   : 2020-10-28 : INC1657584 : Snigdha : Update for the IE date format issue
    * Modified by   : 2020-01-14 : Hara Sahoo: Changes made as part of enquiry submission in an unauthenticated user context- Added storeEncryPtWizardDataAndNavigateToMyPost
    * Modified by   : 2022-05-30 : Thang Nguyen : [DDS-10785] Added navigatePage parameter for gotoPage function
 */
({
    gotoNextPage : function(cmp) {
        var gotoConditionalPage = '';
        var payLoad = '';
        if (arguments.length == 1) {
            var nextPage = cmp.get('v.nextPage');
            var wizardPageEvent = cmp.getEvent("wizardPageEvent");
            wizardPageEvent.setParams({ "type" : "nav_next"});
            
            if (nextPage) {
                wizardPageEvent.setParam("nextPage", nextPage);
            }
        } else if(arguments.length == 2)
        {
            // take second argument, optional parameters
            gotoConditionalPage = arguments[1]; 
            var nextPage = gotoConditionalPage;
            var wizardPageEvent = cmp.getEvent("wizardPageEvent");
            wizardPageEvent.setParams({ "type" : "nav_next"});
            
            if (nextPage) {
                wizardPageEvent.setParam("nextPage", nextPage);
            }
        } 
        
        wizardPageEvent.fire();
    },
    
    gotoPrevPage : function(cmp) {
        var gotoConditionalPage = '';
        if (arguments.length == 1) {
            var prevPage = cmp.get('v.prevPage');
            var wizardPageEvent = cmp.getEvent("wizardPageEvent");
            wizardPageEvent.setParams({ "type" : "nav_prev"});
            
            if (prevPage) {
                wizardPageEvent.setParam("prevPage", prevPage);
            }
        }
        else if(arguments.length == 2)
        {
            // take second argument, optional parameters
            gotoConditionalPage = arguments[1]; 
            var prevPage = gotoConditionalPage;
            var wizardPageEvent = cmp.getEvent("wizardPageEvent");
            wizardPageEvent.setParams({ "type" : "nav_prev"});
            
            if (prevPage) {
                wizardPageEvent.setParam("prevPage", prevPage);
            }
        } 
        
        wizardPageEvent.fire();
    },
    
    gotoPage : function(cmp, navigatePage) {
        var navigateTo = cmp.get('v.gotoPages');
        var urlPage = '';
        if($A.util.isEmpty(navigatePage) || $A.util.isUndefined(navigatePage)){
            urlPage = navigateTo.missingItemPage;
        }else{
            urlPage = navigateTo[navigatePage];
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": urlPage
        });
        urlEvent.fire();
    },
    
    showErrorSummary: function(cmp) {
        cmp.set('v.showErrorSummary', true);
        window.scrollTo(0,0);
        var chasErrorSummary = document.getElementById("ChasErrorSummary");
        if (chasErrorSummary) chasErrorSummary.focus();
    },
    
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
    
    checkAllInputs: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('chasInput'));
        var isValid = this.checkInputs(allInputs, showError);
        this.updateErrorSummary(cmp, allInputs);
        
        if(isValid){
            cmp.set('v.formValid', true);
        }else{
            cmp.set('v.formValid', false);
        }
        return isValid;
    },
    
    checkInputs: function(inputs, showError) {
        var validationMap = this.validationMap();
        var isValid = true;
        for (var i=0; i<inputs.length; i++) {
            var inputCmp = inputs[i];
            var inputName = inputCmp.get('v.name');
            var inputRequired = inputCmp.get('v.required');
            var validationFunction = validationMap[inputName];
            if (validationFunction) validationFunction.bind(this)(inputCmp, showError);
            // We only set error to null when there are no errors. If error is undefined then there may still be errors.
            // Undefined , required == not valid
            // Defined , required == not valid
            // Null, required == valid
            // 
            // Undefined, not required == valid
            // Defined, not required == not valid
            // Null, not required == valid
            var inputError = inputCmp.get('v.error');
            isValid = isValid && !inputError && (!inputRequired || (inputError === null && inputRequired));
        }
        return isValid;
    },
    
    updateErrorSummary: function(cmp, allInputs) {
        var errors = [];
        
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
        cmp.set('v.errors', errors);
    },
    
    
    /////////////////////////////////////////
    ////////////// VALIDATIONS //////////////
    
    validateNotFalse : function(cmp, showError, errorMsg) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val) {
                isValid = false;
                cmp.set('v.error', errorMsg);
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    
    validateNotNull : function(cmp, showError, errorMsg) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', errorMsg);
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    
    validateNull : function(cmp, showError, errorMsg) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (val && val.trim()) {
                isValid = false;
                cmp.set('v.error', errorMsg);
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    
    validateNotNullSelect : function(cmp, showError, errorMsg) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || val.startsWith("Select")) {
                isValid = false;
                cmp.set('v.error', errorMsg);
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validateGivenName : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', "Enter given name");
            } else if (val.match(/\d/)) {
                isValid = false;
                cmp.set('v.error', "Please enter letters and/or special characters only");
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validateSurname : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', "Enter surname");
            }else if (val.match(/\d/)) {
                isValid = false;
                cmp.set('v.error', "Please enter letters and/or special characters only");
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validateEmail : function(cmp, showError, errorMessage) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', errorMessage || "Enter email address");
            }else if (!val.match(regExpEmailformat)) {
                isValid = false;
                cmp.set('v.error', errorMessage || "Enter valid email address");
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validatePhone : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (val) {
                var valTrimmed = val.replace(/[\s\)\(-]+/g, '');
                if (
                    valTrimmed.match(/^0\d{9}$/) ||     // 10 character number starting with 0
                    valTrimmed.match(/^\+?61\d{9}$/) || // 12 character number starting with +61
                    valTrimmed.match(/^13\d{4}$/) ||    // 6 character number starting with 13
                    valTrimmed.match(/^1300\d{6}$/)     // 10 character number starting with 1300
                ){
                    cmp.set('v.error', null);
                } else {
                    isValid = false;
                    cmp.set('v.error', "Enter valid phone number including area code");
                }
            } else {
                isValid = false;
                cmp.set('v.error', "Enter phone number");
            }
        }
        return isValid;
    },
    validatePostcode : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', "Enter postcode");
            } else if (val.match(/^\d{4}$/)) {
                cmp.set('v.error', null);
            } else {
                isValid = false;
                cmp.set('v.error', "Enter valid postcode");
            }
        }
        return isValid;
    },
    validateAddress: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter address")
    },
    validateCity: function(cmp, showError) {
        return this.validateNotNull(cmp, showError, "Enter suburb or city")
    },
    validateSelect: function(cmp, showError) {
        return this.validateNotNullSelect(cmp, showError, "Choose an option")
    },
    validateState: function(cmp, showError) {
        return this.validateNotNullSelect(cmp, showError, "Choose an option")
    },
    validateCountry: function(cmp, showError) {
        return this.validateNotNullSelect(cmp, showError, "Choose a country")
    },
    validateCurrency: function(cmp, showError) {                   //-- Added by Jansi - Jul 17 2018
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (val && !val.match(/^\d+(\.\d+)?$/)){
                isValid = false;
                cmp.set('v.error', "Enter a valid number");
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validateDate: function(cmp, showError) {   //-- Added by Jansi - Jul 17 2018
        var isSafari = false;
        //INC1657584 : Snigdha : To cater to dateformat issue in IE
        var isSafariorIE = false;
        
        let isValid = true;
        var inputDate;
        if(this.checkBrowser(cmp).includes('Safari')|| this.checkBrowser(cmp).includes('IE')) {
            //isSafari = true;
            isSafariorIE = true;
        }
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            let val = cmp.get('v.value');
            if(isSafariorIE) {
                var bits = val.split(/[- /.]/);
                inputDate = new Date(bits[2], bits[1]-1, bits[0]).setHours(0,0,0);
            }else {
                inputDate = new Date(val).setHours(0,0,0);
            }
            let today = new Date().setHours(0,0,0);
            
            if (!val ||
                // !val.match(/^(?:\d{4}([- /.])\d{2}\1\d{2}|\d{2}([- /.])\d{2}\2\d{4})$/) ||
                !val.match(/^(?:\d{4}([- /.])\d{1,2}\1\d{1,2}|\d{1,2}([- /.])\d{1,2}\2\d{4})$/) ||
                !this.isValidDate(val)) {
                    isValid = false;
                    cmp.set('v.error', "Enter a valid date");
                } else if (inputDate > today) {
                    isValid = false;
                    cmp.set('v.error', "Item send date must be a present date or earlier.")
                } else {
                    cmp.set('v.error', null);
                }
        }
        return isValid;
    },
    validateTrackingNumber : function(cmp, showError) {
        var isValid = true;
        if (cmp) {
            if (showError) cmp.set("v.showError", showError);
            var val = cmp.get('v.value');
            if (!val || !val.trim()) {
                isValid = false;
                cmp.set('v.error', "Enter tracking number");
            } else if (val && !val.match(/^[a-z0-9]+$/i)) {
                isValid = false;
                cmp.set('v.error', "Enter a valid tracking number");
            } else {
                cmp.set('v.error', null);
            }
        }
        return isValid;
    },
    validateAddressNotNull : function(cmp, showError) {
        var isValid = true;
        var overriden = cmp.get("v.isOverriden");
        var hasQualifiedForSafeDropFlow = cmp.get("v.wizardData.hasQualifiedForSafeDropFlow");      
        var mailRedirectionType = cmp.get('v.wizardData.selectedRadio1Name');
        if(overriden)
        {
            isValid = this.checkManualAddressisValid(cmp);
        } else
        {
            
            if (cmp) {
                if (showError) cmp.set("v.showError", showError);
                var issueName = cmp.get('v.wizardData.IssueName');
                var senderOrRecipientType = cmp.get('v.wizardData.senderOrRecipientType');
                
                var selectedAddress = cmp.get('v.selectedAddress');
                var addressTyped = cmp.get('v.addressTyped');
                var selectedDeliveryAddress = cmp.get("v.wizardData.selectedDeliveryAddress");
                var recipientDeliveryAddress = cmp.get("v.wizardData.recipientDeliveryAddress");
                if (mailRedirectionType !='Mail hold' && ($A.util.isEmpty(recipientDeliveryAddress) || $A.util.isUndefined(recipientDeliveryAddress)))
                {
                    if($A.util.isEmpty(selectedAddress) && $A.util.isEmpty(addressTyped) && $A.util.isEmpty(selectedDeliveryAddress)){
                        cmp.set('v.error','Enter the address. Start typing and select an option from the list.');
                        isValid = false;
                        cmp.set("v.showError", true);
                    }
                    if($A.util.isEmpty(selectedAddress) && !$A.util.isEmpty(addressTyped) && $A.util.isEmpty(selectedDeliveryAddress))
                    {
                        cmp.set('v.error',"Address not found. Try editing, or select 'Enter address manually instead' from the list.");
                        isValid = false;
                        cmp.set("v.showError", true);
                    }
                } 
                
                //Delivery address validation for Delivery issue and Mail redirection forms
                if(issueName == 'Incorrect delivery address needs fixing' || mailRedirectionType == 'Mail hold' || mailRedirectionType == 'Mail redirection'){
                    var incorrectAddress = cmp.get('v.incorrectAddress');
                    var incorrectAddressTyped = cmp.get('v.incorrectAddressTyped');
                    var incorrectDeliveryAddress = cmp.get("v.wizardData.incorrectDeliveryAddress");
                    if($A.util.isEmpty(incorrectAddress) && $A.util.isEmpty(incorrectAddressTyped) && $A.util.isEmpty(incorrectDeliveryAddress)){
                        cmp.set('v.fieldError','Enter the address. Start typing and select an option from the list.');
                        isValid = false;
                        cmp.set("v.incorrectShowError", true);
                    }
                    if($A.util.isEmpty(incorrectAddress) && !$A.util.isEmpty(incorrectAddressTyped) && $A.util.isEmpty(incorrectDeliveryAddress))
                    {
                        cmp.set('v.fieldError',"Address not found. Try editing, or select 'Enter address manually instead' from the list.");
                        isValid = false;
                        cmp.set("v.incorrectShowError", true);
                    }
                }
                //Recipient delivery address validation, only for non-safe drop flows
                if(!hasQualifiedForSafeDropFlow && senderOrRecipientType == 'Domestic'){
                    var recipientAddressTyped = cmp.get('v.recipientAddressTyped');
                    var recipientAddress = cmp.get('v.recipientAddress');                
                    var recipientDeliveryAddress = cmp.get("v.wizardData.recipientDeliveryAddress");
                    if($A.util.isEmpty(recipientAddress) && $A.util.isEmpty(recipientAddressTyped) && $A.util.isEmpty(recipientDeliveryAddress)){
                        cmp.set('v.fieldError','Enter the address. Start typing and select an option from the list.');
                        isValid = false;
                        cmp.set("v.recipientShowError", true);
                    }
                    if($A.util.isEmpty(recipientAddress) && !$A.util.isEmpty(recipientAddressTyped) && $A.util.isEmpty(recipientDeliveryAddress))
                    {
                        cmp.set('v.fieldError',"Address not found. Try editing, or select 'Enter address manually instead' from the list.");
                        isValid = false;
                        cmp.set("v.recipientShowError", true);
                    }
                }
                
            }
        }
        return isValid;
    },
    checkManualAddressisValid : function(cmp) {
        var isValid = true;
        var inputErrors = cmp.get("v.inputErr");
        var inputFieldCount =  cmp.get("v.inputFieldCount");
        var overrideAddr = cmp.get("v.overrideAddress");
        var selectedAddr = cmp.get("v.selectedAddress");
        if(inputErrors.length > 0 || inputFieldCount < 4)
        {
            //isValid = this.updateErrorSummary(cmp,inputErrors);
            isValid = false;
            cmp.set("v.inputFieldError",true);
            
        }
        else
        {
            if(($A.util.isEmpty(overrideAddr) || $A.util.isUndefined(overrideAddr)) && ($A.util.isEmpty(selectedAddr) || $A.util.isUndefined(selectedAddr)))
            {
                //isValid = this.updateErrorSummary(cmp,inputErrors);
                isValid = false;
                cmp.set("v.inputFieldError",true);
            }
        }
        return isValid;
    },
    //-- formType is used to differentiate two blocks of the AME component in a single parent component
    getAddressTyped : function(cmp, event, formType) {
        var streetAddress = event.getParam('searchAddressTerm');
        if(formType == 'AMEAddressBlock')
        {
            cmp.set("v.addressTyped",streetAddress);
        }
        if(formType == 'AMEAddressBlock1')
        {
            cmp.set("v.incorrectAddressTyped",streetAddress);
            cmp.set("v.recipientAddressTyped",streetAddress);
        }
    },
    getSelectedAddress : function(cmp, event, formType) {
        var streetAddress = event.getParam('address');
        cmp.set("v.selectedAddress",streetAddress.address);
        this.setSelectedAddress(cmp, event, formType);
        
    },
    setSelectedAddress : function(cmp, event, formType) {
        var streetAddress = event.getParam('address');
        var issueName = cmp.get('v.wizardData.IssueName');
        var senderOrRecipientType = cmp.get('v.wizardData.senderOrRecipientType');
        var mailRedirectionType = cmp.get('v.wizardData.selectedRadio1Name');
        // Missing item form
        if(cmp.get('v.wizardData.selectedRadio1Name') == 'Sender')
        {
            cmp.set("v.wizardData.senderAddressLine1",streetAddress.addressLine);
            cmp.set("v.wizardData.senderAddressLine2",streetAddress.addressLine3);
            cmp.set("v.wizardData.senderCity",streetAddress.city);
            cmp.set("v.wizardData.senderState",streetAddress.state);
            cmp.set("v.wizardData.senderPostcode",streetAddress.postcode);
        }
        
        //set the address strings into indiviual line items- Delivery issue form, option : Incorrect delivery address needs fixing(Incorrect address)
        if(formType == 'AMEAddressBlock1')
        {
            cmp.set("v.incorrectAddress",streetAddress.address);
            cmp.set("v.recipientAddress",streetAddress.address);
            // Delivery issue form- Option : Incorrect delivery address needs fixing
            if(issueName == 'Incorrect delivery address needs fixing'){
                cmp.set("v.wizardData.inCorrectDeliveryAddressLine1",streetAddress.addressLine);
                cmp.set("v.wizardData.inCorrectDeliveryAddressLine2",streetAddress.addressLine3);
                cmp.set("v.wizardData.inCorrectDeliveryCity",streetAddress.city);
                cmp.set("v.wizardData.inCorrectDeliveryState",streetAddress.state);
                cmp.set("v.wizardData.inCorrectDeliveryPostcode",streetAddress.postcode);
                cmp.set("v.wizardData.incorrectDeliveryAddress", streetAddress.address);
            }
            // Mail redirect and Mail hold 
            if(mailRedirectionType == 'Mail hold' || mailRedirectionType == 'Mail redirection')
            {
                cmp.set("v.wizardData.oldAddressLine1",streetAddress.addressLine);
                cmp.set("v.wizardData.oldAddressLine2",streetAddress.addressLine3);
                cmp.set("v.wizardData.oldCity",streetAddress.city);
                cmp.set("v.wizardData.oldState",streetAddress.state);
                cmp.set("v.wizardData.oldPostcode",streetAddress.postcode);
                cmp.set("v.wizardData.incorrectDeliveryAddress", streetAddress.address);
            }
            // Missing item form
            if(senderOrRecipientType == 'Domestic'){
                cmp.set("v.wizardData.recipientAddressLine1",streetAddress.addressLine);
                cmp.set("v.wizardData.recipientAddressLine2",streetAddress.addressLine3);
                cmp.set("v.wizardData.recipientCity",streetAddress.city);
                cmp.set("v.wizardData.recipientState",streetAddress.state);
                cmp.set("v.wizardData.recipientPostcode",streetAddress.postcode);
                cmp.set("v.wizardData.recipientDeliveryAddress", streetAddress.address);
                cmp.set("v.wizardData.recipientDPID", streetAddress.dpid);
            }
        }
        if(formType == 'AMEAddressBlock')
        {
            //set the address strings into indiviual line items- Delivery issue form, option : Incorrect delivery address needs fixing(Correct address)
            cmp.set("v.selectedAddress",streetAddress.address);
            cmp.set("v.wizardData.deliveryAddressLine1",streetAddress.addressLine);
            cmp.set("v.wizardData.deliveryAddressLine2",streetAddress.addressLine3);
            cmp.set("v.wizardData.deliveryCity",streetAddress.city);
            cmp.set("v.wizardData.deliveryState",streetAddress.state);
            cmp.set("v.wizardData.deliveryPostcode",streetAddress.postcode);
            
            //set the address strings into indiviual line items- Mail redirection form
            if(mailRedirectionType == 'Mail redirection')
            {
                cmp.set("v.wizardData.newAddressLine1",streetAddress.addressLine);
                cmp.set("v.wizardData.newAddressLine2",streetAddress.addressLine3);
                cmp.set("v.wizardData.newCity",streetAddress.city);
                cmp.set("v.wizardData.newState",streetAddress.state);
                cmp.set("v.wizardData.newPostcode",streetAddress.postcode);
            }
            
            cmp.set("v.wizardData.selectedDeliveryAddress", streetAddress.address);
        }
        
    },
    setOverrideAddress : function(cmp, event, formType) {
        var streetAddress = event.getParam('searchterm');
        var senderOrRecipientType = cmp.get('v.wizardData.senderOrRecipientType');
        var mailRedirectionType = cmp.get('v.wizardData.selectedRadio1Name');
        var issueName = cmp.get('v.wizardData.IssueName');
        if(formType == 'AMEAddressBlock')
        {
            cmp.set("v.wizardData.deliveryAddressLine1",streetAddress['addressLine1']);
            cmp.set("v.wizardData.deliveryAddressLine2",streetAddress['addressLine2']);
            cmp.set("v.wizardData.deliveryCity",streetAddress['city']);
            cmp.set("v.wizardData.deliveryState",streetAddress['state']);
            cmp.set("v.wizardData.deliveryPostcode",streetAddress['postcode']);
            // Missing item form
            if(cmp.get('v.wizardData.selectedRadio1Name') == 'Sender')
            {
                cmp.set("v.wizardData.senderAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.senderAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.senderCity",streetAddress['city']);
                cmp.set("v.wizardData.senderState",streetAddress['state']);
                cmp.set("v.wizardData.senderPostcode",streetAddress['postcode']);
            }
            
            if(mailRedirectionType == 'Mail redirection')
            {
                cmp.set("v.wizardData.newAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.newAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.newCity",streetAddress['city']);
                cmp.set("v.wizardData.newState",streetAddress['state']);
                cmp.set("v.wizardData.newPostcode",streetAddress['postcode']);
            }
        }
        if(formType == 'AMEAddressBlock1')
        {
            // Delivery issue form- Option : Incorrect delivery address needs fixing
            if(issueName == 'Incorrect delivery address needs fixing'){
                cmp.set("v.wizardData.inCorrectDeliveryAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.inCorrectDeliveryAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.inCorrectDeliveryCity",streetAddress['city']);
                cmp.set("v.wizardData.inCorrectDeliveryState",streetAddress['state']);
                cmp.set("v.wizardData.inCorrectDeliveryPostcode",streetAddress['postcode']);
            }
            // Missing item form
            if(senderOrRecipientType == 'Domestic'){
                cmp.set("v.wizardData.recipientAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.recipientAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.recipientCity",streetAddress['city']);
                cmp.set("v.wizardData.recipientState",streetAddress['state']);
                cmp.set("v.wizardData.recipientPostcode",streetAddress['postcode']);
            }
            if(mailRedirectionType == 'Mail redirection' || mailRedirectionType == 'Mail hold')
            {
                cmp.set("v.wizardData.oldAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.oldAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.oldCity",streetAddress['city']);
                cmp.set("v.wizardData.oldState",streetAddress['state']);
                cmp.set("v.wizardData.oldPostcode",streetAddress['postcode']);
            }
        }
        
    },
    getOverrideAddress : function(cmp, event, formType) {
        //reset the selected address variable from the previous search
        cmp.set("v.selectedAddress",'');
        cmp.set("v.incorrectAddress",'');
        var streetAddress = event.getParam('searchterm');
        // create a empty array to store map keys 
        var allInputs = [];
        var addressEntered='';
        var count = 0;
        for (var singlekey in streetAddress) {
            if(streetAddress[singlekey] == '')
            {
                allInputs.push(singlekey);
                
            }
            else
            {
                //set the address strings into indiviual line items
                this.setOverrideAddress(cmp, event, formType);
                if(streetAddress[singlekey])
                {
                    addressEntered = addressEntered + streetAddress[singlekey] + ' ';
                    if(singlekey != 'addressLine2')
                    {
                        count = count + 1;
                    }
                }
            }
        }
        cmp.set("v.inputFieldCount", count);
        cmp.set("v.inputErr",allInputs); 
        // set the manual address entered
        if(addressEntered != null && addressEntered !='undefined')
        {
            //set the wizard data with the override address
            cmp.set("v.overrideAddress",addressEntered);
            if(formType == 'AMEAddressBlock')
            {
                cmp.set('v.wizardData.selectedDeliveryAddress', addressEntered);
            }
            if(formType == 'AMEAddressBlock1')
            {
                cmp.set('v.wizardData.incorrectDeliveryAddress', addressEntered);
                cmp.set('v.wizardData.recipientDeliveryAddress', addressEntered);
            }
            
        }
    },
    checkBrowser : function(component) {
        var browserType = navigator.sayswho = (function() {
            var ua = navigator.userAgent, tem,
                M = ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
            if(/trident/i.test(M[1])) {
                tem =  /\brv[ :]+(\d+)/g.exec(ua) || [];
                return 'IE '+(tem[1] || '');
            }
            if(M[1] === 'Chrome') {
                tem = ua.match(/\b(OPR|Edge)\/(\d+)/);
                if(tem != null) return tem.slice(1).join(' ').replace('OPR', 'Opera');
            }
            M = M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
            if((tem = ua.match(/version\/(\d+)/i)) != null) M.splice(1, 1, tem[1]);
            return M.join(' ');
        })();
        return browserType;
    },
    // Expect input as dd/mm/yyyy
    isValidDate: function(s) {
        var bits = s.split(/[- /.]/);
        if(bits[2].length >3){                                      //- if format is DD/MM/YYYY, then last element length in array is 4
            var d = new Date(bits[2], bits[1] - 1, bits[0]);
            return d && (d.getMonth() + 1) == bits[1] && d.getFullYear() >= 1900;
        } else if(bits[0].length >3){                               //- if format is YYYY/MM/DD, then first element length in array is 4
            var d = new Date(bits[0], bits[1] - 1, bits[2]);
            return d && (d.getMonth() + 1) == bits[1] && d.getFullYear() >= 1900;
        } else {
            return true;
        }
    },
    buildDataAnalytics : function(cmp, event, helper) {
        // we expect something to be returned here, if nothing returned means a technical issue
        if(cmp.get('v.wizardData.eddStatus') != '') {
            var duplicateCaseText = 'new';
            var variationId = '';
            if(cmp.get('v.wizardData.duplicateCase') != '') {
                duplicateCaseText = 'duplicate';
            }
            cmp.set("v.duplicateCaseText",duplicateCaseText);
            var latestEventLocationMessage = cmp.get('v.wizardData.latestEventLocationMessage');
            var alertMessage=cmp.get('v.wizardData.trackStatusValue');
            if(!$A.util.isEmpty(latestEventLocationMessage) || !$A.util.isUndefined(latestEventLocationMessage))
            {
                alertMessage = latestEventLocationMessage;
                
            }
            cmp.set("v.alertMessage",alertMessage);
            
            var isEligibleForMyNetworkAssignment = cmp.get('v.wizardData.isEligibleForMyNetworkAssignment') ? 'yes' : 'no';
            cmp.set("v.isEligibleForNetwork",isEligibleForMyNetworkAssignment);
            // set the value from transfer to po selected post office
            var transferToPoSelectedValue = cmp.get('v.wizardData.transferToPoSelectedValue');
            cmp.set("v.transferToPoSelectedValue",transferToPoSelectedValue);
            // assign an unique identifier for adobe analytics for EDD variations in the contextual thank you pages
            if(cmp.get("v.stage") == 'submit')
            {
                // check if there is a delivered scan and assign an unique identifier for adobe analytics
                if(!$A.util.isEmpty(cmp.get("v.wizardData.latestDeliveredScanWcid"))) {
                    variationId = ':delivered';
                    // check if user has seen a safedrop image and assign an unique identifier for adobe analytics
                    if(cmp.get('v.wizardData.hasCustomerSeenSafeDrop') == 'true') {
                        variationId = ':safedrop';
                    }
                } else
                {
                    // check EDD status. Within and past edd plus business days and assign an unique identifier for adobe analytics
                    if(cmp.get('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays')) {
                        variationId = ':withineddplus5';
                    }
                    if(cmp.get('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays')) {
                        variationId = ':pastedd';
                    }
                }
                
                
                cmp.set("v.EDDVariationId",variationId);
            }
        }
    },
    
    asArray: function(x) {
        if (Array.isArray(x)) return x;
        else return x ? [x] : [];
    },
    storeEncryPtWizardDataAndNavigateToMyPost : function(cmp){
        
        var action = cmp.get("c.encryptData");
        action.setParams({ "inputData" : JSON.stringify(cmp.get('v.wizardData')) });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj = '';
                if(response.getReturnValue() != null){
                    
                    //var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                    returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                    // 28/08/2018 - added for global storage of wizard data
                    localStorage.setItem("cacheKey",  returnObj["cacheKey"]);
                }
                else
                    /*console.log('Response from encryptData is null');*/
                    
                    //-- firing the URL for login, if encryption returns issue also navigating to login screen without wizard data in cache
                    var wizardData = cmp.get('v.wizardData');
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url":cmp.get('v.authenticatedURL')
                });
                
                // if we are to pass the cacheKey in the relayState we might be able to do it here...
                //var url = cmp.get('v.authenticatedURL') + '?cacheKey=' + returnObj["cacheKey"];
                //urlEvent.setParams({
                //    "url":url
                //});
                urlEvent.fire();
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                    }
                } else {
                }
            }
        });
        $A.enqueueAction(action);
    },
})