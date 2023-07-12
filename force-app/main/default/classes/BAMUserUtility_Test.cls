/**
 * @description Test class that covers BAMUserUtility class
 * @author Nathan Franklin
 * @date 2019-05-13
 * @changelog
 * 2023-07-14 - Nathan Franklin - Fixing sm all bug in test class
 */
@isTest
private class BAMUserUtility_Test {

	public static Id bspProfileId = [Select Id From Profile Where Name = :BspConstants.BSP_COMMUNITY_PROFILE_NAME].Id;
	public static Id businessPortalProfileId = [Select Id From Profile Where Name = :BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME].Id;
	public static Id bspNetworkId = [Select Id From Network Where Name = 'AP Business Support Portal'].Id;
	public static Id merchantPortalNetworkId = [Select Id From Network Where Name = 'Australia Post Merchant Portal'].Id;

	@testSetup
	public static void setup() {
		MerchantPortalSettings__c settings = new MerchantPortalSettings__c();
		settings.NetworkId__c = merchantPortalNetworkId;
		settings.ContactOwnerUsername__c = 'apintegration@auspost.com.au';
		insert settings;


		List<Account> accounts = TestDataProvider.createAccount('BAM Test Account', 11);
		insert accounts;

		accounts[0].LEGACY_ID__c = '60000000';
		update accounts[0];

		List<Contact> contacts = new List<Contact>();
		for(Integer i=0;i<accounts.size();i++) {
			Contact con = TestDataProvider.createContact('Contact 1', accounts[i].Id, null);
			con.FirstName = 'Contact ' + i;
			con.LastName = 'Contact ' + i;
			con.Status__c = 'Active';
			contacts.add(con);
		}

		// set the cnumber of the contacts used for testing
		contacts[0].OID_ID__c = '12345'; // group 1
		contacts[1].OID_ID__c = '12345'; // group 1
		contacts[2].OID_ID__c = '12345'; // group 1
		contacts[3].OID_ID__c = '12345'; // group 1
		contacts[4].OID_ID__c = '12345'; // group 1
		contacts[5].OID_ID__c = '56789'; // group 2
		contacts[6].OID_ID__c = '56789'; // group 2
		contacts[7].OID_ID__c = '56789'; // group 2
		contacts[8].OID_ID__c = '56789'; // group 2
		contacts[9].OID_ID__c = '35263'; // group 3
		contacts[10].OID_ID__c = '35263'; // group 3
		insert contacts;

		// connect associated users for some of the contacts only
		// we will use this as a part of our persona testing
		//NOTE: Elements 4,5 and 9 DO NOT have user records associated to them
		List<User> users = new List<User>();

		// contacts[0] is bsp community
		users.add(TestUtility.createPortalUser('Testing0', bspProfileId, contacts[0].Id));

		// contacts[1] is business portal community
		users.add(TestUtility.createPortalUser('Testing1', businessPortalProfileId, contacts[1].Id));

		// contacts[2] is bsp community
		users.add(TestUtility.createPortalUser('Testing2', bspProfileId, contacts[2].Id));

		// contacts[3] is bsp community (Active false) - set below after permission set assignment
		User inactiveUser = TestUtility.createPortalUser('Testing3', bspProfileId, contacts[3].Id);
		inactiveUser.IsActive = false;
		users.add(inactiveUser);

		// contacts[6] is bsp community
		users.add(TestUtility.createPortalUser('Testing6', bspProfileId, contacts[6].Id));

		// contacts[7] is bsp community
		users.add(TestUtility.createPortalUser('Testing7', bspProfileId, contacts[7].Id));

		// contacts[8] is business portal community
		users.add(TestUtility.createPortalUser('Testing8', businessPortalProfileId, contacts[8].Id));

		// contacts[9] is business portal community
		// inactive
		inactiveUser = TestUtility.createPortalUser('Testing9', businessPortalProfileId, contacts[9].Id);
		inactiveUser.IsActive = false;
		users.add(inactiveUser);

		insert users;

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 * Test that the correct persona's are returned for BSP Community. This persona returned will be based on the testSetup above
	 ****************************************************/
	public static testMethod void testBspPersonaList() {

		System.debug('TEST: testBspPersonaList: START');

		// grab a list of personas for BSP community
		// grab any of the contacts that have a BSP user attached to them that is active
		User u = [Select Id From User Where Contact.OID_ID__c = '12345' And IsActive = true And ProfileId = :bspProfileId Limit 1];

		Test.startTest();

		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility('12345', bspNetworkId);
		List<BAMUserUtility.UserPersona> personas = personaUtility.personas.values();

		Test.stopTest();

		// verify that the number of persona returned was 2.
		// for BSP, this will include:
		//  all active BSP community users
		// all this is obviously based on the CNumber matching.
		System.assertEquals(2, personas.size(), 'Incorrect Number of Personas Returned.');

		// verify that the actual personas returned are correct
		List<Id> contactIds = new List<Id>{personas[0].contactId, personas[1].contactId};
		Set<String> namesofValidPersonas = new Set<String>{'Contact 0', 'Contact 2'}; // from the testSetup values above
		for(Contact con : [Select FirstName From Contact Where Id in :contactIds]) {
			System.assertEquals(true, namesofValidPersonas.contains(con.FirstName), 'Incorrect Personas Returned.');
		}

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 * Test that the correct persona's are returned for Business Community. This persona returned will be based on the testSetup above
	 ****************************************************/
	public static testMethod void testBusinessPortalPersonaList() {

		System.debug('TEST: testBusinessPortalPersonaList: START');

		Test.startTest();

		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility('12345', merchantPortalNetworkId);
		List<BAMUserUtility.UserPersona> personas = personaUtility.personas.values();

		Test.stopTest();

		// verify that the number of persona returned was 3.
		// for business portal, this will include:
		//  all active and inactive business portal users
		//  any active MPB or BSP community users
		// all this is obviously based on the CNumber matching.
		System.assertEquals(3, personas.size(), 'Incorrect Number of Personas Returned.');

		// verify that the actual personas returned are correct
		List<Id> contactIds = new List<Id>{personas[0].contactId, personas[1].contactId, personas[2].contactId};
		Set<String> namesofValidPersonas = new Set<String>{'Contact 0', 'Contact 1', 'Contact 2'}; // from the testSetup values above
		for(Contact con : [Select FirstName From Contact Where Id in :contactIds]) {
			System.assertEquals(true, namesofValidPersonas.contains(con.FirstName), 'Incorrect Personas Returned.');
		}

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 * This will test that a BSP comnmunity user can be switched to another persona of the same individual (matching CNumber's)
	 ****************************************************/
	public static testMethod void testPersonaSwitch() {

		System.debug('TEST: testPersonaSwitch: START');

		User switchUser = [Select Id
								From User
								Where Contact.OID_ID__c = '56789'
								And IsActive = true
								And ProfileId = :bspProfileId
								And Contact.FirstName = 'Contact 7'
								Limit 1];

		Test.startTest();

		BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility('56789', merchantPortalNetworkId);

		// switch the federation id to the new persona the user wants to switch to.
		// Salesforce forces the use of federation id when using Login handlers, hence the need to set the handler
		personaUtility.switchPersona(switchUser.Id);

		Test.stopTest();

		// verify that the federation was updated successfully
		switchUser = [Select Id, FederationIdentifier From User Where Id = :switchUser.Id];
		System.assertEquals(personaUtility.getPersonaFormat(), switchUser.FederationIdentifier, 'The persona was not switched correctly.');

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 * Test that the logged in user only has access to their own personas (contacts with the same CNumber)
	 ****************************************************/
	public static testMethod void testBusinessPortalPersonaListUserContext() {

		System.debug('TEST: testBusinessPortalPersonaListUserContext: START');

		// grab a list of personas for BSP community
		List<BAMUserUtility.UserPersona> personas;
		User u = [Select Id From User Where Contact.OID_ID__c = '12345' And IsActive = true And ProfileId = :businessPortalProfileId Limit 1];
		System.runAs(u) {

			Test.startTest();

			BAMUserUtility.BAMPersonaSwitchUtility personaUtility = new BAMUserUtility.BAMPersonaSwitchUtility(Id.valueOf(UserInfo.getUserId()), merchantPortalNetworkId);
			personas = personaUtility.personas.values();

			Test.stopTest();

			// verify that the number of persona returned was 3.
			// for business portal, this will include:
			//  all active and inactive business portal users
			//  any active MPB or BSP community users
			// all this is obviously based on the CNumber matching.
			System.assertEquals(3, personas.size(), 'Incorrect Number of Personas Returned.');
		}

		// verify that the actual personas returned are correct
		List<Id> contactIds = new List<Id>{personas[0].contactId, personas[1].contactId, personas[2].contactId};
		Set<String> namesofValidPersonas = new Set<String>{'Contact 0', 'Contact 1', 'Contact 2'}; // from the testSetup values above
		for(Contact con : [Select FirstName From Contact Where Id in :contactIds]) {
			System.assertEquals(true, namesofValidPersonas.contains(con.FirstName), 'Incorrect Personas Returned.');
		}

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 * Test All the methods relating to BAM Data rules
	 ****************************************************/
	public static testMethod void testBAMDataRules() {

		System.debug('TEST: testBAMDataRules: START');

		User u = [Select Id, ContactId, Contact.AccountId From User Where Contact.OID_ID__c = '12345' And IsActive = true And ProfileId = :businessPortalProfileId Limit 1];

		BAMApplication__c app = BAMTestUtility.createBamApplication('BSP');
		System.debug(app);
		insert app;

		Asset accAsset = BAMTestUtility.createAsset(u.Contact.AccountId, app.Product__c, true);
		insert accAsset;

		BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
		insert appRole;

		Billing_Account__c billingAccount = BAMTestUtility.createTestBillingAccount(u.Contact.AccountId, 'Test Billing Account');
		insert billingAccount;

		BAMGroup__c grp = BAMTestUtility.createTestGroup(u.Contact.AccountId);
		insert grp;

		BAMGroupBillingAccount__c grpBillingAccount = BAMTestUtility.createTestGroupBillingAccount(grp.Id, billingAccount.Id);
		insert grpBillingAccount;

		BAMContactApplication__c contactApp = BAMTestUtility.createTestContactApplication(u.ContactId, app.Id);
		insert contactApp;

		BAMContactRole__c contactRole = BAMTestUtility.createTestContactRole(contactApp.Id, appRole.Id);
		insert contactRole;

		BAMLinkedEntity__c linkedEntity = BAMTestUtility.createTestLinkedEntity(contactRole.Id, grp.Id, 'grp');
		insert linkedEntity;

		Test.startTest();

		System.assertEquals(1, BAMUserUtility.getGroups(new Set<Id>{grp.Id}, u.Contact.AccountId).size());
		System.assertEquals(1, BAMUserUtility.getContactApplicationConfig(u.ContactId).size());
		System.assertNotEquals(null, BAMUserUtility.getContactApplicationConfig(u.ContactId, 'BSP'));
		System.assertNotEquals(null, BAMUserUtility.getUserContact(u.Id));
		System.assertEquals(true, BAMUserUtility.contactApplicationIsActive(contactApp));
		System.assertEquals(true, BAMUserUtility.contactApplicationIsActive(contactApp));
		System.assertEquals(false, BAMUserUtility.contactApplicationIsPendingProvision(contactApp));
		System.assertEquals(1, BAMUserUtility.getApplicationRolesForAccount(u.Contact.AccountId).size());
		System.assertNotEquals(null, BAMUserUtility.retrieveContactUserDetail(u.ContactId));

		// check current user doesn't have access to call BAM API
		System.runAs(u) {
			System.assertEquals(false, BAMUserUtility.currentUserHasBAMApiAccess());
		}

		Test.stopTest();

	}

	/**
	 * Ensures that the JIT Login handler returns the correct persona
	 */
	public static testMethod void testJitLoginHandler() {

		System.debug('TEST: testJitLoginHandler: START');

		Test.startTest();

		// this should cause an update of the fed id on one the user records
		BAMJitLoginHandler handler = new BAMJitLoginHandler();
		handler.createUser(null, bspNetworkId, bspNetworkId, '12345.merchant', new Map<String, String>{'https://saml.auspost.com.au/core/attributes/cnumber' => '12345'}, '');

		// grab a list of personas for BSP community
		// grab any of the contacts that have a BSP user attached to them that is active
		// this should return 2 possible users (contacts[0] / contacts[2] above)
		Set<String> userFedIds = new Set<String>();
		for(User us : [Select Id, FederationIdentifier From User Where Contact.OID_ID__c = '12345' And IsActive = true And ProfileId = :bspProfileId]) {
			System.debug(us);
			userFedIds.add(us.FederationIdentifier);
		}

		// we check one of these to ensure the federation has been set
		System.assertEquals(true, userFedIds.contains(BAMUserUtility.formatMerchantPortalCNumber('12345')));

		// check updateUser for user activation
		// contacts[9]
		User us = [Select Id From User Where LastName = 'Testing9' And IsActive = false];
		us.FederationIdentifier = '35263.merchant';
		update us;

		handler.updateUser(us.Id, null, merchantPortalNetworkId, merchantPortalNetworkId, '35263.merchant', new Map<String, String>{'https://saml.auspost.com.au/core/attributes/cnumber' => '35263'}, '');

		// check to make sure the user account was activated
		us = [Select Id, IsActive From User Where LastName = 'Testing9'];
		System.assertEquals(true, us.IsActive);

		Test.stopTest();

	}
}