/*
* Created by nmain on 14/07/2016.
* Author:        Nathan Main
* Company:       salesforce.com
* Description:   Test Class for event Calendar.
*
* History:       SV: 27/03/2017: Inserted account to associate with all the Event records to avoid triggering process builder Coverage_Freq_Event.
*
*/

@IsTest
private class Calendar_Controller_Test {

    //SV: 28/03/2017: Created new variable ACC_COVERAGE_METHOD to bypass the flow condition to not meet criteria. 
    //Flow: Coverage_Freq_Event, Decision Step: Event Criteria
    private static final string ACC_COVERAGE_METHOD = 'Face to Face Meeting'; 
    
    //@isTest(SeeAllData=true)
    //static void testBehavior() {
    static testmethod void testBehavior() {

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        String UserNameUnique = UserInfo.getOrganizationId() + System.now().millisecond() + 'stdusr@testorg.com';
        system.debug('--> User Name--> '+UserNameUnique);
        User u = new User(Alias = 'admin1', Email='standarduser1@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName=UserNameUnique);
        
        //SV: 28/03/2017: Inserted account to associate with the Event records to avoid triggering process builder Coverage_Freq_Event
        Account accEvent = new Account();
        System.runAs(u) {
            accEvent = new Account();
            accEvent.Name = 'Mick1234';
            accEvent.CoverageMethod__c = ACC_COVERAGE_METHOD;
            accEvent.NewLastActivityDate__c = Date.today()+10;
            insert accEvent;
        }
        
        Test.StartTest();
        
        Calendar_Controller testCalendarController = new Calendar_Controller();

        // Work around MIXED_DML error
        User testRunAsUser = new User(Id = Userinfo.getUserId());
        System.runAs(testRunAsUser) {
            DateTime futureDateTime = DateTime.now() + 1;
            DateTime pastDateTime = DateTime.now() - 5;
            //SV: Updated Type and WhatId for all event records as per above comments in history
            Event testEvent = new Event(Subject='Test Subject',Status__c='Completed',StartDateTime=futureDateTime, EndDateTime=futureDateTime+1, OwnerId=UserInfo.getUserId(), Type = 'Misc1234', WhatId = accEvent.Id);
            insert testEvent;
            Event testEvent2 = new Event(Subject='Test Subject',Status__c='Completed',StartDateTime=pastDateTime, EndDateTime=pastDateTime+1, OwnerId=UserInfo.getUserId(), Type = 'Misc1234', WhatId = accEvent.Id);
            insert testEvent2;
            Event testEvent3 = new Event(Subject='Test Subject',Status__c='Not Started',StartDateTime=futureDateTime, EndDateTime=futureDateTime+1, OwnerId=UserInfo.getUserId(), Type = 'Misc1234', WhatId = accEvent.Id);
            insert testEvent3;
            Event testEvent4= new Event(Subject='Test Subject',Status__c='Not Started',StartDateTime=pastDateTime, EndDateTime=pastDateTime+1, OwnerId=UserInfo.getUserId(), Type = 'Misc1234', WhatId = accEvent.Id);
            insert testEvent4;
        }
        Calendar_Controller.eventdata(testRunAsUser.Id);

        UserRole newUserRole1 = new UserRole(DeveloperName='TestRole_1', Name = 'TestRole_1');
        insert newUserRole1;
        UserRole role1 = [SELECT Id,Name FROM UserRole WHERE DeveloperName='TestRole_1'];
        UserRole newUserRole2 = new UserRole(DeveloperName='TestRole_2', Name = 'TestRole2', ParentRoleId =newUserRole1.Id);
        insert newUserRole2;

        Profile pf = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator'];
        User user1 = createTestUser(newUserRole1.Id,pf.Id,'TestUser1','TestUser1');
        insert user1;
        User user2 = createTestUser(newUserRole2.Id,pf.Id,'TestUser2','TestUser2');
        insert user2;


        testCalendarController.showTeamMemberEvents();
        testCalendarController.userMap = testCalendarController.getUsersForUserRole(user1.Id);
        List<SelectOption> UserOptionList = testCalendarController.getListOfUser();
        system.assert(UserOptionList.size() > 1);

        // This test assumes that there is at least one user in the Org that has a role set.
        List<User> usersWithRole = [SELECT Id,Name FROM User WHERE UserRoleId <> NULL];
        System.assert(usersWithRole.isEmpty() == false);

        //map<Id, User> userMap = testCalendarController.getUsersForUserRole(usersWithRole.get(0).Id);
        map<Id, User> userMap = testCalendarController.getUsersForUserRole(user1.Id);
        system.assert(userMap.isEmpty() == false);

        //map<Id, User> userMap2 = testCalendarController.getUsersForRoleId(usersWithRole.get(0).Id);
        map<Id, User> userMap2 = testCalendarController.getUsersForRoleId(newUserRole1.Id);
        system.assert(userMap2.isEmpty() == false);
        // Cant assert because if the first user that has a role does not have a subordinate this will fail.

        //map<Id, User> userMap3 = testCalendarController.getUsersForRoleName(usersWithRole.get(0).Name);
        map<Id, User> userMap3 = testCalendarController.getUsersForRoleName(newUserRole1.Name);
        system.assert(userMap3.isEmpty() == false);

        //set<Id> allSubRoleIds = testCalendarController.getSubRoleIds(new set<ID>{ usersWithRole.get(0).Id });
        set<Id> allSubRoleIds = testCalendarController.getSubRoleIds(new set<ID>{ newUserRole1.Id });
        system.assert(allSubRoleIds.isEmpty() == false);

        Calendar_Controller.calEvent testEmptyCalEvent = new Calendar_Controller.calEvent();
        Calendar_Controller.calEvent testCalEvent = new Calendar_Controller.calEvent('testEventTitle', false, 'testEventStartString', 'testEventEndString', 'testEventUrl', 'testEventOwnerAlias', 'testEventClassName');
        system.debug('--> Title1 --> '+testCalEvent.title);
        system.assert(testCalEvent.title == 'testEventOwnerAlias' + ' ' + 'testEventTitle');
        
        Calendar_Controller.calEvent testCalEvent2 = new Calendar_Controller.calEvent('', false, 'testEventStartString', 'testEventEndString', 'testEventUrl', 'testEventOwnerAlias', 'testEventClassName');        
        system.debug('--> Title2 --> '+testCalEvent.title);

        Test.StopTest();
    }

    public static User createTestUser(Id roleId, Id profID, String fName, String lName)
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');

        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                lastName = lName,
                email = randomInt + '@test' + orgId + '.org',
                Username = randomInt  + '@test' + orgId + '.org',
                EmailEncodingKey = 'ISO-8859-1',
                Alias = uniqueName.substring(18, 23),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = profId,
                UserRoleId = roleId,
                IsActive = true);
        return tuser;
    }
}