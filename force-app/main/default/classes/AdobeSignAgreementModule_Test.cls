/**
 * Created by hasan on 22/02/2024.
 */

@IsTest
private class AdobeSignAgreementModule_Test {

	@TestSetup
	static void setupData() {
		Test.startTest();
		//Creating users in future to avoid mix DML issues
		// create a super user: a;;ows to delete agreement documents with title containing '- signed'
		List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
		TestDataFactory.UserDTO adobeSignSuperAdmin = new TestDataFactory.UserDTO();
		adobeSignSuperAdmin.profileName = 'Retail Operations';
		adobeSignSuperAdmin.permissionSetNames = new Set<String>{'AdobeSignSuperAdmin'};
		adobeSignSuperAdmin.userName = 'superPowerAdobeUser';
		adobeSignSuperAdmin.role = 'CEO/Reporting';
		userDTOs.add(adobeSignSuperAdmin);

		// this user is not allowed to delete documents
		TestDataFactory.UserDTO adobeUser = new TestDataFactory.UserDTO();
		adobeUser.profileName = 'Retail Operations';
		adobeUser.userName = 'justANormalAdobeUser';
		adobeUser.role = 'CEO/Reporting';
		userDTOs.add(adobeUser);

		TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
		System.enqueueJob(queueable);
		Test.stopTest();
	}

	/**
	 * Testing of a user having the permission to delete sign agreement
	 */
	@IsTest
	static void preventDeletionOfSignedAgreementsTestAllowedToDelete() {
		// =====================================
		// Data Preparation
		// =====================================
		User superPowerAdobeUser = [SELECT Id FROM User WHERE FirstName = 'superPowerAdobeUser'];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		List<echosign_dev1__SIGN_Agreement__c> agreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true);
		agreements[0].echosign_dev1__Status__c = 'Signed';

		// =====================================
		// Stubbing
		// =====================================
		AdobeSignAgreementModule module = AdobeSignAgreementModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.runAs(superPowerAdobeUser) {
			module.onBeforeDelete((List<SObject>) agreements, mockUow);
		}
		Test.stopTest();

