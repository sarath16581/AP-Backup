/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 16/06/2015
  * @description  : Trigger on Case Object to call the Handler class to perform necessary action
  * @changelog
  * 2022-02-03 - Nathan Franklin - Added temporary CaseTriggerHandler3
  */
trigger CaseCommonTrigger on Case(before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete){

    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Case.sObjectType))){     // verify if triggers are disabled
		
        // New domain based trigger dispatch
        // IMPORTANT for this to be at the top to work for SSSW Strategic routing
        (new CaseTriggerHandler2()).dispatch();
        
        CaseTriggerHandler.execute();  // Case handler dispatches appropriate event

        // New domain based trigger dispatch
        // NOTE: This is used specifically ONLY for code the MUST run after the legacy code runs
        // This is temporary and after all the legacy code is migrated to domain architecture, this should be decommissioned
        (new CaseTriggerHandler3()).dispatch();
    }

    // Added by : Adrian Recio
    // Description: I2C specific case trigger handler which is filtered by Enteprise recordtype
    if(trigger.isAfter){
        if(trigger.isUpdate){
            CaseTriggerHandler_IToC.afterUpdateTriggerHandler(trigger.OldMap, trigger.New);
        }
    }

}