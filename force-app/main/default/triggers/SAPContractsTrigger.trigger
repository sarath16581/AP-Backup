/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 16/08/2016
  * @description  : Trigger on SAP Contracts to call the Handler Class
  */
trigger SAPContractsTrigger on APT_SAP_Contracts__c(before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete){    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(APT_SAP_Contracts__c.sObjectType))){ // verify if triggers are disabled
        APTSAPContractsTriggerHandler.execute();  // Handler dispatches appropriate event
    }
}