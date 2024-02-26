/**************************************************
Description:  Test for AdobeSignContentDocumentLinkModule
History:
--------------------------------------------------
2024-02-21 - H Liyanage - Created
**************************************************/

@IsTest
private class AdobeSignContentDocumentLinkModule_Test {

	/**
	 * Testing of copying signed apttus contract from agreement to apttus contract record.
	 * Only the document's title contains '- Signed' will be copied over.
	 */
	@IsTest
	static void linkSignedDocumentsToMasterRecordForApttusContractsTest() {
		// =====================================
		// Data Preparationccccccccccc
		// =====================================
		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// create contract
		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(2, primaryContact.Id, opportunityRecord.Id, true);

		// create agreement for mster record
		List <echosign_dev1__SIGN_Agreement__c> agreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, apttusContracts[0].Id, true);
		agreements[0].echosign_dev1__Status__c = 'Signed';

		// create content documents
		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentDocument contentDocument = new ContentDocument();
		contentDocument.Id = documentId;
		contentDocument.Title = 'Document - signed.pdf';

		// Content version record
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, contentDocument.Id, true)[0];
		contentVersionRecord.Title = 'Document - signed.pdf';

		// content document link to agreement
		List<ContentDocumentLink> documentLinkRecords = ApplicationTestDataFactory.getContentDocumentLinks(1, agreements[0].Id, documentId, true);
		documentLinkRecords[0].Visibility = 'AllUsers';


		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentsSelector mockContentDocumentsSelector = (ContentDocumentsSelector) MockUtility.mockSelector(ContentDocumentsSelector.class);
		AdobeSignAgreementSelector adobeSignAgreementMockSelector = (AdobeSignAgreementSelector) MockUtility.mockSelector(AdobeSignAgreementSelector.class);
		AdobeSignContentDocumentLinkModule module = AdobeSignContentDocumentLinkModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentsSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, ContentDocument>{contentDocument.Id => contentDocument});
		MockUtility.Mocks.when(adobeSignAgreementMockSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(agreements);
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		module.onAfterInsert(documentLinkRecords, mockUow);
		Test.stopTest();

		// verifications
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals(apttusContracts[0].Id, ((ContentDocumentLink)MockUtility.mockUnitOfWorkDMLs[0]).LinkedEntityId, 'Linked entity should be the apttus contract id');
	}

	/**
	 * Testing of copying signed VOI contract from agreement to Organisation(account) record.
	 * Only the document's title contains '- Signed' will be copied over.
	 */
	@IsTest
	static void linkSignedDocumentsToMasterRecordForOrganisationTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];

		// create agreement for mster record
		List <echosign_dev1__SIGN_Agreement__c> agreements = ApplicationTestDataFactoryAdobeSign.getAgreementsForAccount(1, 'Signed', account.Id, true);

		// create content documents
		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentDocument contentDocument = new ContentDocument();
		contentDocument.Id = documentId;
		contentDocument.Title = 'Document - signed.pdf';

		// Content version record
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, contentDocument.Id, true)[0];
		contentVersionRecord.Title = 'Document - signed.pdf';

		// content document link to agreement
		List<ContentDocumentLink> documentLinkRecords = ApplicationTestDataFactory.getContentDocumentLinks(1, agreements[0].Id, documentId, true);
		documentLinkRecords[0].Visibility = 'AllUsers';

		// create new content document link to account and add to save result (expected result)
		ContentDocumentLink newLink = new ContentDocumentLink();
		newLink.ContentDocumentId = documentLinkRecords[0].ContentDocumentId;
		newLink.LinkedEntityId = account.Id;
		newLink.ShareType = 'V';
		newLink.Visibility = 'AllUsers';


		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentsSelector mockContentDocumentsSelector = (ContentDocumentsSelector) MockUtility.mockSelector(ContentDocumentsSelector.class);
		AdobeSignAgreementSelector adobeSignAgreementMockSelector = (AdobeSignAgreementSelector) MockUtility.mockSelector(AdobeSignAgreementSelector.class);
		AdobeSignContentDocumentLinkModule module = AdobeSignContentDocumentLinkModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentsSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, ContentDocument>{contentDocument.Id => contentDocument});
		MockUtility.Mocks.when(adobeSignAgreementMockSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(agreements);
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		module.onAfterInsert(documentLinkRecords, mockUow);
		Test.stopTest();

		// verifications
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals(account.Id, ((ContentDocumentLink)MockUtility.mockUnitOfWorkDMLs[0]).LinkedEntityId, 'Linked entity should be that account id');
	}



}