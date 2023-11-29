/**
 * @author Hasantha Liyanage
 * @date 2023-08-17
 * @group Test
 * @domain BSP
 * @description Controller apex test class the BSP Credit Claim component
 * @changelog
 * 2023-08-17 - Hasantha Liyanage - Created
 */

@IsTest
private class BSPCreditClaimController_Test {
	@TestSetup
	static void testBehavior() {
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		contact.FirstName = 'bspuser';
		insert contact;
		List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
		TestDataFactory.UserDTO bspUser = new TestDataFactory.UserDTO();
		bspUser.profileName = 'Merchant Portal Community User';
		bspUser.permissionSetNames = new Set<String>{'BSP_Community_Access'};
		bspUser.userName = 'BSPUserForCreditClaim';
		bspUser.role = '';
		bspUser.contactId = contact.Id;
		userDTOs.add(bspUser);

		TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
		System.enqueueJob(queueable);
	}

	/**
	 * Testing of dispute case creation as a community user
	 * This test is to check a successful creation of a case with a valid billing account number and disputed items
	 */
	@IsTest
	static void createCreditClaimSuccessTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// get a bsp context user
		User bspUser = [SELECT Id, ContactId, Contact.AccountId, AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
		// creating a custom setting for error message
		BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
		errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
		errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';

		// creating a case, Id is created as we need to use this for reference in after save
		Case cse = ApplicationTestDataFactory.getCases(1, true)[0];

		// billing account for the user
		Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountForBillingAccount.Id = bspUser.Contact.AccountId;

		// contact to check billing account for user
		Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, false)[0];
		contact.Id = bspUser.ContactId;
		cse.ContactId = contact.Id;
		cse.AccountId = accountForBillingAccount.Id;
		Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
				'Enterprise_Credit_Dispute_Claim'
		}).values()[0].Id;
		cse.RecordTypeId = creditDisputeCaseRecordTypeId;
		cse.Billing_Number__c = '123456';

		// related billing accounts
		List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
		billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
		billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
		billingAccountRecords[0].Legacy_ID__c = '123456';

		// disputed items to be created with the case
		List<Disputed_Item__c> disputedItems = ApplicationTestDataFactory.getDisputedItems(3, cse.Id, true);
		Map<Id, Disputed_Item__c> disputedItemsByIds = new Map<Id, Disputed_Item__c>();
		for (Disputed_Item__c disputedItem : disputedItems) {
			disputedItemsByIds.put(disputedItem.Id, disputedItem);
		}

		// =====================================
		// Stubbing
		// =====================================
		AssignmentRulesSelector mockAssignmentRulesSelector = (AssignmentRulesSelector) MockUtility.mockSelector(AssignmentRulesSelector.class);
		AssignmentRule ar = ApplicationTestDataFactory.getAssignmentRules(1, 'Case', true)[0];
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockAssignmentRulesSelector.selectActiveRulesBySObjectType('Case')).thenReturn(new Map<Id, AssignmentRule>{
				ar.Id => ar
		});

		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, BSPErrorMessages__c>{
						'Invalid Billing Account Credit Claim' => errorMessagesSettings
				});

		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
				new Set<Id>{
						accountForBillingAccount.Id
				})).thenReturn(
				new Map<Id, Billing_Account__c>{
						billingAccountRecords[0].Id => billingAccountRecords[0]
				}
		);

		String stJson = '{"success":true,"id":' +'"'+ cse.Id + '"'+ '}';
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize(stJson, Database.SaveResult.class);
		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenReturn(svResultList);
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cse.Id => cse});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BSPCreditClaimController.CreditClaimResponseWrapper wrapper;
		System.runAs(bspUser) {
			wrapper = BSPCreditClaimController.createCreditClaim(cse, null, disputedItems, new Map<Object,String>());
		}
		Test.stopTest();

		// make sure the dml is performed
		List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 2);

		System.assertEquals(
				Case.getSobjectType().getDescribe().getName(),
				insertedRecords[0][0].getSObjectType().getDescribe().getName(),
				'createCreditClaimSuccessTest : Make sure the case record is available after creation'
		);

		System.assertEquals(
				Disputed_Item__c.getSobjectType().getDescribe().getName(),
				insertedRecords[1][0].getSObjectType().getDescribe().getName(),
				'createCreditClaimSuccessTest : Make sure the Disputed_Item__c record is available after creation'
		);

		System.assertNotEquals(
				null,
				insertedRecords[0][0].get('Id'),
				'createCreditClaimSuccessTest : Case Id should be populated as it is created'
		);

		System.assertEquals(
				null,
				insertedRecords[0][0].get('Related_Billing_Account__c'),
				'createCreditClaimSuccessTest : Related_Billing_Account__c should not be populated when other account number field is populated'
		);

		System.assertEquals(
				bspUser.ContactId,
				insertedRecords[0][0].get('ContactId'),
				'createCreditClaimSuccessTest : ContactId should be populated'
		);

		System.assertEquals(
				bspUser.AccountId,
				insertedRecords[0][0].get('AccountId'),
				'createCreditClaimSuccessTest : ContactId should be populated'
		);

		System.assertEquals(
				creditDisputeCaseRecordTypeId,
				insertedRecords[0][0].get('RecordTypeId'),
				'createCreditClaimSuccessTest : RecordTypeId should be credit claim'
		);



		System.assertEquals(
				cse.Id,
				insertedRecords[1][0].get('Case__c'),
				'createCreditClaimSuccessTest : Disputed Items should be created against the case record'
		);
	}

	/**
	 * Testing of when there's an error the wrapper should throw the status error to the front end
	 */
	@IsTest
	static void createCreditClaimFailedTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// get a bsp context user
		User bspUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
		// creating a custom setting for error message
		BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
		errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
		errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
		// creating a case, Id is created as we need to use this for reference in after save
		Case cse = ApplicationTestDataFactory.getCases(1, true)[0];
		// billing account for the user
		Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountForBillingAccount.Id = bspUser.Contact.AccountId;
		// contact to check billing account for user
		Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, false)[0];
		contact.Id = bspUser.ContactId;
		cse.ContactId = contact.Id;
		cse.AccountId = accountForBillingAccount.Id;
		Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
				'Enterprise_Credit_Dispute_Claim'
		}).values()[0].Id;
		cse.RecordTypeId = creditDisputeCaseRecordTypeId;
		cse.Billing_Number__c = '12345612323'; // invalid billing account
		// related billing accounts
		List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
		billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
		billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
		billingAccountRecords[0].Legacy_ID__c = '123456';


		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, BSPErrorMessages__c>{
						'Invalid Billing Account Credit Claim' => errorMessagesSettings
				});
		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
				new Set<Id>{
						accountForBillingAccount.Id
				})).thenReturn(
				new Map<Id, Billing_Account__c>{
						billingAccountRecords[0].Id => billingAccountRecords[0]
				}
		);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BSPCreditClaimController.CreditClaimResponseWrapper wrapper;
		System.runAs(bspUser) {
			wrapper = BSPCreditClaimController.createCreditClaim(cse, null, null, new Map<Object,String>());
		}
		Test.stopTest();
		System.assertEquals('error', wrapper.Status, 'Expected Status of the case to be populated as error.');
	}

	/**
	 * Testing of isValidBillingAccount method,
	 * expecting an error message when an entered business account number is not found in database
	*/
	@IsTest
	static void isValidBillingAccountTestFailed() {
		// =====================================
		// Data Preparation
		// =====================================
		// creating a custom setting for error message
		BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
		errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
		errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, BSPErrorMessages__c>{
						'Invalid Billing Account Credit Claim' => errorMessagesSettings
				});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BSPCreditClaimController.BillingAccountsWrapper billingAccountsWrapper;
		billingAccountsWrapper = BSPCreditClaimController.isValidBillingAccount('');

		Test.stopTest();

		System.assertNotEquals(
				null,
				billingAccountsWrapper.message,
				'isValidBillingAccountTest : error message should return when the matching billing account is not available'
		);
	}

	/**
	 * Testing of isValidBillingAccount method,
	 * no error message is expected as the billing account number entered is valid
	*/
	@IsTest
	static void isValidBillingAccountTestSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		// get a bsp context user
		User bspUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
		// creating a custom setting for error message
		BSPErrorMessages__c errorMessagesSettings = new BSPErrorMessages__c();
		errorMessagesSettings.Name = 'Invalid Billing Account Credit Claim';
		errorMessagesSettings.Message__c = 'Invalid Billing Account Credit Claim';
		// creating a case, Id is created as we need to use this for reference in after save
		Case cse = ApplicationTestDataFactory.getCases(1, true)[0];
		// billing account for the user
		Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountForBillingAccount.Id = bspUser.Contact.AccountId;
		// contact to check billing account for user
		Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, false)[0];
		contact.Id = bspUser.ContactId;
		cse.ContactId = contact.Id;
		cse.AccountId = accountForBillingAccount.Id;
		Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
				'Enterprise_Credit_Dispute_Claim'
		}).values()[0].Id;
		cse.RecordTypeId = creditDisputeCaseRecordTypeId;
		cse.Billing_Number__c = '123456';
		// related billing accounts
		List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
		billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountForBillingAccount.Id, 'SAP ERP', true)[0]);
		billingAccountRecords[0].Organisation__c = accountForBillingAccount.Id;
		billingAccountRecords[0].Legacy_ID__c = '123456';
		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>) fflib_Match.anyObject()))
				.thenReturn(new Map<String, BSPErrorMessages__c>{
						'Invalid Billing Account Credit Claim' => errorMessagesSettings
				});
		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByOrgId(
				new Set<Id>{
						accountForBillingAccount.Id
				})).thenReturn(
				new Map<Id, Billing_Account__c>{
						billingAccountRecords[0].Id => billingAccountRecords[0]
				}
		);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BSPCreditClaimController.BillingAccountsWrapper billingAccountsWrapper;
		System.runAs(bspUser) {
			billingAccountsWrapper = BSPCreditClaimController.isValidBillingAccount('123456');
		}
		Test.stopTest();

		System.assertEquals(
				null,
				billingAccountsWrapper.message,
				'isValidBillingAccountTestSuccess : No error message expected when the entered account number is valid'
		);
	}

	/**
	* ensures the getSuperAdminRoles returns data, this is mostly to get the coverage as the actual selector class being tested properly
	*/
	@IsTest
	public static void getSuperAdminRolesTest() {
		// =====================================
		// Data Preparation
		// =====================================
		// get a bsp context user
		User bspUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
		// billing account for the user
		Account accountForBillingAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountForBillingAccount.Id = bspUser.Contact.AccountId;
		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
		//get BAM Applications
		BAMApplication__c application = ApplicationTestDataFactory.getBamApplications(1,'BAM',products[0].Id, true)[0];
		application.AppKey__c = 'BAM';
		// contact to check billing account for user
		Contact contact = ApplicationTestDataFactory.getContacts(1, accountForBillingAccount.Id, true)[0];
		contact.Status__c = 'Active';
		contact.email = 'something@gma.com';
		contact.firstName = 'firstName';

		BAMContactApplication__c contactApplication = ApplicationTestDataFactory.getBamContactApplications(1,contact.Id, application.Id, true)[0];
		contactApplication.Contact__r = contact;
		// contact tole
		BAMApplicationRole__c role = ApplicationTestDataFactory.getBamApplicationRoles(1,'Super Admin', application.Id, true)[0];

		BAMContactRole__c contactRole = ApplicationTestDataFactory.getBamContactRoles(1,role.Id, application.Id, true)[0];
		contactRole.ContactApplication__r = contactApplication;
		// =====================================
		// Stubbing
		// =====================================
		BAMContactRoleSelector mockBAMContactRoleSelector = (BAMContactRoleSelector) MockUtility.mockSelector(BAMContactRoleSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockBAMContactRoleSelector.selectRolesByRoleAndOrgId(
				(Set<String>)fflib_Match.anyObject(),
				(Set<Id>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject()))
				.thenReturn(new List<BAMContactRole__c>{
						contactRole
				});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<BSPCreditClaimController.RoleWrapper>  admins;
		System.runAs(bspUser) {
			admins = BSPCreditClaimController.getSuperAdminRoles();
		}
		Test.stopTest();

		System.assertNotEquals(
				0,
				admins.size(),
				'getSuperAdminRolesTest : ensures the getSuperAdminRoles returns data'
		);
	}

	/**
	 * Testing of case comments are created when other account number entered and the values are populated as expected in the body
	 */
	@IsTest
	private static void testBuildBillingAccountCaseCommentsIsOther() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Object, String> formData = new Map<Object,String>();
		formData.put('businessAccountNumber','123456');
		formData.put('isOther','true');
		String commentBody;

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		commentBody = BSPCreditClaimController.buildBillingAccountCaseComments(commentBody, formData);

		Test.stopTest();

		System.assertEquals(true, commentBody.contains('123456'), 'Expected case comments to be populated with 123456 but instead got something different.');
	}

	/**
	 * Testing of case comments are created when account number selected and the values are populated as expected in the body
	 */
	@IsTest
	private static void testBuildBillingAccountCaseCommentsIsSelected() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Object, String> formData = new Map<Object,String>();
		formData.put('businessAccountNumber','123456 - Star Track');
		formData.put('isOther','false');
		String commentBody;

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		commentBody = BSPCreditClaimController.buildBillingAccountCaseComments(commentBody, formData);

		Test.stopTest();

		System.assertEquals(true, commentBody.contains('123456 - Star Track'), 'Expected case comments to be populated with 123456 - Star Track but instead got something different.');
	}

	/**
	 * This method is responsible for testing and verifying the creation of case comments.
	 */
	@IsTest
	private static void testCreateCaseComments() {
		// =====================================
		// Data Preparation
		// =====================================
		// get a bsp context user
		User bspUser = [SELECT Id, ContactId, Contact.AccountId, AccountId FROM User WHERE FirstName = 'BSPUserForCreditClaim'];
		Map<Object, String> formData = new Map<Object,String>();
		formData.put('businessAccountNumber','123456 - Star Track');
		formData.put('isOther','false');
		Case cse = ApplicationTestDataFactory.getCases(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cse.Id => cse});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.runAs(bspUser) {
			BSPCreditClaimController.createCaseComments(formData, cse);
		}

		Test.stopTest();
		List<List<sObject>> insertedRecords = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 1);
		System.assertEquals(
				CaseComment.getSobjectType().getDescribe().getName(),
				insertedRecords[0][0].getSObjectType().getDescribe().getName(),
				'testCreateCaseComments : Case comment record should be created'
		);

		System.assertEquals(
				false,
				insertedRecords[0][0].get('IsPublished'),
				'testCreateCaseComments : Case comment should be private'
		);
	}
}