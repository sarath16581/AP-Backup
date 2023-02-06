/**
 * @author Naveen Rajanna
 * @date 2023-01-27
 * @group Tests
 * @tag Tests
 * @description Test class for UserLicenseHandlerQueueable
 * @changelog
 * 2023-01-27 - Initial creation
 */
@IsTest
private class UserLicenseHandlerQueueable_Test {
	private static List<PackageLicense> packageLicenseList = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'Apttus'];
	private static List<PermissionSet> permissionSetList = [SELECT Id FROM PermissionSet WHERE Name = 'EA_Insight_User'];
	private static List<PermissionSetGroup> permissionSetGroupList = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'BG_Sales_User'];
	private static List<PermissionSetLicense> permissionSetLicenseList = [
		SELECT Id
		FROM PermissionSetLicense
		WHERE DeveloperName = 'EinsteinAnalyticsPlusPsl'
	];

	/**
	 * Insert Custom Settings referenced by Queueable Apex and a User to whom we add/remove licenses
	 */
	@TestSetup
	static void makeData() {
		MockUtility.disableTriggerExecution();
		List<User> userList = ApplicationTestDataFactory.getUsers(2, false);
		userList[0].Username = 'testuser@apextest.com.test';
		userList[1].Username = 'adminuser@apextest.com.test';
		insert userList;
	}

	/**
	 * Positive scenario : Assign UserPackageLicenses and PermissionSetLicenses for the supplied UserIds
	 */
	@IsTest
	static void testAssignLicenses() {
		User adminUser = [SELECT Id, Email FROM User WHERE Username = 'adminuser@apextest.com.test' LIMIT 1];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			User testUser = [SELECT Id FROM User WHERE Username = 'testuser@apextest.com.test' LIMIT 1];
			// verify counts before running tests
			System.assertEquals(0, [SELECT Id FROM UserPackageLicense WHERE UserId = :testUser.Id].size(), 'User Package License assignment exists');
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup assignment exists'
			);
			System.assertEquals(
				0,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License assignment exists'
			);

			// =====================================
			// Stubbing
			// =====================================
			// None

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			// Invoke Queueable to assign Apttus user package license, EA_Insight_User permission set along with EinsteinAnalyticsPlusPsl, BG_Sales_User permission set group
			System.enqueueJob(
				new UserLicenseHandlerQueueable(
					false,
					new Set<Id>{ testUser.Id },
					new Map<Id, PackageLicense>(packageLicenseList).keySet(),
					new Map<Id, PermissionSet>(permissionSetList).keySet(),
					new Map<Id, PermissionSetGroup>(permissionSetGroupList).keySet(),
					null
				)
			);
			Test.stopTest();

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');

			System.assertEquals(1, [SELECT Id FROM UserPackageLicense WHERE UserId = :testUser.Id].size(), 'User Package License was not assigned');
			System.assertEquals(
				3,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup was not assigned'
			);
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License was not assigned'
			);

			// verify email was not sent to admin
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(0, emailList.size(), 'Summary email was not supposed to be sent');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}

	/**
	 * Positive scenario : Remove UserPackageLicenses and PermissionSetLicenses for the supplied UserIds
	 */
	@IsTest
	static void testRemoveLicenses() {
		User adminUser = [SELECT Id, Email FROM User WHERE Username = 'adminuser@apextest.com.test' LIMIT 1];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			User testUser = [SELECT Id FROM User WHERE Username = 'testuser@apextest.com.test' LIMIT 1];
			insert (new UserPackageLicense(UserId = testUser.Id, PackageLicenseId = packageLicenseList[0].Id));
			insert (new List<PermissionSetAssignment>{
				new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permissionSetList[0].Id),
				new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetGroupId = permissionSetGroupList[0].Id)
			});
			// verify counts before running tests
			System.assertEquals(
				1,
				[SELECT Id FROM UserPackageLicense WHERE UserId = :testUser.Id].size(),
				'User Package License was not assigned to remove'
			);
			System.assertEquals(
				3,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup was not assigned to remove'
			);
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License was not assigned to remove'
			);

			// =====================================
			// Stubbing
			// =====================================
			// None

			// =====================================
			// Testing
			// =====================================

			Test.startTest();
			// Invoke Queueable to remove Apttus user package license, EA_Insight_User permission set, BG_Sales_User permission set group, EinsteinAnalyticsPlusPsl permision set license
			System.enqueueJob(
				new UserLicenseHandlerQueueable(
					true,
					new Set<Id>{ testUser.Id },
					new Map<Id, PackageLicense>(packageLicenseList).keySet(),
					new Map<Id, PermissionSet>(permissionSetList).keySet(),
					new Map<Id, PermissionSetGroup>(permissionSetGroupList).keySet(),
					new Map<Id, PermissionSetLicense>(permissionSetLicenseList).keySet()
				)
			);
			Test.stopTest();

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');

			System.assertEquals(
				0,
				[SELECT Id FROM UserPackageLicense WHERE UserId = :testUser.Id].size(),
				'User Package License assignment was not removed'
			);
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup assignment was not removed'
			);
			System.assertEquals(
				0,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License assignment was not removed'
			);

			// verify email was not sent to admin
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(0, emailList.size(), 'Summary email was not supposed to be sent');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}

	/**
	 * Negative scenario : Error scenario when assigning one of the license type for the supplied UserIds
	 * Assign permission set and permission set license assignment - here the permission set is also configured with a permission set license assignment
	 * and observe that the queueable gets completed as DML allows partial success and also the error encountered is sent in a email to the running user
	 */
	@IsTest
	static void testInsertDMLError() {
		User adminUser = [SELECT Id, Email FROM User WHERE Username = 'adminuser@apextest.com.test' LIMIT 1];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			User testUser = [SELECT Id FROM User WHERE Username = 'testuser@apextest.com.test' LIMIT 1];
			// verify counts before running tests
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup assignment exists'
			);
			System.assertEquals(
				0,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License assignment exists'
			);

			// =====================================
			// Stubbing
			// =====================================
			// None

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			// Invoke Queueable to assign EA_Insight_User permission set containing EinsteinAnalyticsPlusPsl permission set license,
			// and explicitely assign EinsteinAnalyticsPlusPsl permission set license
			System.enqueueJob(
				new UserLicenseHandlerQueueable(
					false,
					new Set<Id>{ testUser.Id },
					null,
					new Map<Id, PermissionSet>(permissionSetList).keySet(),
					null,
					new Map<Id, PermissionSetLicense>(permissionSetLicenseList).keySet()
				)
			);
			Test.stopTest();

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');

			System.assertEquals(
				2,
				[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet and PermissionSetGroup was not assigned'
			);
			System.assertEquals(
				1,
				[SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId = :testUser.Id].size(),
				'PermissionSet License was not assigned'
			);

			// verify an email message is sent to admin
			// for the failure of insert of the EinsteinAnalyticsPlusPsl permission set license
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(1, emailList.size(), 'Summary email was not sent');
			System.assert(emailList[0].Subject.contains('UserLicenseHandlerQueueable'), 'Summary email Subject not matching');
			System.assert(emailList[0].ToAddress.contains(adminUser.Email), 'Summary email ToAddress not matching');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}

	/**
	 * Negative scenario : Error scenario when deleting one of the license type supplying the assignments
	 * Delete permission set assignment - here the Id is mocked up (doesn't exist in org)
	 * and observe that the queueable gets completed as DML allows partial success and also the error encountered is sent in a email to the running user
	 */
	@IsTest
	static void testDeleteDMLError() {
		User adminUser = [SELECT Id, Email FROM User WHERE Username = 'adminuser@apextest.com.test' LIMIT 1];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			// None

			// =====================================
			// Stubbing
			// =====================================
			// None

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			// Invoke Queueable to assign EA_Insight_User permission set containing EinsteinAnalyticsPlusPsl permission set license,
			// and explicitely assign EinsteinAnalyticsPlusPsl permission set license
			System.enqueueJob(
				new UserLicenseHandlerQueueable(
					true,
					null,
					new List<PermissionSetAssignment>{
						new PermissionSetAssignment(Id = fflib_IDGenerator.generate(PermissionSetAssignment.SObjectType))
					},
					null
				)
			);
			Test.stopTest();

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');

			// verify an email message is sent to admin
			// for the failure of insert of the EinsteinAnalyticsPlusPsl permission set license
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(1, emailList.size(), 'Summary email was not sent');
			System.assert(emailList[0].Subject.contains('UserLicenseHandlerQueueable'), 'Summary email Subject not matching');
			System.assert(emailList[0].ToAddress.contains(adminUser.Email), 'Summary email ToAddress not matching');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}

	/**
	 * Negative scenario : Test Queueable job chaining based on the specified DML Limit rows for one of the license type
	 */
	@IsTest
	static void testQueueableChain() {
		User adminUser = [SELECT Id, Email FROM User WHERE Username = 'adminuser@apextest.com.test' LIMIT 1];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			User testUser = [SELECT Id FROM User WHERE Username = 'testuser@apextest.com.test' LIMIT 1];
			// verify counts before running tests
			System.assertEquals(0, [SELECT Id FROM UserPackageLicense WHERE UserId = :testUser.Id].size(), 'User Package License assignment exists');

			UserDeactivationSettings__c settings = UserDeactivationSettings__c.getOrgDefaults();
			settings.DMLRecordLimit__c = 1;
			insert settings;

			// =====================================
			// Stubbing
			// =====================================
			// None

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			// Invoke Queueable to assign two user package license with config having DML Row Limit 1, and obserrve two queueable jobs are trigerred
			System.enqueueJob(
				new UserLicenseHandlerQueueable(
					false,
					new Set<Id>{ testUser.Id },
					new Map<Id, PackageLicense>([SELECT Id FROM PackageLicense WHERE NamespacePrefix IN ('Apttus', 'Apttus_Config2')]).keySet(),
					null,
					null,
					null
				)
			);
			Test.stopTest();

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');

			System.assertEquals(true, UserLicenseHandlerQueueable.doChain, 'Queueable job chain did not fire');

			// verify email was not sent to admin
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(0, emailList.size(), 'Summary email was not supposed to be sent');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}
}