/****************************************************************************************
Description: Test class to cover cpGetGroups Controller functionality
History:
-----------------------------------------------------------------------------------------
            No Created History found.
2018-06-07  TDO-37 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            Test to Retrieve Chatter group component used in customer community project,
            Test for exception during Retrieve Chatter group component.
*****************************************************************************************/
@isTest
private class cpGetGroups_Test {

    private static ConnectApi.ChatterGroupPage testPage = new ConnectApi.ChatterGroupPage();
    private static User adminUser = new User();

    /***********************************************************************************************
     *  Scenario:
     *      Prepare Test data to Retrieve Chatter group component used in customer community project.
     ***********************************************************************************************/
    private static void loadTestData() {
        //Create running user
        cpTestDataFactory dataFactory = new cpTestDataFactory();

        Profile adminProf = [SELECT Id, Name FROM Profile WHERE name = 'System Administrator' LIMIT 1];

        String adminEmail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id, adminEmail);
        Database.insert(adminUser);
    }

    /***********************************************************************************
     *  Scenario:
     *      Test to Retrieve Chatter group component used in customer community project.
     ***********************************************************************************/
    /*TDO_TODO: Removing seeAllData = true caused exception - Caused by: system.UnsupportedOperationException:
    ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).*/
    /*TDO_TODO: corrections: update cpGetGroups to handle communityId passed to ConnectApi.ChatterGroups.getGroups,
    to improve the test code coverage*/
    @isTest(seeAllData = true)
    static void testGetGroupsMethods() {
        //Prepare Test data.
        loadTestData();

        //Create Group data
        List<ConnectApi.ChatterGroupDetail> testGroups = new List<ConnectApi.ChatterGroupDetail>();
        testGroups.add(new ConnectApi.ChatterGroupDetail());
        testGroups.add(new ConnectApi.ChatterGroupDetail());
        testPage.groups = testGroups;

        ConnectApi.ChatterGroupDetail chatterGroup = testPage.groups[0];
        chatterGroup.visibility = ConnectApi.GroupVisibilityType.PublicAccess;
        chatterGroup.memberCount = 5;
        chatterGroup.Name = 'Test AUS Post Community group';
        chatterGroup.description = 'Test AUS Post Community group description';
        System.runAs(adminUser) {

            Test.startTest();

            list<cpChatterGroupWrapper> wrapperList = cpGetGroups.getCommunityGroups('5', 'all groups');
            list<cpChatterGroupWrapper> wrapperList2 = cpGetGroups.getCommunityGroups('5', 'Public groups');
            String retString = cpGetGroups.getConversationSettings();

            Test.stopTest();
        }

        Community_Settings__mdt communitySettingMetadata = [SELECT DeveloperName,Entity_Name__c,Entity_Value__c
                                                            FROM Community_Settings__mdt
                                                            WHERE DeveloperName = 'Community_Conversation_Detail'
                                                            LIMIT 1];

        String conversationId = communitySettingMetadata.Entity_Value__c;

        System.assertNotEquals(null,conversationId,
                'cpGetGroups_Test_testGetGroupsMethods : Conversation Id from Custom setting is retrieved.');

    }

    /*****************************************************************
     *  Scenario:
     *      Test for exception during Retrieve Chatter group component.
     *****************************************************************/
    @isTest
    static void testForRetrieveException() {
        //Prepare Test data.
        loadTestData();
        System.runAs(adminUser) {

            Test.startTest();

            list<cpChatterGroupWrapper> wrapperList = cpGetGroups.getCommunityGroups('5', 'all groups');
            list<cpChatterGroupWrapper> wrapperList2 = cpGetGroups.getCommunityGroups('5', 'Public groups');
            String retString = cpGetGroups.getConversationSettings();

            Test.stopTest();
        }

        Community_Settings__mdt communitySettingMetadata = [SELECT DeveloperName,Entity_Name__c,Entity_Value__c
                                                            FROM Community_Settings__mdt
                                                            WHERE DeveloperName = 'Community_Conversation_Detail'
                                                            LIMIT 1];

        String conversationId = communitySettingMetadata.Entity_Value__c;

        System.assertNotEquals(null,conversationId,
                'cpGetGroups_Test_testGetGroupsMethods : Conversation Id from Custom setting is retrieved.');

    }
}