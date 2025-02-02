/**
 * @author Naveen Rajanna
 * @date 2023-01-27
 * @group Tests
 * @tag Tests
 * @description Test class for UserDeactivationBatchable
 * @changelog
 * 2023-01-27 - Initial creation
 * 2024-08-01 - Mona Raghav -  REQ3575796 - Added test coverage for the changes done for email notification prior to deactivation
 * 2024-08-05 - Mona Raghav -  REQ3575796 - Updated testUserDeactivateFailedAndEnsureQueueableNotFired and testUserDeactivateSuccessAndEnsureQueueableFired
 */
@IsTest
private class UserDeactivationBatchable_Test {
	/**
	 * Insert Custom Settings referenced by Batch Apex
	 */
	@TestSetup
	static void makeData() {
		UserDeactivationSettings__c settings = UserDeactivationSettings__c.getOrgDefaults();
		settings.BatchSize__c = 10;
		settings.LastLoginDays__c = 3;
		settings.LastInviteDays__c = 0;
		settings.LastLoginDaysNotification__c = 1;
		settings.NotificationEmail__c = 'dummy@test.com';
		insert settings;       
	}

	/**
	 * Verify the Start method Selector is run only once
	 */
	@IsTest
	static void testBatchStart() {
		User adminUser = ApplicationTestDataFactory.getUsers(1, false)[0];
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			// None

			// =====================================
			// Stubbing
			// =====================================
			UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(
					mockUsersSelector.selectUsersEligibleForDeactivationQueryLocator(
						(Set<String>) fflib_Match.anyObject(),
						(Integer) fflib_Match.anyInteger(),
						(Integer) fflib_Match.anyInteger(),
						(Set<String>) fflib_Match.anyObject(),
						(Set<Object>) fflib_Match.anyObject()
					)
				)
				.thenReturn(null);
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			UserDeactivationBatchable batch = new UserDeactivationBatchable();
			batch.start(null);
			Test.stopTest();

			//verify that UsersSelector is called once to get the query locator
			((UsersSelector) MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1)))
				.selectUsersEligibleForDeactivationQueryLocator(
					(Set<String>) fflib_Match.anyObject(),
					(Integer) fflib_Match.anyInteger(),
					(Integer) fflib_Match.anyInteger(),
					(Set<String>) fflib_Match.anyObject(),
					(Set<Object>) fflib_Match.anyObject()
				);
		}
	}

	/**
	 * Positive scenario : User successfully deactivated, ensure queueable is fired to remove licenses for deactivated users
	 * and email not sent (as it is only when there is user deactivation failures)
	 */
	@IsTest
	static void testUserDeactivateSuccessAndEnsureQueueableFired() {
		List<User> userList = ApplicationTestDataFactory.getUsers(2, false);
        User adminUser = userList[0];
        
        // =====================================
		// Data Preparation
		// =====================================
        User userObj = userList[1];
        userObj.MyNetwork_Retail_User__c = true;
        userObj.IsActive  = true;
        insert userObj;
        
		System.runAs(adminUser) {
			// =====================================
			// Data Preparation
			// =====================================
			MockUtility.disableTriggerExecution();

			// =====================================
			// Stubbing
			// =====================================
			UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(
					mockUsersSelector.selectUsersEligibleForDeactivationQueryLocator(
						(Set<String>) fflib_Match.anyObject(),
						(Integer) fflib_Match.anyInteger(),
						(Integer) fflib_Match.anyInteger(),
						(Set<String>) fflib_Match.anyObject(),
						(Set<Object>) fflib_Match.anyObject()
					)
				)
				.thenReturn(
					Database.getQueryLocator(
						[
							SELECT Id, Name, Username, CreatedDate, LastAutoDeactivatedDate__c, LastLoginDate
							FROM User
							WHERE Id = : userObj.Id
						]
					)
				);
			MockUtility.Mocks.when(MockUtility.mockDatabase().dmlUpdate((List<SObject>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
				.thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			UserDeactivationBatchable batch = new UserDeactivationBatchable();
			batch.execute(null);
			Test.stopTest();

			//verify that UsersSelector is called once to get the query locator
			((UsersSelector) MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1)))
				.selectUsersEligibleForDeactivationQueryLocator(
					(Set<String>) fflib_Match.anyObject(),
					(Integer) fflib_Match.anyInteger(),
					(Integer) fflib_Match.anyInteger(),
					(Set<String>) fflib_Match.anyObject(),
					(Set<Object>) fflib_Match.anyObject()
				);

			// verify the batch apex was successfully completed
			List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
			System.assertEquals(1, vJob.size(), 'Batch failed to run');
			System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');

			// verify email was not sent to admin
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(0, emailList.size(), 'Summary email was not supposed to be sent');

			List<AsyncApexJob> vQJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
			System.assertEquals(1, vQJob.size(), 'Queueable failed to run');
			System.assertEquals('Completed', vQJob[0].Status, 'Queueable status: failed');
			
			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());
		}
	}

	/**
	 * Negative scenario : User failed to deactivate, ensure queueable is NOT fired to remove licenses for deactivated users
	 * and email is sent to the address specified in custom setting
	 */
	@IsTest
	static void testUserDeactivateFailedAndEnsureQueueableNotFired() {
		List<User> userList = ApplicationTestDataFactory.getUsers(2, false);
        User adminUser = userList[0];
        
        // =====================================
		// Data Preparation
		// =====================================
        User userObj = userList[1];
        userObj.MyNetwork_Retail_User__c = true;
        userObj.IsActive  = true;
        insert userObj;
            
		System.runAs(adminUser) {

			// =====================================
			// Stubbing
			// =====================================
			UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(
					mockUsersSelector.selectUsersEligibleForDeactivationQueryLocator(
						(Set<String>) fflib_Match.anyObject(),
						(Integer) fflib_Match.anyInteger(),
						(Integer) fflib_Match.anyInteger(),
						(Set<String>) fflib_Match.anyObject(),
						(Set<Object>) fflib_Match.anyObject()
					)
				)
				.thenReturn(
					Database.getQueryLocator(
						[
							SELECT Id, Name, Username, CreatedDate, LastAutoDeactivatedDate__c, LastLoginDate
							FROM User
							WHERE Id = : userObj.Id
						]
					)
				);
			MockUtility.Mocks.when(MockUtility.mockDatabase().dmlUpdate((List<SObject>) fflib_Match.anyObject(), fflib_Match.anyBoolean()))
				.thenAnswer(new MockUtility.AnswerGenericDMLFailed());
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			UserDeactivationBatchable batch = new UserDeactivationBatchable();
			batch.execute(null);
			Test.stopTest();

			//verify that UsersSelector is called once to get the query locator
			((UsersSelector) MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1)))
				.selectUsersEligibleForDeactivationQueryLocator(
					(Set<String>) fflib_Match.anyObject(),
					(Integer) fflib_Match.anyInteger(),
					(Integer) fflib_Match.anyInteger(),
					(Set<String>) fflib_Match.anyObject(),
					(Set<Object>) fflib_Match.anyObject()
				);

			// verify the batch apex was successfully completed
			List<AsyncApexJob> vJob = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
			System.assertEquals(1, vJob.size(), 'Batch failed to run');
			System.assertEquals('Completed', vJob[0].Status, 'Batch status: failed');

			// verify email has been sent to admin
			List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
			System.assertEquals(1, emailList.size(), 'Summary email was not sent');
			System.assert(emailList[0].Subject.contains('UserDeactivationBatchable'), 'Summary email Subject not matching');
			System.assert(emailList[0].ToAddress.contains('dummy@test.com'), 'Summary email ToAddress not matching');

			// verify no ExceptionLog was created
			System.assertEquals(0, [SELECT Id FROM ExceptionLog__c].size());

			// check that the queueable was not fired
			((ApplicationDatabase) MockUtility.Mocks.verify(MockUtility.mockDatabase(), 0)).enqueueJob(fflib_Match.anyObject());
		}
	}

	/**
	 * Negative scenario : Raise exception if something goes wrong in batch job execute()
	 */
	@IsTest
	static void testExecuteException() {
		//Testing
		Test.startTest();
		UserDeactivationBatchable batch = new UserDeactivationBatchable();
		batch.execute(null, null);
		Test.stopTest();
		// verify ExceptionLog was created
		List<ExceptionLog__c> exceptionLogList = [SELECT Id, MethodName__c FROM ExceptionLog__c];
		System.assertEquals(1, exceptionLogList.size());
		System.assertEquals('execute bc', exceptionLogList[0].MethodName__c);
	}

	/**
	 * Negative scenario : Raise exception if something goes wrong in batch finish()
	 */
	@IsTest
	static void testExecuteFinishException() {
		//Test Data
		User testUser = ApplicationTestDataFactory.getUsers(1, false)[0];
	    List<User> testUserList = new List<User>();
		testUserList.add(testUser);
		//Testing
		Test.startTest();
		UserDeactivationBatchable batch = new UserDeactivationBatchable();
		batch.setUpdateable(testUserList);
		batch.finish(null);
		Test.stopTest();
		
		// verify ExceptionLog was created
		List<ExceptionLog__c> exceptionLogList = [SELECT Id, MethodName__c FROM ExceptionLog__c];
		System.assertEquals(1, exceptionLogList.size());
		System.assertEquals('finish', exceptionLogList[0].MethodName__c);
	}

	/**
	 * Negative scenario : User failed to deactivate, ensure queueable is NOT fired to remove licenses for deactivated users
	 * and email is sent to the address specified in custom setting
	 */
	@IsTest
	static void testExecuteUserNotificationList() {
        // =====================================
		// Data Preparation
		// 
		// =====================================
		List<User> myNetworkUsersList = new List<User>();
        User testMyNetworkUser = [Select Id, Profile.Name From User Where Profile.Name = 'MyNetwork Portal' LIMIT 1];
        testMyNetworkUser.MyNetwork_Retail_User__c = false;
        testMyNetworkUser.Email  = 'dummy@test.com';
		testMyNetworkUser = (User)ApplicationTestDataFactory.setUnwritableFields(testMyNetworkUser, new Map<String, Object>{ 'LastLoginDate' => Datetime.now().addDays(-1) });
		myNetworkUsersList.add(testMyNetworkUser);

		User adminUser = ApplicationTestDataFactory.getUsers(1, false)[0];
		System.runAs(adminUser) {			
			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			UserDeactivationBatchable batch = new UserDeactivationBatchable();
			batch.execute(null,myNetworkUsersList);
            Test.stopTest();
			System.assertEquals(1, batch.getUserEmailNotification().size(), 'Error while notifying for deactivation');
		}
	}
    
    @IsTest
	static void testUserNotificationEmailtest() {
        
        // =====================================
		// Data Preparation
		// 
		// =====================================
		List<User> myNetworkUsersList = new List<User>();
        User testMyNetworkUser = [Select Id, Profile.Name From User Where Profile.Name = 'MyNetwork Portal' LIMIT 1];
        testMyNetworkUser.MyNetwork_Retail_User__c = false;
        testMyNetworkUser.Email  = 'dummy@test.com';
		testMyNetworkUser = (User)ApplicationTestDataFactory.setUnwritableFields(testMyNetworkUser, new Map<String, Object>{ 'LastLoginDate' => Datetime.now().addDays(-1) });
		myNetworkUsersList.add(testMyNetworkUser);

		User adminUser = ApplicationTestDataFactory.getUsers(1, false)[0];
		System.runAs(adminUser) {
			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			UserDeactivationBatchable batch = new UserDeactivationBatchable();
            batch.setUserEmailNotification(myNetworkUsersList);
			batch.finish(null);
			Test.stopTest();			
            List<EmailMessage> emailList = [SELECT Id, Subject, ToAddress FROM EmailMessage];
            System.assertEquals(1, emailList.size(), 'Summary email was not sent');
		}
	}
}