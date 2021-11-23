/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 14/05/2021
  * @description  : Component used as wrapper for Sub Account Request Quick Action Button. It has following features
  *                 1. It invokes createProposalSubAccountsRequest LWC component.
*********************************History*******************************************************************
14.05.2021    Dheeraj Mandavilli   Created
*/
 
({
    navigateToCreateSubAccountCmp : function(component, event) {
        //let self = this;
        var helper = this;
        var event = $A.get("e.force:navigateToComponent");
        console.log('initalLoad>>><<<<<<',component.get("v.initialLoad"));
        event.setParams({
            componentDef : "c:createProposalSubAccountsRequest",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                initialLoad:component.get("v.initialLoad")
            }
        });
        event.fire();
    },

    closePopUp : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }

});