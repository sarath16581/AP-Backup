/**************************************************
Description:    Whenever an new emailmessage is inserted,
                if the emailmessage's parentID links to case and case's Service_Now_Ticket_Number__c is not null,
                then create a new record for cusotm obj called 'Outbound Email Message'.
History:
--------------------------------------------------
2014-07-10  yuanyuan.zhang@bluewolf.com  Created
2019-02-22  nathan.franklin@auspost.com.au  Adding message to top of text body when attachments exist on the Email Message
2021-08-11  Seth Heang - Uplift API version to 52
**************************************************/
trigger EmailMessage_AI_createOutBoundMessage on EmailMessage (after insert) {
    
    final String KEYPREFIX_CASE = Case.SObjectType.getDescribe().getKeyPrefix(); 
    Map<String, List<EmailMessage>> map_caseId_list_emailmessage = new Map<String, List<EmailMessage>>();
    Set<String> set_validCaseIds = new Set<String>();
    List<Outbound_Email_Message__c> list_outboundMsg = new List<Outbound_Email_Message__c>();
    
    for (EmailMessage em : trigger.new) {
        if (em.ParentId != null) {//Get all em , which's parentId is related to case
            String parentId = em.ParentId;
            if (parentId.substring(0,3) == KEYPREFIX_CASE) {
                if (!map_caseId_list_emailmessage.containsKey(parentId)) {
                    map_caseId_list_emailmessage.put(parentId, new List<EmailMessage>());
                }
                map_caseId_list_emailmessage.get(parentId).add(em);
            }
        }
    }
    
    if (!map_caseId_list_emailmessage.isEmpty()) {
        for (Case c : [SELECT Id From Case WHERE Id IN :map_caseId_list_emailmessage.keySet() AND Service_Now_Ticket_Number__c != null ]) {
            set_validCaseIds.add(c.Id);
        }
        
        for (String cId : set_validCaseIds) {
            for (EmailMessage em : map_caseId_list_emailmessage.get(cId)) {
                Outbound_Email_Message__c oem = new Outbound_Email_Message__c();
                oem.BccAddress__c = em.BccAddress;
                oem.CcAddress__c = em.CcAddress;
                oem.FromAddress__c = em.FromAddress;
                oem.FromName__c = em.FromName;
                oem.HasAttachment__c = em.HasAttachment;
                oem.Headers__c = em.Headers;
                oem.Htmlbody__c = em.HtmlBody;
                oem.Incoming__c = em.Incoming;
                oem.MessageDate__c = em.MessageDate;
                //oem.Name = em.
                //oem.LastActivityDate
                oem.Status__c = em.Status;
                oem.Subject__c = em.Subject;
                oem.TextBody__c = (em.HasAttachment ? '*** THIS MESSAGE CONTAINS ATTACHMENTS ***\n\n' : '') + em.TextBody;
                oem.ToAddress__c = em.ToAddress;
                oem.ActivityId__c = em.ActivityId;
                oem.ParentId__c = em.ParentId;
                oem.EmailId__c = em.Id;
                //oem.ReplyToEmailMessageId__c = em.ReplyToEmailMessageId;
                list_outboundMsg.add(oem);
            }
        }
        
        if (list_outboundMsg.size() > 0) insert list_outboundMsg;
    }
    
}