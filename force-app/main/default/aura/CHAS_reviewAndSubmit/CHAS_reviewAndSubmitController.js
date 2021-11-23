({
    goForward: function (cmp, event, helper) {

        cmp.set("v.showSpinner", true);
        
        //-- Call Sever method to create Case, based on success forward to success page otherwise error page
        var action = cmp.get(cmp.get("v.apexCaseCreationFunction"));
        action.setParams({ "wizardData" : cmp.get("v.wizardData") ,
                         "authUserData" : cmp.get("v.authUserData")});
        //action.setParams({ "authUserData" : cmp.get("v.authUserData") });
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                cmp.set('v.wizardData.caseNumber', returnObj["caseNumber"]);
                cmp.set('v.wizardData.caseCreationStatus',returnObj["caseStatus"]);
            }
            else if (state === "INCOMPLETE") {
                cmp.set('v.wizardData.caseCreationStatus', 'INCOMPLETE');
            }
                else if (state === "ERROR") {
                    cmp.set('v.wizardData.caseCreationStatus', 'ERROR');
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //-- Console log
                            if(cmp.get("v.debugMode")){
                                console.log("Error message: " + errors[0].message);
                            }
                        }
                    } else {
                        //-- Console log
                        if(cmp.get("v.debugMode")){
                            console.log("Unknown error");
                        }
                    }
                }
            
            //-- Navigating to next page/cmp
            helper.gotoNextPage(cmp);
            
        });
        
        $A.enqueueAction(action);
    }
    
})