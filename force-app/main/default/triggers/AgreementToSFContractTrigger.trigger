/*------------------------------------------------------------
Author:        Chester Borbon
Company:       Accenture
Description:   Main trigger to execute apttus contract related transactions.
Test Class:    AgreementToSFContractTriggerHandlerTest
History
<Date>      <Authors Name>     <Brief Description of Change>
5-Oct-2018   Chester Borbon    Added after update and before delete events to execute contract cloning
                               methods from AgreementToSFContractTriggerHandler.
5-May-2018    Shashwat Nath    Added before update event to restrict incorrect Contract Activation                      
------------------------------------------------------------*/
trigger AgreementToSFContractTrigger on Apttus__APTS_Agreement__c (after update, before delete , before Update) {
    // trigger after
    if(trigger.isAfter)  {
        // trigger update
        if (trigger.isUpdate) {
            // Perform Apttus Contract/Agreement cloning
            AgreementToSFContractTriggerHandler.onAfterUpdate(trigger.oldMap, trigger.new);
        }
    // trigger before
    } else if(trigger.isBefore) {
        // trigger delete
        if (trigger.isDelete) {
            // Perform SF Contract clone delete
            AgreementToSFContractTriggerHandler.onBeforeDelete(trigger.old);
        }
        if (trigger.Isupdate) {
            // Restrict Users from Activating Contract by Chnaging Status
            Map<Id,Apttus__APTS_Agreement__c> contractMap =  new Map<Id,Apttus__APTS_Agreement__c>();
            //Picking up only those records whose current Category In Effect and Current Status is Activated
            for(Apttus__APTS_Agreement__c apt : trigger.new){
                if(Constants.IN_EFFECT.equalsIgnoreCase(apt.Apttus__Status_Category__c) && !Constants.IN_EFFECT.equalsIgnoreCase(trigger.oldmap.get(apt.id).Apttus__Status_Category__c)
                        && Constants.ACTIVATED.equalsIgnoreCase(apt.Apttus__Status__c) && !Constants.ACTIVATED.equalsIgnoreCase(trigger.oldmap.get(apt.id).Apttus__Status__c)){
                            contractMap.put(apt.id,apt);
                        }
            }
            if(contractMap.values().size()>0){
                AgreementToSFContractTriggerHandler.restrictActivation(contractMap);
            }
        }
    }
}