/**
 * @description Test class for TransactionSecurityPolicyManager
 * @author Naveen Rajanna
 * @date 2024-02-20
 * @group Tests
 * @changelog
 * 2024-02-20 - Naveen Rajanna - created - REQ3445775.
 */
@isTest
public class TransactionSecurityPolicyManager_Test {

	@TestSetup
	static void testDataSetup() {
		User adminUser = ApplicationTestDataFactory.getUsers(1, false)[0];
		adminUser.Alias = 'admtsp1';
		adminUser.Username = 'admtsp1@admtsp1.com';

		Id ssswProfileId = [SELECT Id FROM profile WHERE Name = :SSSWConstants.SSSW_AGENT_PROFILE LIMIT 1].Id;
		User ssswAgent1 = ApplicationTestDataFactory.getUsers(1, ssswProfileId, false)[0];
		ssswAgent1.Alias = 'sA1tsp2';
		ssswAgent1.Username = 'sA1tsp2@sA1tsp2.com';

		User ssswAgent2 = ApplicationTestDataFactory.getUsers(1, ssswProfileId, false)[0];
		ssswAgent2.Alias = 'sA2tsp2';
		ssswAgent2.Username = 'sA2tsp2@sA2tsp2.com';

		Id apintegProfileId = [SELECT Id FROM Profile WHERE Name = 'AP Integration' LIMIT 1].Id;
		User apIntUser = ApplicationTestDataFactory.getUsers(1, apintegProfileId, false)[0];
		apIntUser.Alias = 'ainttsp3';
		apIntUser.Username = 'ainttsp3@ainttsp3.com';

		List<User> userList = new List<User>{adminUser, ssswAgent1, ssswAgent2, apIntUser};
		insert userList;

		// org Setting  - LoginEventWindowsPlatformValidation is disabled and ReportEventSensitiveFieldValidation is enabled
		TransactionSecurityPolicySetting__c orgSetting = TransactionSecurityPolicyTestDataFactory.generateTransactionSecurityPolicySetting(1, UserInfo.getOrganizationId(), false, true, false)[0];

		// ssswProfile Setting  - LoginEventWindowsPlatformValidation is enabled and ReportEventSensitiveFieldValidation is enabled
		TransactionSecurityPolicySetting__c profileSetting = TransactionSecurityPolicyTestDataFactory.generateTransactionSecurityPolicySetting(1, ssswProfileId, true, true, false)[0];

		// adminUser Setting  - LoginEventWindowsPlatformValidation is disabled and ReportEventSensitiveFieldValidation is disabled
		TransactionSecurityPolicySetting__c adminUserSetting = TransactionSecurityPolicyTestDataFactory.generateTransactionSecurityPolicySetting(1, adminUser.Id, false, false, false)[0];

		// ssswAgent1 Setting  - LoginEventWindowsPlatformValidation is disabled and ReportEventSensitiveFieldValidation is enabled
		TransactionSecurityPolicySetting__c ssswAgent1Setting = TransactionSecurityPolicyTestDataFactory.generateTransactionSecurityPolicySetting(1, ssswAgent1.Id, false, true, false)[0];

		List<TransactionSecurityPolicySetting__c> transactionSecurityPolicySettings = new List<TransactionSecurityPolicySetting__c>{orgSetting, profileSetting, adminUserSetting, ssswAgent1Setting};
		insert transactionSecurityPolicySettings;
	}

