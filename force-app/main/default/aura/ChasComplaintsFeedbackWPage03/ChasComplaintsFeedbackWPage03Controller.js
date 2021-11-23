({
    goBackHandler: function (component, event, helper) {
        helper.gotoPrevPage(component);
     }
    // goForward: function (component, event, helper) {
    //      // make Spinner attribute true for display loading spinner 
    //     component.set("v.showSpinner", true);
        
    //     //-- 1. Create a 'Case', set the Case number to 'Wizard Data', If any error while creating Case show the error message and stop
    //    // var enquiryType =  component.get("v.wizardData.selectedRadioName");
    //    // var complaintDetails =  component.get("v.wizardData.complaintDetails");
    //    // var givenName =  component.get("v.wizardData.givenName");
    //    // var surname =  component.get("v.wizardData.surname");
    //    // var email =  component.get("v.wizardData.emailId");
    //   //  var phone =  component.get("v.wizardData.phone");
    //   //  var origin = 'Web';
        
    //     /////////
    //     var action = component.get("c.createCaseFromComplaintWizard");
    //     action.setParams({
    //         "wizardData": component.get("v.wizardData")
    //         // "origin" : origin,
    //         // "enquiryType" : enquiryType,
    //         // "complaintDetails":complaintDetails,
    //         // "givenName":givenName,
    //         // "surname":surname,
    //         //  "email":email,
    //         //"phone":phone
            
    //     });
        
    //     // Create a callback that is executed after 
    //     // the server-side action returns
    //     action.setCallback(this, function(response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
                
    //             var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
    //             component.set('v.wizardData.caseNumber', returnObj["caseNumber"]);
    //             component.set('v.wizardData.caseCreationStatus',returnObj["caseStatus"]);
    //         }
    //         else if (state === "INCOMPLETE") {
    //             component.set('v.wizardData.caseCreationStatus', 'INCOMPLETE');
    //         }
    //             else if (state === "ERROR") {
    //                 component.set('v.wizardData.caseCreationStatus', 'ERROR');
    //                 var errors = response.getError();
    //                 if (errors) {
    //                     if (errors[0] && errors[0].message) {
    //                         //-- Console log
    //                         if(component.get("v.debugMode")){
    //                             console.log("Error message: " + errors[0].message);
    //                         }
    //                     }
    //                 } else {
    //                     //-- Console log
    //                     if(component.get("v.debugMode")){
    //                         console.log("Unknown error");
    //                     }
    //                 }
    //             }
            
    //         //-- Navigating to next page/component
    //         helper.gotoNextPage(component)
      
    //     });
    //     $A.enqueueAction(action);
        
    // },

    // goBack: function (component, event, helper) {
    //     helper.gotoPrevPage(component);
    // }
})