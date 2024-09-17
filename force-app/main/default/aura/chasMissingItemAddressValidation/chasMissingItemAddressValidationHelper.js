({
    checkAllValid: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('searchAddress').getElement());
        for (var i=0; i<allInputs.length; i++) {
            var inputCmp = allInputs[i];
            var inputName = inputCmp.get('v.name');
            var inputRequired = inputCmp.get('v.required');
        }
        //var isValid = this.checkInputs(allInputs, showError);
        
        if(isValid){
            cmp.set('v.formValid', true);
        }else{
            cmp.set('v.formValid', false);
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
        return this.validateNotNull(cmp, showError, "Enter a detailed item description");
    },
    validateItemValue: function(cmp, showError) {
        return this.validateCurrency(cmp, showError);
    },
    validationMap: function() {
        return {
            'recipientOrSenderRadioButtons': this.validateRadioButtons
        };
    },
    getOverrideAddress : function(cmp, event, helper) {
        //reset the selected address variable from the previous search
        cmp.set("v.selectedAddress",'');
        
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
            //set the address strings into indiviual line items
            else
            {
                cmp.set("v.wizardData.recipientAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.recipientAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.recipientCity",streetAddress['city']);
                cmp.set("v.wizardData.recipientState",streetAddress['state']);
                cmp.set("v.wizardData.recipientPostcode",streetAddress['postcode']);
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
            cmp.set('v.wizardData.correctDeliveryAddress', addressEntered);
            cmp.set('v.wizardData.recipientDeliveryAddress', addressEntered);
            
        }
    },
    checkManualAddressisValid : function(cmp, event, helper) {
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
    
    
    
    getSelectedAddress : function(cmp, event, helper) {
        var streetAddress = event.getParam('address');
        cmp.set("v.selectedAddress",streetAddress.address);
        cmp.set("v.dpid",streetAddress.delpointId);
        //set the address strings into indiviual line items
        cmp.set("v.wizardData.recipientAddressLine1",streetAddress.addressLine);
        cmp.set("v.wizardData.recipientAddressLine2",streetAddress.addressLine3);
        cmp.set("v.wizardData.recipientCity",streetAddress.city);
        cmp.set("v.wizardData.recipientState",streetAddress.state);
        cmp.set("v.wizardData.recipientPostcode",streetAddress.postcode);
        
        if(streetAddress)
        {
            //set the wizard data with the selected address
            cmp.set('v.wizardData.correctDeliveryAddress', cmp.get('v.selectedAddress'));
            //push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address:selected'
            );
        }
    },
    getAddressTyped : function(cmp, event, helper) {
        var streetAddress = event.getParam('searchAddressTerm');
        cmp.set("v.addressTyped",streetAddress);
    },
    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },
    dpidMatch : function(cmp,event,helper) 
    {
        var dpidFromOneTrackService = cmp.get("v.wizardData.dpid");
        var dpidFromAMEService = cmp.get("v.dpid");
        var dpidFromUrl = cmp.get('v.dpidFromUrl');
        //check if dipidFromUrl matches to that returned from consignment service
        if((!$A.util.isEmpty(dpidFromUrl) || !$A.util.isUndefined(dpidFromUrl)) && !cmp.get("v.isFromBackButton"))
        {
            if(dpidFromOneTrackService != null && dpidFromOneTrackService != dpidFromUrl)
            {
                cmp.set("v.addressMatched",'noMatch');
                //when the dipidFromUrl is an invalid one and user manually enters the address.
                if(dpidFromAMEService != null && dpidFromOneTrackService != dpidFromAMEService)
                {
                    cmp.set("v.addressMatched",'noMatch');
                }else
                {
                    cmp.set("v.addressMatched",'Match');
                } 
            }
        }
        else
        {
            //check if the dpid matches
            if(dpidFromOneTrackService != dpidFromAMEService)
            {
                cmp.set("v.addressMatched",'noMatch');
                //push analytics for 'helpsupport-form-navigate' for self-help
                this.pushAnalytics(cmp,'item details:address:not match');
            }
            else
            {
                cmp.set("v.addressMatched",'Match');
            }  
        }
        
    },
    getSafeDropGuid : function(cmp,event,helper) {
        cmp.set('v.error500', false);
        var action = cmp.get("c.getSafeDropGuid");
        //--Old code - Not relevant anymore, can be removed after 31/12/2020
        /*action.setParams({
            "trackingNumber":  cmp.get("v.wizardData.trackingId")
        });*/
        //--Pass the article id to the redirect service, as the trackngId could be a consignment or an article
        action.setParams({
            "trackingNumber":  cmp.get("v.wizardData.articleId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                //--Check for status code SUCCESS 
                if(result.statusCode == '200')
                {
                    if(! $A.util.isEmpty(result.safeDropGuid) || $A.util.isUndefined(result.safeDropGuid))
                    {
                        cmp.set('v.wizardData.safeDropGuid', result.safeDropGuid);
                        this.getSafeDropImage(cmp,event,helper);
                        
                    }
                }
                //--Check for status code NO CONTENT, mail redirection applied
                else if(result.statusCode == '204')
                {
                    cmp.set('v.wizardData.hasCustomerSeenSafeDrop', 'false');
                    // decide network eligibility and set the isEligibleForMyNetworkAssignment flag
                    this.checkNetworkEligibility(cmp,event,helper);
                    helper.gotoNextPage(cmp,'chasMissingItemWPage02'); 
                }
                //--Check for other statuses like 404/401/429 or 500/503, display a generic message to the user
                    else
                    {
                        cmp.set('v.error500', true);
                        cmp.set('v.isLoading', false);
                    }
                
            }
            else if (state === "INCOMPLETE") {
                
            }
                else if (state === "ERROR") {
                    
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    cmp.set('v.error500', true);
                    cmp.set('v.isLoading', false);
                }
        });
        // Enqueue action that returns a continuation
        $A.enqueueAction(action);
    },
    getAMEAddressFromDPID : function(cmp,event,helper) {
        //this.showSpinner(cmp,event,helper);
        var DPID = cmp.get("v.dpidFromUrl");
        var action = cmp.get("c.getAMEAddressString");
        action.setParams({
            "dpid": DPID
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj =  JSON.parse(response.getReturnValue());
                cmp.set("v.wizardData.correctDeliveryAddress", returnObj[0].singleLine);
                if(cmp.get("v.wizardData.hasQualifiedForSafeDropFlow"))
                {
                    //set the address strings into indiviual line items
                    cmp.set("v.wizardData.recipientAddressLine1",returnObj[0].semiStructured.addressLines[0]);
                    cmp.set("v.wizardData.recipientAddressLine2",returnObj[0].semiStructured.addressLines[1]);
                    cmp.set("v.wizardData.recipientCity",returnObj[0].semiStructured.locality);
                    cmp.set("v.wizardData.recipientState",returnObj[0].semiStructured.state);
                    cmp.set("v.wizardData.recipientPostcode",returnObj[0].semiStructured.postcode);
                }
                cmp.set("v.wizardData.dpidFromUrl",cmp.get("v.dpidFromUrl"));
                var correctDeliveryAddress = cmp.get('v.wizardData.correctDeliveryAddress');
                if(!$A.util.isEmpty(correctDeliveryAddress) || !$A.util.isUndefined(correctDeliveryAddress))
                {
                    cmp.set("v.selectedAddress",correctDeliveryAddress);
                    $A.enqueueAction(cmp.get('c.redirectService'));
                    
                }
            }
            else if (state === "INCOMPLETE") {
                
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        // Enqueue action that returns a continuation
        $A.enqueueAction(action);
    },
    redirectService : function(cmp,event,helper) {
        /*AME returned the address:
        1.Check if address selected is valid
        2.Check if the dpid returned matches
        3.If all of the above is true, call the safedrop continuation service to display the safedrop image
        4.Navigate to the chasMissingItemForm screen (safedrop flow)
        */
        
        //Match the dpids returned from the AME service to that from the One Track service
        this.dpidMatch(cmp,event,helper);
        //Check if address selected from the service is valid
        var formValid = helper.validateAddressNotNull(cmp, true);
        if(formValid)
        {
            var addressMatch = cmp.get("v.addressMatched");
            //if dpid matches, call the the redirect service, to get the safedrop guid and then continuation service to retrieve the safe drop image
            if(addressMatch == 'Match')
            {
                this.showSpinner(cmp,event,helper);
                cmp.set('v.displaySpinner', true);
                this.getSafeDropGuid(cmp,event,helper);
            } else if(addressMatch == 'noMatch')
            {
                //do something, this is an edge case
                
            }else {
                //do something, this is an edge case
                //helper.showSpinner(cmp,event,helper);
                //helper.getSafeDropImage(cmp,event,helper);
            }
        } else 
        {
            cmp.set("v.addressMatched",'');
            cmp.set("v.inputError",'true');
        }
    },
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
    checkNetworkEligibility : function(cmp,event,helper) {
        var isEligibleForMyNetworkAssignment = false;
        var safedropDelivered = cmp.get("v.wizardData.safedropDelivered");
        var isReturnToSender = $A.util.isUndefined(cmp.get("v.wizardData.isReturnToSender")) ? false : cmp.get("v.wizardData.isReturnToSender");
        var duplicateCase = cmp.get("v.wizardData.duplicateCase");
        var hasSignature = $A.util.isUndefined(cmp.get("v.wizardData.hasSignature")) ? false : cmp.get("v.wizardData.hasSignature");
        var hasCustomerSeenSafeDrop = cmp.get("v.wizardData.hasCustomerSeenSafeDrop");
        if(hasCustomerSeenSafeDrop == 'true')
        {
            if(!isReturnToSender && duplicateCase == '' && !hasSignature)
            {
                isEligibleForMyNetworkAssignment = true;
                cmp.set('v.wizardData.isEligibleForMyNetworkAssignment',isEligibleForMyNetworkAssignment);
            }  
        }
        else
        {
            if(safedropDelivered == '' && !isReturnToSender && duplicateCase == '' && !hasSignature)
            {
                isEligibleForMyNetworkAssignment = true;
                cmp.set('v.wizardData.isEligibleForMyNetworkAssignment',isEligibleForMyNetworkAssignment);
            }  
        }
        
    },
    
    getSafeDropImage : function(cmp,event,helper) {
        this.showSpinner(cmp,event,helper);
        var guid = cmp.get("v.wizardData.safeDropGuid");
        var action = cmp.get("c.getSafeDropImage");
        action.setParams({
            "safedropGuid": guid
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.wizardData.safeDropPayload', response.getReturnValue());
                cmp.set("v.imageString",response.getReturnValue());
                cmp.set("v.imageSrc",'data:image/jpeg;base64,'+ cmp.get("v.wizardData.safeDropPayload"));
                cmp.set("v.imageExists", 'true');
                cmp.set('v.displaySpinner', false);
                //push analytics for 'helpsupport-form-navigate' on display of the safe drop image
                this.pushAnalytics(cmp,'item details:safe drop');
            }
            else if (state === "INCOMPLETE") {
                
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        // Enqueue action that returns a continuation
        $A.enqueueAction(action);
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
                alertMessage = latestEventLocationMessage;
                
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
            
        } 
    },
    showSpinner: function(cmp, event, helper) {
        cmp.set("v.isLoading", true);
    },
    hideSpinner : function(cmp,event,helper){
        cmp.set("v.isLoading", false);
    },
    fileDownload : function(cmp,event,helper){
        var a = document.createElement("a"); //Create <a>
        a.href = "data:image/jpeg;base64," + cmp.get("v.wizardData.safeDropPayload"); //Image Base64 Goes here
        a.download = "SafedropImage.jpeg"; //File name Here
        a.click(); //Downloaded file
    },
    
})