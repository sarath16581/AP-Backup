/**
 * Created by: Sautul Mehta
 * Description: Class to have the cleanup of the generated documents for APPC View Rate Card.
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
global with sharing class APT_CleanupAPPCRateCard implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        R2T_Exempted_Proposal_Settings__mdt customMetadata = [SELECT Id, MasterLabel, Label FROM R2T_Exempted_Proposal_Settings__mdt where MasterLabel = :APT_Constants.METADATTYPERECORD_TEMPLATE_APPC_RATE_CARD];
        String templateName = customMetadata.Label;
        String query = 'select Id, Title from ContentDocument where Id in (Select ContentDocumentId from ContentVersion where APT_Template_Name__c = :templateName)';
        
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<ContentDocument> templateAttachments) {
        system.debug(templateAttachments.size());
        try {
            if(!templateAttachments.isEmpty())
            {
                delete templateAttachments;
            }
        } catch(Exception e) {
            System.debug(e);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}