/***
 * @author Disha Kariya
 * @date 2020-05-19
 * @group Tests
 * @tag Selector
 * @tag Account SObject
 * @domain Core
 * @description Test Class covering MyPostBusinessAssetsSelector
 * @changelog
 * 2020-05-19 - Disha Kariya - Created
 */
@IsTest
public with sharing class MyPostBusinessAssetsSelector_Test {
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert acc;

        List<Product2> prod = ApplicationTestDataFactory.getPSRProducts(2, false);
        insert prod;
        List<Asset> assetList = new List<Asset>();
        Asset assetTrans = ApplicationTestDataFactory.getPSRTransactionalAssets(1, acc.Id, prod[0].Id, false,'Inactive', false)[0];
        assetList.add(assetTrans);
        Asset assetAssigned = ApplicationTestDataFactory.getPSRAssignedAssets(1, acc.Id, prod[0].Id, true, Date.today(), Date.today().addDays(14), 'Active', false)[0];
        assetList.add(assetAssigned);
        insert assetList;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        MyPostBusinessAssetsSelector selector1 = MyPostBusinessAssetsSelector.newInstance();
        MyPostBusinessAssetsSelector selector = MyPostBusinessAssetsSelector.newInstance(2);
        Map<Id, Asset> results = selector.selectPSRUnprocessedByAccounts(new Set<Id>{assetList[0].AccountId});
        System.assertEquals(0, results.size(), 'Unprocessed assets found');

        Test.stopTest();
    }
}