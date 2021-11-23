trigger ContractPerformanceAgreement on Contract_Performance_Agreement__c (before insert , before Update ,after insert , after update) {
    if(trigger.isBefore && ( trigger.isUpdate || trigger.isInsert ) ){
        ContractPerformanceService cps = new ContractPerformanceService((list<sObject>)trigger.new, (map<id,sObject>)trigger.oldMap);
        cps.setNextDueDateAgreement();
    }


    if(trigger.isAfter && ( trigger.isUpdate || trigger.isInsert) ){
        ContractPerformanceService cps = new ContractPerformanceService((list<sObject>)trigger.new, (map<id,sObject>)trigger.oldMap);
        cps.reSetTriggerFlowFlagAgrmnt();
    }
}