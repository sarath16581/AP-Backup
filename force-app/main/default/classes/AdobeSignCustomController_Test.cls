/***
 * @author Hasantha Liyanage
 * @date 2024-01-28
 * @domain Core
 * @description Test class for AdobeSignCustomController
 * @changelog
 * --------------------------------------------------
 * 26/02/2024 hasantha.liyanage@auspost.com.au unit test modified to suit the refactor
***/

@IsTest
private class AdobeSignCustomController_Test {

	/**
	 * Testing the success scenario with a primary org contact for the org.
	 */
	@isTest
	static void navigateToVOIAgreementSuccessTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = 'VOI_Property';
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// contact to check billing account for user
		Contact contact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		contact.ConveyancerContact__c = true;


		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						'VOI_Property' => voiPropertySettings
				});
		MockUtility.Mocks.when(contactsSelector.selectPrimaryContactByAccount(new Set<Id>{organisation.Id})).thenReturn(new List<Contact>{contact});
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		// Call the method being tested
		Object response = AdobeSignCustomController.autoRedirect('AdobeSignVOI', organisation.Id, null);

		Test.stopTest();

		// Verify that the RedirectResponse is not null
		System.assertNotEquals(null, response);
	}

	/**
	 * Checking for the organisations primary contact missing error message,
	 * with returning empty contact list should throw the error message.
	 */
	@IsTest
	static void navigateToVOIAgreementOrgMissingContactTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = 'VOI_Property';
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];


		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						'VOI_Property' => voiPropertySettings
				});
		MockUtility.Mocks.when(contactsSelector.selectPrimaryContactByAccount(new Set<Id>{organisation.Id})).thenReturn(new List<Contact>{});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// Call the method being tested
		Boolean isExceptionThrown = false;
		try {
			AdobeSignCustomController.navigateToVOI(organisation.Id);
		} catch(AuraHandledException e){
			isExceptionThrown = e.getMessage().containsIgnoreCase(AdobeSignCustomController.MSG_ERROR_ORG_MISSING_CONTACT);

		}
		Test.stopTest();
		System.assertEquals(
				true,
				isExceptionThrown,
				'navigateToVOIAgreementOrgMissingContactTest : The organisation missing contact message should be displayed'
		);
	}

	/**
 * Testing of fall trough error messages from not supported source urls
 */
	@IsTest
	static void navigateToAgreementPageNotSupportedTest() {
		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		Boolean isExceptionThrown = false;
		try {
			// Call the method being tested
			AdobeSignCustomController.autoRedirect('SomethingElse', organisation.Id, null);
		} catch(AuraHandledException e){
			isExceptionThrown = e.getMessage().containsIgnoreCase(AdobeSignCustomController.MSG_ERROR_PAGE_NOT_SUPPORTED);
		}

		Test.stopTest();
		System.assertEquals(
				true,
				isExceptionThrown,
				'navigateToVOIAgreementPageNotSupportedTest : source url should not be supported'
		);
	}

	/**
	 * Testing of apptus contract redirection based on the VF page
	 */
	@IsTest
	static void navigateToApttusAgreementPageTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];

		// setting the formula field
		apttusContract = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{'DaysUntilContractExpires__c' => '10'});
		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContract.Id => apttusContract};

		// =====================================
		// Stubbing
		// =====================================
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						AdobeSignCustomController.TEMPLATE_APTTUS => voiPropertySettings
				});
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject(),
				new Set<Object>{ fflib_Match.anyObject()
		})).thenReturn(mockApttusContractMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// Call the method being tested
		AdobeSignCustomController.RedirectResponse response = (AdobeSignCustomController.RedirectResponse)AdobeSignCustomController.autoRedirect('AdobeSignApttus', apttusContract.Id, null);

		Test.stopTest();

		System.assertNotEquals(
				null,
				response.pageRef,
				'navigateToApttusAgreementPageTest : pageRef response expected'
		);
	}

	/**
	 * Testing of apptus contract redirection based on the VF page with an expired contract
	 * should throw the missing contract error message
	 */
	@IsTest
	static void navigateToApttusAgreementPageOnExpiredContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];

		// do not set the DaysUntilContractExpires__c formula value here, this will allow to throw the error message
		apttusContract = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{'DaysUntilContractExpires__c' => '0'});
		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContract.Id => apttusContract};

		// =====================================
		// Stubbing
		// =====================================
		ApttusContractsSelector apttusContractSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						AdobeSignCustomController.TEMPLATE_APTTUS => voiPropertySettings
				});
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						AdobeSignCustomController.TEMPLATE_APTTUS => voiPropertySettings
				});
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject(),
				new Set<Object>{ fflib_Match.anyObject()
				})).thenReturn(mockApttusContractMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Boolean isExceptionThrown = false;
		try {
			// Call the method being tested
			AdobeSignCustomController.RedirectResponse response = (AdobeSignCustomController.RedirectResponse)AdobeSignCustomController.autoRedirect('AdobeSignApttus', apttusContract.Id, null);


		} catch(AuraHandledException e){
			isExceptionThrown = e.getMessage().containsIgnoreCase(AdobeSignCustomController.MSG_ERROR_APT_CONTRACT_EXPIRED);
		}

		Test.stopTest();
		System.assertEquals(
				true,
				isExceptionThrown,
				'navigateToApttusAgreementPageOnExpiredContractTest : Error message should be thrown as The contract has expired'
		);
	}

	/**
	 * Testing of apptus contract missing error message
	 */
	@IsTest
	static void navigateToApttusAgreementMissingContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						AdobeSignCustomController.TEMPLATE_APTTUS => voiPropertySettings
				});
		// we do not stub the contract here to mimic the error message
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Boolean isExceptionThrown = false;
		try {
			// Call the method being tested
			AdobeSignCustomController.RedirectResponse response = (AdobeSignCustomController.RedirectResponse)AdobeSignCustomController.autoRedirect('AdobeSignApttus', apttusContract.Id, null);


		} catch(AuraHandledException e){
			isExceptionThrown = e.getMessage().containsIgnoreCase(AdobeSignCustomController.MSG_ERROR_APT_MISSING_CONTRACT);
		}

		Test.stopTest();
		System.assertEquals(
				true,
				isExceptionThrown,
				'navigateToApttusAgreementMissingContractTest : Contract missing error should be displayed'
		);
	}

	/**
	 * Testing of cancel apttus agreement success scenario
	 */
	@IsTest
	static void CancelApttusAgreementPageTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];

		// setting the formula field
		apttusContract = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{'DaysUntilContractExpires__c' => '10'});
		Map<Id, Apttus__APTS_Agreement__c> mockApttusContractMap = new Map<Id, Apttus__APTS_Agreement__c>{apttusContract.Id => apttusContract};

		List <echosign_dev1__SIGN_Agreement__c>  agreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, apttusContract.Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApttusContractsSelector apttusContractMockSelector = (ApttusContractsSelector)MockUtility.mockSelector(ApttusContractsSelector.class);
		AdobeSignAgreementSelector adobeSignAgreementMockSelector = (AdobeSignAgreementSelector)MockUtility.mockSelector(AdobeSignAgreementSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(apttusContractMockSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);
		MockUtility.Mocks.when(adobeSignAgreementMockSelector.selectOutForSignatureByApttusContractId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(agreements);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		// Call the method being tested
		AdobeSignCustomController.RedirectResponse response = (AdobeSignCustomController.RedirectResponse)AdobeSignCustomController.autoRedirect('AdobeSignApttusCancel', apttusContract.Id, null);

		Test.stopTest();

		System.assertNotEquals(
				null,
				response.pageRef.containsIgnoreCase('a7G000000000005EAA'),
				'CancelApttusAgreementPageTest : pageRef response expected'
		);
	}

	/**
	 * Testing of cancel Apttus agreement contract not found error message
	 */
	@IsTest
	static void cancelApttusAgreementMissingContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = fflib_IDGenerator.generate(echosign_dev1__Agreement_Template__c.SObjectType);

		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, AdobeSignTemplateSettings__c>{
						AdobeSignCustomController.TEMPLATE_APTTUS => voiPropertySettings
				});
		// we do not stub the contract here to mimic the error message
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Boolean isExceptionThrown = false;
		try {
			// Call the method being tested
			AdobeSignCustomController.RedirectResponse response = (AdobeSignCustomController.RedirectResponse)AdobeSignCustomController.autoRedirect('AdobeSignApttusCancel', apttusContract.Id, null);
		} catch(AuraHandledException e){
			isExceptionThrown = e.getMessage().containsIgnoreCase(AdobeSignCustomController.MSG_ERROR_APT_MISSING_CONTRACT);
		}

		Test.stopTest();
		System.assertEquals(
				true,
				isExceptionThrown,
				'cancelApttusAgreementMissingContractTest : Contract missing error should be displayed'
		);
	}

	@IsTest
	static void createNewContentVersionsForSelectedDocumentsTest() {

		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// create contract
		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(2, primaryContact.Id, opportunityRecord.Id, true);

		// create agreement for mster record
		List <echosign_dev1__SIGN_Agreement__c> agreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, apttusContracts[0].Id, true);
		agreements[0].echosign_dev1__Status__c = 'Signed';

		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentDocument contentDocument = new ContentDocument();
		contentDocument.Id = documentId;
		contentDocument.Title = 'Document - signed.pdf';

		// Content version record
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, contentDocument.Id, true)[0];
		contentVersionRecord.Title = 'Document - signed.pdf';
		Map <Id, ContentVersion> contentVersionByContentDocumentId = new Map <Id, ContentVersion> ();
		contentVersionByContentDocumentId.put(contentVersionRecord.Id, contentVersionRecord);
		// content document link to agreement
		List<ContentDocumentLink> documentLinkRecords = ApplicationTestDataFactory.getContentDocumentLinks(1, agreements[0].Id, documentId, true);
		documentLinkRecords[0].Visibility = 'AllUsers';

		// =====================================
		// Stubbing
		// =====================================
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockContentVersionsSelector.selectByContentDocumentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(contentVersionByContentDocumentId);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		// Call the method being tested
		AdobeSignCustomController.createNewContentVersionsForSelectedDocuments( apttusContracts[0].Id, new List<Id> {contentDocument.Id});
		Test.stopTest();

		List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 1);

		System.assertEquals(
				ContentVersion.getSobjectType().getDescribe().getName(),
				insertedRecords[0][0].getSObjectType().getDescribe().getName(),
				'createNewContentVersionsForSelectedDocumentsTest : Make sure the ContentVersion record is available after creation'
		);

	}

}