/*------------------------------------------------------------
Author:         Stephen James Laylo
Description:    Handler for AttachmentTrigger
Test Class:     AttachmentTriggerHandler_Test

History
<Date>         <Authors Name>           <Brief Description of Change>
04/02/2016     Stephen James Laylo      Created Handler for AttachmentTrigger
05/02/2016     Stephen James Laylo      Added the method getAllowedAgreementDocumentStatusForAttachment()
11/02/2016     Stephen James Laylo      Added try and catch in stampAgreementDocumentGeneratedDate() method
24/02/2016     Stephen James Laylo      Edited the criteria of preventNewAttachments()
24/02/2016     Stephen James Laylo      Added new method renameGeneratedAttachmentsOfAgreementDocument()
10/03/2016     Lyndon Lavapie           Added logic to stampAgreementDocumentGeneratedDate() to capture Floor Plan Attachment ID and Update Floor Plan URL Field
14/03/2016     Lyndon Lavapie           Added new method createActivityHistoryForDeletedAgreeentDocumentAttachment()
15/03/2016     Lyndon Lavapie           Added criteria to the Document Generated Date field
13/05/2016     Andrew Judd              Removed Scanned Paper specific criteria from preventNewAttachments
23/03/2017     Disha Kariya             Edited to meet Salesforce standards in preventNewAttachments method
20/09/2018     Chester Borbon           Added a method that would force link the files from Apttus Contract to the cloned Salesforce Contract.
21/10/2018     Melissa Carino           Added code comments to the AttachmentTriggerHandler  
29/03/2019     Ramtej Juloori           Commented linkExisting files from contentdocumentlinktriggerhandler and moved to scheduler class, which is invoked on 
                                        activating a contract and uploading a file to apttus contract
2022-11-04     Naveen Rajanna           REQ3018517 Add null check to prevent nullpointerexception for startrackDuplicateInboundEmail
                                        ------------------------------------------------------------*/
public class AttachmentTriggerHandler {
    //Constants
    private static final String ATTACHMENT_PREVENTION_ERROR_MSG_1 = 'You are not allowed to attach a file if the Agreement Document Status is not [ALLOWED_STATUS_LIST].';
    private static final String AGREEMENT_DOCUMENT_API_NAME = 'Agreement_Document__c';
    private static final String FLOOR_PLAN_FILE_NAME = 'Floor PLan';
    private static final String FLOOR_PLAN_URL = '/servlet/servlet.FileDownload?file=';
    private static final Set<String> IMAGE_CONTENT_TYPE = new Set<String>{'image/jpeg','image/png','image/gif','image/jpg'};

