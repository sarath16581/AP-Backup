/**
* @author Ashapriya Gadi
* @date 2021-11-19
* @group Tests
* @tag Selector
* @tag Entitlement
* @domain Core
* @description Test class covering EntitlementsSelector
* @changelog
* 2021-11-19 - Ashapriya Gadi - Created
*/
@IsTest
private class EntitlementsSelector_Test {
    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        EntitlementsSelector selector = EntitlementsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        Test.stopTest();
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Entitlement\\b').matcher(soql).find(), 'Resulting query not select from Entitlement');


    }
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorByIdAndName() {
        // =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
        //Insert Entitlement
        List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, false));
        insert orgAaccounts;
        SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name ='Standard Entitlement BGS - VIC' LIMIT 1 ];
        List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(1, false,'BGS Entitlement Standard - VIC',sla.Id,orgAaccounts[0].Id));
        insert entitlements;
        // =====================================
		// Testing
		// =====================================
        Test.startTest();
		EntitlementsSelector selector = EntitlementsSelector.newInstance();
		List<Entitlement> results = selector.selectById(new Set<Id>{entitlements[0].Id});
        List<Entitlement> resultsName = selector.selectByName(new Set<String>{entitlements[0].Name});
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Expected result size is not 1');
        System.assertEquals(1, resultsName.size(), 'Expected result size is not 1');
    }
}