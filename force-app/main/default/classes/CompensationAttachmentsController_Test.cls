/**
* @author Hasantha Liyanage
* @date 2018-09-09
* @group Compensation
* @tag Controller
* @tag Compensation__c
* @domain Compensation
* @description This class contains unit tests for vCompensationAttachmentsController
* 2023-07-28 - Hasantha.Liyanage@auspost.com.au Added test method for new compensation custom permission validations
*/


@IsTest
private class CompensationAttachmentsController_Test {
    @TestSetup
    static void setupData() {
        Test.startTest();
        //Creating users in future to avoid mix DML issues
        TestDataFactory.insertUserFuture('SSSW - Service Agent',new Set<String>{'CC_Compensation_Supervisor'},'Superagent','CEO/Reporting');
        Test.stopTest();
    }

    @IsTest
    static void getPageConfig_001() {

        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];

        Test.startTest();
        CompensationAttachmentsController.PageConfig config;
        System.runAs(superagent) {
            config = CompensationAttachmentsController.getPageConfig();
        }
        Test.stopTest();

        System.assertEquals(
                true,
                config.isAllowedToCreateCompensation,
                'getPageConfig_001: User should be able to perform compensation super user actions'
        );
    }

    @IsTest
    static void getPageConfig_002() {

        Test.startTest();
        CompensationAttachmentsController.PageConfig config = CompensationAttachmentsController.getPageConfig();
        Test.stopTest();

        System.assertEquals(
                false,
                config.isAllowedToCreateCompensation,
                'getPageConfig_002: User should NOT be able to perform compensation super user/agent user actions'
        );
    }

    @IsTest
    static void getFileAttachmentDetails_001() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);

        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';

        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{'entityIds' => cases[0].Id}, new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT}, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecordForCase.Id => documentLinkRecordForCase});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getFileAttachmentDetails(compensations[0],attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                documentLinkRecordForCase.ContentDocumentId,
                attachmentDetails[0].Id,
                'getFileAttachmentDetails_001 : File Details should be populated from the related content document details'
        );

        System.assertEquals(
                false,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetails_001 : isSelected field should be set to true as compensation record already does not have the same attachment'
        );

    }

    @IsTest
    static void getFileAttachmentDetails_002() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);

        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        ContentDocumentLink documentLinkRecordForCompensation = ApplicationTestDataFactory.getContentDocumentLinks(1, compensations[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';

        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{'entityIds' => cases[0].Id}, new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT}, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecordForCase.Id => documentLinkRecordForCase});
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{'entityIds' => compensations[0].Id}, new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT}, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecordForCompensation.Id => documentLinkRecordForCompensation});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getFileAttachmentDetails(compensations[0],attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                documentLinkRecordForCase.ContentDocumentId,
                attachmentDetails[0].Id,
                'getFileAttachmentDetails_002 : File Details should be populated from the case\'s related content document details'
        );

        System.assertEquals(
                true,
                attachmentDetails[0].isSelected,
                'getFileAttachmentDetails_002 : isSelected field should be set to false as compensation record already have the same attachment'
        );

    }

    @IsTest
    static void getAttachmentDetails_001() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);

        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector)MockUtility.mockSelector(AttachmentsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId(new Set<Id>{cases[0].Id}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getAttachmentDetails(compensations[0],attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                attachmentForCase.ParentId,
                attachmentDetails[0].ParentId,
                'getAttachmentDetails_001 : Attachment Details should be populated from the case\'s related content document details'
        );

        System.assertEquals(
                false,
                attachmentDetails[0].isSelected,
                'getAttachmentDetails_001 : isSelected field should NOT be set to true as compensation record already does NOT have the same attachment duplicated'
        );
    }

    @IsTest
    static void getAttachmentDetails_002() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);
        Attachment attachmentForCompensation = ApplicationTestDataFactory.getAttachments(1, compensations[0].Id, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector)MockUtility.mockSelector(AttachmentsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId(new Set<Id>{cases[0].Id}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId(new Set<Id>{compensations[0].Id}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCompensation.Id => attachmentForCompensation});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = new List<CompensationAttachmentsController.AttachmentDetail>();
        CompensationAttachmentsController.getAttachmentDetails(compensations[0],attachmentDetails);
        Test.stopTest();

        System.assertEquals(
                true,
                attachmentDetails[0].isSelected,
                'getAttachmentDetails_002 : isSelected field should be set to true as compensation record already has the same attachment duplicated'
        );
    }

    @IsTest
    static void createAttachments_001() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);

        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        // =====================================
        // Stubbing
        // =====================================

        CompensationSelector mockCompensationSelector = (CompensationSelector)MockUtility.mockSelector(CompensationSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector)MockUtility.mockSelector(AttachmentsSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId(new Set<Id>{cases[0].Id}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectById(new Set<Id>{attachmentForCase.Id},new Set<Object>{AttachmentsSelector.Options.WITH_BODY}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c> {compensations[0]});
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{'entityIds' => cases[0].Id}, new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT}, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecordForCase.Id => documentLinkRecordForCase});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = CompensationAttachmentsController.getAttachmentsByParentId(compensations[0].Id);
        CompensationAttachmentsController.getAttachmentDetails(compensations[0],attachmentDetails);
        for(CompensationAttachmentsController.AttachmentDetail detail: attachmentDetails){
            detail.isSelectedNew = true; // user selecting the attachment/files in the UI
        }
        CompensationAttachmentsController.createAttachments(attachmentDetails,compensations[0].Id);
        Test.stopTest();

        // make sure the dml is performed
        List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase,2);

        // not that it is verified, let's check for the result
        for(List<SObject> obj :insertedRecords){
            if(Attachment.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('ParentId'),
                        'createAttachments_001 : Attachment record should be created against compensation record'
                );
            }

            if(ContentDocumentLink.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('LinkedEntityId'),
                        'createAttachments_001 : ContentDocumentLink record should be created against compensation record'
                );
            }
        }
    }

    @IsTest
    static void createAttachments_002() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        Attachment attachmentForCase = ApplicationTestDataFactory.getAttachments(1, cases[0].Id, true)[0];
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id,recordTypeId, true);

        Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
        ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
        ContentDocumentLink documentLinkRecordForCase = ApplicationTestDataFactory.getContentDocumentLinks(1, cases[0].Id, documentId, true)[0];
        documentLinkRecordForCase.Visibility = 'AllUsers';
        // =====================================
        // Stubbing
        // =====================================

        CompensationSelector mockCompensationSelector = (CompensationSelector)MockUtility.mockSelector(CompensationSelector.class);
        AttachmentsSelector mockAttachmentsSelector = (AttachmentsSelector)MockUtility.mockSelector(AttachmentsSelector.class);
        ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        // set up our responses
        MockUtility.Mocks.startStubbing();
        // Selectors
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectByParentId(new Set<Id>{cases[0].Id}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.when(mockAttachmentsSelector
                .selectById(new Set<Id>{attachmentForCase.Id},new Set<Object>{AttachmentsSelector.Options.WITH_BODY}))
                .thenReturn(new Map<Id, Attachment>{attachmentForCase.Id => attachmentForCase});
        MockUtility.Mocks.when(mockCompensationSelector
                .getById(compensations[0].Id, new Set<Object>()))
                .thenReturn(new List<Compensation__c> {compensations[0]});
        MockUtility.Mocks.when(mockContentDocumentLinksSelector
                .search(new Map<String, Object>{'entityIds' => cases[0].Id}, new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT}, true))
                .thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecordForCase.Id => documentLinkRecordForCase});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<CompensationAttachmentsController.AttachmentDetail> attachmentDetails = CompensationAttachmentsController.getAttachmentsByParentId(compensations[0].Id);
        CompensationAttachmentsController.getAttachmentDetails(compensations[0],attachmentDetails);
        for(CompensationAttachmentsController.AttachmentDetail detail: attachmentDetails){
            if(detail.isAttachment) {
                detail.isSelectedNew = false;
            } else {
                detail.isSelectedNew = true; // user selecting the files in the UI NOT the attachment
            }
        }
        CompensationAttachmentsController.createAttachments(attachmentDetails,compensations[0].Id);
        Test.stopTest();

        // make sure the dml is performed
        List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase,1);

        // not that it is verified, let's check for the result
        for(List<SObject> obj :insertedRecords){
            if(ContentDocumentLink.getSobjectType().getDescribe().getName().equalsIgnoreCase(obj[0].getSObjectType().getDescribe().getName())) {
                System.assertEquals(
                        compensations[0].Id,
                        obj[0].get('LinkedEntityId'),
                        'createAttachments_002 : ContentDocumentLink record should be created against compensation record'
                );
            }
        }
    }
}