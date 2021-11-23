/**
   * Created by: Shashwat Nath
   * Description: Test class for SendToPartnerPageController class
   * Date: 09/10/2019
   */
@isTest
public with sharing class SendToPartnerPageControllerTest {
    @testSetup static void setup() {
        Account Acc = new Account();
        Acc.name = 'Test';
        insert Acc;

        //data setup
        Rate_List__c rtList = new Rate_List__c();
        rtList.name = 'Test';
        rtList.Status__c = 'Active';
        rtList.Licence_Type__c = 'LPO';
        insert rtList;
        
        SystemSettings__c setRec = new SystemSettings__c();
        setRec.Disable_Attachment_Trigger__c = true;
        insert setRec;
        
        List<Allowed_Agreement_Document_Status__c> allowedAgreementDocumentStatusForAttachment = new List<Allowed_Agreement_Document_Status__c>();
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Draft'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Pending Pre-Approval'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Awaiting Signature'));
        insert allowedAgreementDocumentStatusForAttachment;


        Agreement_Document__c agreementRec = new Agreement_Document__c();
        agreementRec.Rate_List__c = NULL;
        agreementRec.Licence__c = Acc.id;
        agreementRec.Status__c = 'Draft';
        insert agreementRec;

        Attachment attach = new Attachment();
        Blob body;
        body = Blob.valueOf('Some Text');
        attach.Body = body;
        // add the user entered name
        attach.Name = 'Test PDF';
        attach.IsPrivate = false;
        // attach the pdf to the account
        attach.ParentId = agreementRec.id;
        insert attach;
        
        Task taskRecord = new Task();
        taskRecord.subject = 'Test';
        insert taskRecord ;
        
    }
    
    public static testmethod void findAttachmentTest() {
        List<Agreement_Document__c> agreementRecList = new List<Agreement_Document__c>();
        agreementRecList = [SELECT ID from Agreement_Document__c LIMIT 1];
        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(agreementRecList[0]);
            SendToPartnerPageController spc = new SendToPartnerPageController(sc);
            SendToPartnerPageController.findAttachment('Test PDF',  agreementRecList[0].ID);
        Test.StopTest();
        List<Attachment> attchmntList = new List<Attachment>();
        attchmntList = [SELECT id from Attachment where parentId =: agreementRecList[0].Id];
        if(!attchmntList.IsEmpty()){
            system.assertEquals(attchmntList.Size(),1);
        }
       
    }
    
    public static testmethod void getActivityHistoryTest() {
        List<Agreement_Document__c> agreementRecList = new List<Agreement_Document__c>();
        agreementRecList = [SELECT ID from Agreement_Document__c LIMIT 1];
        Test.StartTest();
            SendToPartnerPageController.getActivityHistory('Test',  agreementRecList[0].ID);
        Test.StopTest();
        List<Task> taskList = new List<Task>();
        taskList = [SELECT id from task where whatId=: agreementRecList[0].Id];
        if(!taskList.IsEmpty()){
            system.assertEquals(taskList.Size(),1);
        }
       
    }
    
    public static testmethod void updateAgreementTest() {
        List<Agreement_Document__c> agreementRecList = new List<Agreement_Document__c>();
        agreementRecList = [SELECT ID from Agreement_Document__c LIMIT 1];
        Test.StartTest();
            SendToPartnerPageController.updateAgreement(agreementRecList[0].ID, true);
        Test.StopTest();
        List<Agreement_Document__c> agreementRecListUpdated = new List<Agreement_Document__c>();
        agreementRecListUpdated = [SELECT ID,Non_Compliant_Document_Sent__c  from Agreement_Document__c where id=:agreementRecList[0].id LIMIT 1];
        if(!agreementRecListUpdated.IsEmpty()){
            system.assertEquals(agreementRecListUpdated[0].Non_Compliant_Document_Sent__c , true);
        }
       
    }
    
    public static testmethod void generateActivityHistoryTest() {
        List<Agreement_Document__c> agreementRecList = new List<Agreement_Document__c>();
        agreementRecList = [SELECT ID from Agreement_Document__c LIMIT 1];
        Test.StartTest();
            SendToPartnerPageController.generateActivityHistory(agreementRecList[0].ID);
        Test.StopTest();
        List<Task> taskList = new List<Task>();
        taskList = [SELECT id from task where whatId=: agreementRecList[0].Id];
        if(!taskList.IsEmpty()){
            system.assertEquals(taskList.Size(),1);
        }
    }
}