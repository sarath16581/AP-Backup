trigger APT_AppliedRuleInfoActionTrigger on Apttus_Config2__AppliedRuleActionInfo__c (after insert) {

if(trigger.isAfter && trigger.isInsert) {
        String result = APT_AppliedRuleInfoActionTriggerHandler.APT_DeleteBlankRule(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(Apttus_Config2__AppliedRuleActionInfo__c ara : trigger.new) {
                ara.addError(result);
            }               
        }
    }

}