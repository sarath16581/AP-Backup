/**
 * Created by hasan on 28/01/2024.
 */

@IsTest
private class AdobeSignCustomController_Test {

	/**
	 * Testing the success scenario with a primary org contact for the org.
	 */
	@IsTest
	static void navigateToVOIAgreementSuccessTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = 'VOI_Property';
		voiPropertySettings.TemplateId__c = 'aF21m0000008OgcCAE';

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

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = Page.AdobeSignVOI;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.redirect();

		Test.stopTest();

		System.assertEquals(
				organisation.Id,
				pageRef.getParameters().get('masterId'),
				'navigateToVOIAgreementTest : master id should be set to parameters'
		);
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
		voiPropertySettings.TemplateId__c = 'aF21m0000008OgcCAE';

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
		PageReference pageRef = Page.AdobeSignVOI;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);

		pageRef = ext.redirect();

		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_ORG_MISSING_CONTACT)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
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
		PageReference pageRef = new PageReference('/apex/something');
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);

		pageRef = ext.redirect();

		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_PAGE_NOT_SUPPORTED)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToVOIAgreementPageNotSupportedTest : source url should not be supported'
		);
	}

	/**
	 * Testing of generic error message.
	 */
	@IsTest
	static void navigateToAgreementPageGenericErrorTest() {
		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = null;
		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);

		pageRef = ext.redirect();

		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_PAGE_GENERIC)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToVOIAgreementPageGenericErrorTest : Generic error message is expected'
		);
	}

	/**
	 * Testing of apptus contract redirection based on the VF page
	 */
	@IsTest
	static void navigateToApptusAgreementPageTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = 'aF21m0000008OgcCAE';

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
		MockUtility.Mocks.when(apttusContractSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(mockApttusContractMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = Page.AdobeSignApttus;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(apttusContract);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.redirect();

		Test.stopTest();

		System.assertEquals(
				apttusContract.Id,
				pageRef.getParameters().get('masterId'),
				'navigateToApptusAgreementPageTest : master id should be set to parameters'
		);
	}

	/**
	 * Testing of apptus contract redirection based on the VF page with an expired contract
	 * should throw the missing contract error message
	 */
	@IsTest
	static void navigateToApptusAgreementPageOnExpiredContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = 'aF21m0000008OgcCAE';

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
		Test.startTest();
		PageReference pageRef = Page.AdobeSignApttus;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(apttusContract);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.redirect();

		Test.stopTest();

		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_APT_CONTRACT_EXPIRED)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToApptusAgreementPageOnExpiredContractTest : Error message should be thrown as The contract has expired'
		);
	}

	/**
	 * Testing of apptus contract missing error message
	 */
	@IsTest
	static void navigateToApptusAgreementMissingContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting
		AdobeSignTemplateSettings__c voiPropertySettings = new AdobeSignTemplateSettings__c();
		voiPropertySettings.Name = AdobeSignCustomController.TEMPLATE_APTTUS;
		voiPropertySettings.TemplateId__c = 'aF21m0000008OgcCAE';

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

		PageReference pageRef = Page.AdobeSignApttus;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController ctrl = new ApexPages.StandardController(apttusContract);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.redirect();

		Test.stopTest();

		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_APT_MISSING_CONTRACT)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToApptusAgreementMissingContractTest : Contract missing error should be displayed'
		);
	}

	/**
	 * Testing of cancel apptus agreement success scenario
	 */
	@IsTest
	static void CancelApptusAgreementPageTest() {
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
		PageReference pageRef = Page.AdobeSignApttusCancel;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(agreements[0]);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.cancelAgreement();

		Test.stopTest();

		System.assertEquals(
				agreements[0].Id,
				pageRef.getParameters().get('id'),
				'CancelApptusAgreementPageTest : id should be set to parameters'
		);

		System.assertEquals(
				'1',
				pageRef.getParameters().get('sfdc.override'),
				'CancelApptusAgreementPageTest : sfdc.override should be set to parameters'
		);

		System.assertEquals(
				'cancel',
				pageRef.getParameters().get('onLoadAction'),
				'CancelApptusAgreementPageTest : onLoadAction should be set to parameters'
		);
	}

	/**
	 * Testing of cancel Apptus agreement contract not found error message
	 */
	@IsTest
	static void cancelApptusAgreementMissingContractTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// create contract related records
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, true);
		Account account = accountList[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

		// create contract
		List<Apttus__APTS_Agreement__c> apttusContracts = ApplicationTestDataFactory.getApttusContracts(2, primaryContact.Id, opportunityRecord.Id, true);
		// create agreement to pass to controller
		echosign_dev1__SIGN_Agreement__c  agreement1 = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForAccount(1, account.Id, true)[0];

		// =====================================
		// Stubbing not required
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = Page.AdobeSignApttusCancel;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController ctrl = new ApexPages.StandardController(agreement1);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);
		pageRef = ext.cancelAgreement();

		Test.stopTest();

		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_APT_MISSING_CONTRACT)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'CancelApptusAgreementMissingContractTest : Contract missing error should be displayed'
		);
	}

	/**
	 * Testing of fall trough error messages from not supported source urls for Cancel Apptus agreement
	 */
	@IsTest
	static void navigateToCancelApptusAgreementPageNotSupportedTest() {
		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = new PageReference('/apex/something');
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);

		pageRef = ext.cancelAgreement();

		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_PAGE_NOT_SUPPORTED)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToCancelApptusAgreementPageNotSupportedTest : source url should not be supported'
		);
	}

	/**
	 * Testing of generic error message for cancel apptus agreement.
	 */
	@IsTest
	static void navigateToCancelApptusAgreementPageGenericErrorTest() {
		// create an organisation record
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PageReference pageRef = null;
		ApexPages.StandardController ctrl = new ApexPages.StandardController(organisation);
		AdobeSignCustomController ext = new AdobeSignCustomController(ctrl);

		pageRef = ext.cancelAgreement();

		Test.stopTest();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		Boolean errorMessageFound = false;
		for (ApexPages.Message message : pageMessages) {
			if (message.getSummary().contains(AdobeSignCustomController.MSG_ERROR_PAGE_GENERIC)) {
				errorMessageFound = true;
				break;
			}
		}

		System.assertEquals(
				true,
				errorMessageFound,
				'navigateToCancelApptusAgreementPageGenericErrorTest : Generic error message is expected'
		);
	}
}