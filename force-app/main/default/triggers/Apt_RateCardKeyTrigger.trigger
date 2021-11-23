/**
Description: This apex trigger is for Apttus's Line Item  (Apttus_Config2__LineItem__c)
Last Modified By: Seth Heang
Last Modified Date: 13/01/2020 | Add a trigger to update NetPrice with custom pricing for Local Pickup and Delivery Services Product
Last Modified Date: 27/05/2020 | Commented code for updating NetPrice with custom pricing for Local Pickup and Delivery Services Product
Mathew Jose - 29/05/2021 - Added the before update event method calls onRateCardKeyUpdate,onPriceChange (STP-5812)

**/
trigger Apt_RateCardKeyTrigger on Apttus_Config2__LineItem__c (before insert,before delete,after insert,after update,before update) {
    if(trigger.isBefore == true) {

        if(trigger.isdelete){
            APT_LineItemTriggerHandler.APT_updateConfig(trigger.old);
        }
        /* Modified By: Mathew Jose- updated as per User Story - STP-5812 */
        if(trigger.isUpdate){
            APT_LineItemTriggerHandler.onRateCardKeyUpdate(trigger.new,trigger.oldMap); 
            APT_LineItemTriggerHandler.onPriceChange(trigger.newMap,trigger.oldMap); 

        }       
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
         /* Modified By: Mansi Shah - Commented as per User Story - STP-5810 */
            // For 'Local Pickup and Delivery Services' Product only, update Apttus's NetPrice with custom pricing values
            //APT_LineItemTriggerHandler.OverWrite_LPD_NetPrice(Trigger.New);
        }
    }
   
}