		System.assertEquals(
				0,
				agreements[0].getErrors().size(),
				'preventDeletionOfSignedAgreementsTestAllowedToDelete: User should be able to delete the record'
		);

	}

	/**
	 * User is not allowed to delete any agreements which has the status with Signed
	 */
	@IsTest
	static void preventDeletionOfSignedAgreementsTestSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		User justANormalAdobeUser = [SELECT Id FROM User WHERE FirstName = 'justANormalAdobeUser'];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		List<echosign_dev1__SIGN_Agreement__c> agreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true);
		agreements[0].echosign_dev1__Status__c = 'Signed';

		// =====================================
		// Stubbing
		// =====================================
		AdobeSignAgreementModule module = AdobeSignAgreementModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.runAs(justANormalAdobeUser) {
			module.onBeforeDelete((List<SObject>) agreements, mockUow);
		}
		Test.stopTest();

		for(echosign_dev1__SIGN_Agreement__c  agreement : agreements) {
			System.assertEquals(
					'You are not allowed to delete signed agreements',
					agreement.getErrors()[0].getMessage(),
					'preventDeletionOfSignedAgreementsTestSuccess: User should not be able to delete agreements with the status having Signed');
		}

	}

	/**
	 * Testing of execution of delete logic with agreements not having Signed status and documents
	 */
	@IsTest
	static void deleteContentDocumentsTestOnSignAgreementNoSignedDocsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true)[0];
		agreement.echosign_dev1__Status__c = 'Out for Signature';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => 'something.pdf' });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });

		// Creating document 2
		// Agreement before signed
		echosign_dev1__SIGN_Agreement__c changedAgreement = agreement.clone(true);
		changedAgreement.echosign_dev1__Status__c = 'Draft';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd2 = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd2 });
		cd2 = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => '- dr.pdf' });
		ContentVersion contentVersionRecord2 = ApplicationTestDataFactory.getContentVersions(1, cd2.Id, true)[0];
		ContentDocumentLink documentLinkRecord2 = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd2.Id, true)[0];
		documentLinkRecord2.Visibility = 'AllUsers';
		documentLinkRecord2 = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord2, new Map <String, Object>{ 'ContentDocument' => cd2 });
		documentLinkRecord2 = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord2, new Map <String, Object>{ 'ContentDocumentId' => cd2.Id });

		// creating old agreement record for after update trigger logic mocking
		Map <Id, echosign_dev1__SIGN_Agreement__c> oldAgreements = new Map <Id, echosign_dev1__SIGN_Agreement__c>{agreement.Id => agreement};
		Map<Id, ContentDocumentLink> allDocumentLinkRecords = new Map<Id, ContentDocumentLink>();
		allDocumentLinkRecords.put(documentLinkRecord.Id,documentLinkRecord);
		allDocumentLinkRecords.put(documentLinkRecord2.Id,documentLinkRecord2);

		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		AdobeSignAgreementModule module = AdobeSignAgreementModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentLinksSelector
				.search(new Map<String, Object>{
						'entityIds' => new Set<Id>{agreement.Id}
				}, new Set<Object>{
						ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
				}, true))
				.thenReturn(allDocumentLinkRecords);
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		module.onAfterUpdate(new List<SObject> {changedAgreement},  (Map<Id, SObject>) oldAgreements ,mockUow);
		Test.stopTest();

		fflib_ArgumentCaptor deletedSObjectsCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDeleted((List<SObject>)deletedSObjectsCapture.capture());
		List<ContentDocument> docsDeleted = (List<ContentDocument>)deletedSObjectsCapture.getValue();
		System.assertEquals(null, docsDeleted, 'Expected to NOT TO delete any documents');
	}

	/**
	 * Testing the delete documents when there are signed agreements and the document contains - Signed title
	 */
	@IsTest
	static void deleteContentDocumentsTestOnSignAgreementSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true)[0];
		agreement.echosign_dev1__Status__c = 'Out for Signature';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => 'something.pdf' });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });

		// Creating document 2
		// Agreement before signed
		echosign_dev1__SIGN_Agreement__c changedAgreement = agreement.clone(true);
		changedAgreement.echosign_dev1__Status__c = 'Signed';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd2 = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd2 });
		cd2 = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => '- Signed.pdf' });
		ContentVersion contentVersionRecord2 = ApplicationTestDataFactory.getContentVersions(1, cd2.Id, true)[0];
		ContentDocumentLink documentLinkRecord2 = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd2.Id, true)[0];
		documentLinkRecord2.Visibility = 'AllUsers';
		documentLinkRecord2 = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord2, new Map <String, Object>{ 'ContentDocument' => cd2 });
		documentLinkRecord2 = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord2, new Map <String, Object>{ 'ContentDocumentId' => cd2.Id });

		// creating old agreement record for after update trigger logic mocking
		Map <Id, echosign_dev1__SIGN_Agreement__c> oldAgreements = new Map <Id, echosign_dev1__SIGN_Agreement__c>{agreement.Id => agreement};
		Map<Id, ContentDocumentLink> allDocumentLinkRecords = new Map<Id, ContentDocumentLink>();
		allDocumentLinkRecords.put(documentLinkRecord.Id,documentLinkRecord);
		allDocumentLinkRecords.put(documentLinkRecord2.Id,documentLinkRecord2);

		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		AdobeSignAgreementModule module = AdobeSignAgreementModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentLinksSelector
				.search(new Map<String, Object>{
						'entityIds' => new Set<Id>{agreement.Id}
				}, new Set<Object>{
						ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT
				}, true))
				.thenReturn(allDocumentLinkRecords);
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		module.onAfterUpdate(new List<SObject> {changedAgreement},  (Map<Id, SObject>) oldAgreements ,mockUow);
		Test.stopTest();

		fflib_ArgumentCaptor deletedSObjectsCapture = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDeleted((List<SObject>)deletedSObjectsCapture.capture());
		List<ContentDocument> docsDeleted = (List<ContentDocument>)deletedSObjectsCapture.getValue();
		System.assertEquals(1, docsDeleted.size(), 'Expected to delete one existing ContentDocument record');
		System.assertEquals(docsDeleted[0].Id, cd.Id, 'Expected to deleted record with title NOT contains - Signed');

	}
}