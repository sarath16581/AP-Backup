/**************************************************
Description:    Test class for APCommunityUserUtility class
History:
--------------------------------------------------
2019-10-22  arjun.singh@auspost.com.au  Created
**************************************************/
@isTest
public with sharing class APCommunityUserUtility_Test {
    public static id ddcConsumerCommunityProfileId = [Select Id from Profile where name =: APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME].Id;
    public static id ddcConsumerCommunityTempProfileId = [Select Id from Profile where name =: APCommunityJitLoginHandler.DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME].Id;
    public static id apOnlineCommunityMembershipPermissionSetId = [Select id from PermissionSet where name = : APCommunityJitLoginHandler.AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_NAME].Id;
    public static id consumerRecordTyeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(APCommunityUserUtility.CONSUMER_RECORD_TYPE_NAME).getRecordTypeId();
    public static Id apCommunityNetworkId = [Select Id From Network Where Name = 'Australia Post Community'].Id;
    
    @TestSetup
    public static void setup(){
        
        Account acc = TestUtility.createPersonAccount('Wayne',consumerRecordTyeId);
            acc.FirstName = 'Bruce';
            acc.PersonEmail = 'bruce@wayne.com';
            Database.insert(acc);

        Contact personContact = [Select Id From Contact Where accountId =: acc.Id];

        User portalUserRecord = TestUtility.createPortalUser('Testing0', ddcConsumerCommunityProfileId, personContact.Id) ;
        insert portalUserRecord;  
                 
    }
    /**
    * Test New User provisioning using Custom Jit Handler and correct permission Set and Profile Assignment 
    */
    public static testMethod void testAPCommunityJitHandlerWithNewUser() {

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        Integer randomNumber = Integer.valueof((Math.random() * 10));
        string userName = 'actg' +randomNumber +'@'+  'gmail.com.ap';
        attribute.put('userid',userName);
        attribute.put('firstName','firstNameTest');
        attribute.put('lastName','lastNameTest');
        attribute.put('email',userName);
        attribute.put('apcn','12345test'+randomNumber);
        attribute.put('ConsumerUserName',userName);
        attribute.put('User.Username',userName);
        attribute.put('User.Email',userName);
        attribute.put('User.LastName','abc@gmail.com');
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',ddcConsumerCommunityTempProfileId);
                
        Test.StartTest();
        handler.createUser(null, apCommunityNetworkId, apCommunityNetworkId, '12345.ap', attribute, '');
        Test.StopTest();
        User newUser = [Select id, Profile.Id from User where userName =: attribute.get('User.Username')];
        
        list<PermissionSetAssignment> permissionSetAssignmentList = [Select id from PermissionSetAssignment 
                                                                    where AssigneeId =: newUser.Id AND PermissionSetId =: apOnlineCommunityMembershipPermissionSetId];
        System.assertEquals(permissionSetAssignmentList.size(),1);
        System.assertEquals(newUser.Profile.Id, ddcConsumerCommunityProfileId);
    }
    /**
    * Test Existing User provisioning using Custom Jit Handler and correct permission Set and Profile Assignment 
    */
    public static testMethod void testAPCommunityJitHandlerWithExistingUser() {

        User existingUser = [Select id, firstName, lastName, email, userName, isActive, ProfileId, contact.apcn__c from User where lastName ='Testing0' and profileId =: ddcConsumerCommunityProfileId];

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        attribute.put('userid',existingUser.userName);
        attribute.put('firstName',existingUser.firstName);
        attribute.put('lastName',existingUser.lastName);
        attribute.put('email',existingUser.email);
        attribute.put('apcn',existingUser.contact.apcn__c);
        attribute.put('ConsumerUserName',existingUser.userName);
        attribute.put('User.Username',existingUser.userName);
        attribute.put('User.Email',existingUser.email);
        attribute.put('User.LastName',existingUser.lastName);
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',existingUser.profileId);

        list<PermissionSetAssignment> permissionSetAssignmentListBefore = [Select id from PermissionSetAssignment 
                                                                    where AssigneeId =: existingUser.Id AND PermissionSetId =: apOnlineCommunityMembershipPermissionSetId];
        System.assertEquals(permissionSetAssignmentListBefore.size(),0);
        Test.StartTest();
        handler.updateUser(existingUser.Id, null, apCommunityNetworkId, apCommunityNetworkId, existingUser.userName, attribute, '');
        Test.StopTest();

        list<PermissionSetAssignment> permissionSetAssignmentListAfter = [Select id from PermissionSetAssignment 
                                                                    where AssigneeId =: existingUser.Id AND PermissionSetId =: apOnlineCommunityMembershipPermissionSetId];
        System.assertEquals(permissionSetAssignmentListAfter.size(),1);
    }
    /**
    * Test Existing Deactivated User provisioning using Custom Jit Handler. User should be activated 
    */
    public static testMethod void testAPCommunityJitHandlerWithExistingDeactivatedUser() {

        User existingUser = [Select id, firstName, lastName, email, userName, isActive, ProfileId, contact.apcn__c from User where lastName ='Testing0' and profileId =: ddcConsumerCommunityProfileId];
        existingUser.isActive = false;
        update existingUser;

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        attribute.put('userid',existingUser.userName);
        attribute.put('firstName',existingUser.firstName);
        attribute.put('lastName',existingUser.lastName);
        attribute.put('email',existingUser.email);
        attribute.put('apcn',existingUser.contact.apcn__c);
        attribute.put('ConsumerUserName',existingUser.userName);
        attribute.put('User.Username',existingUser.userName);
        attribute.put('User.Email',existingUser.email);
        attribute.put('User.LastName',existingUser.lastName);
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',existingUser.profileId);

        Test.StartTest();
        handler.updateUser(existingUser.Id, null, apCommunityNetworkId, apCommunityNetworkId, existingUser.userName, attribute, '');
        Test.StopTest();
        User usrRec = [Select id, isActive from User where id=: existingUser.Id];
        System.assertEquals(usrRec.isActive,True);
    }

    /**
    * Test Existing User access when Disallow user Step up is true 
    */
    public static testMethod void testAPCommunityJitHandlerWithExistingDisAllowedUser() {

        User existingUser = [Select id, firstName, lastName, email, userName, isActive, ProfileId, contact.apcn__c, Disallow_Community_Stepup__c from User where lastName ='Testing0' and profileId =: ddcConsumerCommunityProfileId];
        existingUser.Disallow_Community_Stepup__c = true;
        update existingUser;

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        attribute.put('userid',existingUser.userName);
        attribute.put('firstName',existingUser.firstName);
        attribute.put('lastName',existingUser.lastName);
        attribute.put('email',existingUser.email);
        attribute.put('apcn',existingUser.contact.apcn__c);
        attribute.put('ConsumerUserName',existingUser.userName);
        attribute.put('User.Username',existingUser.userName);
        attribute.put('User.Email',existingUser.email);
        attribute.put('User.LastName',existingUser.lastName);
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',existingUser.profileId);

        Test.StartTest();
        try{
            handler.updateUser(existingUser.Id, null, apCommunityNetworkId, apCommunityNetworkId, existingUser.userName, attribute, '');
        }catch (Exception e){
            System.assertEquals(e.getMessage(),APCommunityJitLoginHandler.DISALLOWED_COMMUNITY_SEPTUP_MESSAGE);
        }
        Test.StopTest();
        User usrRec = [Select id, isActive from User where id=: existingUser.Id];
        System.assertEquals(usrRec.isActive,True);
    }
    /**
    * Test Existing User with Temp Profile 
    */
    public static testMethod void testAPCommunityJitHandlerWithExistingTempProfileUser() {

        User existingUser = [Select id, firstName, lastName, email, userName, isActive, ProfileId, contact.apcn__c, Disallow_Community_Stepup__c from User where lastName ='Testing0' and profileId =: ddcConsumerCommunityProfileId];
        existingUser.profileId = ddcConsumerCommunityTempProfileId;
        update existingUser;

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        attribute.put('userid',existingUser.userName);
        attribute.put('firstName',null);
        attribute.put('lastName',existingUser.lastName);
        attribute.put('email',existingUser.email);
        attribute.put('apcn',existingUser.contact.apcn__c);
        attribute.put('ConsumerUserName',existingUser.userName);
        attribute.put('User.Username',existingUser.userName);
        attribute.put('User.Email',existingUser.email);
        attribute.put('User.LastName',existingUser.lastName);
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',existingUser.profileId);

        Test.StartTest();
            handler.updateUser(existingUser.Id, null, apCommunityNetworkId, apCommunityNetworkId, existingUser.userName, attribute, '');
        Test.StopTest();
        User usrRec = [Select id, profileId from User where id=: existingUser.Id];
        System.assertEquals(usrRec.profileId,ddcConsumerCommunityProfileId);
    } 
    /**
    * Test Exception Scenarios 
    */
    public static testMethod void testExceptionScenarios() {

        User existingUser = [Select id, firstName, lastName, email, userName, isActive, ProfileId, contact.apcn__c, Disallow_Community_Stepup__c from User where lastName ='Testing0' and profileId =: ddcConsumerCommunityProfileId];
        
        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        attribute.put('userid',existingUser.userName);
        attribute.put('firstName',existingUser.firstName);
        attribute.put('lastName',existingUser.lastName);
        attribute.put('email',existingUser.email);
        attribute.put('apcn',existingUser.contact.apcn__c);
        attribute.put('ConsumerUserName',existingUser.userName);
        attribute.put('User.Username',existingUser.userName);
        attribute.put('User.Email',null);
        attribute.put('User.LastName',existingUser.lastName);
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',existingUser.profileId);

        Test.StartTest();
        try{
            handler.updateUser(existingUser.Id, null, apCommunityNetworkId, apCommunityNetworkId, existingUser.userName, attribute, '');
        }catch (Exception e){
            System.assert(e.getMessage() != null);
        }
        Test.StopTest();
    } 
     /**
    * Test New User creation Exception Scenario 
    */
    public static testMethod void testExceptionScenarioForNewUserCreation() {

        APCommunityJitLoginHandler handler = new APCommunityJitLoginHandler();
        Map<String, String> attribute = new Map<String, String>();

        Integer randomNumber = Integer.valueof((Math.random() * 10));
        string userName = 'actg' +randomNumber +'@'+  'gmail.com.ap';
        attribute.put('userid',userName);
        attribute.put('firstName','firstNameTest');
        attribute.put('lastName','lastNameTest');
        attribute.put('email',userName);
        attribute.put('apcn','12345test'+randomNumber);
        attribute.put('ConsumerUserName',userName);
        attribute.put('User.Username',userName);
        attribute.put('User.Email',null);
        attribute.put('User.LastName','abc@gmail.com');
        attribute.put('User.IsActive','1');
        attribute.put('User.ProfileId',ddcConsumerCommunityTempProfileId);
       
        Test.StartTest();
        try{
            handler.createUser(null, apCommunityNetworkId, apCommunityNetworkId, '12345.ap', attribute, '');
        }catch (Exception e){
            System.assert(e.getMessage() != null);
        }
        Test.StopTest();
    }              
}