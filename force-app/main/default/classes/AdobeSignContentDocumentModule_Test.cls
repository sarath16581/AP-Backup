/***
 * @author Hasantha Liyanage
 * @date 2024-02-22
 * @domain Core
 * @description Test class for AdobeSignContentDocumentModule
 * @changelog
 ***/

@IsTest
private class AdobeSignContentDocumentModule_Test {
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
	 * User is not allowed to delete any documents related to agreement object with Title containing - Signed
	 */
	@IsTest
	static void deleteContentDocumentsValidationTestSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		User justANormalAdobeUser = [SELECT Id FROM User WHERE FirstName = 'justANormalAdobeUser'];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true)[0];
		agreement.echosign_dev1__Status__c = 'Signed';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => '- Signed.pdf' });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord.ShareType = 'V';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });

		List<ContentDocument> contentDocuments = new List<ContentDocument>();
		contentDocuments.add(cd);
		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		AdobeSignContentDocumentModule module = AdobeSignContentDocumentModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentLinksSelector
				.search(new Map<String, Object>{
						'documentIds' => new Set<Id>{cd.Id}
				},true))
				.thenReturn(new Map<Id,ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
			System.runAs(justANormalAdobeUser) {
				module.onBeforeDelete(contentDocuments, mockUow);
			}
		Test.stopTest();

		for (ContentDocument document : contentDocuments) {
			System.assertEquals('Cannot delete ContentDocument with a link to a signed Agreement', document.getErrors()[0].getMessage());
		}

	}

	/**
	 * User is allowed to delete any documents related to an agreement as the user has the AdobeSignSuperAdmin permissions
	 */
	@IsTest
	static void deleteContentDocumentsValidationAllowedTest() {
		// =====================================
		// Data Preparation
		// =====================================
		User superPowerAdobeUser = [SELECT Id FROM User WHERE FirstName = 'superPowerAdobeUser'];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true)[0];
		agreement.echosign_dev1__Status__c = 'Signed';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => '- Signed.pdf' });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });


		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		AdobeSignContentDocumentModule module = AdobeSignContentDocumentModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentLinksSelector
				.search(new Map<String, Object>{
						'documentIds' => new Set<Id>{cd.Id}
				},true))
				.thenReturn(new Map<Id,ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.runAs(superPowerAdobeUser) {
			module.onBeforeDelete(new List<SObject> {cd}, mockUow);
		}
		Test.stopTest();

		System.assertEquals(0, cd.getErrors().size());
	}

	/**
	 * User is allowed to delete any documents related to an agreement except '- Signed' titled docs
	 */
	@IsTest
	static void deleteContentDocumentsValidationAllowedToDeleteOtherTest() {
		// =====================================
		// Data Preparation
		// =====================================
		User justANormalAdobeUser = [SELECT Id FROM User WHERE FirstName = 'justANormalAdobeUser'];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// Creating document 1
		// Agreement before sign
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, account.Id, true)[0];
		agreement.echosign_dev1__Status__c = 'Signed';

		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id, 'Title' => '-can delete.pdf' });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, agreement.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });


		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		AdobeSignContentDocumentModule module = AdobeSignContentDocumentModule.newInstance();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContentDocumentLinksSelector
				.search(new Map<String, Object>{
						'documentIds' => new Set<Id>{cd.Id}
				},true))
				.thenReturn(new Map<Id,ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.runAs(justANormalAdobeUser) {
			module.onBeforeDelete(new List<SObject> {cd}, mockUow);
		}
		Test.stopTest();

		System.assertEquals(0, cd.getErrors().size());
	}
}