    /*------------------------------------------------------------
    Author:         Stephen James Laylo
    Description:    Updates the Document Generated Date field when a Document is generated or attached to Agreement Document

    Input:          List<Attachment>
    Return:         Void
    ------------------------------------------------------------*/
    public static void stampAgreementDocumentGeneratedDate(List<Attachment> newAtts) {
        //Set<Id> agreementDocIds = new Set<Id>();

        Map<Id,String> parentattsMap = new Map<Id,String>();
        Map<Id,String> parentDocMap= new Map<Id,String>();

        //Iterate through all attachments
        for (Attachment newAtt : newAtts) {
            //Check if attachment has a parent Id associated and parent record is of type Agreement Document object.
            if (newAtt.ParentId != null && CommonUtils.getObjectAPINameByRecordId(newAtt.ParentId) == AGREEMENT_DOCUMENT_API_NAME) {

                //agreementDocIds.add(newAtt.ParentId);
                //Add attachment names for corresponding agreement Document Parent.
                parentDocMap.put(newAtt.ParentId,newAtt.Name);

                //Fetch content type of attachment
                String contenttype = newAtt.contenttype;


                //agreementDocIds.add(newAtt.ParentId);
                //Check if Attachment name is 'Floor Plan' and is of type ''image/jpeg','image/png','image/gif','image/jpg''
                if(newAtt.Name.containsIgnoreCase(FLOOR_PLAN_FILE_NAME) && IMAGE_CONTENT_TYPE.contains(contenttype)){
                    parentattsMap.put(newAtt.ParentId,newAtt.Id);
                }

            }
        }

        //Get Parent Agreement Document details for all attachments: Generated Date and Name
        List<Agreement_Document__c> agreementDocs = new List<Agreement_Document__c>([SELECT Id, Document_Generated_Date__c,Document_Name__c FROM Agreement_Document__c WHERE Id IN :parentDocMap.keySet()]);

        //Iterate through fetched Agreement document
        for (Agreement_Document__c agreementDoc : agreementDocs) {
            //Check if the attached document is a PDF and match to agreement document 'document name' field
            //parentDocMap.get(agreementDoc.Id).endsWith('.pdf') &&

            //Check If attachment name matches agreement document name, and if yes, set current date time
            //on document generated date for the given agreement document record.
            //REQ3018517
            if(parentDocMap.get(agreementDoc.Id) != null && parentDocMap.get(agreementDoc.Id).containsIgnoreCase(agreementDoc.Document_Name__c)){
                agreementDoc.Document_Generated_Date__c = DateTime.Now();
            }
            //Prepare the Floor Plan URLs based on base content URL and attachment Id Id for floor plan attachments.
            if(parentattsMap.keySet().contains(agreementDoc.Id)){
                agreementDoc.Floor_Plan_URL__c = FLOOR_PLAN_URL + parentattsMap.get(agreementDoc.Id);
            }
        }

        try {
            //Update all Agreement Document Records in Scope
            update agreementDocs;
        }
        //In case Update fails for any reason it will be handled in catch block below and user can see the details in debug log.
        catch (Exception err) {
            System.debug('An error occured: ' + err);
        }
    }

    /*------------------------------------------------------------
    Author:         Stephen James Laylo
    Description:    Updates the name of Attachment with the convention of "<Agreement Document Type> - Org ID - yyyymmddhhmm"

    Input:          List<Attachment>
    Return:         Void
    ------------------------------------------------------------*/
    /*
      public static void renameGeneratedAttachmentsOfAgreementDocument(List<Attachment> newAtts) {
      Map<Id, Agreement_Document__c> agreementDocsMap = new Map<Id, Agreement_Document__c>();

      for (Agreement_Document__c agreementDoc : [SELECT Id, Document_Generated_Date__c, Licence__r.Facility__r.WCIS_Code__c, Document_Name__c FROM Agreement_Document__c]) {
      agreementDocsMap.put(agreementDoc.Id, agreementDoc);
      }

      for (Attachment newAtt : newAtts) {
      if (newAtt.ParentId != null && CommonUtils.getObjectAPINameByRecordId(newAtt.ParentId) == AGREEMENT_DOCUMENT_API_NAME && agreementDocsMap.containsKey(newAtt.ParentId)) {
      String[] splittedFileExt = newAtt.Name.split('\\.');

      if (splittedFileExt.size() > 1) {
      String docName = newAtt.Name.replace('.' + splittedFileExt[splittedFileExt.size() - 1], '');
      if ((agreementDocsMap.get(newAtt.ParentId).Document_Name__c + ' - ' + String.valueOf(newAtt.ParentId).substring(0, 15)) == docName) {
      newAtt.Name = agreementDocsMap.get(newAtt.ParentId).Document_Name__c + ' - ' + agreementDocsMap.get(newAtt.ParentId).Licence__r.Facility__r.WCIS_Code__c + ' - ' + System.now().format('yyyyMMddhhmm') + '.' + splittedFileExt[splittedFileExt.size() - 1];
      }
      }
      }
      }
      }
    */
    /*------------------------------------------------------------
    Author:         Stephen James Laylo
    Description:    Adds an error when the user attach a file to a Agreement Document Record with prohibited Status

    Input:          List<Attachment>
    Return:         Void
    ------------------------------------------------------------*/
    public static void preventNewAttachments(List<Attachment> newAtts) {

        //Given Map holds Id and corresponding Agreement Document Record.
        Map<Id, Agreement_Document__c> mapAgreementDocs = new Map<Id, Agreement_Document__c>();
        //Get list of parent record Ids that Attachments are being attached to
        Set<Id> parentIds = new Set<Id>();
        //Fetch all Parent Ids for given Attachments. This is done to avoid hitting governer limits in SOQL Query.
        for (Attachment at : newAtts)
            parentIds.add(at.ParentId);
        //Map agreement document records, constrained by parent Ids
        for (Agreement_Document__c agreementDoc : [SELECT Id, Status__c, Licence__r.Licence_Status__c, Approval_Type__c FROM Agreement_Document__c WHERE Id IN :parentIds]) {
            mapAgreementDocs.put(agreementDoc.Id, agreementDoc);
        }
        //If any attachments are being attached to Partner Agreement Document records, then perform check to see if permitted
        if (!mapAgreementDocs.isEmpty()){
            System.debug('<<<Partner Agreement Document only>>>');
            //Iterate through all attachments in scope
            for (Attachment newAtt : newAtts) {
                //if (CommonUtils.getObjectAPINameByRecordId(newAtt.ParentId) == AGREEMENT_DOCUMENT_API_NAME && mapAgreementDocs.containsKey(newAtt.ParentId)) {    Commented by Disha for code optimisation suggested by Andrew on 23/03/2017

                //Check if the Status on the current attachment's Parent is in the Allowed Statuses list.
                // If Not, show the error message to the users.
                if (mapAgreementDocs.containsKey(newAtt.ParentId)) {
                    if (!isAttachmentAllowed(mapAgreementDocs.get(newAtt.ParentId).Status__c)) {
                        newAtt.addError(ATTACHMENT_PREVENTION_ERROR_MSG_1.replace('[ALLOWED_STATUS_LIST]', getAllowedAgreementDocumentStatusForAttachment()));
                    }
                }
            }
        }
    }

