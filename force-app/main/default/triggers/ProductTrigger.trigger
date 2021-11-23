/**************************************************
Type:       Trigger for Product Object
Purpose:    Captures all the changes 
History:
--------------------------------------------------
05.23.2012   Joseph Barrameda (CloudSherpas.com)    Created

***************************************************/

trigger ProductTrigger on Product2 (after update){
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if ( trigger.isAfter && trigger.isUpdate ) {
            ProductUtil.CaptureChanges(trigger.oldMap  , trigger.newMap, Trigger.new);
            // created by conrad.c.v.borbon on August 3, 2018 - ProductTriggerHandler.ProductAfterUpdate
            ProductTriggerHandler.ProductAfterUpdate(trigger.old,Trigger.new);
        }
    }
}