/**
 * @description Test class for LimitLoginSecurityPolicy Class
 * @author Swati Mogadala
 * @date 2022-09-21
 * @group Tests
 * @changelog
 * 2022-09-21 - Swati Mogadala - Created
 */
@isTest
public class LimitLoginSecurityPolicy_Test {
   /**
	 * Test: When logging user is 'System Support user' 
	 * Validate that user is bypassed for all login events 
	 */
   @isTest
   private static void testEvaluateHandleLoginEventAsSystemSupportUser() {
      //Generate Login User
      Id ssuppId = SecurityPolicyTestDataFactory.systemSupportUserId;
      
      //Testing
      Test.startTest();
         LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
         // Test Admin User logging via Mac Platform
         Boolean ssupp1 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssuppId, 'Mac', true));
         // Test Admin User logging via Windows Platform
         Boolean ssupp2 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssuppId, 'Windows', true));
      Test.stopTest();
   
      //Assert or verify
      System.assertequals(false, ssupp1, 'Login as System Support User via Mac platform is not working');  
      System.assertequals(false, ssupp2, 'Login as System Support User via Windows platform is not working');  
   }
   /**
	 * Test: When logging user has a 'System Administrator' profile 
	 * Validate that user is bypassed for all login events 
	 */
   @isTest
   private static void testEvaluateHandleLoginEventAsAdminProfileUser() {
      //Generate Login User
      Profile adminProfile = [SELECT Id,Name FROM Profile where Name =: SecurityPolicyUtil.ADMIN_PROFILE LIMIT 1];
      User adminUser = ApplicationTestDataFactory.getUsers(1, adminProfile.Id, true)[0];
      adminUser = (User) ApplicationTestDataFactory.setUnwritableFields(adminUser, new Map<String, Object>{'Profile' => adminProfile});
      Map<Id, User> userMap = new Map<Id, User>{adminUser.Id => adminUser};

      // Stubbing 
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);

		// set up our responses		
		MockUtility.Mocks.startStubbing();
         MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(userMap);
		MockUtility.Mocks.stopStubbing();

      //Testing
      Test.startTest();
         LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
         Boolean admin1 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(adminUser.Id, 'Mac', true));
         Boolean admin2 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(adminUser.Id, 'Windows', true));
      Test.stopTest();
   
      //Assert or verify
      System.assertequals(false, admin1, 'Login as Admin Profile User via Mac platform is not working');  
      System.assertequals(false, admin2, 'Login as Admin Profile User via Windows platform is not working');      
   }
   /**
	 * Test: When logging user's profile has been restricted for login security policy via custom settings 
	 * Validate that user is blocked when logging via non-Windows platform only 
	 */
   @isTest
   private static void testEvaluateHandleLoginEventAsSSSWLoginEnforcedProfileUser() {
      //Generate Login User
      Profile ssswProfile = [SELECT Id,Name FROM profile where Name =: SecurityPolicyUtil.SSSW_AGENT_PROFILE LIMIT 1];
      User ssswLoginEnforcedUser = ApplicationTestDataFactory.getUsers(1, ssswProfile.Id, true)[0];
      ssswLoginEnforcedUser = (User) ApplicationTestDataFactory.setUnwritableFields(ssswLoginEnforcedUser, new Map<String, Object>{'Profile' => ssswProfile});
      Map<Id, User> userMap = new Map<Id, User>{ssswLoginEnforcedUser.Id => ssswLoginEnforcedUser};

      //Generate Sample Security Policies having SSSW Agent Profile with all policies enforced, where as ssswLoginByPassUser and Organisation having all policies NOT enforced/bypassed
      User ssswLoginByPassUser = ApplicationTestDataFactory.getUsers(1, SecurityPolicyTestDataFactory.ssswProfileId, true)[0];
      List<SecurityPolicy__c> policyList = SecurityPolicyTestDataFactory.getSampleSecurityPolicies(SecurityPolicyTestDataFactory.ssswProfileId, ssswLoginByPassUser.Id);

      // Stubbing
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
      CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);
      
      // set up our responses		
		MockUtility.Mocks.startStubbing();
         MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(userMap);
         MockUtility.Mocks.when(settingsSelector.selectBySetupOwnerId((Set<Id>)fflib_Match.anyObject())).thenReturn(policyList);
		MockUtility.Mocks.stopStubbing();

      //Testing
      Test.startTest();
         LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
         Boolean ssswLoginEnforced1 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssswLoginEnforcedUser.Id, 'Mac', true));
         Boolean ssswLoginEnforced2 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssswLoginEnforcedUser.Id, 'Windows', true));
      Test.stopTest();
   
      //Assert or verify
      System.assertequals(true, ssswLoginEnforced1, 'Login as SSSW Agent Profile User having Login Enforced in Custom Settings via Mac platform is not working');  
      System.assertequals(false, ssswLoginEnforced2, 'Login as SSSW Agent Profile User having Login Enforced in Custom Settings via Windows platform is not working');      
   }
   /**
	 * Test: When logging user has been bypassed for login security policy via custom settings 
	 * Validate that user is not blocked when logging via non-Windows platform alsoa
	 */
   @isTest
   private static void testEvaluateHandleLoginEventAsSSSWLoginByPassUser() {
      //Generate Login User
      Profile ssswProfile = [SELECT Id,Name FROM profile where Name =: SecurityPolicyUtil.SSSW_AGENT_PROFILE LIMIT 1];
      User ssswLoginByPassUser = ApplicationTestDataFactory.getUsers(1, ssswProfile.Id, true)[0];
      ssswLoginByPassUser = (User) ApplicationTestDataFactory.setUnwritableFields(ssswLoginByPassUser, new Map<String, Object>{'Profile' => ssswProfile});
      Map<Id, User> userMap = new Map<Id, User>{ssswLoginByPassUser.Id => ssswLoginByPassUser};

      //Generate Sample Security Policies having SSSW Agent Profile with all policies enforced, where as ssswLoginByPassUser and Organisation having all policies NOT enforced/bypassed
      List<SecurityPolicy__c> policyList = SecurityPolicyTestDataFactory.getSampleSecurityPolicies(SecurityPolicyTestDataFactory.ssswProfileId, ssswLoginByPassUser.Id);

      // Stubbing 
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
      CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		// set up our responses		
		MockUtility.Mocks.startStubbing();
         MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(userMap);
         MockUtility.Mocks.when(settingsSelector.selectBySetupOwnerId((Set<Id>)fflib_Match.anyObject())).thenReturn(policyList);
		MockUtility.Mocks.stopStubbing();

      //Testing
      Test.startTest();
         LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
         Boolean ssswByPass1 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssswLoginByPassUser.Id, 'Mac', true));
         Boolean ssswByPass2 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(ssswLoginByPassUser.Id, 'Windows', true));
      Test.stopTest();
   
      //Assert or verify
      System.assertequals(false, ssswByPass1, 'Login as SSSW Agent Profile User who has been explicitely bypassed in Custom Setting via Mac platform is not working');  
      System.assertequals(false, ssswByPass2, 'Login as SSSW Agent Profile User who has been explicitely bypassed in Custom Setting via Windows platform is not working');      
   }
   /**
	 * Test:  
	 * Validate that all non login events and null events are handled and return false for login event Security transaction policy
	 */
   @isTest
   private static void testEvaluateOthers() {
      
      LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
      Test.startTest();
         //Loginevent with Null should return false
         Boolean result1 = testLimitLoginSecurityPolicy.evaluate(null);

         //For all non -login events should return false
         Boolean result2 = testLimitLoginSecurityPolicy.evaluate(new apiEvent());
      Test.stopTest();

      System.assertequals(false, result1, 'LoginEvent if null is not returning false');
      System.assertequals(false, result2, 'Non login events not returning false');
   }
   /**
	 * Test: Validate that any exception will be handled 
	 */
   @isTest
   private static void testEvaluateExceptionScenario(){
      Test.startTest();
      try {
         LimitLoginSecurityPolicy testLimitLoginSecurityPolicy = new LimitLoginSecurityPolicy();
         Boolean result1 = testLimitLoginSecurityPolicy.evaluate(SecurityPolicyTestDataFactory.getLoginEvent(null, null, true));
      } catch (Exception e) {
       System.assert(true, 'Expected Exception to be thrown');
      }
      Test.stopTest();
   }
}