    /*------------------------------------------------------------
    Author:         Stephen James Laylo
    Description:    Checks if the status of a Agreement Document Record is in the list of allowed Statuses

    Input:          String - Agreement Document Record Status
    Return:         Boolean
    ------------------------------------------------------------*/
    public static Boolean isAttachmentAllowed(String agreementDocStatus) {
        //Get all allowed Document Statuses from Custom Settings
        Map<String, Allowed_Agreement_Document_Status__c> mapAllowedAgreementDocStatuses = Allowed_Agreement_Document_Status__c.getAll();

        //Iterate through all allowed statuses
        for (Allowed_Agreement_Document_Status__c allowedAgreementDocStatus : mapAllowedAgreementDocStatuses.values()) {
            //Check if current status is in allowed statuses list.
            if (agreementDocStatus.toUpperCase() == allowedAgreementDocStatus.Name.toUpperCase()) {
                return true;
            }
        }

        return false;
    }

    /*------------------------------------------------------------
    Author:         Stephen James Laylo
    Description:    Retrieves the allowed Agreement Document Status for Attachment

    Input:          N/A
    Return:         String
    ------------------------------------------------------------*/
    public static String getAllowedAgreementDocumentStatusForAttachment() {
        //allowedAgreementDocumentStatusForAttachment will hold all the allowed statuses separated by comma.
        String allowedAgreementDocumentStatusForAttachment = '';

        //Get all allowed statuses from Custom Settings
        Map<String, Allowed_Agreement_Document_Status__c> mapAllowedAgreementDocStatuses = Allowed_Agreement_Document_Status__c.getAll();

        //Iterate through Statuses and prepare string with comma seperated statuses.
        for (String allowedAgreementDocStatus : mapAllowedAgreementDocStatuses.keySet()) {
            allowedAgreementDocumentStatusForAttachment += allowedAgreementDocStatus + ', ';
        }
        //Trim the end characters ", " for cleaner statuses list.
        if (allowedAgreementDocumentStatusForAttachment.length() > 0) {
            allowedAgreementDocumentStatusForAttachment = allowedAgreementDocumentStatusForAttachment.substring(0, allowedAgreementDocumentStatusForAttachment.length() - 2);
        }

        return allowedAgreementDocumentStatusForAttachment;
    }

