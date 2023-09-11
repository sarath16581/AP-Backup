/**
 * Created by kamil.szyc on 23/8/2022.
 */

@IsTest
private class LpoCpoAccessHandlerQueueable_Test {
	@TestSetup
	static void setup() {
		MockUtility.disableTriggerExecution();
		List<Account> accounts = TestDataProvider.createAccount('Test Account', 1);
		accounts[0].BillingCity = 'Test City';
		accounts[0].BillingStreet = 'Test Street';
		accounts[0].BillingPostalCode = '1234';
		accounts[0].Billing_DPID__c = '12345678';
		insert accounts;

		insert new Contact(
				FirstName = 'test',
				LastName = 'miao',
				MobilePhone = '041111111',
				Email = 'lpo@test.com',
				AccountId = accounts[0].Id
		);

		setDataForLPOReparentTest();
	}

	@Future static void setDataForLPOReparentTest() {
		Contact commContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = 'lpo@test.com' LIMIT 1];
		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];
		insert new User(
				Email = commContact.Email,
				EmailEncodingKey = 'UTF-8',
				FirstName = commContact.FirstName,
				LastName = commContact.LastName,
				ContactId = commContact.Id,
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				ProfileId = communityUserProfile.Id,
				Alias = commContact.FirstName,
				TimeZoneSidKey = 'America/Los_Angeles',
				MobilePhone = '098765432',
				Username = 'commUser@lpoTest.com',
				IsActive = true
		);
	}
	@IsTest static void testDeleteMembership() {
		User adminUser = new User(
				ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
				Username = 'testAdmin@sf.com.au',
				Alias = 'GDS',
				TimeZoneSidKey = 'America/New_York',
				EmailEncodingKey = 'ISO-8859-1',
				LocaleSidKey = 'en_US',
				LanguageLocaleKey = 'en_US',
				FirstName = 'Genelia',
				LastName = 'Dsouza',
				UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Business_Reporting' LIMIT 1].Id,
				Email = 'test@please.work.au'
		);
		insert adminUser;
		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];

		System.runAs(adminUser) {

			Test.startTest();
			List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));

			List<Network__c> networkFacilities = ApplicationTestDataFactory.getLPONetwork(2, false);
			networkFacilities[0].Org_ID__c = 'test1';
			networkFacilities[1].Org_ID__c = 'test2';
			insert networkFacilities;

			Id orgRtId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
			orgAccounts[0].RecordTypeId = orgRtId;
			orgAccounts[0].ABN__c = '12345678901';
			orgAccounts[1].RecordTypeId = orgRtId;
			orgAccounts[1].ABN__c = '12345678902';
			orgAccounts[0].Post_Office_Assigned__c = networkFacilities[0].Id;
			orgAccounts[1].Post_Office_Assigned__c = networkFacilities[1].Id;
			insert orgAccounts;
			orgAccounts[0].IsPartner = true;
			orgAccounts[1].IsPartner = true;
			update orgAccounts;

			List<Account> licenceAccounts = new List<Account>{
					ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, null, false)[0],
					ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[1].Id, null, false)[0]
			};
			insert licenceAccounts;

			Account facilityAccount1 = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacilities[0].Id, false)[0];
			Account facilityAccount2 = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacilities[1].Id, false)[0];

			facilityAccount1.ParentId = licenceAccounts[0].Id;
			facilityAccount2.ParentId = licenceAccounts[1].Id;
			insert new List<Account>{
					facilityAccount1, facilityAccount2
			};

			List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, licenceAccounts[0].Id, false);
			insert contacts;

			User testUsr = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{
					contacts[0].Id
			}, communityUserProfile.Id, false)[0];
			testUsr.Username = 'cpoAndLpoTest@ausPost' + System.currentTimeMillis() + '.au';
			insert testUsr;

			// =====================================
			// Stubbing
			// =====================================
			// None!

			// =====================================
			// Testing
			// =====================================
			contacts[0].AccountId = orgAccounts[1].Id;
			update contacts[0];
			insert new AccountTeamMember(
					UserId = testUsr.Id,
					AccountId = orgAccounts[0].Id,
					TeamMemberRole = 'Post Office User'
			);
			Set<Id> contactIdsToRemoveExistingMembership = new Set<Id>{
					contacts[0].Id
			};
			System.enqueueJob(new LpoCpoAccessHandlerQueueable(null, contactIdsToRemoveExistingMembership, null, null));

			Test.stopTest();
			System.assertEquals(0, [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUsr.Id AND AccountId = :orgAccounts[0].Id], 'former account team membership was not removed');
		}
	}
	@IsTest static void testCreateMembership() {
		User adminUser = new User(
				ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
				Username = 'testAdmin@sf.com.au',
				Alias = 'GDS',
				TimeZoneSidKey = 'America/New_York',
				EmailEncodingKey = 'ISO-8859-1',
				LocaleSidKey = 'en_US',
				LanguageLocaleKey = 'en_US',
				FirstName = 'Genelia',
				LastName = 'Dsouza',
				UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Business_Reporting' LIMIT 1].Id,
				Email = 'test@please.work.au'
		);
		insert adminUser;
		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];

		System.runAs(adminUser) {

			Test.startTest();
			List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));

			List<Network__c> networkFacilities = ApplicationTestDataFactory.getLPONetwork(2, false);
			networkFacilities[0].Org_ID__c = 'test1';
			networkFacilities[1].Org_ID__c = 'test2';
			insert networkFacilities;

			Id orgRtId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
			orgAccounts[0].RecordTypeId = orgRtId;
			orgAccounts[0].ABN__c = '12345678901';
			orgAccounts[1].RecordTypeId = orgRtId;
			orgAccounts[1].ABN__c = '12345678902';
			orgAccounts[0].Post_Office_Assigned__c = networkFacilities[0].Id;
			orgAccounts[1].Post_Office_Assigned__c = networkFacilities[1].Id;
			insert orgAccounts;
			orgAccounts[0].IsPartner = true;
			orgAccounts[1].IsPartner = true;
			update orgAccounts;

			List<Account> licenceAccounts = new List<Account>{
					ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, null, false)[0],
					ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[1].Id, null, false)[0]
			};
			insert licenceAccounts;

			Account facilityAccount1 = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacilities[0].Id, false)[0];
			Account facilityAccount2 = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacilities[1].Id, false)[0];

			facilityAccount1.ParentId = licenceAccounts[0].Id;
			facilityAccount2.ParentId = licenceAccounts[1].Id;
			insert new List<Account>{
					facilityAccount1, facilityAccount2
			};

			List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, licenceAccounts[0].Id, false);
			insert contacts;

			User testUsr = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{
					contacts[0].Id
			}, communityUserProfile.Id, false)[0];
			testUsr.Username = 'cpoAndLpoTest@ausPost' + System.currentTimeMillis() + '.au';
			insert testUsr;

			// =====================================
			// Stubbing
			// =====================================
			// None!

			// =====================================
			// Testing
			// =====================================
			contacts[0].AccountId = orgAccounts[1].Id;
			update contacts[0];
			insert new AccountTeamMember(
					UserId = testUsr.Id,
					AccountId = orgAccounts[0].Id,
					TeamMemberRole = 'Post Office User'
			);
			System.assertEquals(0, [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUsr.Id AND AccountId = :orgAccounts[1].Id], 'No account team membership should have been created before the start of the test');
			Map<String, Set<Id>> contactIdsByNetworkFacility = new Map<String, Set<Id>>{
					'test2' => new Set<Id>{
							contacts[0].Id
					}
			};
			System.enqueueJob(new LpoCpoAccessHandlerQueueable(contactIdsByNetworkFacility, null, null, null));

			Test.stopTest();
			System.assertEquals(1, [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUsr.Id AND AccountId = :orgAccounts[1].Id], 'test user should get access to the LPO since it has the same WCIS code as the CPO');
		}
	}
}