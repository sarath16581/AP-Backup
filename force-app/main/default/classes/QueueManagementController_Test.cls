/**************************************************************************************
Description:    Test class to cover QueueManagementController functionality
History:
---------------------------------------------------------------------------------------
2015-10-29  paul.stamer@auspost.com.au  Created
2018-06-26  TDO-99 : rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added assertEquals and assertNotEquals, added create test data setup method
            and removed try catch from testUserAssignment method.
***************************************************************************************/
@isTest
private class QueueManagementController_Test {
    /*********************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    **********************************************************************************/
    @testSetup
    static void createTestData(){
        QM__c custSetting = new QM__c();
        custSetting.Profile__c = 'SSSW - Service Agent';
        custSetting.Customer_Status__c = 'Awaiting Customer Response';
        custSetting.Network_Status__c= 'Awaiting Network Response';
        custSetting.New_Status__c= 'New';
        insert custSetting;
    }

    /*********************************************************************************
    *  Scenario:
    *      Test the User Assignment.
    **********************************************************************************/
    @isTest
    static void testUserAssignment() {
        //Fetch a profile.
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%SSSW - Service Agent%' LIMIT 1];

        //Create a user.
        User user = new User();
        user.LastName = 'Test';
        user.FirstName = 'Test';
        user.Alias = 'sinTUser';
        user.Username = 'singleTestUser@email.com';
        user.CommunityNickname = 'sinTUser';
        user.Email = 'singleTestUser@email.com';
        user.TimeZoneSidKey = 'GMT';
        user.LocaleSidKey = 'en_AU';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.ProfileId = profile.Id;
        insert user;

        //Fetch a group.
        Group grp=[SELECT Id FROM Group WHERE DeveloperName='SSSW_Customer_Service_Reporting' LIMIT 1];

        //Create a group member.
        GroupMember gm= new GroupMember(GroupId = grp.id, UserOrGroupId = user.id );
        upsert gm;

        QueueManagementController queueManagement = new QueueManagementController();

        Test.startTest();
            //Search for user
            queueManagement.criteriaSelectedValue = 'User';

            //Search for user named 'Test'
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();
            queueManagement.save();

            queueManagement.criteriaSelectedValue = 'User';
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();

            //Assign a selected value from the available left hand side options.
            queueManagement.selectedLeftValue = new List<String>();
            queueManagement.selectedLeftValue.add(queueManagement.leftSelectOptions[0].getValue());
            queueManagement.addItems();
            queueManagement.save();

            queueManagement.criteriaSelectedValue = 'Queue';
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();

            //Assign a selected value from the available right hand side options.
            queueManagement.selectedRightValue = new List<String>();
            queueManagement.selectedRightValue.add(queueManagement.rightSelectOptions[0].getValue());
            queueManagement.removeItems();
            queueManagement.save();

            //Check that the expected message is in pageMessages.
            ApexPages.Message[] pageMessages = ApexPages.getMessages();

            System.assertNotEquals(0,pageMessages.size(),
                    'QueueManagementController_Test_testUserAssignment : pageMessages size should not be zero');

            Boolean messageFound = false;
            //Loop through the pageMessages.
            for(ApexPages.Message message : pageMessages) {
                //Check if the Changes Saved message is present.
                String msg = message.getSummary();
                if(msg.contains('Changes Saved')) {
                    messageFound = true;
                }
            }

            System.assertEquals(true,messageFound,
                    'QueueManagementController_Test_testUserAssignment : Changes Saved message should be retrieved.');

            //Call clearAllData to Re-initialize variables and clear data.
            queueManagement.clearAllData();

        Test.stopTest();
    }

    /*********************************************************************************
    *  Scenario:
    *      Test the Queue Assignment.
    **********************************************************************************/
    @isTest
    static void testQueueAssignment() {
        //Fetch a profile.
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%SSSW%' LIMIT 1];

        //Create a user.
        User user = new User();
        user.LastName = 'Test';
        user.FirstName = 'Test';
        user.Alias = 'sinTUser';
        user.Username = 'singleTestUser@email.com';
        user.CommunityNickname = 'sinTUser';
        user.Email = 'singleTestUser@email.com';
        user.TimeZoneSidKey = 'GMT';
        user.LocaleSidKey = 'en_AU';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.ProfileId = profile.Id;
        insert user;

        QueueManagementController queueManagement = new QueueManagementController();

        Test.startTest();
            //Search for user
            queueManagement.criteriaSelectedValue = 'Queue';

            //Search for user named 'Test'
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();
            queueManagement.save();
            
            queueManagement.criteriaSelectedValue = 'Queue';
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();

            //Assign a selected value from the available left hand side options.
            queueManagement.selectedLeftValue = new List<String>();
            queueManagement.selectedLeftValue.add(queueManagement.leftSelectOptions[0].getValue());
            queueManagement.addItems();
            queueManagement.save();

            queueManagement.criteriaSelectedValue = 'Queue';
            queueManagement.searchText = 'Test';
            queueManagement.queryNames();

            //Check that the expected message is in pageMessages.
            ApexPages.Message[] pageMessages = ApexPages.getMessages();

            System.assertNotEquals(0,pageMessages.size(),
                    'QueueManagementController_Test_testQueueAssignment : pageMessages size should not be zero');

            Boolean messageFound = false;
            //Loop through the pageMessages.
            for(ApexPages.Message message : pageMessages) {
                //Check if the Changes Saved message is present.
                String msg = message.getSummary();
                if(msg.contains('Changes Saved')) {
                    messageFound = true;
                }
            }

            System.assertEquals(true,messageFound,
                    'QueueManagementController_Test_testQueueAssignment : Changes Saved message should be retrieved.');

                //Call clearAllData to Re-initialize variables and clear data.
                queueManagement.clearAllData();

        Test.stopTest();
    }
}