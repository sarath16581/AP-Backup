/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Test Class for FeedItemTrigger
  */
@isTest
public with sharing class FeedItemTrigger_Test {
    
     // Variables
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String CHATTER_GRP = 'Service - Urgent Notifications';
    
    /**
      * @description       This method creates test data used to trigger entitlement process
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static void createTestAllowPostSettings(String grpId,String userIds,String roleIds,String profileIds,String permSet){
        AllowChatterPostSettings__c postSetting = new AllowChatterPostSettings__c ();
        postSetting.Name = 'Urgent Notifications';
        postSetting.ChatterGroup__c = grpId;
        postSetting.AllowUsers__c = userIds;
        postSetting.AllowProfiles__c = profileIds;
        postSetting.AllowRoles__c = roleIds;
        postSetting.AllowPermissionSet__c = permSet;
        Database.insert(postSetting);
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_NoCustomSettings(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.id);
            
            Test.startTest();
                Database.insert(post);
            Test.stopTest();
            
            FeedItem feed = [SELECT Id FROM FeedItem WHERE Id =: post.Id];
            System.assert(feed != null);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_NoCustomSettings(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.id);
            Database.insert(post);
            
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                Database.insert(comment);
            Test.stopTest();
            
            FeedComment feed = [SELECT Id FROM FeedComment WHERE Id =: comment.Id];
            System.assert(feed != null);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_NoProfile(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                try{
                    Database.insert(post);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_Profile(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        createTestAllowPostSettings(chatterGroup.Id,null,null,prof.id,null);
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                Database.insert(post);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_NoProfile(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        
        FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
        Database.insert(post);
        createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                try{
                    Database.insert(comment);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_Profile(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        
        FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
        Database.insert(post);
        createTestAllowPostSettings(chatterGroup.Id,null,null,prof.id,null);
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                Database.insert(comment);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_NoRole(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.Id)){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                try{
                    Database.insert(post);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_Role(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.Id)){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            createTestAllowPostSettings(chatterGroup.Id,null,role.id,null,null);
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                Database.insert(post);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_NoRole(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        FeedItem post;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            Database.insert(post);
            createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
        }
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.Id)){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                try{
                    Database.insert(comment);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_Role(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        FeedItem post;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            Database.insert(post);
            createTestAllowPostSettings(chatterGroup.Id,null,role.id,null,null);
        }
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,role.Id)){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                Database.insert(comment);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_NoUser(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.Id);
        Database.insert(runningUser);
        
        System.runAs(runningUser){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                try{
                    Database.insert(post);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testPostAccess_CustomSettings_User(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.Id);
        Database.insert(runningUser);
        
        System.runAs(runningUser){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            createTestAllowPostSettings(chatterGroup.Id,runningUser.id,null,null,null);
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            
            Test.startTest();
                Database.insert(post);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedItem];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_NoUser(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.Id);
        Database.insert(runningUser);
        
        FeedItem post;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            Database.insert(post);
            createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
        }
        
        System.runAs(runningUser){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                try{
                    Database.insert(comment);
                }
                catch(DMLException exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals(Label.CHATTER_POST_ACCESS_MSG,exp.getDmlMessage(0));
                }
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       This method tests scenario of creating new case without assigning to HLC agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCommentAccess_CustomSettings_User(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        UserRole role = TestUtility.getUserRole('SSSW_North_Service_Agent');
        
        User runningUser = TestUtility.createUser('Wayne',prof.id,role.Id);
        Database.insert(runningUser);
        
        FeedItem post;
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            post = TestUtility.createChatterPost('Test Post',chatterGroup.Id);
            Database.insert(post);
            createTestAllowPostSettings(chatterGroup.Id,runningUser.id,null,null,null);
        }
        
        System.runAs(runningUser){
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Test.startTest();
                Database.insert(comment);
            Test.stopTest();
            
            Integer postCount = [SELECT count() FROM FeedComment];
            System.assertEquals(1,postCount);
        }
    }
    
    /**
      * @description       Test method to validate deletion and undelete of Case
                           Scenario is not part of requirement, created for code coverage purpose only
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFeedItemDeleteUndelete(){
        Profile prof = [SELECT Id FROM Profile WHERE Name =: ADMIN_PROFILE LIMIT 1];
        User adminUser = TestUtility.createUser('Admin',prof.id,null);
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        System.runAs(adminUser){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.id);
            Database.insert(post);
            Database.delete(post);
            Test.startTest();
                //Database.undelete(post);
            Test.stopTest();
        }
    }
    
    /**
      * @description       Test method to validate deletion and undelete of Case
                           Scenario is not part of requirement, created for code coverage purpose only
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testFeedCommentDeleteUndelete(){
        Profile prof = [SELECT Id FROM Profile WHERE Name =: ADMIN_PROFILE LIMIT 1];
        User adminUser = TestUtility.createUser('Admin',prof.id,null);
        CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
        Database.insert(chatterGroup);
        System.runAs(adminUser){
            FeedItem post = TestUtility.createChatterPost('Test Post',chatterGroup.id);
            Database.insert(post);
            FeedComment comment = TestUtility.createChatterPostComment('Added Comment',post.Id);
            Database.insert(comment);
            Database.delete(comment);
            Test.startTest();
                //Database.undelete(comment);
            Test.stopTest();
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            CollaborationGroup chatterGroup = TestUtility.createChatterGroup(CHATTER_GRP, 'Public');
            Database.insert(chatterGroup);
            createTestAllowPostSettings(chatterGroup.Id,null,null,null,null);
            
            FeedItemTriggerHelper helper = new FeedItemTriggerHelper();
            Test.startTest();
                try{
                    helper.verifyAccess(new List<Case>{null});
                }
                catch(Exception exp){
                    System.debug('** Exception Type ==>'+ exp.getTypeName());
                    System.assertEquals('System.NullPointerException',exp.getTypeName());
                }
            Test.stopTest();
            
        }
    }
    
}