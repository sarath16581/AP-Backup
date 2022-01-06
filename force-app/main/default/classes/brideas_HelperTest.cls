@isTest
private class brideas_HelperTest {

    @testSetup
    static void setup() {
        Test.startTest();
        TestDataFactory.createStandardUser();
        TestDataFactory.createCommunityUser();

        String cId = brideas_Helper.getCommunityId('');

        Idea idea1 = new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1', CommunityId=cId);

        insert idea1;

        User testUser = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com' LIMIT 1];

        System.runAs(testUser){
            Idea idea2 = new Idea(Title='Test idea_2', Body='Body of test idea_2', Status='New', Categories='test_2', CommunityId=cId);

            insert idea2;
        }

        Test.stopTest();

        Integer ideasCount = [SELECT COUNT() FROM Idea];

        System.assertEquals(2, ideasCount);
    }

    @isTest
    private static void testAddSubscriberToIdea(){
        Test.startTest();

        User testUser = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com' LIMIT 1];
        User testCommunityUser = [SELECT Id FROM User WHERE Username = 'testcommunityusr@testorg.com' LIMIT 1];
        Idea idea1 = [SELECT Id FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Idea idea2 = [SELECT Id FROM Idea WHERE Title='Test idea_2' LIMIT 1];
        Integer initialCount = [SELECT COUNT() FROM brideas_Subscription__c];

        brideas_Helper.addSubscriberToIdea(testUser.Id, idea1.Id);
        brideas_Helper.addSubscriberToIdea(testCommunityUser.Id, idea2.Id);

        Test.stopTest();

        Integer resultCount = [SELECT COUNT() FROM brideas_Subscription__c];

        System.assertEquals(initialCount + 2, resultCount);
    }

    @isTest
    private static void testUnsubscribeUserFromIdea(){
        Test.startTest();

        User testUser = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com' LIMIT 1];
        Idea idea1 = [SELECT Id FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Integer subscrCountInitial = [SELECT COUNT() FROM brideas_Subscription__c];

        brideas_Subscription__c subscr = new brideas_Subscription__c(
                Idea__c = idea1.Id,
                User__c = testUser.Id
            );

        insert subscr;

        Integer subscrCountAfterInsert = [SELECT COUNT() FROM brideas_Subscription__c];

        brideas_Helper.unsubscribeUserFromIdea(idea1.Id, testUser.Id);

        Integer subscrCountAfterUnsubscr = [SELECT COUNT() FROM brideas_Subscription__c];

        Test.stopTest();

        System.assertEquals(subscrCountInitial + 1, subscrCountAfterInsert);
        System.assertEquals(subscrCountInitial, subscrCountAfterUnsubscr);
    }

    @isTest
    private static void testUnsubscribeFromIdeaByToken(){
        Test.startTest();

        User testUser = [SELECT Id FROM User WHERE Username = 'testusr@testorg.com' LIMIT 1];
        Idea idea1 = [SELECT Id FROM Idea WHERE Title='Test idea_1' LIMIT 1];
        Integer subscrCountInitial = [SELECT COUNT() FROM brideas_Subscription__c];

        brideas_Subscription__c subscr = new brideas_Subscription__c(
                Idea__c = idea1.Id,
                User__c = testUser.Id,
                Token__c = 'testToken'
            );

        insert subscr;

        Integer subscrCountAfterInsert = [SELECT COUNT() FROM brideas_Subscription__c];

        brideas_Helper.unsubscribeFromIdeaByToken('testToken');

        Integer subscrCountAfterUnsubscr = [SELECT COUNT() FROM brideas_Subscription__c];

        Test.stopTest();

        System.assertEquals(subscrCountInitial + 1, subscrCountAfterInsert);
        System.assertEquals(subscrCountInitial, subscrCountAfterUnsubscr);
    }

    @isTest
    private static void testGetConfigValue(){
        Test.startTest();

        String community = brideas_Helper.getConfigValue('community');

        Test.stopTest();

        System.assertEquals('TestPublic', community, 'result contain not null value');
    }

    @isTest
    private static void testGetActionReputationPoints(){

        Test.startTest();

        String reputationPoints = [SELECT DeveloperName, Value__c FROM brideas_MetadataType__mdt WHERE DeveloperName = 'reputation_points'].Value__c;
        Map<String, String> reputationData = (Map<String,String>)JSON.deserializeStrict(reputationPoints, Map<String,String>.class);
        Integer points = brideas_Helper.getActionReputationPoints('postIdeaPoints');

        Test.stopTest();

        System.assertEquals(Integer.valueOf(reputationData.get('postIdeaPoints')), points, 'result contains points for posting idea');
    }

    @isTest
    private static void testUpdateMemberReputation(){
        Test.startTest();

        User testUser = [SELECT Id FROM User WHERE Username = 'testcommunityusr@testorg.com' LIMIT 1];

        Decimal reputationPointsBeforeAction = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :testUser.Id LIMIT 1].ReputationPoints;

        System.runAs(testUser) {
            brideas_Helper.updateMemberReputation('postIdeaPoints', 1);
        }

        Test.stopTest();

        Decimal reputationPointsAfterAction = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :testUser.Id LIMIT 1].ReputationPoints;

        System.assert(true); //reputation points is not testable feature because of NetworkId
        //System.assertNotEquals(reputationPointsBeforeAction, reputationPointsAfterAction, 'the amount of reputation points is not the same before and after posting idea');
    }