	@isTest
	private static void testEvaluateLoginEvent() {
		Id ssuppId = [SELECT Id FROM User WHERE Alias = 'ssupp' LIMIT 1].Id;
		User adminUser = [SELECT Id FROM User WHERE Alias = 'admtsp1' LIMIT 1];
		User ssswAgentUser1 = [SELECT Id FROM User WHERE Alias = 'sA1tsp2' LIMIT 1];
		User ssswAgentUser2 = [SELECT Id FROM User WHERE Alias = 'sA2tsp2' LIMIT 1];
		User apIntUsr = [SELECT Id FROM User WHERE Alias = 'ainttsp3' LIMIT 1];

		// Testing
		Test.startTest();
		TransactionSecurityPolicyManager transactionSecurityPolicyManager = new TransactionSecurityPolicyManager();
		// Test System Support User logging via Mac Platform who is bypassed by default
		Boolean ssuppMac = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssuppId, 'Mac', true));
		// Test System Support User logging via Windows Platform who is bypassed by default
		Boolean ssuppWin = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssuppId, 'Windows', true));

		// Test admin User logging via Mac Platform who is bypassed by default
		Boolean adminMac = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(adminUser.Id, 'Mac', true));
		// Test admin User logging via Windows Platform who is bypassed by default
		Boolean adminWin = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(adminUser.Id, 'Windows', true));

		// Test ssswAgentUser1 User logging via Mac Platform who has LoginEventWindowsPlatformValidation disabled as per user setting
		Boolean ssswAgent1Mac = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssswAgentUser1.Id, 'Mac', true));
		// Test ssswAgentUser1 User logging via Windows Platform who has LoginEventWindowsPlatformValidation disabled as per user setting
		Boolean ssswAgent1Win = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssswAgentUser1.Id, 'Windows', true));

		// Test ssswAgentUser2 User logging via Mac Platform who has LoginEventWindowsPlatformValidation enabled as per ssswProfile setting
		Boolean ssswAgent2Mac = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssswAgentUser2.Id, 'Mac', true));
		// Test ssswAgentUser2 User logging via Windows Platform who has LoginEventWindowsPlatformValidation enabled as per ssswProfile setting
		Boolean ssswAgent2Win = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(ssswAgentUser2.Id, 'Windows', true));

		// Test apIntUsr User logging via Mac Platform who has LoginEventWindowsPlatformValidation disabled as per org setting
		Boolean apIntUsrMac = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(apIntUsr.Id, 'Mac', true));
		// Test apIntUsr User logging via Windows Platform who has LoginEventWindowsPlatformValidation disabled as per org setting
		Boolean apIntUsrWin = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getLoginEvent(apIntUsr.Id, 'Windows', true));
		Test.stopTest();

		// Assert or verify
		System.Assert.areEqual(false, ssuppMac, 'Login as System Support User via Mac platform should be bypassed');
		System.Assert.areEqual(false, ssuppWin, 'Login as System Support User via Windows platform should be bypassed');

		System.Assert.areEqual(false, adminMac, 'Login as Admin Profile User via Mac platform should be bypassed');
		System.Assert.areEqual(false, adminWin, 'Login as Admin Profile User via Windows platform should be bypassed');

		System.Assert.areEqual(false, ssswAgent1Mac, 'Login as ssswAgent1 User via Mac platform should be allowed as per ssswAgent1 setting');
		System.Assert.areEqual(false, ssswAgent1Win, 'Login as ssswAgent1 User via Windows platform should be allowed');

		System.Assert.areEqual(true, ssswAgent2Mac, 'Login as ssswAgent2 User via Mac platform should NOT be allowed as per ssswProfile setting');
		System.Assert.areEqual(false, ssswAgent2Win, 'Login as ssswAgent2 User via Windows platform should be allowed');

		System.Assert.areEqual(false, apIntUsrMac, 'Login as apInt User via Mac platform should be allowed as per Org setting');
		System.Assert.areEqual(false, apIntUsrWin, 'Login as apInt User via Windows platform should be allowed');
	}

	@isTest
	private static void testEvaluateReportEvent() {
		User adminUser = [SELECT Id FROM User WHERE Alias = 'admtsp1' LIMIT 1];
		User apIntUsr = [SELECT Id FROM User WHERE Alias = 'ainttsp3' LIMIT 1];
		User ssswAgent2 = [SELECT Id FROM User WHERE Alias = 'sA2tsp2' LIMIT 1];

		Integer rowsProcessed = 50000;
		String operation = 'ReportExported';
		String queriedEntities = 'Compensation__c,Account';
		String sensitiveReportColumn = '[Account.Name,Compensation__c.Name, Compensation__c.Account_Number__c],[LegalEntityName, Name, AccountNumber]';
		String nonSensitiveReportColumn = '[Account.Name,Compensation__c.Name],[LegalEntityName, Name]';

		// Testing
		Test.startTest();
		TransactionSecurityPolicyManager transactionSecurityPolicyManager = new TransactionSecurityPolicyManager();
		
		// Run as adminUser who has ReportEventSensitiveFieldValidation disabled as per user setting
		Boolean adminUsercheck1 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(adminUser.Id, queriedEntities, sensitiveReportColumn, operation, -1, true));
		Boolean adminUsercheck2 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(adminUser.Id, queriedEntities, sensitiveReportColumn, 'ReportPreviewed', rowsProcessed, true));
		Boolean adminUsercheck3 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(adminUser.Id, queriedEntities, sensitiveReportColumn, operation, rowsProcessed, true));
		Boolean adminUsercheck4 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(adminUser.Id, queriedEntities, nonSensitiveReportColumn, operation, rowsProcessed, true));

		// Run as apIntUsr who has ReportEventSensitiveFieldValidation enabled as per org setting
		Boolean apIntUsrcheck1 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(apIntUsr.Id, queriedEntities, sensitiveReportColumn, operation, rowsProcessed, true));
		Boolean apIntUsrcheck2 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(apIntUsr.Id, queriedEntities, nonSensitiveReportColumn, operation, rowsProcessed, true));
		Boolean apIntUsrcheck3 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(apIntUsr.Id, 'Application__c', '[Id,Name],[Id,Name]', operation, rowsProcessed, true));
		
		// Run as ssswAgent2 who has ReportEventSensitiveFieldValidation enabled as per ssswProfile setting
		Boolean ssswAgent2check1 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(ssswAgent2.Id, queriedEntities, sensitiveReportColumn, operation, rowsProcessed, true));
		Boolean ssswAgent2check2 = transactionSecurityPolicyManager.evaluate(TransactionSecurityPolicyTestDataFactory.getReportEvent(ssswAgent2.Id, queriedEntities, nonSensitiveReportColumn, operation, rowsProcessed, true));

		Test.stopTest();

		// Assert or verify
		System.assertEquals(false, adminUsercheck1, 'Report operation should be bypassed has rowsProcessed exported is less');
		System.assertEquals(false, adminUsercheck2, 'Report operation should be bypassed has operation is not export');
		System.assertEquals(false, adminUsercheck3, 'Report operation should be allowed even if sensitive fields as per adminUser setting');
		System.assertEquals(false, adminUsercheck4, 'Report operation should be allowed even if no sensitive fields as per adminUser setting');
		
		System.assertEquals(true, apIntUsrcheck1, 'Report operation should NOT be allowed even if sensitive fields as per org setting');
		System.assertEquals(false, apIntUsrcheck2, 'Report operation should be allowed as no sensitive fields');
		System.assertEquals(false, apIntUsrcheck3, 'Report operation should be allowed as object is not part of configured sensitive fields objects');

		System.assertEquals(true, ssswAgent2check1, 'Report operation should NOT be allowed even if sensitive fields as per ssswProfile setting');
		System.assertEquals(false, ssswAgent2check2, 'Report operation should be allowed as no sensitive fields');
		
	}

	@isTest
	private static void testEvaluateOthers() {
		TransactionSecurityPolicyManager transactionSecurityPolicyManager = new TransactionSecurityPolicyManager();
		Test.startTest();
		//Loginevent with Null should return false
		Boolean result1 = transactionSecurityPolicyManager.evaluate(null);

		//For all non -login events should return false
		Boolean result2 = transactionSecurityPolicyManager.evaluate(new listViewEvent());
		Test.stopTest();

		System.assertequals(false, result1, 'LoginEvent if null is not returning true');
		System.assertequals(false, result2, 'Non login events not returning false');
	}
}