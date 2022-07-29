({
    checkAllValid: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('chasInput'));
        // Must use single '&' so that it runs through all functions.
        var isValid = (
            this.checkInputs(allInputs, showError) &
            cmp.get('v.authUserData.isUserAuthenticated') === true
            );
        this.updateErrorSummary(cmp, allInputs);
        if(isValid){
            cmp.set('v.formValid', true);
        }else{
            cmp.set('v.formValid', false);
        }
        return isValid;
    },
    checkAllValidForGuest: function(cmp, showError) { 
        var allInputs = this.asArray(cmp.find('chasInput'));
        // Must use single '&' so that it runs through all functions.
        var isValid = (
            this.checkInputs(allInputs, showError));
        this.updateErrorSummary(cmp, allInputs);
        if(isValid){
            cmp.set('v.formValid', true);
        }else{
            cmp.set('v.formValid', false);
        }
        return isValid;
    },

    validationMap: function() {
        return {
            'userPhoneNumber': this.validatePhone,
            'ChasGivenName': this.validateGivenName,
            'ChasSurname': this.validateSurname,
            'ChasEmail': this.validateEmail
            
        };
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
                    console.log('Response from encryptData is null');
                
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