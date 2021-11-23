/**************************************************
Description: This class contains unit tests for validating the behavior of ResourceBamAccessManagementProvision and ResourceBamAccessManagementValidation

History:
2019-08-05  	nathan.franklin@auspost.com.au		Created.
*************************************/
@isTest
public class ResourceBamAccessManagement_Test {

	@testSetup
	public static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'BAM_PROVISION_RESPONSE', URL2__c = '/dummy/url');
		insert setting;


		Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
		testAccount.Business_Solutions_Customer__c = true;
		testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
		Database.insert(testAccount);

		testAccount.Legacy_Id__c = '60000000';
		update testAccount;

		// for linking to applications only
		Product2 prodBAM = new Product2(Name = 'Test Generic Product');
		insert prodBAM;

		// insert applications
		BAMApplication__c application = BAMTestUtility.createBamApplication('BAM', prodBAM.Id);
		insert application;

		// insert 'Admin' role for each application
		BAMApplicationRole__c role = BAMTestUtility.createApplicationRole(application, 'Super Admin');
		// remove default values
		role.ShowBillingAccount__c = false;
		role.ShowGroup__c = false;
		insert role;

		// insert accounts
		// produce accounts like this: BAM1
		List<Account> accounts = TestDataProvider.createAccount('BAM', 1);
		insert accounts;

		// create contacts
		// C1230 is linked to account[0]
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < accounts.size(); i++) {
			Contact con = TestDataProvider.createContact('Contact', accounts[i].Id, null);
			con.FirstName = 'Contact ' + i;
			con.LastName = 'Contact ' + i;
			con.Status__c = 'Active';
			con.OID_ID__c = 'C123' + i;
			contacts.add(con);
		}
		insert contacts;

		// create the community user
		User testCommunityUser = createUser('P102Community', 'W6152User', 'community.user@merchant.com.us', 'Merchant Portal Community User', contacts[0].Id);
		insert testCommunityUser;

		User testUser = createUser('QSally', 'Z8712Saunders', 'sally.saunders@1sallysemporium.com.is', 'System Administrator', null);
		insert testUser;

		assignBAMPermissionSet(testUser.Id);
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

		Contact contact = [Select Id, AccountId From Contact];
		Product2 prodBAM = [Select Id From Product2];

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prodBAM.Id, true));
		insert assets;

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamAccessManagementValidationV1 handle = new ResourceBamAccessManagementValidationV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

	}

	public static testMethod void testProvisionOk() {

		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];

		Contact contact = [Select Id, AccountId From Contact];
		Product2 prodBAM = [Select Id From Product2];

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prodBAM.Id, true));
		insert assets;

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamAccessManagementProvisionV1 handle = new ResourceBamAccessManagementProvisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertEquals(204, response.getResponseCode());
		}

		Test.stopTest();

	}

	/**
	 * The asset isn't activated on the account therefore no user can be onboarded to Access Management
	 */
	public static testMethod void testValidationFailed() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];

		Contact contact = [Select Id, AccountId From Contact];

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamAccessManagementValidationV1 handle = new ResourceBamAccessManagementValidationV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertNotEquals(204, response.getResponseCode());
		}

		Test.stopTest();
	}

	/**
	 * The request ID (Camunda Id) is empty therefore a non 204 response will be returned
	 */
	public static testMethod void testProvisionFailed1() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];

		Contact contact = [Select Id, AccountId From Contact];

		Product2 prodBAM = [Select Id From Product2];

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prodBAM.Id, true));
		insert assets;

		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact);
			payload.put('id', null);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamAccessManagementProvisionV1 handle = new ResourceBamAccessManagementProvisionV1();
			ResourceAPIService.IResourceResponse response = handle.post();

			System.assertNotEquals(204, response.getResponseCode());
		}

		Test.stopTest();
	}

	/**
	 * When we call out to Camunda to acknolwedge the completion of the request, this will simulate an error response back from Camunda which will trigger some error handling routines
	 */
	public static testMethod void testProvisionCamundaResponseError() {
		User testUser = [Select Id From User Where Email = 'sally.saunders@1sallysemporium.com.is' And Profile.Name = 'System Administrator'];

		Contact contact = [Select Id, AccountId From Contact];

		Product2 prodBAM = [Select Id From Product2];

		BAMExternalOnboardingRequest__c  eor = BAMTestUtility.createExternalOnboardingRequest(contact.Id, null, 'Pending', System.now());
		insert eor;

		// only insert assets for account[0]
		// this means any contact of account[1] will not get any results because accounts[1] has no applications activated
		List<Asset> assets = new List<Asset>();
		assets.add(BAMTestUtility.createAsset(contact.AccountId, prodBAM.Id, true));
		insert assets;

		Test.setMock(HttpCalloutMock.class, new ErrorResponseMock());
		Test.startTest();

		System.runAs(testUser) {

			Map<String, Object> payload = getOkPayload(contact);
			((Map<String, Object>)payload.get('request')).put('id', eor.Id);

			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf(JSON.serialize(payload));
			RestContext.request = req;

			ResourceBamAccessManagementProvisionV1 handle = new ResourceBamAccessManagementProvisionV1();
			handle.post();
		}

		Test.stopTest();

		// the future will fire and will cause a call out a response code of 500 because of the mock.
		// no assertion can be made here.
		System.assert(true);

	}

	class ErrorResponseMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			return response;
		}
	}

	public static Map<String, Object> getOkPayload(Contact contact) {
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
								'appKey' => 'BAM',
								'roles' => new List<Map<String, Object>>{
										new Map<String, Object>{'role' => 'Super Admin', 'orgs' => null, 'billingAccounts' => null, 'groups' => null}
								}
						}
				}
		};
	}
}