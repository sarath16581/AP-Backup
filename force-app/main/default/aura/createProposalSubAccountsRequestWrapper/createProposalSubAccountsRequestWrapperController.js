/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 10/05/2021
  * @description  : Component used as wrapper for Sub Account Request invoked from Credit Assessment VF Page. It has following features
  *                 1. It invokes createSubAccountsFromProposal LWC component.
*********************************History*******************************************************************
10.05.2021    Dheeraj Mandavilli   Created
*/
({

    closePopUp : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }
    
});