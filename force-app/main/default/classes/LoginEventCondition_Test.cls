/**
* Tests for the TransactionEventCondition class, to make sure that our 
  Transaction Security Apex logic handles events and event field values as expected.
--------------------------------------- History --------------------------------------------------
* Created 04/08/2022 -Swati.mogadala@auspost.com.au
 **/
@isTest
public class LoginEventCondition_Test {


    /**
     * Positive test case 1: Evaluate will return true when the user has the "SSSW- Service Agent Profile"
     **/
    static testMethod void testUserWithSSSWProfile() {
        // insert a User for our test which has the SSSW- Service Agent profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'SSSW - Service Agent'];
        User user = TestUtility.createUser('Test', profile.id, null);
        insert user;
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Android';

        // test that the Apex returns true for this event
        LoginEventCondition eventCondition = new LoginEventCondition();
        System.assertEquals(true, eventCondition.evaluate(testEvent), 'SSSW service agent trying to log not using Windows');

    }

    //Negative test case

    static testMethod void testUserWithCustomProfile() {
        // insert a User for our test which has the SSSW- Service Agent profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'SSSW - Service Agent'];
        User user = TestUtility.createUser('Test', profile.id, null);
        insert user;
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Windows';

        // test that the Apex returns true for this event
        LoginEventCondition eventCondition = new LoginEventCondition();
        System.assertEquals(false, eventCondition.evaluate(testEvent));
    }
  
	//Negative test case
  
    static testMethod void testUserWithSomeProfile() {
        // insert a User for our test which has the System Admin profile
        Profile profile = [SELECT id, Name FROM Profile WHERE Name = 'Standard User'];
        // assertOnProfile(profile.id, false);
        User user = TestUtility.createUser('Test', profile.Id, null);
        insert user;
        // set up our event and its field values
        LoginEvent testEvent = new LoginEvent();
        testEvent.UserId = user.Id;
        testEvent.Platform = 'Mac';

        // test that the Apex returns true for this event
        LoginEventCondition eventCondition = new LoginEventCondition();
        System.assertEquals(false, eventCondition.evaluate(testEvent));
    }

}