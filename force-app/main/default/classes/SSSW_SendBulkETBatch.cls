/**
  * @description       Accepts the email contact lists, subjects and body to send to ET Webservice.
   *                    Inserts new tasks if successful and create ET Backlog records if not.
   *                    Sending as batch of 100 as per recommendation from SEMA.
  * @param             NA
  * @return            NA
  * @throws            NA
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    20/12/2016          Dion Gunn        Modified to run as a batch class to avoid hitting governor limits
    16/02/2017          Dion Gunn        Further modifications to reduce heap size.
	09/05/2017          Angelo Rivera    Created new parameter value (contId) for ExacttargetEmail().sendMailToMultipleAddressesBulk
*******************************  History ************************************************/
public class SSSW_SendBulkETBatch implements Database.Batchable<Case>, Database.AllowsCallouts, Database.Stateful {

    private List<Case> cases;
    private Map<Id,String> emailBodyList;
    private Map<Id,String> emailSubList;
    private Map<Id,String> contAddress;
    private Map<Id,String> contNames;
    private Map<Id,String> contId; //05092017 - Angelo Rivera - map of contact Id
    private Map<Id, String> textContent;
    private String fromEmail;
    private String fromName;
    private String batchToken;
    private List<ExactTargetBacklog__c> etb = new List<ExactTargetBacklog__c>();
    private List<Task> tskList = new List<Task>();

    public SSSW_SendBulkETBatch(String fromEmail, String fromName, Map<Id,String> emailBodyList, Map<Id,String> emailSubList, Map<Id,String> contAddress, Map<Id,String> contNames,
            Map<Id,String> textContent, List<Case> caseList, Map<Id,String> contId) {
        this.fromEmail = fromEmail;
        this.fromName = fromName;
        this.emailBodyList = emailBodyList;
        this.emailSubList = emailSubList;
        this.contAddress = contAddress;
        this.contNames = contNames;
        this.textContent = textContent;
        this.cases = caseList;
        this.contId = contId; //05092017 - Angelo Rivera - This will be passed to ExactTargetEmail as the SubscriberId
    }

    public Iterable<Case> start(Database.BatchableContext BC) {
        ExactTargetEmail etm = new ExactTargetEmail();
        batchToken = etm.validToken;
        return cases;
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        String defaultRecTypeId = [Select Id from RecordType where developerName = :SSSWCOnstants.DEFAULT_TASKS limit 1].Id;
        List<String> caseBodyList = new List<String>();
        List<String> caseSubList = new List<String>();
        List<String> casecontAddress = new List<String>();
        List<String> casecontNames = new List<String>();
        List<String> casecontIds = new List<String>(); //05092017 - Angelo Rivera - This will be passed to ExactTargetEmail as the SubscriberId
	
        for(Case c : scope) {
            caseBodyList.add(emailBodyList.get(c.Id));
            caseSubList.add(emailSubList.get(c.Id));
            casecontAddress.add(contAddress.get(c.Id));
            casecontNames.add(contNames.get(c.Id));
            casecontIds.add(contId.get(c.Id)); //05092017 - Angelo Rivera - This will be passed to ExactTargetEmail as the SubscriberId
        }
        
        //05092017 - Angelo Rivera - Changed the last parameter from casecontAddress to casecontIds
        ExactTargetEmail.ExactTargetSentResult etsr = new ExacttargetEmail().sendMailToMultipleAddressesBulk(batchToken,
                fromEmail, fromName, casecontAddress, casecontNames, caseBodyList, caseSubList, casecontIds);

        for (Case c : scope) {
            tskList.add(new task(WhatId = c.Id, RecordTypeId = defaultRecTypeId,
                    Subject = SSSWCOnstants.TASK_SUB + c.CaseNumber,
                    Type = SSSWConstants.Email, whoId = c.ContactId, Description = textContent.get(c.Id),
                    Status = SSSWConstants.STAT_COMPLETED, Interaction_Type__c = SSSWConstants.TASK_INT_TYPE));
        }

        if (!etsr.isSuccessful) {
            ExactTargetBacklog__c c = new ExactTargetBacklog__c();
            c.EmailContentJSON__c = etsr.requestBody;
            c.ErrorMessage__c = etsr.message;
            c.IsBatchEmail__c = etsr.IsBatchEmail;
            etb.add(c);
        }
        System.debug(LoggingLevel.Error, '**HeapSize**' + Limits.getHeapSize());
    }

    public void finish(Database.BatchableContext BC) {
       try {
            if (!tskList.isEmpty()) {
                database.insert(tskList);
            }

            if (!etb.isEmpty()) {
                insert etb;
            }
        } catch (Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
                    SSSW_SendBulkEmailContr.class.getName(), 'sendEmail', '', LoggingLevel.ERROR);
        }
    }

}