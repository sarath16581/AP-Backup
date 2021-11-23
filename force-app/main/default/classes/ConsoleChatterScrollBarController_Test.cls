/**
 * @author S Judd
 * @date 26/4/2021
 * @description Test for Console footer page controller for Customer Service app.
 * @domain Contact Centre Service Cloud
 */

@IsTest
private class ConsoleChatterScrollBarController_Test {

   static void setup() {
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'SSSW - Service Agent'];
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');
        insert testUser;

        // create chatter group
        String groupName = 'Test Console Chatter Group Name';

        CollaborationGroup theGroup = new CollaborationGroup();
        theGroup.CollaborationType = 'Private';
        theGroup.isBroadcast = true;
        theGroup.Name = groupName;

        insert theGroup;

        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = theGroup.Id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.MemberId = testUser.Id;

        insert groupMember;
    }

    @isTest
    static void testConsoleChatterScrollBar() {
        setup();
        //Insert a post against the ChatterGroup
        String groupName = 'Test Console Chatter Group Name';
        CollaborationGroup theGroup = [SELECT Id from CollaborationGroup where Name =:groupName LIMIT 1];
        User testUsr = [SELECT Id from User WHERE Alias = 'testusr'];

        FeedItem f = new FeedItem();
        f.Body = 'sssw test';
        f.parentid = theGroup.id;
        insert f;
        // Test for the chatter group id
        System.runAs(testUsr) {
            Test.startTest();
            ConsoleChatterScrollBarController ctrl = new ConsoleChatterScrollBarController();
            Test.stopTest();
            System.assertEquals(ctrl.chatterGroupId,+theGroup.id);
        }

    }
}