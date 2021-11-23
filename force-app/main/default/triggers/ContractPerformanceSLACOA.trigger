trigger ContractPerformanceSLACOA on Contract_Performance_SLA_COA__c (before insert, before update, after insert, after update) {
    if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert) ){
        ContractPerformanceService cps = new ContractPerformanceService(trigger.new, trigger.oldMap);
        cps.setNextDueDateSLACOA();
    }
    if(trigger.isafter && (trigger.isUpdate || trigger.isInsert)  ){
        ContractPerformanceService cps = new ContractPerformanceService(trigger.new, trigger.oldMap);
        cps.CreateResultRecords();
        cps.reSetTriggerFlowFlagSLACOA();
    }
}