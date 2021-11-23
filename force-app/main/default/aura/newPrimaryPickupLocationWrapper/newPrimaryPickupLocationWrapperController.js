/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 26/05/2021
  * @description  : Component used as wrapper for Pickup Location Quick Action Button from CSQ. It has following features
  *                 1. It invokes newPrimaryPickupLocation LWC component.
*********************************History*******************************************************************
26.05.2021    Dheeraj Mandavilli   Created
*/

({
    closePopUp : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }
})