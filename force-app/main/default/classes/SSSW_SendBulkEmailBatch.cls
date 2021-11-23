/**
  * @description       Merges case info into an email, grabs the HTML content, roles the database back
   *                    and prepares for sending via the SSSW_SendBulkETBatch class.
  * @param             NA
  * @return            NA
  * @throws            NA
  * @revision History  01 May 2017 - Angelo.Rivera@auspost.com.au - Added the passing of contact Id to SSSW_SendBulkETBatch
  */
public class SSSW_SendBulkEmailBatch implements Database.Batchable<Case>, Database.Stateful {

    private List<Case> cases;
    private String templateId;
    private Map<Id,String> emailBodyList = new Map<Id,String>();
    private Map<Id,String> emailSubList = new Map<Id,String>();
	private Map<Id,String> contAddress = new Map<Id,String>();
    private Map<Id,String> contId = new Map<Id,String>();
    private Map<Id,String> contNames = new Map<Id,String>();
    private Map<Id, String> textContent = new Map<Id, String>();

    public SSSW_SendBulkEmailBatch(List<Case> caseList, String tempId) {
        this.cases = caseList;
        this.templateId = tempId;
    }

    public Iterable<Case> start(Database.BatchableContext BC) {
        return cases;
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> caseList = scope;
        EmailTemplate et = [Select id, subject, HtmlValue From EmailTemplate e where Id = :templateId limit 1];
        Savepoint sp = Database.setSavepoint();
        for (Case cse : caseList) {

            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            sem.setToAddresses(new List<String>{
                    cse.Contact.Email
            });
            sem.setTargetObjectId(cse.Contact.id);
            sem.setWhatId(cse.Id);
            sem.setTemplateId(et.Id);
            //This is needed to ensure the triggers don't fire and blow soql query limits
            sem.setSaveAsActivity(false);
         //   if (!test.isRunningTest()) {
                Messaging.sendEmail(new Messaging.Email[]{
                        sem
                });
         //   }
            if (!test.isRunningTest()) {
                emailBodyList.put(cse.Id,JSON.serialize(sem.getHtmlBody().escapeHtml3()));
                //emailBodyList.put(cse.Id,sem.getHtmlBody().escapeHtml3());
                //System.debug(LoggingLevel.ERROR, 'Plain body>>>>>> ' + sem.getHtmlBody());
                System.debug(LoggingLevel.ERROR, 'Escaped body>>>>>> ' + sem.getHtmlBody().escapeHtml3());
                //System.debug(LoggingLevel.ERROR, 'Escaped Serialized body>>>>>> ' + JSON.serialize(sem.getHtmlBody().escapeHtml3()));
            } else if(test.isRunningTest()) {
                emailBodyList.put(cse.Id,JSON.serialize('This is the body of the email'));
            }
            if (!test.isRunningTest()) {
                textContent.put(cse.Id, sem.getPlainTextBody().escapeHtml3());
            }
            emailSubList.put(cse.Id,sem.getSubject());
            contId.put(cse.Id,cse.Contact.id); // 01 May 2017 - Angelo.Rivera@auspost.com.au - Added this to be passed to SSSW_SendBulkETBatch
			contAddress.put(cse.Id,cse.Contact.Email);
            System.debug(LoggingLevel.ERROR, 'DEBUG### Contact Id>>>>>> ' + JSON.serialize(contId));
            contNames.put(cse.Id,cse.Contact.Name);
            Database.rollback(sp);
        }
    }

    public void finish(Database.BatchableContext BC) {
        //13-02-2017 Dion Gunn: Modified batch size so it's fetched from custom setting
        Integer batchSize = Exact_Target_LogIn__c.getValues('marketinglogin').BulkSSSWBatchSize__c != null ?
                Integer.valueOf(Exact_Target_LogIn__c.getValues('marketinglogin').BulkSSSWBatchSize__c) : 10;
        Database.executeBatch(new SSSW_SendBulkETBatch(SSSWConstants.ORGWIDEEMAIL, SSSWConstants.EMAIL_SUBJECT, emailBodyList,
                emailSubList, contAddress, contNames, textContent, cases, contId), batchSize); // 01 May 2017 - Angelo Rivera - Added contId as SSSW_SendBulkETBatch parameter
    }
}