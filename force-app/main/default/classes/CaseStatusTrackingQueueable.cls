/**
 * @description       : 
 * @author            : naveen.rajanna@auspost.com.au
 * @group             : 
 * @last modified on  : 2021-09-30
 * @last modified by  : naveen.rajanna@auspost.com.au
**/
public class CaseStatusTrackingQueueable implements Queueable {
    private Map<Id, Case> caseMap = new Map<Id, Case>();
    private List<RollupCalculationFailureLog__c> newRollupLogFailures = new List<RollupCalculationFailureLog__c>();
    
    public CaseStatusTrackingQueueable(Map<Id, Case> caseMap) {
        this.caseMap = caseMap;
    }

    public void execute(QueueableContext context) {
		try {
            List<Case> caseList = caseMap.values(); 
            Integer index = 0;
            Database.SaveResult[] results = Database.update(caseList, false);
            for(Database.SaveResult result : results) {
                if(!result.isSuccess()) {
                    String error = '';
                    for(Database.Error err : result.getErrors()) {
                        error += err.getMessage() + '\n';
                    }
                    newRollupLogFailures.add(
                        new RollupCalculationFailureLog__c(
                            RecordId__c = caseList[index].Id,
                            Message__c = error.left(255)
                        )
                    );
                }
                index++;
            }

            if(!newRollupLogFailures.isEmpty()) {
                upsert newRollupLogFailures RecordId__c;
            }
        } catch(Exception exp) {
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 'StatusTrackingRollup_Batchable', 'execute', null, LoggingLevel.ERROR);
        }
    }
}