/**************************************************
Description:    \Test class to cover bspBase
History:
--------------------------------------------------
2019-04-28 nathan.franklin@auspost.com.au Created
**************************************************/
@isTest
public class bspBase_Test {


	@testSetup
	public static void testSetup(){

		Id deliveryEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId();
		Id ssswGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWGeneralEnquiry').getRecordTypeId();
		Id ssswDeliveryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SSSWDelivery').getRecordTypeId();

		CCUSettings__c setting = new CCUSettings__c(
			// startrack
			Exclude_case_types__c = 'LDC',
			StarTrackAsyncWebServiceTimeout__c = 10,
			BSPSyncConsignmentSearchTimeout__c = 5,
			Exclude_Case_Purpose__c = 'Controlled Returns',

			// ap
			IncludedRecordTypes__c = 'SSSW%',
			EmailMsgKeyword__c = '%customerservice%',
			Max_Length_for_Consignment_Number__c = 40,
			Pickup_Booking_Ref_Number_Max_Length__c = 8,
			Pickup_Booking_Ref_Number_Min_Length__c = 7,
			DeliveryRecordTypeId__c = ssswDeliveryRecordTypeId,
			GeneralRecordTypeId__c = ssswGeneralRecordTypeId,
			APSyncWebServiceTimeout__c = 5,
			AusPostAsyncWebServiceTimeout__c = 10,
			UseContinuationforAPConsignSearch__c = true,
			DoNotShowFileNames__c = 'CN08-',
			APConsignmentSearchSourceSystemID__c = 'SFDC_BSP',

			// general
			MaxEnquiryRecords__c = 500,
			EnquiriesPerPage__c = 15,
			BSPCaseStatusList__c = 'In Progress,Action Required,Resolved,Closed',
			CCUCommunityUserProfileId__c = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id,
			AdminCaseSubject__c = 'Enterprise Contact Registration'
		);
		insert setting;

//		Account defaultAcc = TestDataProvider.createAccount('Test Account', 1)[0];
//		defaultAcc.Legacy_Id__c = '60000000';
//		insert defaultAcc;

		Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
		testAccount.Business_Solutions_Customer__c = true;
		testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
		testAccount.ServiceSLA__c = 'Enterprise';
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		update testAccount;

		List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 4, new List<Account>{testAccount});
		testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[0].LEGACY_ID__c = 'P123456';
		testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
		testBillingAccList[1].LEGACY_ID__c = 'P223456';
		testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[2].LEGACY_ID__c = 'P323456';
		testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
		testBillingAccList[3].LEGACY_ID__c = 'P423456';
		Database.insert(testBillingAccList);

		// create an article for each billing account
		// list<Billing_Account__c> not used lol
		List<Article__c> articles = TestDataProvider.createArticle('test subject', 4, new list<Billing_Account__c>());
		articles[0].Billing_Account__c = testBillingAccList[0].Id;
		articles[1].Billing_Account__c = testBillingAccList[1].Id;
		articles[2].Billing_Account__c = testBillingAccList[2].Id;
		articles[3].Billing_Account__c = testBillingAccList[3].Id;
		insert articles;

