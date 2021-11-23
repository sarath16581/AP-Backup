trigger Entitlement_Rule_BeforeInsUpd on Entitlement_Rule__c (before insert, before update) {
    // this will sorts the rule field value pair (for duplicate validation purpose)
    for (Entitlement_Rule__c erule : trigger.new) {
        if (erule.Rule__c != '' && erule.Rule__c != null) {
            List<String> fieldopvalues = erule.Rule__c.split('\\|\\|');
            fieldopvalues.sort();
            erule.Rule__c = String.join(fieldopvalues,'||');
        }
    }
}