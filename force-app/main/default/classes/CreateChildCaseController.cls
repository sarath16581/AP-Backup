/********************************************************************************
Description:  Class to cover createChildCase functionality for Service Delivery.
History:
---------------------------------------------------------------------------------
13-11-2018  dilshan.egodawela@auspost.com.au  Created
*********************************************************************************/
public with sharing class CreateChildCaseController {

    //maaping file extensions and mime types used while converting attachment to files and vice versa
    public static final map<string,string> mimeTypeMapping = new map<string,string>{
        'png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'htm' => 'text/html', 'html' => 'text/html', 
        'pdf' => 'application/pdf', 'doc' => 'application/msword', 'docx' => 'application/msword', 
        'xls' => 'application/vnd.ms-excel', 'xlsx' => 'application/vnd.ms-excel', 'ppt' => 'application/vnd.ms-powerpoint', 
        'pptx' => 'application/vnd.ms-powerpoint', 'txt' => 'text/plain'
    };
    /*********************************************************************************
    * Created History: 13-11-2018  dilshan.egodawela@auspost.com.au
    * Description:
    *      Method to retrieve the target record types based on source record type.
    **********************************************************************************/
    @AuraEnabled
    public static List<PickListValue> getChildRecordTypes(Id sourceRecordTypeId) {
        try {
            List<Id> targetRecTypeId = new List<Id>();
            //Retrieve the target record types for the source record type name and collect target 
            //record types dev name into a list
            for(Service_Delivery_Setting__mdt metadata :[SELECT Target_RecordType_Id__c
                                                                     FROM Service_Delivery_Setting__mdt
                                                                     WHERE Source_RecordType_Id__c = :sourceRecordTypeId AND IsActive__c = true]){
                targetRecTypeId.add(metadata.Target_RecordType_Id__c);
            }
            List<PickListValue> pickList = new List<PickListValue>();
            for(RecordType rtype :[SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Case' AND 
                                  Id IN :targetRecTypeId]){
                pickList.add(new PickListValue(rtype.Name, rtype.Id));
            }
            return pickList;
        } catch (Exception e){
            AuraHandledException ex = new AuraHandledException('RecordType list retreival fail: '+e.getMessage()+' at '+e.getStacktraceString());
            ex.setMessage(e.getMessage()+' at '+e.getStacktraceString());
            throw ex;
        }
        
    }

    /***********************************************************************************
    * Created History: 28-11-2018  rahul.kapoor@auspost.com.au
    * Description:
    *      Method to retrieve the fields from the field set based on record type.
    ************************************************************************************/
    @AuraEnabled
    public static List<FieldSetMember> getFieldSet(String sourceRecordTypeId, String targetRecordTypeId, string parentId) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Case');
        Schema.DescribeSObjectResult describe = targetType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetDescribe = describe.fieldSets.getMap();
        //Retrieve the source record type name for the selected record type id.
        String targetRecordTypeDevName = Schema.SobjectType.Case.getRecordTypeInfosById().get(targetRecordTypeId).getDeveloperName();
        //Retrieve the field set name for the selected record type.
        Schema.FieldSet fieldSet = fieldSetDescribe.get([SELECT FieldSet__c
                                                         FROM Service_Delivery_Setting__mdt
                                                         WHERE Source_RecordType_Id__c =: sourceRecordTypeId
                                                         AND Target_RecordType_Id__c =:targetRecordTypeId LIMIT 1].FieldSet__c
        );

        //Prepare the field set to render the UI fields.
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        List<FieldSetMember> preparedFieldSet = new List<FieldSetMember>();

        //Form SOQL from the fields available from fieldset and query parentCase to fill in the default values
        String SelectQueryforParentCase = 'SELECT ';
        for(Schema.FieldSetMember fieldSetSchema: fieldSetMembers){
            SelectQueryforParentCase += fieldSetSchema.fieldPath+', ';
        }
        SelectQueryforParentCase = SelectQueryforParentCase.removeEnd(', ')+' FROM Case WHERE Id = \''+parentId+'\'';
        Case ParentCase = Database.Query(SelectQueryforParentCase);

        for (Schema.FieldSetMember fieldSetSchema: fieldSetMembers) {
            FieldSetMember fieldSetMapper = new FieldSetMember(fieldSetSchema);
            // default values are determined and populated at apex level as this could be configured in a custom setting in the future, if you like
            // default value for Case Origin field on case object
            fieldSetMapper.defaultValue = ParentCase.get(fieldSetSchema.fieldPath);
            //REQ3448199 - Removing refrence of record type report request
            //if(targetRecordTypeDevName.equalsIgnoreCase('Report_Request') && 'Origin'.equalsIgnoreCase(fieldSetSchema.fieldPath)){
             // fieldSetMapper.defaultValue = 'Salesforce User';
            // }
            if(targetRecordTypeDevName.equalsIgnoreCase('StarTrack_Credit_Dispute_Claim') && 'Origin'.equalsIgnoreCase(fieldSetSchema.fieldPath)){
                fieldSetMapper.defaultValue = 'Other';
            }
            if('Requestor__c'.equalsIgnoreCase(fieldSetSchema.fieldPath)){
                Id userId = UserInfo.getUserId();
                fieldSetMapper.defaultValue = userId;
            }
            preparedFieldSet.add(fieldSetMapper);
        }

        return preparedFieldSet;
    }

    /***********************************************************************************
    * Created History: 28-11-2018  rahul.kapoor@auspost.com.au
    * Description:
    *      Method to retrieve the fields from the field set based on record type.
    ************************************************************************************/
    @AuraEnabled
    public static List<FieldSetMember> getFieldSetForSave(String sourceRecordTypeId, String targetRecordTypeId) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Case');
        Schema.DescribeSObjectResult describe = targetType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetDescribe = describe.fieldSets.getMap();

        //Retrieve the field set name for the selected record type.
        Schema.FieldSet fieldSet = fieldSetDescribe.get([SELECT FieldSet__c
                                                         FROM Service_Delivery_Setting__mdt
                                                         WHERE Source_RecordType_Id__c =: sourceRecordTypeId
                                                         AND Target_RecordType_Id__c =:targetRecordTypeId LIMIT 1].FieldSet__c
        );

        //Prepare the field set to render the UI fields.
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        List<FieldSetMember> preparedFieldSet = new List<FieldSetMember>();

        for (Schema.FieldSetMember fieldSetSchema: fieldSetMembers) {
            FieldSetMember fieldSetMapper = new FieldSetMember(fieldSetSchema);

            preparedFieldSet.add(fieldSetMapper);
        }

        return preparedFieldSet;
    }

    /*********************************************************************************
   * Created History: 28-11-2018  Rahul Kapoor
   * Description:
   *      Method to insert and create a child case for Service Delivery.
   **********************************************************************************/
    @AuraEnabled
    public static String createChildCase(String recordData, String sourceRecordTypeId, String targetRecordTypeId, Id parentId, List<string> selectedDocsAndAttachmentIds) {
        String caseNum = '';
        try {
            //Deserialize the JSON String.
            Map<String, String> mapData = (Map<String,String>) JSON.deserialize(recordData, Map<String,String>.class);

            //Call getFieldSetForSave to retrieve the fields from the field set based on record type.
            List<FieldSetMember> fieldSetList = getFieldSetForSave(sourceRecordTypeId, targetRecordTypeId);
            //Set the fields to insert a case.
            Case insCase = new Case();
            insCase.ParentId = parentId;
            //Retrieve and set the Record Type Id.
            insCase.RecordTypeId = targetRecordTypeId;
            //Loop through the fieldSetList.
            for(FieldSetMember fld : fieldSetList){
                if(mapData.containsKey(fld.fieldPath)){
                    insCase.put(fld.fieldPath, mapData.get(fld.fieldPath));
                }
            }
            //Find owner id in metadata
            string OwnerId  = [SELECT Owner_ID__c
                               FROM Service_Delivery_Setting__mdt
                               WHERE Source_RecordType_Id__c =: sourceRecordTypeId
                               AND Target_RecordType_Id__c =: targetRecordTypeId LIMIT 1].Owner_ID__c;           
            if(OwnerId != null && OwnerId != ''){
                //If owner id found assign it to child case
                insCase.OwnerId = OwnerId;
            }
            else{
                //If owner Id is not defined proceed to run assignment rules
                //set dml options to run assignment rules and assign owner id for the child case created
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule= true;
                insCase.setOptions(dmo);
            }
            //Create a case.
            insert insCase;
           
            Case parentCase = [SELECT Id, RecordTypeId, CaseNumber FROM Case WHERE Id = :ParentId];
            Case childCase = [SELECT Id, RecordTypeId, CaseNumber FROM Case WHERE Id = :insCase.Id];
            //share docs and attachments according to metadata
            shareAttachmentAndFilesToChildCases(parentCase, childCase, selectedDocsAndAttachmentIds);           
            //Return the case number of the inserted case.
            return childCase.CaseNumber;
        } catch (Exception ex){
            system.debug(' exception '+ex.getMessage()+' at '+ex.getStacktraceString());
            AuraHandledException e = new AuraHandledException('Error in save Method '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage());
            throw e;
        }       
    }

    /***********************************************************************************
    * Created History: 27-12-2018  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to retrieve the Attachments for the provided Case
    ************************************************************************************/
    @AuraEnabled
    Public static List<Attachment> getAttachmentList(Id parentCaseId){
        try{
            List<Attachment> attachmentList = new List<Attachment>();
            attachmentList.addAll([SELECT Id, Name, Body FROM Attachment WHERE ParentId = :parentCaseId]);
            attachmentList.addAll([SELECT Id, Name, Body FROM Attachment WHERE ParentId IN 
                :[SELECT Id FROM EmailMessage WHERE ParentId = :parentCaseId]]);
            return attachmentList;
        }
        catch(Exception ex){
            system.debug('exception getting attachments '+ex.getMessage()+' at '+ex.getStacktraceString());
            AuraHandledException e = new AuraHandledException('Error in getting attachments '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }

    /***********************************************************************************
    * Created History: 27-12-2018  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to retrieve the Attachments for the provided Case
    ************************************************************************************/
    @AuraEnabled
    Public static List<ContentDocument> getDocumentList(Id parentCaseId){
        try{
            List<Id> contentDocIdList = new List<Id>();
            List<ContentDocumentLink> contentDocLinkList =  [SELECT Id, ContentDocumentId FROM ContentDocumentLink 
                WHERE LinkedEntityId  = :parentCaseId];
            for(ContentDocumentLink contentDocLink :contentDocLinkList){
                    contentDocIdList.add(contentDocLink.ContentDocumentId);
            }
            return [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocIdList];
        }
        catch(Exception ex){
            system.debug('exception getting attachments '+ex.getMessage()+' at '+ex.getStacktraceString());
            AuraHandledException e = new AuraHandledException('Error in getting attachments '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage());
            throw e;
        }
    }

    /*********************************************************************************
   * Created History: 11-12-2018  Rahul Kapoor
   * Description:
   *      Wrapper class for Field Set Member.
   **********************************************************************************/
    public class FieldSetMember {

        public FieldSetMember(Schema.FieldSetMember f) {
            this.fieldPath = f.fieldPath;
            this.label = f.label;
            this.required = f.required;
            this.type = '' + f.getType();
        }
        @AuraEnabled public String fieldPath { get;set; }
        @AuraEnabled public String label { get;set; }
        @AuraEnabled public Boolean required { get;set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Object defaultValue { get; set; }
    }

    /*********************************************************************************
   * Created History: 11-12-2018  Rahul Kapoor
   * Description:
   *      Wrapper class for Picklist values.
   **********************************************************************************/
    public class PickListValue {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public PickListValue(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    /*********************************************************************************
    * Created History: 21-12-2018  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to retrieve Case by Id on load of lightning component
    **********************************************************************************/
    @AuraEnabled
    public static Case getCaseRecord(Id caseId) {
        try{
            return [SELECT Id, RecordTypeId, Case_RecordType_Name__c FROM Case WHERE Id = :caseId];
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }

    /*********************************************************************************
    * Created History: 08-01-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to copy selected attachments for child case created
    **********************************************************************************/
    public static void creatAttachmentsforChildCase(List<Id> attachmentIds, Id parentCaseId) {
        try{
            if(attachmentIds != null && attachmentIds.size() > 0){
                List<Attachment> attachmentToInsert = new List<Attachment>();
                for(Attachment atchmnt :[SELECT Id, Body, Name, Description, ParentId
                                FROM Attachment WHERE Id IN :attachmentIds]){
                    //Attachment tempAtchmnt = atchmnt.clone();
                    Attachment tempAtchmnt = new Attachment();
                    tempAtchmnt.ParentId = parentCaseId;
                    tempAtchmnt.Body = atchmnt.Body;
                    tempAtchmnt.Name = atchmnt.Name;
                    tempAtchmnt.Description = atchmnt.Description;
                    attachmentToInsert.add(tempAtchmnt);
                }
                insert attachmentToInsert;
            }
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    } 

    /*********************************************************************************
    * Created History: 08-01-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to copy selected attachments for child case created
    **********************************************************************************/
    public static void shareDocsforChildCase(List<Id> documentIds, Id parentCaseId) {
        try{
            if(documentIds != null && documentIds.size() > 0){
                List<ContentDocumentLink> shareDocsList = new List<ContentDocumentLink>();
                for(Id docId :documentIds){
                    shareDocsList.add(new ContentDocumentLink(LinkedEntityId = parentCaseId, 
                        ContentDocumentId = docId, ShareType = 'V'));
                }
                insert shareDocsList;
            }
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }

    /*********************************************************************************
    * Created History: 04-02-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to share files and attachments to the child case created after converting
        if required
    **********************************************************************************/
    public static void shareAttachmentAndFilesToChildCases(Case ParentCase, Case ChildCase, List<Id> selectedAttachmentsAndFiles){
        try{
            List<Id> attachmentIds = new List<Id>();
            List<Id> documentIds = new List<Id>();
            //query metadata and check if conversion of files to attachment or attachment to files is allowed
            List<Service_Delivery_Setting__mdt> metadataInfo = [SELECT Id, Convert_attachment_to_files__c, Convert_files_to_attachment__c 
                FROM Service_Delivery_Setting__mdt WHERE Source_RecordType_Id__c = :ParentCase.RecordTypeId AND Target_RecordType_Id__c
                = :ChildCase.RecordTypeId LIMIT 1];
            if(metadataInfo != null && metadataInfo.size() > 0){
                //Iterate through selected files and attachments and seperate the ids into two different lists
                for(Id selId :selectedAttachmentsAndFiles){
                    if(string.valueOf(selId.getsobjecttype()) == 'Attachment'){
                        attachmentIds.add(selId);
                    }
                    else if(string.valueOf(selId.getsobjecttype()) == 'ContentDocument'){
                        documentIds.add(selId);
                    }
                }
                //if conversion is allowed from attachment to files
                if(metadataInfo[0].Convert_attachment_to_files__c){
                    //share files as files
                    shareDocsforChildCase(documentIds, ChildCase.Id);
                    //convert attachment to files and share
                    convertAttachmentToFileAndShare(attachmentIds, ChildCase);
                }
                //if conversion is allowed from files to attachment
                else if(metadataInfo[0].Convert_files_to_attachment__c){                   
                    //share attachments as attachments
                    creatAttachmentsforChildCase(attachmentIds, ChildCase.Id);
                    //convert files to attachment and share
                    convertFileToAttachmentAndShare(documentIds, ChildCase);
                }
                else{
                    //share files and attachments as it is if no checkbox is checked
                    shareDocsforChildCase(documentIds, ChildCase.Id);
                    creatAttachmentsforChildCase(attachmentIds, ChildCase.Id);
                }
            }
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured in file/attachment sharing: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }

    /*********************************************************************************
    * Created History: 04-02-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to convert attachment to files and share with case
    **********************************************************************************/  
    public static void convertAttachmentToFileAndShare(List<Id> attachmentIds, Case parentCase){
        try{
            List<ContentVersion> cvToInsert = new List<ContentVersion>();
            List<contentdocumentlink> cdToInsert = new List<contentdocumentlink>();
            for(Attachment attach :[SELECT Id, Body, ContentType, Name FROM Attachment WHERE Id IN :attachmentIds]){
                ContentVersion cv = new ContentVersion();
                cv.VersionData = attach.Body;
                cv.pathonClient = 'NULL';
                cv.Title = attach.Name.substringBefore('.');
                for(string filext :mimeTypeMapping.keySet()){
                    if(mimeTypeMapping.get(filext) == attach.ContentType){
                        cv.pathonClient = attach.Name.substringBefore('.')+'.'+filext;
                    }
                }
                cvToInsert.add(cv);              
            }
            if(cvToInsert != null && cvToInsert.size() >0){
                insert cvToInsert;
            } 
            //share inserted documents with case
            for(ContentVersion cv :[SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvToInsert AND IsLatest = true]){
                cdToInsert.add(new contentdocumentlink(LinkedEntityId = parentCase.id, ContentDocumentId = cv.ContentDocumentId, ShareType = 'V'));
            }
            if(cdToInsert != null && cdToInsert.size() >0){
                insert cdToInsert;
            }           
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured in file sharing: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }

    /*********************************************************************************
    * Created History: 04-02-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to convert attachment to files and share with case
    **********************************************************************************/  
    public static void convertFileToAttachmentAndShare(List<Id> documentIds, Case parentCase){
        try{
            List<Attachment> attacmentToInsert = new List<Attachment>();
            for(ContentVersion cv :[SELECT Id, Pathonclient, VersionData, FileExtension, Title FROM ContentVersion WHERE ContentDocumentId IN :documentIds]){
                Attachment att = new Attachment();
                att.Body = cv.VersionData;
                att.Name = cv.Title;
                att.ParentId = parentCase.Id;
                if(mimeTypeMapping.containsKey(cv.FileExtension)){
                    att.ContentType = mimeTypeMapping.get(cv.FileExtension);
                }
                attacmentToInsert.add(att);
            }
            if(attacmentToInsert != null && attacmentToInsert.size() >0){
                insert attacmentToInsert;
            }
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured in attachment sharing: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }

    /*********************************************************************************
    * Created History: 05-02-2019  ramtej.juloori@auspost.com.au
    * Description:
    *      Method to find if  attachment and  files sharing is enabled for the recordtype combination
    **********************************************************************************/  
    @AuraEnabled
    public static boolean checkFileAndAttachmentSharing(Id sourceRecordTypeId, Id targetRecordTypeId){
        try{
            return [SELECT Id, Enable_file_and_attachment_sharing__c FROM Service_Delivery_Setting__mdt WHERE 
                Source_RecordType_Id__c = :sourceRecordTypeId AND Target_RecordType_Id__c = :targetRecordTypeId LIMIT 1].Enable_file_and_attachment_sharing__c;
        }
        catch(exception ex){
            AuraHandledException e = new AuraHandledException('Error Occured in attachment sharing: '+ex.getMessage()+' at '+ex.getStacktraceString());
            e.setMessage(ex.getMessage()+' at '+ex.getStacktraceString());
            throw e;
        }
    }
   
}