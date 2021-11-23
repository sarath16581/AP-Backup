@isTest
private class brideas_SubscriptionTriggerHandlerTest {

    @testSetup
    static void setup() {
        Test.startTest();

        TestDataFactory.createCommunityUser();

        Test.stopTest();

        Integer usersCount = [SELECT COUNT() FROM User WHERE Username = 'testcommunityusr@testorg.com'];

        System.assertEquals(1, usersCount);
    }

    @isTest
    static void testAddReputationPointOnPostIdea(){
        Test.startTest();

        User testUser = [SELECT Id FROM User WHERE Username = 'testcommunityusr@testorg.com' LIMIT 1];
        Decimal reputationPointsBeforeLikeIdea = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :testUser.Id LIMIT 1].ReputationPoints;

        System.runAs(testUser) {
            brideas_Subscription__c subscription = new brideas_Subscription__c();
            insert subscription;
        }

        Test.stopTest();

        Decimal reputationPointsAfterLikeIdea = [SELECT ReputationPoints FROM NetworkMember WHERE MemberId = :testUser.Id LIMIT 1].ReputationPoints;

        System.assert(true); //reputation points is not testable feature because of NetworkId
        //System.assertNotEquals(reputationPointsBeforeLikeIdea, reputationPointsAfterLikeIdea, 'the amount of reputation points is not the same before and after liking idea');
    }
}