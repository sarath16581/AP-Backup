/**
* Tests for the TransactionEventCondition class, to make sure that our 
  Transaction Security Apex logic handles events and event field values as expected.
--------------------------------------- History --------------------------------------------------
* Created 04/08/2022 -Swati.mogadala@auspost.com.au
 **/
@isTest
public class TransactionEventConditionTest {
    
    @testsetup
    public static void setup() {
        //Creating custom setting 
        Transaction_Security_Policy__c settings = new Transaction_Security_Policy__c();
       	settings.Name='LoginEvent';
        settings.Profiles_to_Monitor__c = 'SSSW - Service Agent';
        settings.Platform__c ='Windows';
       	insert settings;
    }
 
     /**
      * Positive test case 1: Evaluate will return true when the user has the "SSSW- Service Agent Profile"
      **/ 
      static testMethod void testUserWithSSSWProfile() {
          // insert a User for our test which has the SSSW- Service Agent profile
          Profile profile = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent'];
          User user = createUserWithProfile(profile.id);
          insert user;
          // set up our event and its field values
          LoginEvent testEvent = new LoginEvent();
          testEvent.UserId = user.Id;
          testEvent.Platform ='Android';
          // test that the Apex returns true for this event
          TransactionEventCondition eventCondition = new TransactionEventCondition();
 		  System.assertEquals(true, eventCondition.evaluate(testEvent),'SSSW service agent trying to logon not using Windows Platform'); 
    
      }

    //negative test case 1
      
     	static testMethod void testUserWithCustomProfile() {
          // insert a User for our test which has the SSSW- Service Agent profile
          Profile profile = [SELECT Id FROM Profile WHERE Name='SSSW - Service Agent'];
          User user = createUserWithProfile(profile.id);
          insert user;
          // set up our event and its field values
          LoginEvent testEvent = new LoginEvent();
          testEvent.UserId = user.Id;
          testEvent.Platform ='Windows';
          // test that the Apex returns true for this event
          TransactionEventCondition eventCondition = new TransactionEventCondition();
          System.assertEquals(false, eventCondition.evaluate(testEvent));  
      }
      //negative test case 2
      static testMethod void testUserWithSomeProfile() {
          // insert a User for our test which has the System Admin profile
          Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
         // assertOnProfile(profile.id, false);
          User user = createUserWithProfile(profile.id);
          insert user;
          // set up our event and its field values
          LoginEvent testEvent = new LoginEvent();
          testEvent.UserId = user.Id;
          testEvent.Platform ='Mac';
          // test that the Apex returns true for this event
          TransactionEventCondition eventCondition = new TransactionEventCondition();
          System.assertEquals(false, eventCondition.evaluate(testEvent));  
      }
      static User createUserWithProfile(String profileId){
          // Usernames have to be unique.
          String username = 'LoginEventCondition@Test.com';
          User user = new User(Alias = 'standt', Email='standarduser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = profileId, 
          TimeZoneSidKey='America/Los_Angeles', UserName=username);
          return user;
      }
 }