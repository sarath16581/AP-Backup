/**
  This apex class is handler class for apex trigger - APT_AsyncMergeCallTrigger
  Created By - Mausam Padhiyar
  Created Date - 24th June, 2016
*Modifications Log
* 15-02-2024 : Bharat Patel: Modified method beforeUpdateEvent(), add logic related to APT_Document_Notification_Off__c
**/ 
public with sharing class APT_AsyncMergeCallTriggerHandler {

    public static final string IN_REVIEW = 'In Review';
    public static string beforeUpdateEvent(list<Apttus__AsyncMergeCall__c> listAsyncMergCall, map<Id, Apttus__AsyncMergeCall__c> mapOldAsyncMergeCall) {
        try {
            if(listAsyncMergCall != null && listAsyncMergCall.size() > 0) {
                Set<ID> ProposalIdsToBeProcessed = new Set<ID>();
                map<Id, list<Apttus__AsyncMergeCall__c>> mapAsyncMergeCall = new map<Id, list<Apttus__AsyncMergeCall__c>>();
                for(Apttus__AsyncMergeCall__c asyncMergeCall : listAsyncMergCall) {
                    //system.debug('*** asyncMergeCall ***'+asyncMergeCall);
                    //only for contract and not for proposal
                    if(String.isEmpty(asyncMergeCall.Apttus_Proposal__QuoteProposalId__c) && !String.isEmpty(asyncMergeCall.Apttus__Agreement__c) && !String.isEmpty(asyncMergeCall.Apttus__Result__c) && !String.isEmpty(asyncMergeCall.Apttus__Action__c) && asyncMergeCall.Apttus__Action__c.equalsIgnoreCase(APT_Constants.ASYNC_ACTION_GENERATE) && !String.isEmpty(asyncMergeCall.Apttus__Status__c) && !String.isEmpty(mapOldAsyncMergeCall.get(asyncMergeCall.Id).Apttus__Status__c) && asyncMergeCall.Apttus__Status__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY) && !mapOldAsyncMergeCall.get(asyncMergeCall.Id).Apttus__Status__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY)) {
                        list<Apttus__AsyncMergeCall__c> listAsyncMergeCall = mapAsyncMergeCall.get(asyncMergeCall.Apttus__Agreement__c);
                        if(listAsyncMergeCall != null && listAsyncMergeCall.size() > 0) {
                            listAsyncMergeCall.add(asyncMergeCall);
                            mapAsyncMergeCall.put(asyncMergeCall.Apttus__Agreement__c, listAsyncMergeCall);
                        } else {
                            listAsyncMergeCall = new list<Apttus__AsyncMergeCall__c>();
                            listAsyncMergeCall.add(asyncMergeCall);
                            mapAsyncMergeCall.put(asyncMergeCall.Apttus__Agreement__c, listAsyncMergeCall);
                        }
                    } else if(String.isNotBlank(asyncMergeCall.Apttus_Proposal__QuoteProposalId__c) 
                                && String.isBlank(asyncMergeCall.Apttus__Agreement__c)
                                && String.isNotBlank(asyncMergeCall.Apttus__Result__c) 
                                && String.isNotBlank(asyncMergeCall.Apttus__Action__c) 
                                && asyncMergeCall.Apttus__Action__c.equalsIgnoreCase(APT_Constants.ASYNC_ACTION_GENERATE)
                                 && !String.isEmpty(asyncMergeCall.Apttus__Status__c) 
                                 && !String.isEmpty(mapOldAsyncMergeCall.get(asyncMergeCall.Id).Apttus__Status__c) 
                                 && asyncMergeCall.Apttus__Status__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY) 
                                 && !mapOldAsyncMergeCall.get(asyncMergeCall.Id).Apttus__Status__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY)){
                        proposalIdsToBeProcessed.add(asyncMergeCall.Apttus_Proposal__QuoteProposalId__c);
                        
                    } else {}
                }
                
                if(proposalIdsToBeProcessed.Size() > 0 ){
                    APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
                    //get email addresses
                    String emailAddresses; 
                    String defaultProposalTemplateName;
                    if(r2tSystemProperties != null) {            
                        if(!String.isEmpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                            emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                        }
                    }
                    List<Apttus_Proposal__Proposal__c> proposalList = [select Id,APT_Document_Notification_Off__c,Name,Apttus_Proposal__Approval_Stage__c,APT_Batch_Error_Message__c,APT_Create_Proposal_Batch_Id__c from Apttus_Proposal__Proposal__c where Id IN:proposalIdsToBeProcessed];
                    Set<ID> JobIDSet = new Set<ID>();
                    for(Apttus_Proposal__Proposal__c proposal : proposalList){
                        JobIDSet.add(proposal.APT_Create_Proposal_Batch_Id__c);
                    }    
                    Map<ID, AsyncApexJob > JobMap = new Map<ID, AsyncApexJob >([select Id,CreatedBy.Email from AsyncApexJob where Id IN:JobIDSet]);
                    Messaging.SingleEmailMessage mail;
                    list<String> toAddresses;
                    list<Messaging.SingleEmailMessage> emaillist;
                    for(Apttus_Proposal__Proposal__c proposal : proposalList){
                        AsyncApexJob asyncJob = JobMap.get(proposal.APT_Create_Proposal_Batch_Id__c);
                        proposal.APT_Document_Generation_in_Progress__c  = false;
                        if(String.Isblank(proposal.Apttus_Proposal__Approval_Stage__c) 
                                || proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_DRAFT) 
                                || proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(IN_REVIEW) 
                                ||  proposal.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_APPROVED)) {
                            proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_GENERATED;
                            proposal.APT_Next_Steps__c = null;
                        }
						if(!proposal.APT_Document_Notification_Off__c) {
                                           // Send an email to the Apex job's submitter notifying of job completion.
                        mail = new Messaging.SingleEmailMessage();
                        
                        
                        
                        toAddresses = new list<String>();
                        if(!(String.isEmpty(emailAddresses)) && !String.isEmpty(APT_Constants.EMPTY_STRING) &&  !emailAddresses.equalsIgnoreCase(APT_Constants.EMPTY_STRING)) {
                            toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
                        }
                        toAddresses.add(asyncJob.CreatedBy.Email);
                        
                        //String[] toAddresses = new String[] {a.CreatedBy.Email};
                        mail.setToAddresses(toAddresses);
                        mail.setSubject(APT_Constants.STRING_PROPOSALDOC_EMAIlSUBJECT+proposal.Name+APT_Constants.STRING_STAR);

                        mail.setHtmlBody(proposal.APT_Batch_Error_Message__c);
                        //mail.setPlainTextBody(mailTextBody);
                        emaillist = new List<Messaging.SingleEmailMessage> (); 
                        emaillist.add(mail);
                        Messaging.sendEmail(emaillist);
						}
                        proposal.APT_Batch_Error_Message__c = null;
                        proposal.APT_Create_Proposal_Batch_Id__c = null;
                        
                    }
                    update proposalList;
                }
                
                if(mapAsyncMergeCall.size() > 0) {
                    //merge doc required agreements only
                    map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APT_Generated_Doc_Ids__c, APT_Merge_Documents__c,
                                                                                                                APT_Is_Generate_Doc_Batch_Running__c
                                                                                                                FROM Apttus__APTS_Agreement__c 
                                                                                                                WHERE Id IN :mapAsyncMergeCall.keySet()
                                                                                                                AND APT_Merge_Documents__c = true]);
                    System.Debug('APT_AsyncMergeCallTriggerHandler - mapAgreement.size(): ' + mapAgreement.size());
                    //collect attachments per agreement
                    list<String> listAttachmentIds = new list<String>();
                    map<Id, list<String>> mapAttachmentIds = new map<Id, list<String>>();
                    if(mapAgreement != null && mapAgreement.size() > 0) {
                        for(Id agreementId : mapAgreement.keySet()) {
                            //reset
                            listAttachmentIds.clear();
                            
                            //already generated docs
                            Apttus__APTS_Agreement__c agreement = mapAgreement.get(agreementId);
                            if(agreement != null && !String.isEmpty(agreement.APT_Generated_Doc_Ids__c)) {
                                list<String> listGenDocIds = agreement.APT_Generated_Doc_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                                if(listGenDocIds != null && listGenDocIds.size() > 0) {
                                    listAttachmentIds.addAll(listGenDocIds);
                                }
                            }
                                
                            for(Apttus__AsyncMergeCall__c AsyncMergeCall : mapAsyncMergeCall.get(agreementId)) {
                                listAttachmentIds.add(AsyncMergeCall.Apttus__Result__c);
                            }
                            
                            if(!agreement.APT_Is_Generate_Doc_Batch_Running__c) {
                                mapAttachmentIds.put(agreementId, listAttachmentIds);
                            }
                        }
                    }
                    
                    //call merge doc ids
                    if(mapAttachmentIds.size() > 0) {
                        APT_MergeDocBatch controller = new APT_MergeDocBatch(userInfo.getSessionId(), mapAttachmentIds.keySet(), mapAttachmentIds);
                        database.executeBatch(controller, 1);
                    }
                }
            }
        } catch(system.Exception ex) {
            return ex.getMessage();
        }
        
        return APT_Constants.SUCCESS_LABEL;
    }
}