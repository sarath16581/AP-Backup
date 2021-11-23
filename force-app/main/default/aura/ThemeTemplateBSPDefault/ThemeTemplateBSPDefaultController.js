({
    doInit: function(cmp) {
        if(cmp.get('v.showProfileMenu')){
            var action = cmp.get("c.initThemeComp");
            action.setStorable();
            action.setCallback(this, function(response) {
                var state = response.getState();
                cmp.set('v.displayBody', true);
                if (state === "SUCCESS") {

                    let objReturn = response.getReturnValue();
                    cmp.set('v.contactId', objReturn.contactId);
                    cmp.set('v.userEmail', objReturn.userEmail);
                    cmp.set('v.userFirstName', objReturn.userFirstName);
                    cmp.set('v.userLastName', objReturn.userLastName);
                    cmp.set('v.serviceSLA', objReturn.serviceSLA);

                    // render AFTER the above data has been set
                    cmp.set('v.isSSOUserAllowedBSP', objReturn.bamBspAccess);
                    cmp.set('v.showProfileMenu', objReturn.bamBspAccess);
                    cmp.set('v.loadSmartSpeakJS', objReturn.bamBspAccess);
                    cmp.set('v.hasAPBillingAccountsAccess', objReturn.hasAPBillingAccountsAccess);

                     cmp.set('v.buttonId', objReturn.buttonId);
                     cmp.set('v.deploymentId', objReturn.deploymentId);
                     cmp.set('v.orgId', objReturn.orgId);
                     cmp.set('v.scriptSrc', objReturn.scriptSrc);
                     cmp.set('v.chatInit', objReturn.chatInit);
                     cmp.set('v.ssEndPoint', objReturn.ssEndPoint);
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +  errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        }else{
            cmp.set('v.isSSOUserAllowedBSP', true);
            cmp.set('v.displayBody', true);
        }
    }
});