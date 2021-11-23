/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag ProposaltSelector
 * @domain Core
 * @description Test Class covering HoldingReferenceRoleSelector 
 * @changelog
 * 2020-10-06 - Shashwat.Nath@austpost.com.au - Created
 */
@IsTest
private class HoldingReferenceRoleSelector_Test{

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

        HoldingReferenceRoleSelector selector = HoldingReferenceRoleSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Holding_Role_Reference__c\\b').matcher(soql).find(), 'Resulting query does not select from Organisation Role');

        Test.stopTest();

    }
    
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringTest() {

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

        HoldingReferenceRoleSelector selector = HoldingReferenceRoleSelector.newInstance(1);
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Holding_Role_Reference__c\\b').matcher(soql).find(), 'Resulting query does not select from Organisation Role');

        Test.stopTest();

    }


   /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

        HoldingReferenceRoleSelector selector = HoldingReferenceRoleSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Holding_Role_Reference__c.SObjectType => new Set<SObjectField>{Holding_Role_Reference__c.Name}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{HoldingReferenceRoleSelector.Options.WITH_OWNER, HoldingReferenceRoleSelector.Options.WITH_RECORDTYPE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Holding_Role_Reference__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

        Test.stopTest();

    }

    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        List<Holding_Role_Reference__c> holdingRoleRefList = new List<Holding_Role_Reference__c>();
        Holding_Role_Reference__c holdRoleRef = new Holding_Role_Reference__c();
        holdRoleRef.name = 'New Account';
        holdingRoleRefList.add(holdRoleRef);
        insert holdingRoleRefList;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        HoldingReferenceRoleSelector selector = HoldingReferenceRoleSelector.newInstance(1, new Set<SObjectField>());
        Map<Id, Holding_Role_Reference__c> results = selector.selectByName('New Account');
        System.assertEquals(1, results.size(), 'Result count was wrong');
        Map<Id, Holding_Role_Reference__c> results1 = selector.selectById(new Set<Id>{holdingRoleRefList[0].id});
        System.assertEquals(1, results1.size(), 'Result count was wrong');
        Test.stopTest();
    }
}