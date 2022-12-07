/**
Description: Populate record count on contract record as master-detail relationship has been changed to look up. Rollup summary
field won't help
Created By - Mausam Padhiyar
Created Date - 9th Aug, 2016

Last Modified By - Mausam Padhiyar
Last Modified Date - 10th Nov, 2016 | 1742 | reduce logic
* @changelog
* 2022-12-01 - Ken McGuire - Added application domain.
*/
trigger APT_SAPContractTrigger on APT_SAP_Contracts__c (after insert, after update, before delete, before insert, before update) {
    
    // Application Domain
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(APT_SAP_Contracts__c.SObjectType))) {
        APTSAPContractsDomainTriggerHandler.newInstance().dispatch();
      }
  
    
    //isbefore?
    if(trigger.isBefore){
        if(trigger.isDelete) {
            String result = APT_SAPContractTriggerHandler.beforeDeleteEvent(trigger.old);
            
            if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
                for(APT_SAP_Contracts__c sc : trigger.old) {
                    sc.addError(result);
                }
            }
        }
        
        if(Trigger.isInsert)
        {
            
            String result = APT_SAPContractTriggerHandler.beforeInsertEvent(trigger.new);
            
            if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
                for(APT_SAP_Contracts__c sc : trigger.new) {
                    sc.addError(result);
                }
            }
            
            
            //APT_SAPContractTriggerHandler.beforeInsertEvent(trigger.newMap.keySet());
        }
        
        if(Trigger.isUpdate)
        {
             String result = APT_SAPContractTriggerHandler.beforeUpdateEvent(trigger.new, trigger.oldMap);
            
            if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
                for(APT_SAP_Contracts__c sc : trigger.new) {
                    sc.addError(result);
                }
            }
        }
    }
    
    //isafter?
    if(trigger.isAfter){
        if(trigger.isInsert) {
            
            //APT_SAPContractTriggerHandler.afterInsertEvent(trigger.newMap.keySet());
            
            
            String result = APT_SAPContractTriggerHandler.afterInsertEvent(trigger.new);
            
            if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
                for(APT_SAP_Contracts__c sc : trigger.new) {
                    sc.addError(result);
                }
            }
            
        }
        
        if(trigger.isUpdate) {
            
            String result = APT_SAPContractTriggerHandler.afterUpdateEvent(trigger.new, trigger.oldMap);
            
            if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
                for(APT_SAP_Contracts__c sc : trigger.new) {
                    sc.addError(result);
                }
            }
            
            //APT_SAPContractTriggerHandler.afterUpdateEvent(trigger.newMap.keySet());
        }
    }
}