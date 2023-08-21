/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : Component used as wrapper for Sub Account Request Quick Action Button from Billing Account. It has following features
  *                 1. It invokes createSubAccounts LWC component.
  *                 2. It also contains validation checks on Billing Account
*********************************History*******************************************************************
24.04.2021    Dheeraj Mandavilli   Created
*/

({
    navigateToCreateSubAccountsCmp : function(component, event) {
        //let self = this;
        var helper = this;
        var event = $A.get("e.force:navigateToComponent");
        console.log('initalLoad>>><<<<<<',component.get("v.initialLoad"));
        event.setParams({
            componentDef : "c:createSubAccountsRequest",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                initialLoad:component.get("v.initialLoad")
            }
        });
        event.fire();
    }
})