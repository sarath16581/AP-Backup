@isTest
public class TestDataFactory {

    public static void createStandardUser(){
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');
        insert testUser;
    }

    public static void createCommunityUser(){
        Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'];

        Account acc = new Account(Name='TestCommunity', OwnerId = UserInfo.getUserId());
        insert acc;

        Contact communityUserContact = new Contact(
                FirstName = 'Test',
                LastName = 'Community',
                AccountId = acc.Id,
                Email = 'testcommunity@example.com'
        );
        insert communityUserContact;

        User testCommunityUser = new User(Alias = 'testcomm', Email='testcommunityusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Community', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = communityUserProfile.Id, IsActive=true,
                TimeZoneSidKey='America/Los_Angeles', UserName='testcommunityusr@testorg.com', ContactId=communityUserContact.Id);
        insert testCommunityUser;
    }
    
    //.. Creating LPO Community User. @auther: rajesh.punjabi@mav3rik.com
    public static User createLPOCommunityUser(){
        Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];

        Account acc = new Account(Name='TestCommunity', OwnerId = UserInfo.getUserId());
        insert acc;

        Contact communityUserContact = new Contact(
                FirstName = 'Test',
                LastName = 'Community',
                AccountId = acc.Id,
                Email = 'testcommunity@example.com'
        );
        insert communityUserContact;

        User testCommunityUser = new User(Alias = 'testcomm', Email='testcommunityusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Community', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = communityUserProfile.Id, IsActive=true,
                TimeZoneSidKey='America/Los_Angeles', UserName='testcommunityusr@testorg.com', ContactId=communityUserContact.Id);
        insert testCommunityUser;
        
        return testCommunityUser;
    }

    @future
    public static void insertUserFuture(String profileName, Set<String> permissionSets, String UserName, String role) {
        Profile p = [SELECT Id FROM Profile WHERE Name=: profileName];
        UserRole r = [SELECT Id FROM UserRole WHERE Name =: role];

        User futureUser = new User(firstname = UserName, lastname = UserName,
                alias = 'future', defaultgroupnotificationfrequency = 'N',
                digestfrequency = 'N', email = 'test@test.org',
                emailencodingkey = 'UTF-8', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p.Id,
                timezonesidkey = 'America/Los_Angeles',
                username = UserName+'@test.org',
                userpermissionsmarketinguser = false,
                userpermissionsofflineuser = false, userroleid = r.Id);
        insert(futureUser);
        list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>();
        List<PermissionSet> permissionSetsToAssign = [SELECT Id FROM PermissionSet WHERE Name IN: permissionSets] ;
        for(PermissionSet permSet: permissionSetsToAssign) {
            permissionSetAssignmentList.add(new PermissionSetAssignment (PermissionSetId = permSet.Id, AssigneeId = futureUser.Id));
        }

        insert permissionSetAssignmentList;
    }
}