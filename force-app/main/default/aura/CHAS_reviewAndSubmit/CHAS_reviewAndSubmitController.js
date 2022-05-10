({
    goForward: function (cmp, event, helper) {
        cmp.set("v.showSpinner", true);

        //-- Call Sever method to create Case, based on success forward to success page otherwise error page
        var action = cmp.get(cmp.get("v.apexCaseCreationFunction"));
        cmp.set('v.wizardData.trackingNumberDetails', JSON.stringify(cmp.get('v.wizardData.trackingNumberDetails')));
        cmp.set('v.wizardData.articles', JSON.stringify(cmp.get('v.wizardData.articles')));
        // var trackingNumberDetails = JSON.stringify(cmp.get('v.wizardData.trackingNumberDetails'));
        // var articles = JSON.stringify(cmp.get('v.wizardData.articles'));
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