		Contact newCon = new Contact(FirstName = 'Nathan', LastName = 'Franklin', MobilePhone = '0400000000', Email = 'mytestemail@testingemails.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Status__c = 'Active');
		Database.insert(newCon);


		// BAM Specific functionality
		// creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
		Product2 bspProduct = new Product2(Name = 'BSP');
		insert bspProduct;

		BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
		insert app;

		List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{
				new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'),
				new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'),
				new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')
		};
		insert appRoles;

		// insert a group for the account
		BAMGroup__c grp = new BAMGroup__c(Organisation__c = testAccount.Id, Status__c = 'Active');
		insert grp;

		// connect some billing accounts to the BAM group so they can be surfaced in BSP
		List<BAMGroupBillingAccount__c> groupBillingAccounts = new List<BAMGroupBillingAccount__c> {
			new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = testBillingAccList[0].Id),
			new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = testBillingAccList[1].Id)
		};
		insert groupBillingAccounts;

		// add the BSP asset to the customer to ensure BSP is enabled
		Asset bspAsset = new Asset(Product2Id = bspProduct.Id, AccountId = testAccount.Id, Name = 'BSP', Status = 'Active');
		insert bspAsset;

		// create cases for verification
		List<Case> newCases = new List<Case>();

		// ST case
		Case newCase = new Case(Subject = 'Case 1', BSP_Addressee_Name__c = 'David 1', Related_Billing_Account__c = testBillingAccList[0].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'High', Status = 'New');
		newCases.add(newCase);

		// ap case
		newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswDeliveryRecordTypeId);
		newCase.ProductCategory__c = 'Domestic Letters';
		newCase.Related_Billing_Account__c = testBillingAccList[1].Id;
		newCases.add(newCase);

		// st case
		newCases.add(new Case(Subject = 'Case 3', BSP_Addressee_Name__c = 'David 3', Related_Billing_Account__c = testBillingAccList[2].Id, AccountId = testAccount.Id, RecordTypeId = deliveryEnquiryRecordTypeId, Priority = 'Low', Status = 'New'));

		// ap case
		newCase = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', testAccount.Id, null, ssswDeliveryRecordTypeId);
		newCase.ProductCategory__c = 'Domestic Letters';
		newCase.Related_Billing_Account__c = testBillingAccList[3].Id;
		newCases.add(newCase);

		Database.insert(newCases);

	}

	/********************************************************************************
	 * Scenario:
	 *
	 * Testing access roles. This test will create data for multiple roles against a single Contact Application.
	 * This isn't technically a real world scenario, but the architecture has been designed in such a way to enable multiple roles if the use case arises
	 * BSP already supports the use of multiple roles and this test will confirm that
	 ********************************************************************************/
	public static testMethod void testBillingAccountAccessRoles() {
		// BillingAccount__c is set to a TEAM billing account in @testSetup
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// grab the cases so we can verify the user has access to them or not
		List<Case> cases = [Select Id, AccountId, Related_Billing_Account__c, Related_Billing_Account__r.LEGACY_ID__c, Related_Billing_Account__r.Id, Related_Billing_Account__r.Organisation__c, ContactId, CreatedById, Contact.BillingAccount__c From Case];
		Map<String, Case> billingAccountCaseMap = new Map<String, Case>();
		for (Case c : cases) {
			billingAccountCaseMap.put(c.Related_Billing_Account__r.LEGACY_ID__c, c);
		}

		// grab the articles so we can verify access
		// drop in a billing account map for easier verification
		List<Article__c> articles = [Select Id, Billing_Account__c, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Organisation__c From Article__c];
		Map<String, Article__c> billingAccountArticleMap = new Map<String, Article__c>();
		for (Article__c article : articles) {
			billingAccountArticleMap.put(article.Billing_Account__r.LEGACY_ID__c, article);
		}

		Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];
		BAMApplicationRole__c bspUserRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'User'];
		BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

		// this group has billing accounts assigned in Test Setup (P123456, P223456)
		BAMGroup__c grp = [Select Id From BAMGroup__c LIMIT 1];

		// populate all the billing accounts we will need to use in this test
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug(billingAccounts);

		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;

		// wee need to assign some roles with billing accounts to the contact to test their access
		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
				new BAMContactRole__c(ApplicationRole__c = bspAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active'),
				new BAMContactRole__c(ApplicationRole__c = bspUserRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
		};
		insert contactRoles;

		// add some linked entities to the contact role
		// this should add the following accounts:
		//  P123456: Admin (from billing account)
		//  P323456: Admin (from billing account)
		//  P223456: User (from group)
		List<BAMLinkedEntity__c> entities = new List<BAMLinkedEntity__c>{
				new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P123456').Id, Status__c = 'Active'),
				new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P323456').Id, Status__c = 'Active'),
				new BAMLinkedEntity__c(ContactRole__c = contactRoles[1].Id, Group__c = grp.Id, Status__c = 'Active') // <-- grp = P123456 / P223456
		};
		insert entities;

		System.Debug(entities);

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			bspBase controller = new bspBase();

			// special flag to make the controller think we are dealing with BSP community
			controller.currentNetworkId = bspCommunity.Id;

			Map<Id, bspBase.AccessRule> billingAccountAccessRuleMap = new Map<Id, bspBase.AccessRule>();
			List<bspBase.AccessRule> accessRules = controller.accessRules;
			System.debug(accessRules);

			// put the access rules into a map so we can verify the data
			for (bspBase.AccessRule rule : accessRules) {
				billingAccountAccessRuleMap.put(rule.entity.Id, rule);
			}

			// verify billing accounts all have the correct role
			System.assertEquals('Admin', billingAccountAccessRuleMap.get(billingAccounts.get('P123456').Id).roleName);
			System.assertEquals('Admin', billingAccountAccessRuleMap.get(billingAccounts.get('P323456').Id).roleName);

			// from the group configuration...
			// NOTE: the billing account P123456 in the group will be overridden by the BA defined in the 'admin' role
			System.assertEquals('User', billingAccountAccessRuleMap.get(billingAccounts.get('P223456').Id).roleName);

			// there should only be 3 access rules defined
			System.assertEquals(3, accessRules.size());

			// should only have access to 3 billing accounts
			System.assertEquals(3, controller.accessibleBillingAccounts.size());

			// should only have access to 3 billing accounts
			Map<String, Id> baNumbers = controller.accessibleBillingAccNumbers;
			System.assert(baNumbers.containsKey('P123456'));
			System.assert(baNumbers.containsKey('P323456'));
			System.assert(baNumbers.containsKey('P223456'));

			// test which of these rules belongs to which side of the business
			List<bspBase.AccessRule> stRules = controller.stBillingAccountsAccessRules;
			System.assertEquals(2, stRules.size());

			// validate st rules
			billingAccountAccessRuleMap = new Map<Id, bspBase.AccessRule>();
			billingAccountAccessRuleMap.put(stRules[0].entity.Id, stRules[0]);
			billingAccountAccessRuleMap.put(stRules[1].entity.Id, stRules[1]);
			System.assert(billingAccountAccessRuleMap.containsKey(billingAccounts.get('P123456').Id));
			System.assert(billingAccountAccessRuleMap.containsKey(billingAccounts.get('P323456').Id));

			List<bspBase.AccessRule> apRules = controller.apBillingAccountsAccessRules;
			System.assertEquals(1, apRules.size());

			// validate ap rules
			billingAccountAccessRuleMap = new Map<Id, bspBase.AccessRule>();
			billingAccountAccessRuleMap.put(apRules[0].entity.Id, apRules[0]);
			System.assert(billingAccountAccessRuleMap.containsKey(billingAccounts.get('P223456').Id));

			// role based property verification
			Map<String, Set<Id>> billingAccountRoles = controller.roleBasedAccessRules;
			System.assertEquals(2, billingAccountRoles.get('Admin').size());
			System.assertEquals(1, billingAccountRoles.get('User').size());

			// confirm canSearchAllConsignments has been set correctly (Defined in ContactApplication__c)
			System.assert(controller.canSearchAllConsignments);

			// make sure we are in the context of BSP
			System.assertEquals(false, controller.isMpbHspFlag);

			//verify misc attributes
			System.assertEquals(con.Id, controller.loginContactId);
			System.assertEquals(con.AccountId, controller.loginAccountId);
			System.assertEquals(con.BillingAccount__c, controller.loginBillingAccountId);
			System.assertEquals('P123456', controller.primaryBillingAccountNumber);
			System.assertEquals('TEAM', controller.primaryBillingAccountSource);
			System.assertEquals(u.Id, controller.loginUserId);
			System.assert(controller.isEnterprise);

			// primary billing account is an ST billing account so this should be false
			System.assertEquals(false, controller.isAPUser);

			// primary billing account is ST so this should return true
			System.assertEquals(true, controller.isSTUser);

			// verify article access (first check all articles should be accessible in authenticated because the canSearchAllConsignments returns true)
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P123456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P223456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P323456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P423456')));

			// verify article access - articles belonging to BA P423456 should be inaccessible since we are not factoring in the canSearchAllConsignments flag
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P123456'), false));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P223456'), false));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P323456'), false));
			System.assertEquals(false, controller.isArticleAccessible(billingAccountArticleMap.get('P423456'), false)); // <-- should be false


			// verify case level access

			// access via the 'Admin' role
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P123456')));

			// permissions to this case is given by the Group which is linked to the 'User' role
			// since the user didn't raise the case, they can't see this one
			System.assertEquals(false, controller.isCaseAccessible(billingAccountCaseMap.get('P223456')));


			// access via the 'Admin' role
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P323456')));

			// should be false since the user has no access to this billing account
			System.assertEquals(false, controller.isCaseAccessible(billingAccountCaseMap.get('P423456')));

			Map<String, Set<Id>> roleMap = bspBase.getLinkedEntitiesByRole(controller.accessRules);
			System.assertEquals(2, roleMap.keySet().size());

			// no need to verify these since they are being read directly from a custom setting
			Object o = controller.excludeSubject;
			o = controller.onlyRecordTypes;
			o = controller.excludecaseTypes;
			o = controller.excludecaseTypeslist;
			o = controller.excludecasePurpose;
			o = controller.excludecasePurposelist;
			o = controller.successMessage;
			o = controller.fileSizeLimit;
			o = controller.fileSizeLimitInteger;
			o = controller.emailKeyword;
			o = controller.doNotShowFile;
			o = controller.hasSTBillingAccounts;
			o = controller.hasAPBillingAccounts;


		}

		Test.stopTest();

	}

	/********************************************************************************
	 * Scenario:
	 *
	 * When a user logs in via CSSO, we enforce the BAM authorisation rules at a higher level where we check for basic things like Contact status etc...
	 * We don't do this if the user is logging in normally to maintain backwards compatability.
	 ********************************************************************************/
	public static testMethod void testCSSOLoginRuleEnforcement() {
		// BillingAccount__c is set to a TEAM billing account in @testSetup
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;

		// we need to assign some roles with billing accounts to the contact to test their access
		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
				new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
		};
		insert contactRoles;

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			bspBase controller = new bspBase();

			// overriding default behaviour since Auth.SessionManagement is not available when testing
			controller.isCSSOLogin = true;

			// make sure no redirect to error page occurs (should return empty page ref)
			PageReference output = controller.preValidateBamBspAccess();
			System.assertEquals(null, output);

		}

		Test.stopTest();
	}

	/********************************************************************************
	 * Scenario:
	 *
	 * When a user logs in via CSSO, we enforce the BAM authorisation rules at a higher level where we check for basic things like Contact status etc...
	 * In this scenario the prevalidate should return an error
	 * We don't do this if the user is logging in normally to maintain backwards compatability.
	 ********************************************************************************/
	public static testMethod void testCSSOLoginRuleEnforcementFailure() {
		// BillingAccount__c is set to a TEAM billing account in @testSetup
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// mark the contact is inactive to trigger the prevalidate error
		con.Status__c = 'Inactive';
		update con;

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;

		// we need to assign some roles with billing accounts to the contact to test their access
		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
				new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
		};
		insert contactRoles;

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			bspBase controller = new bspBase();

			// overriding default behaviour since Auth.SessionManagement is not available when testing
			controller.isCSSOLogin = true;

			// make sure the redirect to the error page occurs informing us that the prevalidate failed
			PageReference output = controller.preValidateBamBspAccess();
			System.assertNotEquals(null, output);

		}

		Test.stopTest();
	}

	/********************************************************************************
	 * Scenario:
	 *
	 * When a user has super admin access they should be able to complete all activities on the account/case.
	 ********************************************************************************/
	public static testMethod void testSuperAdminAccess() {
		// BillingAccount__c is set to a TEAM billing account in @testSetup
		Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];

		// grab the cases so we can verify the user has access to them or not
		List<Case> cases = [Select Id, AccountId, Related_Billing_Account__c, Related_Billing_Account__r.LEGACY_ID__c, Related_Billing_Account__r.Id, Related_Billing_Account__r.Organisation__c, ContactId, CreatedById From Case];
		Map<String, Case> billingAccountCaseMap = new Map<String, Case>();
		for (Case c : cases) {
			billingAccountCaseMap.put(c.Related_Billing_Account__r.LEGACY_ID__c, c);
		}

		// grab the articles so we can verify access
		// drop in a billing account map for easier verification
		List<Article__c> articles = [Select Id, Billing_Account__c, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Organisation__c From Article__c];
		Map<String, Article__c> billingAccountArticleMap = new Map<String, Article__c>();
		for (Article__c article : articles) {
			billingAccountArticleMap.put(article.Billing_Account__r.LEGACY_ID__c, article);
		}

		Network bspCommunity = [Select UrlPathPrefix From Network Where UrlPathPrefix = 'bsp'];

		// grab the application roles for BSP so we can assign them to the user
		BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
		BAMApplicationRole__c bspSuperAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Super Admin'];

		// populate all the billing accounts we will need to use in this test
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
		Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
		System.debug(billingAccounts);

		BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = true, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
		insert contactApplication;

		// wee need to assign some roles with billing accounts to the contact to test their access
		List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
				new BAMContactRole__c(ApplicationRole__c = bspSuperAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
		};
		insert contactRoles;

		User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');


		Test.startTest();

		System.runAs(u) {

			bspBase controller = new bspBase();

			// special flag to make the controller think we are dealing with BSP community
			controller.currentNetworkId = bspCommunity.Id;

			Map<Id, bspBase.AccessRule> billingAccountAccessRuleMap = new Map<Id, bspBase.AccessRule>();
			List<bspBase.AccessRule> accessRules = controller.accessRules;
			System.debug(accessRules);

			// put the access rules into a map so we can verify the data
			for (bspBase.AccessRule rule : accessRules) {
				billingAccountAccessRuleMap.put(rule.entity.Id, rule);
			}

			// verify billing accounts all have the correct role
			System.assertEquals('Super Admin', billingAccountAccessRuleMap.get(con.AccountId).roleName);

			// verify article access, should have access to all
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P123456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P223456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P323456')));
			System.assertEquals(true, controller.isArticleAccessible(billingAccountArticleMap.get('P423456')));

			// verify case level access
			// access to all these cases via the 'Super Admin' role
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P123456')));
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P223456')));
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P323456')));
			System.assertEquals(true, controller.isCaseAccessible(billingAccountCaseMap.get('P423456')));
		}

		Test.stopTest();
	}

	private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
		Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
		for(Billing_Account__c billingAccount : billingAccounts) {
			output.put(billingAccount.LEGACY_ID__c, billingAccount);
		}
		return output;
	}

}