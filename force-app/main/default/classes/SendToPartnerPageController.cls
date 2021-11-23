/**************************************************
Description:    Controller for the SendToPartner Page
History:
--------------------------------------------------
2019-09-25  shashwat.a.nath@accenture.com  Created
**************************************************/

public with sharing class SendToPartnerPageController {
    // Class Level Variable
    public static List<Agreement_Document__c> agreementRecordList;
    // Constructor
    public SendToPartnerPageController(ApexPages.StandardController controller){

    }
    /**
   *  This remote action Method is invoked  When user clicks on Send to Partner button Agreement Document Record
   *  It recieves attachment name and partner agreement record ID to find relevant attachment
   *  Returns back the list of Attachment retrieved
   */

    @remoteaction
    public static List<Attachment> findAttachment(String attachmentName , String recordId){
        system.debug('Attachment Name =>' +attachmentName);
        system.debug('Document Record Id =>' +recordId);
        List<Attachment> attachmentList = new List<Attachment>();
        attachmentList = [SELECT Id, Name, ContentType, LastModifiedDate FROM Attachment WHERE
                            ContentType = 'application/pdf' AND Name LIKE :attachmentName+'%' AND ParentId =:recordId LIMIT 1];
        return attachmentList;
    }

    /**
  *  This remote action Method is invoked  When user clicks on Send to Partner button Agreement Document Record
  *  It recieves attachment name and partner agreement record ID as input parameters to do a relevant Task Search
  *  Returns back the list of Taska retrieved
  */

    @remoteaction
    public static List<Task> getActivityHistory(String fileName , String recordId){
        system.debug('Attachment Name =>' +fileName);
        system.debug('Document Record Id =>' +recordId);
        List<Task> taskList = new List<Task>();
        taskList = [ Select Id, LastModifiedDate, Subject From Task WHERE WhatId =: recordId AND Subject LIKE : '%' + fileName ];
        return taskList;
    }

    /**
  *  This remote action Method is invoked  When user clicks on Send to Partner button Agreement Document Record
  *  It recieves partner agreement record id and a boolean to determine whether non compliance docs are sent
  *  Updates the Partner Agreement record with relevant values
  */

    @remoteaction
    public static void updateAgreement(String recordId , boolean nonComplaintDocsSent){
        List<Agreement_Document__c> agreementRecordList = new List<Agreement_Document__c>();
        agreementRecordList = [ SELECT id , Non_Compliant_Document_Sent__c , Approval_Type__c , Run_WF_Rule_for_Updating_Status_to_AS__c
        from Agreement_Document__c where id = :recordId];
        if(!agreementRecordList.IsEmpty()){
            if(!agreementRecordList[0].Non_Compliant_Document_Sent__c){
                agreementRecordList[0].Non_Compliant_Document_Sent__c = nonComplaintDocsSent ;
            }
            if('No'.equalsIgnoreCase(agreementRecordList[0].Approval_Type__c)){
                agreementRecordList[0].Status__c = 'Active';
            }
            else{
                agreementRecordList[0].Run_WF_Rule_for_Updating_Status_to_AS__c = true;
            }

            database.update(agreementRecordList);

        }
    }

    /**
  *  This remote action Method is invoked  When user clicks on paper button on Dialog box
  *  It creates a task record for each paper based document generation
  */

    @remoteaction
    public static void generateActivityHistory(String recordId ){
        Task taskRecord = new Task();
        taskRecord.Priority = 'Normal';
        taskRecord.Status = 'Completed';
        taskRecord.Description = 'Print Selected: New Agreement Document \n' +  DateTime.now().format('MM/dd/yyyy HH:mm:ss', 'Australia/Sydney');
        taskRecord.WhatId = recordId;
        taskRecord.Subject = 'Print Selected: New Agreement Document';
        taskRecord.Type = 'Other';
        taskRecord.ActivityDate = system.today();
        database.Insert(taskRecord);

    }
}