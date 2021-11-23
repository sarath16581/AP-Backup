/**
*
* Help and support : this class is used to set the reopen date when a case is created within EDD timeframes.
* History :
* --------------------------------------------------
* 2021-06-15 hara.sahoo@auspost.com.au Created
* 2021-07-08 hara.sahoo@auspost.com.au Modified : Added explicit case owner assignment to Awaiting reopen queue
**/
public without sharing class ChasSetCaseWithinEDDOnHold implements Queueable {
    private Id caseId;
    private DateTime reopenDate = null;
    List<Group> reopenQ = [SELECT Id, Name FROM Group WHERE developerName =: SSSWConstants.QUEUE_NAME_REOPEN_Q];
    Id queueId = reopenQ[0].Id;
    
    public ChasSetCaseWithinEDDOnHold(Case newCase)
    {
        caseId = newCase.Id;
    }
    // update case status to In Progress
    // update case reopen date time to EED + Business days
    // update the HeldToOpenOn__c to case reopen date, for history tracking
    public void execute(QueueableContext context)
    {
        try {
            if(caseId != null)
            {
                List<Case> updateCases = [SELECT Id, EstimatedDelivery__c FROM Case WHERE Id =: caseId];
                if(updateCases.size() == 1)
                {
                    Case updateCase = updateCases[0];
                    Date reopenDate = ChasUtil.calculateNextBusinessDay(updateCase.EstimatedDelivery__c,Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c != null ? Integer.valueOf(Consumer_Help_and_Support__c.getInstance().nextUpdateInForLateItems__c): 0 );
                    // update the case details
                    updateCase.Status = SSSWConstants.CASE_STATUS_INPROGRESS;
                    // update the case owner explicitly, this will ensure the status tracking for case status and case owner gets registred
                    updateCase.OwnerId=queueId;
                    updateCase.Case_Reopen_Date__c = reopenDate;
                    updateCase.HeldToOpenOn__c = reopenDate;
                    
                    Database.update(updateCase);
                }
            }
        } catch (Exception exp){
            // error logging
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW','ChasApexController', 'setCaseWithinEDDOnHold', null, LoggingLevel.ERROR);
        }
    }
}