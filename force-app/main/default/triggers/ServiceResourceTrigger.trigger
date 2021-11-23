/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-07
* @domain Field Service 
* @description TDF Enhance 20: Added to set External Name field to enforce uniqueness of Service Resource name
*
* @changelog 
* 2020-07-14 - Andrew Judd - Created 
* 2020-09-11 - Andrew Judd - Refactored to user generic trigger hander 
*/
trigger ServiceResourceTrigger on ServiceResource (before insert, before update) {

    // If triggers not disabled
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(ServiceResource.sObjectType))){     
        // Dispatch event
        ServiceResourceTriggerHandler.execute();  
    }
}