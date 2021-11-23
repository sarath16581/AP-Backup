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
}