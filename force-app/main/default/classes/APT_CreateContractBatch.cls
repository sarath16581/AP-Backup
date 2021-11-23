/**
 * This class will generate docs for agreement
 * Created By - Mausam Padhiyar
 * Created Date - 21st June, 2016
 **************************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 12 Mar, 2020
@Description: Updated Merge Documents logic to refer Files/ Content Documents instead of Attachments
 */
global class APT_CreateContractBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global String strAgreementId{get; set;}
    global String strTemplateLevel{get; set;}
    global String strTemplateOutputFormat{get; set;}
    global String sessionId{get;set;}
    global list<Id> listTemplateId {get; set;}
    global list<Id> listFileIds {get; set;}
    global Boolean bMergeDocuments {get; set;}
    global Boolean bDeleteGenDocs {get; set;}
    
    global map<Id, String> mapTemplateOutputFormat {get; set;}
    global map<Id, String> mapTemplatepLevel {get; set;}
    
    global set<String> setErrorMessage {get;set;}
    global String FileName {get;set;}
    global String serverURL {get; set;}
    global String instanceURL {get; set;}
    global Apttus__APTS_Agreement__c agreement {get;set;}
    
    global set<Id> setSubmitDocTemplateIds {get;set;}
    
    /**
     consturctor
    **/
    global APT_CreateContractBatch(String idAgreement, list<Id> templateIdList, map<Id, String> templatepLevelMap, map<Id, String> templateOutputFormatMap, Boolean mergeDocuments, Boolean deleteGenDocs) {
        //initialize
        FileName = APT_Constants.FILE_NAME_MERGE; 
        //session id
        sessionId = userInfo.getSessionId();
        //server url
        Apttus__ComplySystemProperties__c complySystemProperties = Apttus__ComplySystemProperties__c.getvalues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        instanceURL = complySystemProperties.Apttus__InstanceUrl__c;
        //serverURL = instanceURL + '/services/Soap/u/29.0/' + UserInfo.getOrganizationId(); //Merge server URL
        //serverURL = instanceURL + APT_Constants.services_Soap_u_29_0 + UserInfo.getOrganizationId(); //Merge server URL
        serverURL = instanceURL + '/services/Soap/u/38.0/' + UserInfo.getOrganizationId(); //Merge server URL
        
        listFileIds = new list<Id>();
        listTemplateId = new list<Id>();
        setSubmitDocTemplateIds = new set<Id>();
        
        mapTemplateOutputFormat = new map<Id, String>();
        mapTemplatepLevel = new map<Id, String>();
        
        
        setErrorMessage = new set<String>();
        
        agreement = new Apttus__APTS_Agreement__c();
        
        //set
        listTemplateId = templateIdList;
        strAgreementId = idAgreement;
        mapTemplatepLevel = templatepLevelMap;
        mapTemplateOutputFormat = templateOutputFormatMap;
        bMergeDocuments = mergeDocuments;
        bDeleteGenDocs = mergeDocuments;
    }
    
    /**
     start
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        agreement = [SELECT Id, Name, Document_Generated_by_Merge__c, 
                        APT_Is_Create_Contract_Batch_Job_Running__c, APT_Generated_Doc_Ids__c,
                        APT_Submitted_Async_Merge_Call_Ids__c, APT_Is_Generate_Doc_Batch_Running__c
                        FROM Apttus__APTS_Agreement__c 
                        WHERE Id = :strAgreementId];
        
        return Database.getQueryLocator([SELECT Id, Name, Apttus__Category__c
                                        FROM Apttus__APTS_Template__c
                                        WHERE Id IN :listTemplateId]);
    }
    
    /**
     execute
    **/
    global void execute(Database.BatchableContext BC, list<Apttus__APTS_Template__c> listTemplate){
       //generate doc api

        try {
            if(listTemplate != null && listTemplate.size() > 0) {
                String fileId;
                
                for(Apttus__APTS_Template__c templateSO : listTemplate) {
                    if(!String.isEmpty(templateSO.Apttus__Category__c)) {
                        if(templateSO.Apttus__Category__c.equalsIgnoreCase(APT_Constants.CATEGORY_DEFAULT)) {
                            if(!test.isRunningTest()) {
                                fileId = Apttus.MergeWebService.generateDoc2(templateSO.Id, strAgreementId, mapTemplatepLevel.get(templateSO.Id), mapTemplateOutputFormat.get(templateSO.Id), false, sessionId, serverURL);
                                listFileIds.add(fileId);
                            }
                        }
                    }
                }
            }
        } catch(System.Exception ex) {
            system.debug('*** Gen Doc2 ex.getMessage() 1 ***'+ex.getMessage());
            setErrorMessage.add(ex.getMessage());
        }
        
    }
    
    /**
     finish
    **/
    global void finish(Database.BatchableContext BC) {
        system.debug('******* finish ***********');
        if(setErrorMessage.size() > 0) {
            //send email
            APT_CreateContractUtility.sendEmailNotification(strAgreementId, instanceURL, BC.getJobId(), setErrorMessage);
            
            //update contract, enable create contract button
            agreement.APT_Is_Create_Contract_Batch_Job_Running__c = false;
            agreement.APT_Is_Generate_Doc_Batch_Running__c = false;
            update agreement;
        } else {
            //reset
            agreement.APT_Generated_Doc_Ids__c = null;
            //populate generate doc ids
            if(listFileIds.size() > 0) {
                for(Id fileId : listFileIds) {
                    if(!String.isEmpty(agreement.APT_Generated_Doc_Ids__c)) {
                        agreement.APT_Generated_Doc_Ids__c += APT_Constants.SEPERATOR_COMMA + fileId;
                    } else {
                        agreement.APT_Generated_Doc_Ids__c = fileId;
                    }
                }
            }
            
            agreement.APT_Is_Generate_Doc_Batch_Running__c = false;
            update agreement;
            
            system.debug('*** agreement.APT_Submitted_Async_Merge_Call_Ids__c ***'+agreement.APT_Submitted_Async_Merge_Call_Ids__c);
            
            if(!String.isEmpty(agreement.APT_Submitted_Async_Merge_Call_Ids__c)) {
                list<String> listAsyncMergeCallIds = agreement.APT_Submitted_Async_Merge_Call_Ids__c.split(APT_Constants.SEPERATOR_COMMA);
                if(listAsyncMergeCallIds != null && listAsyncMergeCallIds.size() > 0) {
                    list<Apttus__AsyncMergeCall__c> listAsyncMergCall = [SELECT Id, Apttus__Agreement__c, Apttus__Result__c, Apttus__Status__c
                                                                        FROM Apttus__AsyncMergeCall__c 
                                                                        WHERE Id IN :listAsyncMergeCallIds
                                                                        AND Apttus__Agreement__c = :strAgreementId
                                                                        AND Apttus__Result__c != null
                                                                        AND Apttus__Status__c = :APT_Constants.STATUS_CATEGORY];
                    
                    system.debug('*** listAsyncMergCall ***'+listAsyncMergCall);
                    
                    if(listAsyncMergCall != null && listAsyncMergCall.size() > 0) {
                        for(Apttus__AsyncMergeCall__c asyncMergeCall : listAsyncMergCall) {
                            system.debug('*** asyncMergeCall.Apttus__Result__c ***'+asyncMergeCall.Apttus__Result__c);
                            listFileIds.add(asyncMergeCall.Apttus__Result__c);
                        }
                        
                        //call merge doc ids
                        set<Id> setAgreementIds = new set<Id>();
                        setAgreementIds.add(strAgreementId);
                        
                        list<String> listStrFileIds = new list<String>();
                        for(Id fileId : listFileIds) {
                            listStrFileIds.add(fileId);
                        }
                        
                        map<Id, list<String>> mapFileIds = new map<Id, list<String>>();
                        mapFileIds.put(strAgreementId, listStrFileIds);
                        system.debug('*** mapFileIds ***'+mapFileIds);
                        if(mapFileIds.size() > 0) {
                            APT_MergeDocBatch controller = new APT_MergeDocBatch(sessionId, mapFileIds.keySet(), mapFileIds);
                            database.executeBatch(controller, 1);
                        }
                    }
                }
            } else {
                list<String> listStrFileIds = new list<String>();
                for(Id fileId : listFileIds) {
                    listStrFileIds.add(fileId);
                }
                        
                map<Id, list<String>> mapFileIds = new map<Id, list<String>>();
                mapFileIds.put(strAgreementId, listStrFileIds);
                system.debug('*** mapFileIds ***'+mapFileIds);
                if(mapFileIds.size() > 0) {
                    APT_MergeDocBatch controller = new APT_MergeDocBatch(sessionId, mapFileIds.keySet(), mapFileIds);
                    database.executeBatch(controller, 1);
                }
            }
        }
    }
}