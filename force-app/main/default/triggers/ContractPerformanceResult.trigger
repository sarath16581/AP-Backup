trigger ContractPerformanceResult on Contract_Performance_Result__c (before insert, before update) {
    if(trigger.isBefore && ( trigger.isUpdate || trigger.isInsert)  ){
        ContractPerformanceService cps = new ContractPerformanceService(trigger.new, trigger.oldMap);
        cps.onResultIsBreached();
        cps.onResultSendReminder();
    }
}