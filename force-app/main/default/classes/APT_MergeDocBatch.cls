/**
  This Class will merge documents
  Created By - Mausam Padhiyar
  Created Date - 23rd June, 2016
***************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 12 Mar, 2020
@Description: Updated Merge Documents logic to refer Files/ Content Documents instead of Attachments
*/
global class APT_MergeDocBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global String FileName {get;set;}
    global String sessionID {get;set;}
    global String serverURL {get;set;}
    global String instanceURL {get;set;}
    
    global set<Id> setAgreementId {get; set;}
    global set<String> setErrorMessages {get; set;}
    global map<Id, list<String>> mapFileIds {get; set;}
    
    /**
     constructor
    **/
    global APT_MergeDocBatch(String idSession, set<Id> agreementIdSet, map<Id, list<String>> fileIdsMap) {
        FileName = APT_Constants.FILE_NAME_MERGE;
        //sessionId = userInfo.getSessionId();
        sessionId = idSession;
        //server url
        Apttus__ComplySystemProperties__c complySystemProperties = Apttus__ComplySystemProperties__c.getvalues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        instanceURL = complySystemProperties.Apttus__InstanceUrl__c;
        /* Start: Meet Desai: Updated Apttus Merge Service's API Version from 29 to 38 */
        serverURL = instanceURL + APT_Constants.services_Soap_u_38_0  + UserInfo.getOrganizationId(); //Merge server URL
        /* End: Meet Desai: Updated Apttus Merge Service's API Version from 29 to 38 */
        
        setAgreementId = new set<Id>();
        setErrorMessages = new set<String>();
        
        mapFileIds = new map<Id, list<String>>();
        
        setAgreementId = agreementIdSet;
        mapFileIds = fileIdsMap;
    }
    
    /**
     start
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Name, APT_Merge_Documents__c, APT_Remove_Standalone_Docs__c,
                                        Document_Generated_by_Merge__c, APT_Is_Create_Contract_Batch_Job_Running__c,
                                        APT_Template_Order_Sequence__c
                                        FROM Apttus__APTS_Agreement__c
                                        WHERE Id IN :setAgreementId]);
    }
    
    /**
     execute
    **/
    global void execute(Database.BatchableContext BC, list<Apttus__APTS_Agreement__c> listAgreement){
       try {
           if(listAgreement != null && listAgreement.size() > 0) {
               list<Id> listFileIds = new list<Id>();
               list<Id> listRemoveFileIds = new list<Id>();
               map<Id, Id> mapMergedDocIds = new map<Id, Id>();
               map<Id, Apttus__APTS_Agreement__c> mapAgreement = new map<Id, Apttus__APTS_Agreement__c>();
               system.debug('*** listAgreement ***'+listAgreement);
               
               list<String> listTemplateIds = new list<String>();
               set<Id> setFileIds = new set<Id>();
               for(Apttus__APTS_Agreement__c agreement : listAgreement) {
                   system.debug('*** agreement.APT_Template_Order_Sequence__c ***'+agreement.APT_Template_Order_Sequence__c);
                   if(!String.isEmpty(agreement.APT_Template_Order_Sequence__c)) {
                        listTemplateIds = agreement.APT_Template_Order_Sequence__c.split(APT_Constants.SEPERATOR_COMMA);
                   }
                   
                   for(String agreementId : mapFileIds.get(agreement.id)) {
                        setFileIds.add(agreementId);
                   }
               }
               
               /* Start: Meet Desai: Updated SOQL Query to get data from ContentDocumentLink instead of Attachment */
               map<Id, ContentDocumentLink> mapFile = new map<Id, ContentDocumentLink>();
               for(ContentDocumentLink contentDocumentLink : [SELECT ContentDocument.Id, ContentDocument.Title FROM ContentDocumentLink WHERE ContentDocument.Id IN :setFileIds]){
                    mapFile.put(contentDocumentLink.ContentDocument.Id, contentDocumentLink);
               }
               /* End: Meet Desai: Updated SOQL Query to get data from ContentDocumentLink instead of Attachment */
               system.debug('*** mapFile ***'+mapFile);
               
               map<Id, Apttus__APTS_Template__c> mapTemplate = new map<Id, Apttus__APTS_Template__c>([SELECT Id, Name FROM Apttus__APTS_Template__c WHERE Id IN :listTemplateIds]);
               system.debug('*** mapTemplate ***'+mapTemplate);
               
               for(Apttus__APTS_Agreement__c agreement : listAgreement) {
                   system.debug('*** merge docs? ***'+agreement.APT_Merge_Documents__c);
                   system.debug('*** listRemoveFileIds ***'+listRemoveFileIds);
                   system.debug('*** listRemoveFileIds > size ***'+listRemoveFileIds.size());
                   
                   //merge docs?
                   if(agreement.APT_Merge_Documents__c) {
                       mapAgreement.put(agreement.Id, agreement);
                       //files need to be merged
                       listFileIds.clear();
                       
                       /*
                       //string to id conversion as api supports id
                       for(String agreementId : mapFileIds.get(agreement.id)) {
                           listFileIds.add(agreementId);
                       }
                       */
                       
                       //sort files as per the user selected template order/sequence
                       listTemplateIds.clear();
                       system.debug('*** agreement.APT_Template_Order_Sequence__c ***'+agreement.APT_Template_Order_Sequence__c);
                       if(!String.isEmpty(agreement.APT_Template_Order_Sequence__c)) {
                           listTemplateIds = agreement.APT_Template_Order_Sequence__c.split(APT_Constants.SEPERATOR_COMMA);
                           system.debug('*** listTemplateIds ***'+listTemplateIds);
                           if(listTemplateIds != null && listTemplateIds.size() > 0) {
                               for(String templateId : listTemplateIds) {
                                   system.debug('*** templateId ***'+templateId);
                                   Apttus__APTS_Template__c templateSO = mapTemplate.get(templateId);
                                   system.debug('*** templateSO ***'+templateSO);
                                   if(templateSO != null) {
                                       system.debug('*** mapFileIds.get(agreement.id) ***'+mapFileIds.get(agreement.id));
                                       for(String fileId : mapFileIds.get(agreement.id)) {
                                           system.debug('*** fileId ***'+fileId);
                                           /* Start: Meet Desai: Replaced Attachment with ContentDocumentLink object */
                                           ContentDocumentLink attch = mapFile.get(fileId);
                                            system.debug('*** attch ***'+attch);
                                            system.debug('*** attch.ContentDocument.Title.contains(templateSO.Name) ***'+attch.ContentDocument.Title.contains(templateSO.Name));
                                            if(attch != null && attch.ContentDocument.Title.contains(templateSO.Name)){
                                                system.debug('*** fileId ***'+fileId);
                                                listFileIds.add(fileId);
                                            }
                                            /* End: Meet Desai: Replaced Attachment with ContentDocumentLink object */
                                       }
                                   }
                               }
                           }
                       }
                       
                       system.debug('*** listFileIds ***'+listFileIds);
                       system.debug('*** listFileIds > size ***'+listFileIds.size());
                       //Id DocumentGeneratedbyMerge = Apttus.MergeWebService.mergeDocsToPDF(agreement.Id, listFileIds, agreement.Name + APT_Constants.SEPERATOR_UNDER_SCROLL  + FileName + APT_Constants.DOC_FORMAT_PDF, sessionID, serverURL);
                        //merge doc
                        Apttus.CustomClass.ActionParams objParam = new Apttus.CustomClass.ActionParams();
                        objParam.SessionId = sessionID;
                        objParam.SessionUrl = serverURL;
                        //objParam.ParentId = 'a4wO00000009qqiIAA';	//agreementId
                        objParam.ParentId = agreement.Id;
                        //objParam.DocIds = new ID[]{'00PO0000007FEmP','00PO0000007FEmP', '00PO0000007FEmA'};
                        objParam.DocIds = listFileIds;
                        objParam.DocFileName = agreement.Name + APT_Constants.SEPERATOR_UNDER_SCROLL  + FileName + APT_Constants.DOC_FORMAT_PDF;
                        objParam.AddFooter = false;
                        /* Start: Meet Desai: Do not call Apttus Merge API in case of Test Class */
                        ID DocumentGeneratedbyMerge;
                        if(!test.isRunningTest()){
                            DocumentGeneratedbyMerge = Apttus.MergeWebService.createPDF(objParam);
                        }
                        /* End: Meet Desai: Do not call Apttus Merge API in case of Test Class */
                        system.debug('*** mergedPDF ***'+DocumentGeneratedbyMerge);
                        system.debug('*** DocumentGeneratedbyMerge ***'+DocumentGeneratedbyMerge);
                        //merge doc
                        
                        mapMergedDocIds.put(agreement.Id, DocumentGeneratedbyMerge);
                       
                       //remove standalone files?
                       system.debug('*** remove standalone docs ***'+agreement.APT_Remove_Standalone_Docs__c);
                       if(agreement.APT_Remove_Standalone_Docs__c) {
                           listRemoveFileIds.addAll(listFileIds);
                       }
                   }
               }
               
               //remove standalone files?
               system.debug('*** listRemoveFileIds ***'+listRemoveFileIds);
               if(listRemoveFileIds.size() > 0) {
                   /* Start: Meet Desai: Updated SOQL Query to get data from ContentDocument instead of Attachment */
                   list<ContentDocument> listRemoveFile = [SELECT Id FROM ContentDocument WHERE Id IN :listRemoveFileIds];
                   /* End: Meet Desai: Updated SOQL Query to get data from ContentDocument instead of Attachment */
                   if(listRemoveFile != null && listRemoveFile.size() > 0) {
                       system.debug('*** listRemoveFile ***'+listRemoveFile);
                       system.debug('*** listRemoveFile > size ***'+listRemoveFile.size());
                       delete listRemoveFile;
                   }
                   //delete [SELECT Id FROM Attachment WHERE Id IN :listRemoveFileIds];
               }
               
               system.debug('*** mapAgreement ***'+mapAgreement);
               if(mapAgreement.size() > 0) {
                   list<Apttus__APTS_Agreement__c> listUpdateAgreement = new list<Apttus__APTS_Agreement__c>();
                   for(Apttus__APTS_Agreement__c agreement : mapAgreement.values()) {
                       system.debug('*** agreement.Document_Generated_by_Merge__c ***'+agreement.Document_Generated_by_Merge__c);
                       system.debug('*** mapMergedDocIds.get(agreement.Id) ***'+mapMergedDocIds.get(agreement.Id));
                       if(String.isBlank(agreement.Document_Generated_by_Merge__c) && mapMergedDocIds.get(agreement.Id) != null) {
                            agreement.Document_Generated_by_Merge__c = mapMergedDocIds.get(agreement.Id) + APT_Constants.SEPERATOR_SEMI_COLON;
                        } else {
                            agreement.Document_Generated_by_Merge__c = agreement.Document_Generated_by_Merge__c + mapMergedDocIds.get(agreement.Id) + APT_Constants.SEPERATOR_SEMI_COLON ;
                        }
                        system.debug('*** agreement.Document_Generated_by_Merge__c ***'+agreement.Document_Generated_by_Merge__c);
                        system.debug('*** is create contract batch jon runnung ***'+agreement.APT_Is_Create_Contract_Batch_Job_Running__c);
                        agreement.APT_Is_Create_Contract_Batch_Job_Running__c = false;
                        listUpdateAgreement.add(agreement);
                   }
                   
                   system.debug('*** listUpdateAgreement ***'+listUpdateAgreement);
                   if(listUpdateAgreement.size() > 0) {
                       //update listUpdateAgreement;
                   }
               }
               
               
           }
       } catch(system.exception ex) {
           system.debug('*** Merge Doc > ex.getMessage() ***'+ex.getMessage());
           setErrorMessages.add(ex.getMessage());
       }
    }
    
    /**
     finish
    **/
    global void finish(Database.BatchableContext BC) {
        //update contract, enable create contract button
        //if(setErrorMessages.size() > 0) {
            list<Apttus__APTS_Agreement__c> listUpdateAgreement = new list<Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Name, APT_Merge_Documents__c, APT_Remove_Standalone_Docs__c,
                                                        Document_Generated_by_Merge__c
                                                        FROM Apttus__APTS_Agreement__c
                                                        WHERE Id IN :setAgreementId]) {
                                                            
                agreement.APT_Is_Create_Contract_Batch_Job_Running__c = false;
                listUpdateAgreement.add(agreement);
            }
            
            update listUpdateAgreement;
        //}
        system.debug('*** finish > setErrorMessages ***'+setErrorMessages);
        system.debug('*** finish > setErrorMessages.size() ***'+setErrorMessages.size());
        //send email
        for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Name, APT_Merge_Documents__c, APT_Remove_Standalone_Docs__c,
                                                        Document_Generated_by_Merge__c
                                                        FROM Apttus__APTS_Agreement__c
                                                        WHERE Id IN :setAgreementId]) {
        
            APT_CreateContractUtility.sendEmailNotification(agreement.Id, instanceURL, BC.getJobId(), setErrorMessages);
        }
        
    }
}