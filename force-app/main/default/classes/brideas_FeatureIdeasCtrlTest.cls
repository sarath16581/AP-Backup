/**************************************************************************************
Description:    Test class to cover brideas_FeatureIdeasCtrl functionality
History:
---------------------------------------------------------------------------------------
            No Created History found.
2018-07-31  Rahul Kapoor  Refactored comments and indentation, modified create test data
            setup method, added new testGetUserInfo, testGetTopHomeIdeas,
            testGetTopFeaturedIdeas and testAddVote test methods.
***************************************************************************************/
@IsTest
private class brideas_FeatureIdeasCtrlTest {
    /*********************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    **********************************************************************************/
    @testSetup
    static void setup() {
        Idea testIdea_1;
        List<Idea> ideasList;
        List<Idea> ideas = new List<Idea>();

        //Fetch the profile.
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        //Fetch the community Id.
        String cId = brideas_Helper.getCommunityId('');

        if (cId == NULL || cId == '') {
            throw new brideas_SetupException('To succesfully run the tests you need to crete a Zone with Name="TestPublic"');
        }

        //Create a user.
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com', Work_Center_Code__c='123456');


        //Create new ideas with Home and Featured pages.
            for (Integer i = 0; i < 8; i++) {
                if (i < 3) {
                    ideas.add(new Idea(Title = 'Test idea_1' + i, Homepage__c = true, Body = 'Body of test idea_1', Status = 'New', Categories = 'test_1', CommunityId = cId));
                } else {
                    ideas.add(new Idea(Title = 'Test idea_2' + i, Featured__c = true, Body = 'Body of test idea_2', Status = 'New', Categories = 'test_2', CommunityId = cId));
                }
            }

            insert ideas;

        //Create new ideas with Home and Featured pages.
        ideasList = new List<Idea>();
        ideasList.add(new Idea(Title='Test idea_1', Homepage__c = true, Body='Body of test idea_1', Status='New', Categories='test_1', CommunityId=cId));
        ideasList.add(new Idea(Title='Test idea_2', Homepage__c = true, Body='Body of test idea_2', Status='Delivered', Categories='test_1', CommunityId=cId));
        ideasList.add(new Idea(Title='Test idea_3', Featured__c = true, Body='Body of test idea_3', Status='New', Categories='test_2', CommunityId=cId));
        ideasList.add(new Idea(Title='Test idea_4', Featured__c = true, Body='Body of test idea_4', Status='New', Categories='test_2', CommunityId=cId));

        insert ideasList;

        //Fetch the idea.
        testIdea_1 = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        //Insert the idea comment.
        insert new IdeaComment(CommentBody='First comment', IdeaId=testIdea_1.Id);

        //Create new ideas with Home and Featured pages.
        System.runAs(testUser) {
            ideasList = new List<Idea>();
            ideasList.add(new Idea(Title='Test idea_5', Homepage__c = true, Body='Body of test idea_5', Status='New', Categories='test_3', CommunityId=cId));
            ideasList.add(new Idea(Title='Test idea_6', Homepage__c = true, Body='Body of test idea_6', Status='New', Categories='test_2', CommunityId=cId));
            ideasList.add(new Idea(Title='Test idea_7', Featured__c = true, Body='Body of test idea_7', Status='Delivered', Categories='test_2', CommunityId=cId));
            ideasList.add(new Idea(Title='Test idea_8', Featured__c = true, Body='Body of test idea_8', Status='New', Categories='test_2', CommunityId=cId));

            insert ideasList;

            //Insert the idea vote.
            insert new Vote(ParentId=testIdea_1.Id, Type='Up');

            //Insert the idea comment.
            insert new IdeaComment(CommentBody='Second comment', IdeaId=testIdea_1.Id);
        }
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to get Ideas with pageName as Home.
    **********************************************************************************/
    static testMethod void testGetIdeas() {
        Test.startTest();

        //Call the getIdeas method in Controller.
        List<brideas_IdeaWrapper> wrappedIdeas = brideas_FeatureIdeasCtrl.getIdeas(3, 'Home');

        Test.stopTest();

        System.assertEquals(3, wrappedIdeas.size(),
                'brideas_FeatureIdeasCtrlTest_testGetIdeas : result contains 3 ideas');

    }

    /*********************************************************************************
    *  Scenario:
    *      Test to get Ideas with pageName as Featured.
    **********************************************************************************/
    static testMethod void testGetIdeasFeatured() {
        Test.startTest();

        //Call the getIdeas method in Controller.
        List<brideas_IdeaWrapper> wrappedIdeas = brideas_FeatureIdeasCtrl.getIdeas(5, 'Featured');

        Test.stopTest();

        System.assertEquals(5, wrappedIdeas.size(),
                'brideas_FeatureIdeasCtrlTest_testGetIdeasFeatured : result contains 5 ideas');
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to get user information.
    **********************************************************************************/
    @isTest
    public static void testGetUserInfo() {
        Test.startTest();

        //Call the getUserInfo method in Controller.
        Map<String, String> uInf = brideas_FeatureIdeasCtrl.getUserInfo();

        Test.stopTest();

        System.assertEquals(true, String.isNotEmpty(uInf.get('Id')), 'Id property is empty');
        System.assertEquals(true, String.isNotEmpty(uInf.get('Name')), 'Name property is empty');
        System.assertEquals(true, String.isNotEmpty(uInf.get('Username')), 'Username property is empty');
        System.assertEquals(true, String.isNotEmpty(uInf.get('Email')), 'Email property is empty');
        System.assertEquals(true, String.isNotEmpty(uInf.get('Type')), 'Type property is empty');
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to get top featured ideas with pageName as Home.
    **********************************************************************************/
    static testMethod void testGetTopHomeIdeas() {
        Test.startTest();

        //Call the getTopFeaturedIdeas method in Controller with Home.
        List<brideas_IdeaWrapper> wrappedIdeas = brideas_FeatureIdeasCtrl.getTopFeaturedIdeas(1, 'Home', 'Popular');

        Test.stopTest();

        System.assertEquals(1, wrappedIdeas.size(),
                'brideas_FeatureIdeasCtrlTest_testGetTopHomeIdeas : result contains 1 ideas');

        for (brideas_IdeaWrapper wrappedIdea : wrappedIdeas) {
            System.assertEquals(2, wrappedIdea.votesNum,
                    'brideas_FeatureIdeasCtrlTest_testGetTopHomeIdeas : result contains the number of votes');
        }
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to get top featured ideas with pageName as Featured.
    **********************************************************************************/
    static testMethod void testGetTopFeaturedIdeas() {
        Test.startTest();

        //Call the getTopFeaturedIdeas method in Controller with Featured.
        List<brideas_IdeaWrapper> wrappedIdeas = brideas_FeatureIdeasCtrl.getTopFeaturedIdeas(1, 'Featured', 'Popular');

        Test.stopTest();

        System.assertEquals(1, wrappedIdeas.size(),
                'brideas_FeatureIdeasCtrlTest_testGetTopFeaturedIdeas : result contains 1 ideas');

        for (brideas_IdeaWrapper wrappedIdea : wrappedIdeas) {
            System.assertEquals(1, wrappedIdea.votesNum,
                    'brideas_FeatureIdeasCtrlTest_testGetTopFeaturedIdeas : result contains the number of votes');
        }
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to add votes to the ideas.
    **********************************************************************************/
    @isTest
    static void testAddVote() {
        //Fetch the ideas.
        Idea testIdea_1 = [SELECT Id FROM Idea WHERE Title = 'Test idea_2' LIMIT 1];
        Idea testIdea_2 = [SELECT Id FROM Idea WHERE Title = 'Test idea_3' LIMIT 1];

        //Fetch the User.
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com'];

        Test.startTest();

        System.runAs(testUser) {
            //Call the addVote method in Controller.
            String result = brideas_FeatureIdeasCtrl.addVote(testIdea_1.Id);

            System.assertEquals('2', result,
                    'brideas_FeatureIdeasCtrlTest_testAddVote : Votes should be retrieved.');
        }

        //Call the addVote method in Controller.
        String res = brideas_FeatureIdeasCtrl.addVote(testIdea_2.Id);

        Test.stopTest();

        System.assertEquals('error', res,
                'brideas_FeatureIdeasCtrlTest_testAddVote : Error message should be retrieved.');

    }
}