    /*------------------------------------------------------------
     Author:         Lyndon Lavapie
     Description:    Create a Activity History Record if a Generated Agreement Document attachent was deleted
                     Clear Floor Plan URL Field if the floor plan attachment was deleted

     Input:          List<Attachment>
     Return:         Void
    ------------------------------------------------------------*/
    public static void createActivityHistoryForDeletedAgreeentDocumentAttachment(List<Attachment> oldAtts) {
        //Holds current User Name
        String currentUser = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        //Holds Ids of all Parent Agreement Document records.
        Set<Id> agreementIds = new Set<Id>();
        //Holds Id and corresponding Agreement Document Records.
        Map<Id, Agreement_Document__c> agrDocMap = new Map<Id,Agreement_Document__c>();
        //Holds all attachments that has Agreement Document as parent.
        List<Attachment> attList = new List<Attachment>();
        //Holds Lists of Documents records to update.
        List<Agreement_Document__c> agreementDocsList = new List<Agreement_Document__c>();
        //Iterate through all attachments
        for (Attachment oldAtt : oldAtts) {
            //Find out attachments that are associated to Agreement Document
            if (oldAtt.ParentId != null && CommonUtils.getObjectAPINameByRecordId(oldAtt.ParentId) == AGREEMENT_DOCUMENT_API_NAME) {
                agreementIds.add(oldAtt.ParentId);
                attList.add(oldAtt);

            }
        }
        //Holds IDs of Agreement Documents to Update.
        Set<Id> agrDocToUpdate = new Set<Id>();
        //Holds Activity Histories to Insert for given Attachments
        List<Task> actHistoryList = new List<Task>();
        //Fetch All Agreement Documents in scope
        List<Agreement_Document__c> agreementDocs = new List<Agreement_Document__c>([SELECT Id, Document_Name__c, Floor_Plan_URL__c FROM Agreement_Document__c WHERE Id IN : agreementIds]);
        //Iterate through all Agreement document and create a Map.
        for (Agreement_Document__c agreementDoc : agreementDocs) {
            agrDocMap.put(agreementDoc.Id,agreementDoc);
        }
        //Iterate through all attachments
        for(Attachment att: attList){
            //Create the activity History (Task) for attachment that is getting deleted
            if(att.Name.containsIgnoreCase(agrDocMap.get(att.ParentId).Document_Name__c)){
                Task actHistory = new Task(
                        Subject = currentUser + ' has deleted ' + att.Name,
                        ActivityDate = system.today(),
                        Description  = currentUser + ' has deleted ' + att.Name,
                        WhatId = att.ParentId,
                        Status = 'Completed',
                        Type = 'Other'
                );
                actHistoryList.add(actHistory);

            }
            system.debug(actHistoryList+ '++ actHistoryList ++');

            //Find if Floor Plan attachment is deleted, if yes we need to clear the Floor Plan URL on Agreement Document Record.
            if(agrDocMap.get(att.ParentId).Floor_Plan_URL__c != null && agrDocMap.get(att.ParentId).Floor_Plan_URL__c.containsIgnoreCase(att.id)){
                agrDocToUpdate.add(att.ParentId);
            }
        }
        //Clear the Floor Plan URL for records whose floor plans are getting deleted.
        for(Agreement_Document__c ag: [Select Id From Agreement_Document__c Where Id in: agrDocToUpdate]){
            ag.Floor_Plan_URL__c = '';
            agreementDocsList.add(ag);
        }

        try{
            //Insert Activity Histories
            insert actHistoryList;
        }
        //In case error occurs...
        catch (Exception err) {
            //developer can see error in error log
            System.debug('An error occured: ' + err);
        }

        try{
            //Update Agreement Document records whose floor plan URL is resetted.
            update agreementDocsList;
        }
        //In case error occurs in Update..
        catch (Exception err) {
            //developer can see error in error log
            System.debug('An error occured: ' + err);
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   On delete of attachment, this method will search for new files created related to
                    the same parent agreement record of the attachment. New files will be linked to the clone sf contract.
    Inputs:        attListOld - list of attachments deleted and files check
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio       First version
    ------------------------------------------------------------*/
    public static void linkExistingFiles(List<Attachment> attListOld) {
        try{
            //Holds IDs of Apttus Agreements for which attachments are getting deleted
            Set<ID> aptIDSet = new Set<ID>();
            //Get the Ids for Apttus agreements
            for(Attachment att: attListOld){
                aptIDSet.add(att.ParentId);
            }
            //Fetch all Apttus Agreements for given attachments
            List<Apttus__APTS_Agreement__c> aptContractList = new List<Apttus__APTS_Agreement__c>([SELECT ID, Name,RecordType.Name, APT_Contract_Type__C, APT_has_file__c,
                                                                                                    (SELECT ID, Name, Parent_Agreement__c from SFCon_Agreements__r)
                                                                                                    from Apttus__APTS_Agreement__c
                                                                                                    where ID IN :aptIDSet]);

            //Get Document Details from Salesforce Content - Content Document Link
            List<ContentDocumentLink> cdlListCheck = [SELECT ID, ContentDocumentID, LinkedEntityID
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityID IN: aptIDSet];

            //Map that has Apttus Agreement Reocrds ID as Key and Corresponding ContentDocument Link record.
            Map<ID, ContentDocumentLink> aptIDcdlMap = new Map<ID, ContentDocumentLink>();

            //Iterate through Apttus agreements
            for(Apttus__APTS_Agreement__c apt: aptContractList){
                //Check all content document lists
                for(ContentDocumentLink cdl: cdlListCheck){
                    //If LinkedEntityId on ContentDocumentLink matches Apttus Record Id then add it to Map
                    if(apt.id==cdl.LinkedEntityID)
                        aptIDcdlMap.put(apt.id, cdl);
                }
            }
            //Holds Apttus Agreements to Update
            List<Apttus__APTS_Agreement__c> aptContractUpdateHasFilesList = new List<Apttus__APTS_Agreement__c>();

            //Check if Apttus Agreement/contract records exists for which attachment is deleted.
            if(!aptContractList.isEmpty()){
                //Holds Salesforce Contract List
                List<Contract> sfContractList = new List<Contract>();
                //Iterate through Apttus Agreement/Contract
                for(Apttus__APTS_Agreement__c aptContract : aptContractList){
                    //Set the flag to true on Apttus agreement if corresponding contend document link exists. Else set the flag to false.
                    sfContractList.add(aptContract.SFCon_Agreements__r);
                    if(aptIDcdlMap.containsKey(aptContract.ID)){
                        aptContract.APT_has_file__c = TRUE;
                    }else{
                        aptContract.APT_has_file__c = FALSE;
                    }
                    aptContractUpdateHasFilesList.add(aptContract);
                }

                //Calling method to link Existing Files aptContractList
                //Commenting method to link files under Apttus agreement and SF contract. This method is moved to scheduler class, which is invoked on
                //activating a contract and uploading a file to apttus contract since creating file and creating/updating sf contract are not synchronous methods
                //and can't link files in the same transaction.
                //ContentDocumentLinkTriggerHandler.linkExistingFiles(aptContractList,sfContractList);
                //Calling method to update document type
                ContentDocumentLinkTriggerHandler.updateDocumentType(aptContractList,cdlListCheck);
                //Update Apttus Agreement records
                update aptContractUpdateHasFilesList;
            }
        }catch(exception e){
            system.debug('Delete failed:' + e);
        }
    }
}