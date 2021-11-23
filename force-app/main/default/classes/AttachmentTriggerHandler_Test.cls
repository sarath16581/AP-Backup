/******************************************************************************************
    
    Author:         Stephen James Laylo
    Date Created:   19/02/2015
    Description:    Test class for AttachmentTriggerHandler
    
    Change Log:
    Date:          Author:                  Description:
    19/02/2015     Stephen James Laylo      Created
    15/03/2016     Lyndon Lavapie           Updated for after delete event
    01/06/2016     Andrew Judd (Salesforce.com) Added setting of Network.Org_Unit_Type__c and Facility.Licence_Type__c to LPO for filter
    
*******************************************************************************************/
@isTest
private class AttachmentTriggerHandler_Test {
    
    private static final Id ORGANISATION_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
    private static final Id FACILITY_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();
    private static final Id LICENCE_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Licence').getRecordTypeId();
    
    private static testMethod void testAttachmentsInsertionWithPrevention() {
        List<Allowed_Agreement_Document_Status__c> allowedAgreementDocumentStatusForAttachment = new List<Allowed_Agreement_Document_Status__c>();
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Draft'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Pending Pre-Approval'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Awaiting Signature'));
        insert allowedAgreementDocumentStatusForAttachment;
        
        Account organisation = new Account(Name='HCH88 PTY LTDx', 
                                           RecordTypeId=ORGANISATION_RECORD_TYPE);
        insert organisation;
        
        Account facility = new Account(Name='SPRING HILL LPO', 
                                       RecordTypeId=FACILITY_RECORD_TYPE);
        insert facility;
        
        Account licence = new Account(Name='HCH88 PTY LTD-SPRING HILL LPO', 
                                      ParentId=organisation.Id, 
                                      Facility__c=facility.Id, 
                                      Assignment_Effective_From_Date__c=Date.today(), 
                                      Approval_Status__c='Approved', 
                                      Licence_Type__c='LPO', 
                                      RecordTypeId=LICENCE_RECORD_TYPE);
        insert licence;
        
        Test.startTest();
        
            Agreement_Document__c agreementDocument = new Agreement_Document__c(Licence__c=licence.Id, 
                                                                                Approval_Type__c='Single', 
                                                                                Status__c='New', 
                                                                                Agreement_Effective_From_Date__c=Date.today());
            insert agreementDocument;
            
            Boolean isPrevented = false;
            
        
            Attachment att = new Attachment(Name='Test Attachment', 
                                            Body=Blob.valueOf('Test Attachment File Body'), 
                                            ParentId=agreementDocument.Id);
            try {
                insert att;
            } catch (DmlException de) {
                isPrevented = true;
            }

            List<Attachment> testAttachments = new List<Attachment>([SELECT Id FROM Attachment WHERE ParentId = :agreementDocument.Id]);
            
            System.assertEquals(0, testAttachments.size());
            System.assertEquals(true, isPrevented);
            
            agreementDocument.Approval_Type__c = 'Scanned Paper';
            
            update agreementDocument;
            
            isPrevented = false;
            

            Attachment att2 = new Attachment(Name='Test Attachment', 
                                            Body=Blob.valueOf('Test Attachment File Body'), 
                                            ParentId=agreementDocument.Id);
            try {
                insert att2;
            } catch (DmlException de) {
                isPrevented = true;
            }
            
            testAttachments = new List<Attachment>([SELECT Id FROM Attachment WHERE ParentId = :agreementDocument.Id]);
            
            System.assertEquals(0, testAttachments.size());
            System.assertEquals(true, isPrevented);
        Test.stopTest();
    }
    
    private static testMethod void testAttachmentsInsertionWithoutPrevention() {
        List<Allowed_Agreement_Document_Status__c> allowedAgreementDocumentStatusForAttachment = new List<Allowed_Agreement_Document_Status__c>();
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='New'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Draft'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Pending Pre-Approval'));
        allowedAgreementDocumentStatusForAttachment.add(new Allowed_Agreement_Document_Status__c(Name='Awaiting Signature'));
        insert allowedAgreementDocumentStatusForAttachment;
        
        Network__c parentNetwork = new Network__c(Org_ID__c = '2345');
        insert parentNetwork;

        Network__c network = new Network__c(Org_ID__c = '2346', Parent_Network__c = parentNetwork.id, Org_Unit_Type__c = 'LPO');
        insert network;        
        
        Account organisation = new Account(Name='HCH88 PTY LTDx', 
                                           RecordTypeId=ORGANISATION_RECORD_TYPE);
        insert organisation;
        
        Account facility = new Account(
                                        Name='SPRING HILL LPO',
                                        phone='123',
                                        Licence_Type__c = 'LPO',
                                        Network_Facility__c = network.id,
                                        RecordTypeId=FACILITY_RECORD_TYPE);
        insert facility;
 
        Account licence = new Account(Name='HCH88 PTY LTD-SPRING HILL LPO', 
                                      ParentId=organisation.Id, 
                                      Facility__c=facility.Id, 
                                      Assignment_Effective_From_Date__c=Date.today(), 
                                      Approval_Status__c='Approved', 
                                      Licence_Type__c='LPO', 
                                      RecordTypeId=LICENCE_RECORD_TYPE);
        insert licence;

        APXTConga4__Conga_Template__c congaTemplate = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'Test Document Name');
        Insert congaTemplate;
        
        
        Agreement_Document__c agreementDocument = new Agreement_Document__c(Licence__c=licence.Id, 
                                                                            Approval_Type__c='Full',
                                                                            Document_ID__c = congaTemplate.Id, 
                                                                            Status__c='New', 
                                                                            Agreement_Effective_From_Date__c=Date.today());
        insert agreementDocument;
        
        Boolean isPrevented = false;
        
        Test.startTest();
            List<Attachment> attList = new List<Attachment>();
            Attachment att = new Attachment(Name='Floor Plan', 
                                            Body=Blob.valueOf('Test Attachment File Body'), 
                                            ParentId=agreementDocument.Id,
                                            contenttype = 'image/jpeg');
            Attachment att2 = new Attachment(Name='TEST Document NAME 1234', 
                                            Body=Blob.valueOf('Test Attachment File Body'), 
                                            ParentId=agreementDocument.Id);
            Attachment att3 = new Attachment(Name='TEST Document NAME 4321', 
                                            Body=Blob.valueOf('Test Attachment File Body'), 
                                            ParentId=agreementDocument.Id);
            attList.add(att);
            attList.add(att2);
            attList.add(att3);
            try {
                insert attList;
            } catch (DmlException de) {
                isPrevented = true;
            }
        
            Agreement_Document__c agrDoc = [Select Id, Floor_Plan_URL__c From  Agreement_Document__c where id=: agreementDocument.Id];
            System.assertNotEquals(null, agrDoc.Floor_Plan_URL__c);

            List<Attachment> testAttachments = new List<Attachment>([SELECT Id FROM Attachment WHERE ParentId = :agreementDocument.Id]);

            System.assertEquals(3, testAttachments.size());
            System.assertEquals(false, isPrevented);

            Delete testAttachments;
            agrDoc = [Select Id, Floor_Plan_URL__c From  Agreement_Document__c where id=: agreementDocument.Id];
            List<Task> actHistoryList = new List<Task>([Select Id From Task where whatId =: agreementDocument.Id]);
            System.assertEquals(2, actHistoryList.size());
            System.assertEquals(null, agrDoc.Floor_Plan_URL__c);


        Test.stopTest();


    }

    

}