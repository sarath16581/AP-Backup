@isTest
private class brideas_CommunityHelperTest {
    @isTest
    private static void testGetNetworkById(){
        String networkId = [SELECT Id FROM Network LIMIT 1].Id;

        Test.startTest();

        Network network = brideas_CommunityHelper.getNetworkById(networkId);

        Test.stopTest();

        System.assertNotEquals(null, network, 'result with network' );
    }

    @isTest
    private static void testGetUserById(){
        TestDataFactory.createStandardUser();
        String userId = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com' LIMIT 1].Id;

        Test.startTest();

        User user = brideas_CommunityHelper.getUserById(userId);

        Test.stopTest();

        System.assertEquals('Testing', user.LastName, 'result contain user last name');
    }
}