/**************************************************
Purpose:    Main trigger for workday adjustment object
History:
--------------------------------------------------
8.9.2017    Adrian Recio Created
**************************************************/

trigger WorkDayAdjustmentTrigger on Work_Day_Adjustments__c (before insert, before update, after insert, after update) {

     system.debug('WorkdayAdjustment trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c);

    if (!SystemSettings__c.getInstance().Disable_Triggers__c){       
        if(trigger.isInsert){
            if(trigger.isBefore){    
                WorkDayAdjustmentTriggerHandler.populateSalesTeam(Trigger.new,Trigger.oldMap,false);
                system.debug('WorkdayAdjustment before insert');
            }
            
            if(trigger.isAfter){
                system.debug('WorkdayAdjustment after insert');
            }
        }

        if(trigger.isUpdate){
            if(trigger.isBefore){
                WorkDayAdjustmentTriggerHandler.populateSalesTeam(Trigger.new,Trigger.oldMap,true);
          		system.debug('WorkdayAdjustment before update');
            }
            
            if(trigger.isAfter){
                system.debug('WorkdayAdjustment after update');
            }
        } 
    }
}