/**************************************************
Description: This class contains unit tests for validating the behavior of ResourceBamBspProvision and ResourceBamBspValidation

History:
2019-08-05  	nathan.franklin@auspost.com.au		Created.
*************************************/
@isTest
public class ResourceBamBsp_Test {

	@testSetup
	public static void setup() {
		Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
		testAccount.Business_Solutions_Customer__c = true;
		testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		update testAccount;

		// for linking to applications only
		Product2 prod = new Product2(Name = 'Test Generic Product');
		insert prod;

		// insert applications
		BAMApplication__c application = BAMTestUtility.createBamApplication('BSP', prod.Id);
		insert application;

		// insert 'Admin' role for each application
		BAMApplicationRole__c role = BAMTestUtility.createApplicationRole(application, 'Admin');
		// remove default values
		role.ShowOrganisation__c = false;
		insert role;

		// insert accounts
		// produce accounts like this: BAM1
		List<Account> accounts = TestDataProvider.createAccount('BSP', 1);
		insert accounts;

		List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[0]});
		testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
		testBillingAccList[0].LEGACY_ID__c = 'P123456';
		testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
		testBillingAccList[1].LEGACY_ID__c = 'P223456';
		Database.insert(testBillingAccList);

		// create contacts
		// C1230 is linked to account[0]
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < accounts.size(); i++) {
			Contact con = TestDataProvider.createContact('Contact', accounts[i].Id, null);
			con.FirstName = 'Contact ' + i;
			con.LastName = 'Contact ' + i;
			con.Status__c = 'Active';
			con.OID_ID__c = 'C123' + i;
			con.BillingAccount__c = testBillingAccList[0].Id;
			contacts.add(con);
		}
		insert contacts;

		// create the community user
		User testCommunityUser = createUser('ZCommunity', 'L1238User', 'community.user@merchant.com.us', 'Merchant Portal Community User', contacts[0].Id);
		insert testCommunityUser;

		User testUser = createUser('SSally', 'E721Saunders', 'sally.saunders@1sallysemporium.com.is', 'System Administrator', null);
		insert testUser;

		assignBAMPermissionSet(testUser.Id);

		// create contact for BSP deprovisioning
		Contact conBspDeprov = TestDataProvider.createContact('Contact', accounts[0].Id, null);
		conBspDeprov.FirstName = 'BSP Deprov';
		conBspDeprov.LastName = 'BSP Deprov';
		conBspDeprov.Status__c = 'Active';
		insert conBspDeprov;

		// create the community user
		User testBspCommunityUser = createUser('BSP', 'A2731Deprov', 'bspdeprovtest@sample.com', 'BSP Community User', conBspDeprov.Id);
		insert testBspCommunityUser;
	}

	static User createUser(String firstName, String lastName, String email, String profileName, Id contactId) {
		Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = :profileName];

		String usernameSuffix = String.valueOf(Integer.valueOf((Math.random() * 90)));
		User newUser = new User();
		newUser.ProfileId = sysAdmin.Id;
		newUser.FirstName = firstName;
		newUser.LastName = lastName;
		newUser.Username = lastName.left(4) + '@' + usernameSuffix + '.bsp';
		newUser.Email = email;
		newUser.CommunityNickname = lastName.left(4) + usernameSuffix;
		newUser.Alias = firstName.left(1) + lastName.left(4) + usernameSuffix;
		newUser.TimeZoneSidKey = 'Australia/Sydney'; // Required
		newUser.LocaleSidKey = 'en_AU'; // Required
		newUser.EmailEncodingKey = 'ISO-8859-1'; // Required
		newUser.LanguageLocaleKey = 'en_US'; // Required
		newUser.IsActive = true;
		if(contactId != null) newUser.ContactId = contactId;
		return newUser;
	}

	@future
	static void assignBAMPermissionSet(Id userId) {
		// assign the permission set
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'BAMIntegrationUserPermissionSet'];
		insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
	}

	public static testMethod void testValidationOk() {

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		List<Billing_Account__c> billingAccounts = [Select Id From Billing_Account__c];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName != 'BSP Deprov'];
		Product2 prod = [Select Id From Product2];

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prod.Id, true));
		insert assets;

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact, billingAccounts, contact.BillingAccount__c);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspValidationV1 handle = new ResourceBamBspValidationV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

	}

	public static testMethod void testProvisionOk() {

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		List<Billing_Account__c> billingAccounts = [Select Id From Billing_Account__c];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName != 'BSP Deprov'];
		User provisionedUser = [Select Id From User Where ContactId = :contact.Id];
		Product2 prod = [Select Id From Product2];

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prod.Id, true));
		insert assets;

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact, billingAccounts, contact.BillingAccount__c);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspProvisionV1 handle = new ResourceBamBspProvisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

		System.debug(testUser.Id);

		// make sure the user now has access to BSP
		List<PermissionSetAssignment> assignments = [Select Id From PermissionSetAssignment
														Where PermissionSet.Name = :BspConstants.BSP_COMMUNITY_PERMISSIONSET_NAME
														And AssigneeId = :provisionedUser.Id];
		System.assertNotEquals(0, assignments.size());

	}

	public static testMethod void testDeprovisionOk() {
		System.debug('TEST: testDeprovisionOk');

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName = 'BSP Deprov'];
		User provisionedUser = [Select Id From User Where ContactId = :contact.Id];
		Product2 prod = [Select Id From Product2];

		Test.startTest();

		System.runAs(testUser) {

			// only insert assets for account[0]
			// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
			List<Asset> assets = new List<Asset>();
			assets.add(BAMTestUtility.createAsset(contact.AccountId, prod.Id, true));
			insert assets;

			Map<String, Object> payload = getDeprovPayload(contact);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspDeprovisionV1 handle = new ResourceBamBspDeprovisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

		// make sure the users access has been removed
		List<PermissionSetAssignment> assignments = [Select Id From PermissionSetAssignment
														Where PermissionSet.Name = :BspConstants.BSP_COMMUNITY_PERMISSIONSET_NAME
														And AssigneeId = :provisionedUser.Id];
		System.assertEquals(0, assignments.size());

	}

	public static testMethod void testDeprovisionFailed() {
		System.debug('TEST: testDeprovisionFailed');

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName = 'BSP Deprov'];
		Product2 prod = [Select Id From Product2];

		Test.startTest();

		System.runAs(testUser) {

			// only insert assets for account[0]
			// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
			List<Asset> assets = new List<Asset>();
			assets.add(BAMTestUtility.createAsset(contact.AccountId, prod.Id, true));
			insert assets;

			Map<String, Object> payload = getDeprovPayload(contact);
			payload.put('id', null);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspDeprovisionV1 handle = new ResourceBamBspDeprovisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertNotEquals(204, response.getResponseCode());
		}

		Test.stopTest();

	}

	public static testMethod void testDeprovisionFailed2() {
		System.debug('TEST: testDeprovisionFailed');

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName = 'BSP Deprov'];
		Product2 prod = [Select Id From Product2];

		Test.startTest();

		System.runAs(testUser) {

			// only insert assets for account[0]
			// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
			List<Asset> assets = new List<Asset>();
			assets.add(BAMTestUtility.createAsset(contact.AccountId, prod.Id, true));
			insert assets;

			Map<String, Object> payload = getDeprovPayload(contact);

			// make the contact id invalid
			((Map<String, Object>)payload.get('contact')).put('id', null);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspDeprovisionV1 handle = new ResourceBamBspDeprovisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			// 204 will be sent back because the 500 is handled in the async response
			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

	}

	/**
	 * The asset isn't activated on the account therefore no user can be onboarded to Access Management
	 */
	public static testMethod void testValidationFailed() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		List<Billing_Account__c> billingAccounts = [Select Id From Billing_Account__c];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName != 'BSP Deprov'];

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact, billingAccounts, contact.BillingAccount__c);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspValidationV1 handle = new ResourceBamBspValidationV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertNotEquals(204, response.getResponseCode());
		}

		Test.stopTest();
	}

	/**
	 * The asset isn't activated on the account therefore no user can be onboarded to BSP
	 */
	public static testMethod void testProvisionFailed() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		List<Billing_Account__c> billingAccounts = [Select Id From Billing_Account__c];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName != 'BSP Deprov'];

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact, billingAccounts, contact.BillingAccount__c);
			payload.put('id', null);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspProvisionV1 handle = new ResourceBamBspProvisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertNotEquals(204, response.getResponseCode());
		}

		Test.stopTest();
	}

	/**
	 * The asset isn't activated on the account therefore no user can be onboarded to BSP
	 */
	public static testMethod void testProvisionFailed2() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];
		List<Billing_Account__c> billingAccounts = [Select Id From Billing_Account__c];
		Contact contact = [Select Id, AccountId, BillingAccount__c From Contact Where FirstName != 'BSP Deprov'];

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact, billingAccounts, contact.BillingAccount__c);

			// make the contact id invalid
			((Map<String, Object>)payload.get('contact')).put('id', null);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamBspProvisionV1 handle = new ResourceBamBspProvisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			// 204 will be sent back because the 500 is handled in the async response
			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();
	}

	public static Map<String, Object> getOkPayload(Contact contact, List<Billing_Account__c> billingAccounts, Id primaryBillingAccount) {
		Set<Id> billingAccountIds = new Map<Id, Billing_Account__c>(billingAccounts).keySet();

		return new Map<String, Object>{
				'id' => '213987123',
				'requestor' => new Map<String, Object>{'firstName' => 'wefwef', 'lastName' => 'wegwef', 'emailAddress' => 'uiiuhiuh@iuhiuh.com'},
				'contact' => new Map<String, Object>{
						'id' => contact.Id,
						'organisation' => contact.AccountId,
						'firstName' => 'wefwef',
						'lastName' => 'wegwef',
						'emailAddress' => 'uiiuhiuh@iuhiuh.com',
						'apbcn' => null,
						'apcn' => null,
						'cnumber' => null
				},
				'request' => new Map<String, Object>{
						'id' => 'a3i5D000000HtaLQAS',
						'type' => 'application',
						'application' => new Map<String, Object>{
								'appKey' => 'BSP',
								'primaryBillingAccount' => primaryBillingAccount,
								'roles' => new List<Map<String, Object>>{
										new Map<String, Object>{'role' => 'Admin', 'orgs' => null, 'billingAccounts' => billingAccountIds, 'groups' => null}
								}
						}
				}
		};
	}

	public static Map<String, Object> getDeprovPayload(Contact contact) {
		return new Map<String, Object>{
				'id' => '213987123',
				'requestor' => new Map<String, Object>{'firstName' => 'wefwef', 'lastName' => 'wegwef', 'emailAddress' => 'uiiuhiuh@iuhiuh.com'},
				'contact' => new Map<String, Object>{
						'id' => contact.Id,
						'organisation' => contact.AccountId,
						'firstName' => 'wefwef',
						'lastName' => 'wegwef',
						'emailAddress' => 'uiiuhiuh@iuhiuh.com',
						'apbcn' => null,
						'apcn' => null,
						'cnumber' => null
				},
				'request' => new Map<String, Object>{
						'id' => 'a3i5D000000HtaLQAS',
						'type' => 'application',
						'application' => new Map<String, Object>{
								'appKey' => 'BSP'
						}
				}
		};
	}
}