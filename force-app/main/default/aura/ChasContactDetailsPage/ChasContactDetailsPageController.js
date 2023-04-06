/*
 @changelog : 
 @modified by : hara.sahoo@auspost.com.au
 @date 2020-07-06 : Modified the JS file for additional logic to the navigation screens in goBack() method.
*/
({
     init: function(cmp, event, helper) {
     cmp.set("v.wizardData.safeDropPayload",null);
     },
    goForward: function (cmp, event, helper) {
        var isValid = helper.checkAllValid(cmp, true);
        if(isValid){
            helper.gotoNextPage(cmp);
        }
    },
    goForwardAsGuest: function (cmp, event, helper) {
       var isValid = helper.checkAllValidForGuest(cmp, true);
       if(isValid){
           helper.gotoNextPage(cmp);
       }
   },
    goBack: function (cmp, event, helper) {
        var hasCustomerSeenSafeDrop = cmp.get("v.wizardData.hasCustomerSeenSafeDrop");
        var correctDeliveryAddress = cmp.get("v.wizardData.correctDeliveryAddress");
        var addressEnteredManually = cmp.get("v.isOverriden");
        //check if the image is captured via the safedrop flow
        if (!$A.util.isEmpty(hasCustomerSeenSafeDrop) || !$A.util.isUndefined(hasCustomerSeenSafeDrop))
        {
            helper.gotoPrevPage(cmp,'chasMissingItemForm');
        }
        //check if the address was entered was returned from the AME service or manually entered
        else if (!$A.util.isEmpty(correctDeliveryAddress) || !$A.util.isUndefined(correctDeliveryAddress))
        {
            helper.gotoPrevPage(cmp,'chasMissingItemForm');
        }
        //for all other cases, go back to the form as per the "prev" attribute in corresponding wizard
        else
        {
            helper.gotoPrevPage(cmp);
        }
        
    },
    
    navigateToLoginMyPost: function(cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    
    onChange : function(cmp, event, helper) {
        helper.checkAllValid(cmp, true);  
    },
    
    
    
})