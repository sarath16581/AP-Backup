/**
Apex Trigger on Agreement lodgement point object on after insert, after update,before insert,before update events.
*/
trigger APT_AgreementLPTrigger on APT_Agreement_Lodgement_Point__c (after insert,after update,before insert,before update) {
    if(trigger.isafter && trigger.isinsert){
        APT_AgreementLPTriggerHandler.updateOperationalScheduleOnLPChange(trigger.new);
        String result = APT_AgreementLPTriggerHandler.updateLPDetailsToLineItem(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(APT_Agreement_Lodgement_Point__c agrLP : trigger.new) {
                agrLP.addError(result);
            }               
        }
    }
    
    if(trigger.isafter && trigger.isupdate){
        list<APT_Agreement_Lodgement_Point__c> alpListToBeUpdated = new List<APT_Agreement_Lodgement_Point__c>();
        
        
        for(APT_Agreement_Lodgement_Point__c alp : trigger.new){
            APT_Agreement_Lodgement_Point__c oldAlp = trigger.oldMap.get(alp.Id);
            if(oldAlp!= null && ((oldAlp.APT_Status__c != alp.APT_Status__c && (APT_Constants.INACTIVE).equalsIgnoreCase(alp.APT_Status__c)) || (alp.APT_Billing_Account__c != oldAlp.APT_Billing_Account__c)) ){
                alpListToBeUpdated.add(alp);
            }
        }
        system.debug('*** alpListToBeUpdated ***'+alpListToBeUpdated);
        APT_AgreementLPTriggerHandler.updateOperationalScheduleOnLPChange(alpListToBeUpdated);
        // Defect 1428 Kushal Bhalodiya
        String result = APT_AgreementLPTriggerHandler.updateLPDetailsToLineItem(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(APT_Agreement_Lodgement_Point__c agrLP : trigger.new) {
                agrLP.addError(result);
            }               
        }
    }
    if(trigger.isbefore && (trigger.isupdate || trigger.isinsert)){
        
        for(APT_Agreement_Lodgement_Point__c alp : trigger.new){
            system.debug(alp+'---->');
            if(alp.APT_Status__c == APT_Constants.INACTIVE || alp.APT_Billing_Account__c != null
                         ||  alp.APT_Cash_Account__c != null ||  alp.APT_Charge_Account__c  != null
                         ||  alp.APT_Sub_Account__c != null){
                alp.APT_Billing_Account_Flag__c = true;
            } else{
                alp.APT_Billing_Account_Flag__c = false;
            }
        }
        //Defect 1568
        String result = APT_AgreementLPTriggerHandler.validateDuplicateAccounts(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(APT_Agreement_Lodgement_Point__c agrLP : trigger.new) {
                agrLP.addError(result);
            }               
        }
        
    }
    if(trigger.isbefore && trigger.isinsert){
        String result = APT_AgreementLPTriggerHandler.updateLPDetailsFromLineItem(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(APT_Agreement_Lodgement_Point__c agrLP : trigger.new) {
                agrLP.addError(result);
            }               
        }
    }
}