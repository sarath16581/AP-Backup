/*------------------------------------------------------------
Author:   :      Jeoffrey Palmero
Date Created:    08/06/2019
Description:     Handles logic related to the Apttus Opportunity Line Item

History
<Date>           <Authors Name>     <Brief Description of Change>
08/06/2019        JPalmero           Created
------------------------------------------------------------*/
trigger APTOptyLineItemTrigger on APT_Opportunity_Product_Line_Item__c (before insert, before update, before delete) {
    /* Shashwat.Nath@Auspost.com has Inactivated the trigger on 7/09/2020 below Actions as these would not be 
        required when removing the OPC from Apttus .
        - productControlWhenClosedWon Method is Basically Displays errors to the users when they try to make Chnages to the 
          APT_Opportunity_Product_Line_Item__c records . However going forward users would not be having any accessibilty to update these
          records as the VF page is gettig decommisioned .
          
        - overrideClassification - This method is to update the classification on the APT_Opportunity_Product_Line_Item__c records , As
          the classification would now be driven on the data which user would be inputing on the Opportunity Product Records instead of
          APT_Opportunity_Product_Line_Item__c records
          
        - This trigger can be deleted after Decemeber 2020 
    
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            APTOptyLineItemHandler.beforeInsertActions(trigger.new);
        }
        if(trigger.isUpdate){
            APTOptyLineItemHandler.beforeUpdateActions(trigger.new, trigger.oldMap);
        }
        if (trigger.isDelete) {
            APTOptyLineItemHandler.beforeDeleteActions(trigger.old);
        }
    }
    
    Shashwat.Nath@Auspost.com code comments ends */
}