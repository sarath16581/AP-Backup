/**
* @author Hasantha Liyanage
* @date 2018-09-09
* @group Compensation
* @tag Controller
* @tag Compensation__c
* @domain Compensation
* @description This class contains unit tests for vCompensationAttachmentsController
* 2023-07-28 - Hasantha.Liyanage@auspost.com.au Added test method for new compensation custom permission validations
* 2023-11-06 - hasantha.liyanage@auspost.com.au - Modified: update getAttachmentDetails method to get the attachments on the EmailMessage
*/
@IsTest
private class CompensationAttachmentsController_Test {
    @TestSetup
    static void setupData() {
        Test.startTest();
        //Creating users in future to avoid mix DML issues
        // create a super user: allows to create compensation records, update bank account details, create multiple compensations, send emails
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
        TestDataFactory.UserDTO superAgent = new TestDataFactory.UserDTO();
        superAgent.profileName = 'SSSW - Service Agent';
        superAgent.permissionSetNames = new Set<String>{'CC_Compensation_Supervisor'};
        superAgent.userName = 'Superagent';
        superAgent.role = 'CEO/Reporting';
        userDTOs.add(superAgent);

        // create a normal user without any custom permissions
        TestDataFactory.UserDTO normalUser = new TestDataFactory.UserDTO();
        normalUser.profileName = 'SSSW - Service Agent';
        normalUser.userName = 'user360';
        normalUser.role = 'CEO/Reporting';
        userDTOs.add(normalUser);

        TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
        System.enqueueJob(queueable);
        Test.stopTest();
    }

    /**
     * Testing the logged in agent has one of Is_Compensation_User or Is_Compensation_Supervisor custom permission sets
     * if the user do have access isAllowedToCreateCompensation should set to true as we use this variable to determine
     * access throughout component
     */
    @IsTest
    static void getPageConfigIsAllowedToCreate() {
        // =====================================
        // Data Preparation
        // =====================================
        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Stubbing
        // =====================================
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors

        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c>{
                        compensations[0]
                });
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        CompensationAttachmentsController.PageConfig config;
        System.runAs(superagent) {
            config = CompensationAttachmentsController.getPageConfig(compensations[0].Id);
        }
        Test.stopTest();

