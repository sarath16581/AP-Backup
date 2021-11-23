({

    doInit: function(component,event,helper) {
        // Set the attribute value.
        // You could also fire an event here instead.
        component.set("v.isModalOpen", false);
        component.get("v.recordId");
        console.log('record Id:::',component.get("v.recordId"));
        var recID = component.get('v.recordId');
        var action = component.get('c.getBillingAccountDetails');
        // convert the selected record list into a JSON format and send to the Apex Controller
        action.setParams({ "billingAccountRecord" :recID});
        action.setCallback(this, function(response) {
            // declare toast event for display success/error message banner on salesforce page
           // var toastEvent = $A.get("e.force:showToast");

            if (response.getState() === "SUCCESS") {
                component.set('v.BillingAccount',response.getReturnValue());

                var delFlag = component.get("v.BillingAccount.SAP_marked_for_deletion__c");

                var sourceSystem = component.get("v.BillingAccount.Source_System__c");

                var typeVal = component.get("v.BillingAccount.Type__c");

                var subAccVal = component.get("v.BillingAccount.PAYER_ACCOUNT_ID__c");

                if (delFlag === true){
                    component.set("v.isModalOpen", true);
                    component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created against a Billing Account marked for deletion.');
                }
                else if (sourceSystem != 'SAP ERP'){
                    component.set("v.isModalOpen", true);
                    component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created against a TEAM or PeopleSoft accounts.');
                }else if (typeVal != 'CUST') {
                    component.set("v.isModalOpen", true);
                    component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created for Billing Account Type Agency or Cash.');
                }else if (subAccVal != null) {
                    component.set("v.isModalOpen", true);
                    component.set("v.failedErrMsg", 'This request does not meet the minimum criteria to create a sub-account. A sub-account cannot be created from a sub-account.');
                }else{
                    component.set("v.isModalOpen", false);
                    var recID = component.get('v.recordId');
                    helper.navigateToCreateSubAccountsCmp(component,event); 
                    //$A.enqueueAction(a);
                }
            }

            // error state, display error message banner on salesforce page
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
            }
        });
        $A.enqueueAction(action);

    },

    closePopUp : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
   },

    openModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },

    closeModal: function(component, event, helper) {
        // Set isModalOpen attribute to false
        component.set("v.isModalOpen", false);
    }
})