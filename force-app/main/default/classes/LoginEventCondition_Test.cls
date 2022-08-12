/**
* Tests for the TransactionEventCondition class, to make sure that our 
  Transaction Security Apex logic handles events and event field values as expected.
--------------------------------------- History --------------------------------------------------
* Created 04/08/2022 -Swati.mogadala@auspost.com.au
 **/
@isTest
public class LoginEventCondition_Test {// Test variable declaration
    public static final string SSSW_PROFILE_NAME = 'SSSW - Service Agent';
    public static final string ADMIN_PROFILE_NAME = 'System Administrator';

    @testSetup 
    static void testSetup() {
        // insert a User for our test which has the SSSW- Service Agent profile
        Profile ssswAgentProfile = [SELECT Id FROM Profile WHERE Name = :SSSW_PROFILE_NAME];
        User ssswAgentUser = TestUtility.createUser('Test', ssswAgentProfile.id, null);
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = :ADMIN_PROFILE_NAME];
        User adminUser = TestUtility.createUser('Test', adminProfile.id, null);
        List<User> userList = new List<User>{ssswAgentUser, adminUser};
        insert userList;
    }

    @isTest
    static void testUserWithSSSWProfileWithAndroid() {
        User user = [SELECT Id FROM User where Profile.Name = :SSSW_PROFILE_NAME LIMIT 1];
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Android';

        // test that the Apex returns true for this event
        Test.startTest();
            LoginEventCondition eventCondition = new LoginEventCondition();
            System.assertEquals(true, eventCondition.evaluate(testEvent), 'SSSW service agent trying to log not using Windows');
        Test.stopTest();
    }

    @isTest
    static void testUserWithSSSWProfileWithWindows() {
        User user = [SELECT Id FROM User where Profile.Name = :SSSW_PROFILE_NAME LIMIT 1];
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Windows';

        // test that the Apex returns true for this event
        Test.startTest();
            LoginEventCondition eventCondition = new LoginEventCondition();
            System.assertEquals(false, eventCondition.evaluate(testEvent));
        Test.stopTest();
    }
  
	@isTest
    static void testUserWithAdminProfileWithMac() {
        User user = [SELECT Id FROM User where Profile.Name = :ADMIN_PROFILE_NAME LIMIT 1];
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Mac';

        // test that the Apex returns true for this event
        Test.startTest();
            LoginEventCondition eventCondition = new LoginEventCondition();
            System.assertEquals(false, eventCondition.evaluate(testEvent));
        Test.stopTest();
    }

}