        System.assertEquals(
                true,
                config.isAllowedToCreateCompensation,
                'getPageConfigIsAllowedToCreate: User should be able to perform compensation super user actions'
        );
    }

    /**
     * Testing the logged in agent has one of Is_Compensation_User or Is_Compensation_Supervisor custom permission sets
     * If the user does NOT have the permission sets assigned isAllowedToCreateCompensation has to be false
     */
    @IsTest
    static void getPageConfigIsNotAllowedToCreate() {
        // =====================================
        // Data Preparation
        // =====================================
        User normalUser = [SELECT Id FROM User WHERE FirstName = 'user360'];
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Stubbing
        // =====================================
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors

        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c>{
                        compensations[0]
                });
        MockUtility.Mocks.stopStubbing();
        Test.startTest();
        CompensationAttachmentsController.PageConfig config;
        System.runAs(normalUser) {
            config = CompensationAttachmentsController.getPageConfig(compensations[0].Id);
        }
        Test.stopTest();

        System.assertEquals(
                false,
                config.isAllowedToCreateCompensation,
                'getPageConfigIsNotAllowedToCreate: User should NOT be able to perform compensation super user/agent user actions'
        );
    }

    /**
     * ContentDocuments linked to case which are already NOT linked to the compensation should be able to selected by the user
     * hence the isSelected parameter should set to false to attachment details wrapper instance.
     * based on the isSelected parameter being false, we will allow user to select the record in the UI
     */
    @IsTest
    static void getFileAttachmentDetailsWhenContentDocumentIsNotAlreadySelected() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);

        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';

        // =====================================
        // Stubbing
        // =====================================
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{
                        'entityIds' => cases[0].Id
                }, new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                }, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{
                        documentLinkRecordForCase.Id => documentLinkRecordForCase
                });
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getFileAttachmentDetails(compensations[0], attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                documentLinkRecordForCase.ContentDocumentId,
                attachmentDetails[0].Id,
                'getFileAttachmentDetailsWhenContentDocumentIsNotAlreadySelected : File Details should be populated from the related content document details'
        );

        System.assertEquals(
                false,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetailsWhenContentDocumentIsNotAlreadySelected : isSelected field should be set to false as compensation record already does not have the same attachment'
        );

    }

    /**
     * When ContentDocument record linked to the case is already linked to the compensation record,
     * User will not be able to select it again by disabling the select button when isSelected is true
     */
    @IsTest
    static void getFileAttachmentDetailsWhenContentDocumentIsAlreadySelected() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        ContentDocumentLink documentLinkRecordForCompensation = ApplicationTestDataFactory.getContentDocumentLinks(1, compensations[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        // =====================================
        // Stubbing
        // =====================================
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{
                        'entityIds' => cases[0].Id
                }, new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                }, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{
                        documentLinkRecordForCase.Id => documentLinkRecordForCase
                });
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{
                        'entityIds' => compensations[0].Id
                }, new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                }, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{
                        documentLinkRecordForCompensation.Id => documentLinkRecordForCompensation
                });
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getFileAttachmentDetails(compensations[0], attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                documentLinkRecordForCase.ContentDocumentId,
                attachmentDetails[0].Id,
                'getFileAttachmentDetailsWhenContentDocumentIsAlreadySelected : File Details should be populated from the case\'s related content document details'
        );

        System.assertEquals(
                true,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetailsWhenContentDocumentIsNotAlreadySelected : isSelected field should be set to true as compensation record already have the same attachment'
        );

    }

    /**
     * Attachment records available against Case is not already duplicated against the compensations should
     * allow the user to select them against compensation, hence the isSelected should be false when it is not already created
     * for compensation
     */
    @IsTest
    static void getFileAttachmentDetailsWhenAttachmentRecordIsNotAlreadySelected() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        List<EmailMessage> records = ApplicationTestDataFactory.getEmailMessages(1, true, true, 'test@test.com', 'melbournevanoperations@test.com.au', 'Test Subject', cases[0].Id);
        records[0].Headers = 'Return-Path: caseroutingtesting+caf_=caseroutingtesting=5-1iz5gu7n9ir9bqev6o9wspvpigsnywv2e31uhnp8iy8rfd9fq6.0k-edoeeag.cs57.case.sandbox.salesforce.com@gmail.com\nX-SFDC-Binding: coremailprocessor\nX-SFDC-DOMAINKEYS: None\nX-SFDC-TLS-VERIFIED: no\nX-SFDC-TLS-CIPHER: AES256-SHA\nX-SFDC-TLS-STATUS: true\nX-SFDC-SENDERID-PRA: Pass\nX-SFDC-SENDERID: None\nX-SFDC-SPF: None\nSFDC-Interface: external\nReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 May 2023 06:05:10 +0000\nMessage-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>\nFrom: Mail Delivery System <mailer-daemon@salesforce.com>\nTo: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.com\nX-MS-Exchange-ForwardingLoop: melbournevanoperations@test.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48\nDate: Thu, 19 May 2023 06:05:05 +0000';
        records[0] = (EmailMessage)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'ParentId' => cases[0].Id});
        cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0],new Map<String,List<SObject>>{'EmailMessages'=> new List<EmailMessage>{records[0]}});

        // =====================================
        // Stubbing
        // =====================================
        EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector)MockUtility.mockSelector(EmailMessagesSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector) MockUtility.mockSelector(AttachmentsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockEmailMessagesSelector.selectByParentIds(new Set<Id>{cases[0].Id},new Set<Object>() )).thenReturn(records);
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId((Set<Id>) fflib_Match.anyObject()))
                .thenReturn(new List<Attachment>{ attachmentForCase});
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getAttachmentDetails(compensations[0], attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                attachmentForCase.ParentId,
                attachmentDetails[0].ParentId,
                'getFileAttachmentDetailsWhenAttachmentRecordIsNotAlreadySelected : Attachment Details should be populated from the case\'s related content document details'
        );

        System.assertEquals(
                false,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetailsWhenAttachmentRecordIsNotAlreadySelected : isSelected field should NOT be set to true as compensation record already does NOT have the same attachment duplicated'
        );
    }

    /**
     * When the attachment record is already created against the compensation record user is not allowed to select it again.
     * hence the isSelected should be set to true then the Ui will disable the button
     */
    @IsTest
    static void getFileAttachmentDetailsWhenAttachmentRecordIsAlreadySelected() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Attachment> attachments = new List<Attachment>();
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        attachments.add(attachmentForCase);
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        Attachment attachmentForCompensation = ApplicationTestDataFactory.getAttachments(1, compensations[0].Id, true)[0];
        attachments.add(attachmentForCompensation);
        // =====================================
        // Stubbing
        // =====================================
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector) MockUtility.mockSelector(AttachmentsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId((Set<Id>) fflib_Match.anyObject()))
                .thenReturn(attachments);
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getAttachmentDetails(compensations[0], attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                true,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetailsWhenAttachmentRecordIsAlreadySelected : isSelected field should be set to true as compensation record already has the same attachment duplicated'
        );
    }

    /**
     * If the user select a new ContentDocument isSelectedNew will be set to true in the ui then once the selection is saved,
     * new ContentDocumentLink link record should get created against compensation record
     */
    @IsTest
    static void createAttachmentsLinkSelectedContentDocumentToCompensationRecord() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';

        // =====================================
        // Stubbing
        // =====================================
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector) MockUtility.mockSelector(AttachmentsSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId((Set<Id>) fflib_Match.anyObject()))
                .thenReturn(new List<Attachment>{ attachmentForCase});

        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectById(new Set<Id>{
                        attachmentForCase.Id
                }, new Set<Object>{
                        AttachmentsSelector.Options.WITH_BODY
                }))
                .thenReturn(new Map<Id, Attachment>{
                        attachmentForCase.Id => attachmentForCase
                });
        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c>{
                        compensations[0]
                });
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{
                        'entityIds' => cases[0].Id
                }, new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                }, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{
                        documentLinkRecordForCase.Id => documentLinkRecordForCase
                });
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = CompensationAttachmentsController.getAttachmentsByParentId(compensations[0]);
        CompensationAttachmentsController.getAttachmentDetails(compensations[0], attachmentDetails);
        for (CompensationAttachmentsController.AttachmentDetail detail : attachmentDetails) {
            detail.isSelectedNew = true; // user selecting the attachment/files in the UI
        }
        CompensationAttachmentsController.createAttachments(attachmentDetails, compensations[0].Id);
        Test.stopTest();

        // make sure the dml is performed
        List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 2);
        // not that it is verified, let's check for the result
        for (List<SObject> obj : insertedRecords) {
            if (Attachment.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('ParentId'),
                        'createAttachmentsLinkSelectedContentDocumentToCompensationRecord : ContentDocumentLink record should be created against compensation record'
                );
            }

            if (ContentDocumentLink.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('LinkedEntityId'),
                        'createAttachmentsLinkSelectedContentDocumentToCompensationRecord : ContentDocumentLink record should be created against compensation record'
                );
            }
        }
    }

    /**
     * When both attachments and Files are available to be selected by the user, then user select a file (Not attachment)
     * Then a new ContentDocumentLink record should get created against the compensation record
     */
    @IsTest
    static void createAttachmentsWhenUserSelectContentDocument() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        // =====================================
        // Stubbing
        // =====================================
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector) MockUtility.mockSelector(AttachmentsSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId((Set<Id>) fflib_Match.anyObject()))
                .thenReturn(new List<Attachment>{
                        attachmentForCase
                });
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectById(new Set<Id>{
                        attachmentForCase.Id
                }, new Set<Object>{
                        AttachmentsSelector.Options.WITH_BODY
                }))
                .thenReturn(new Map<Id, Attachment>{
                        attachmentForCase.Id => attachmentForCase
                });
        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c>{
                        compensations[0]
                });
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{
                        'entityIds' => cases[0].Id
                }, new Set<Object>{
                        ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
                }, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{
                        documentLinkRecordForCase.Id => documentLinkRecordForCase
                });
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = CompensationAttachmentsController.getAttachmentsByParentId(compensations[0]);
        CompensationAttachmentsController.getAttachmentDetails(compensations[0], attachmentDetails);
        for (CompensationAttachmentsController.AttachmentDetail detail : attachmentDetails) {
            if (detail.isAttachment) {
                detail.isSelectedNew = false;
            } else {
                detail.isSelectedNew = true; // user selecting the files in the UI NOT the attachment
            }
        }
        CompensationAttachmentsController.createAttachments(attachmentDetails, compensations[0].Id);
        Test.stopTest();

        // make sure the dml is performed
        List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 1);
        // not that it is verified, let's check for the result
        for (List<SObject> obj : insertedRecords) {
            if (ContentDocumentLink.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('LinkedEntityId'),
                        'createAttachmentsWhenUserSelectContentDocument : ContentDocumentLink record should be created against compensation record'
                );
            }
        }
    }
}