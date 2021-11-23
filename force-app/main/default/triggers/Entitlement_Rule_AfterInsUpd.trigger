trigger Entitlement_Rule_AfterInsUpd on Entitlement_Rule__c (after insert, after update) {
    // checks for duplicate and raise an error when duplicate found
    Set<String> ruleSet = new Set<String>();
    for(Entitlement_Rule__c erule : trigger.new) {
        if (erule.Rule__c != '' && erule.Rule__c != null) {
            if (!ruleSet.contains(erule.Rule__c)) {
                ruleSet.add(erule.Rule__c);
            } else {
                erule.Rule__c.addError('Duplicate rule found on Id ' + erule.Id + '.');
            }
        }
    }
    
    // map all existing rule
    Map<String, Entitlement_Rule__c> existingRules = new Map<String, Entitlement_Rule__c>();
    for (Entitlement_Rule__c erule : [Select Id, Rule__c,Entitlement_Rule_Name__c From Entitlement_Rule__c Where Id not in :trigger.newMap.keySet()]) {
        existingRules.put(erule.Rule__c, erule);
    }
    
    // check for existence of rule
    for(Entitlement_Rule__c erule : trigger.new) {
        if (existingRules.containsKey(erule.Rule__c)) {        
            erule.Rule__c.addError('Duplicate rule found on '+ existingRules.get(erule.Rule__c).Entitlement_Rule_Name__c+ '. Id: ' + existingRules.get(erule.Rule__c).Id + '.');
        }
    }
}