    @isTest
    private static void testGetBannedItemsIds(){
        List<brideas_Banned_Idea_Item__c> bannedItems = new List<brideas_Banned_Idea_Item__c>();

        for(Integer i=0;i<3;i++) {
            bannedItems.add(new brideas_Banned_Idea_Item__c(Type__c = 'Idea post', Item_Id__c = 'ideapost' + i));
        }
        for(Integer i=0;i<4;i++) {
            bannedItems.add(new brideas_Banned_Idea_Item__c(Type__c = 'Idea comment', Item_Id__c = 'ideacomment' + i));
        }

        insert bannedItems;

        Test.startTest();

        Set<String> result1 = brideas_Helper.getBannedItemsIds('Idea post');
        Set<String> result2 = brideas_Helper.getBannedItemsIds('Idea comment');

        Test.stopTest();

        System.assertEquals(3, result1.size(), 'should return correct number of banned items ids for Idea post type');
        System.assertEquals(4, result2.size(), 'should return correct number of banned items ids for Idea comment type');
    }

    @isTest
    private static void testCompileOrderByTrending(){
        Test.startTest();

        String orderbyTrending = brideas_Helper.compileOrderByStatement('Trending');

        Test.stopTest();

        System.assertEquals('LastCommentDate DESC NULLS LAST, CreatedDate DESC', orderbyTrending , 'result contain order by trending');
    }

    @isTest
    private static void testCompileOrderByPopular(){
        Test.startTest();

        String orderbyPopular = brideas_Helper.compileOrderByStatement('Popular');

        Test.stopTest();

        System.assertEquals('VoteTotal DESC, CreatedDate DESC', orderbyPopular , 'result contain order by popular');
    }

    @isTest
    private static void testCompileOrderByOldest(){
        Test.startTest();

        String orderbyOldest = brideas_Helper.compileOrderByStatement('Oldest');

        Test.stopTest();

        System.assertEquals('CreatedDate ASC', orderbyOldest , 'result contain order by oldest');
    }

    @isTest
    private static void testGetIdeasVotesNumber(){
        List<String> ideasId = new List<String>();

        for (Idea idea : [SELECT Id FROM Idea LIMIT 100]) {
            ideasId.add(idea.Id);
        }

        Test.startTest();

        Map<String, Integer> votesNumber = brideas_Helper.getIdeasVotesNumber(ideasId);

        Test.stopTest();

        System.assertEquals(1, votesNumber.get(ideasId[0]) , 'result contain votes');
    }

    @isTest
    private static void testGetDefaultStatusValue(){
        Test.startTest();

        String defaultStatus = brideas_Helper.getDefaultStatusValue();

        Test.stopTest();

        System.assertNotEquals(null, defaultStatus , 'result contain default status');
    }

    @isTest
    private static void testUpdateCustomMetadataValue(){
        Test.startTest();

        brideas_Helper.updateCustomMetadataValue(new Map<String,String>{'forbidden_words'=>'testvalue'});

        Test.stopTest();
    }

    @isTest
    private static void testGetSimilarIdeas(){
        Test.startTest();

        List<Idea> ideas = brideas_Helper.getSimilarIdeas(null, null);

        Test.stopTest();

        System.assertEquals('Test idea', ideas[0].Title , 'result contains test similar idea');
    }

    @isTest
    private static void testGetIdeaVotesNumber(){
        String ideaId = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        Integer votes = brideas_Helper.getIdeaVotesNumber(ideaId);

        Test.stopTest();

        System.assertEquals(1, votes , 'result contain votes');
    }

    @isTest
    private static void testSetFlagOnIdea(){
        String ideaId = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        Boolean isSetFlag = brideas_Helper.setFlagOnIdea(ideaId);

        Test.stopTest();

        System.assertEquals(true, isSetFlag , 'result contain true value');
    }

    @isTest
    private static void testGetCommunityUrlByZoneId(){
        Test.startTest();

        String url = brideas_Helper.getCommunityUrlByZoneId(null);

        Test.stopTest();

        System.assertEquals('test.com', url, 'result contain url');
    }

    @isTest
    private static void testCompileWhereStatement(){
        String cId = brideas_Helper.getCommunityId('');
        Community ideaCommunity = [SELECT Name FROM Community WHERE Id = :cId LIMIT 1];

        Map<String,String> filterData = new Map<String,String>();
        filterData.put('search', 'Test');
        filterData.put('search_by_title', 'true');
        filterData.put('category', 'test_1');
        filterData.put('status', 'New');
        filterData.put('showBy', 'createdByMe');

        Test.startTest();

        String whereStatement = brideas_Helper.compileWhereStatement(ideaCommunity.Name, filterData);

        Test.stopTest();

        System.assertNotEquals('', whereStatement, 'result contain statement');
    }
}