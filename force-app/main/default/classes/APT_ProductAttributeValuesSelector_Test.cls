/**
* @author Seth Heang
* @date 2022-04-08
* @group Tests
* @tag Selector
* @tag Apttus_Config2__ProductAttributeValue__c SObject
* @domain Apttus
* @description A very simple selector class that sits in the Apttus domain
* @changelog
* 2022-04-08 - Seth Heang - Created
* 2022-09-08 - Nasir Jawed - Created method testEnsureSelectorMethodsReturnCorrectPACRecord to return product attribute values record
*/
@IsTest
private with sharing class APT_ProductAttributeValuesSelector_Test {
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
    */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

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

        APT_ProductAttributeValuesSelector selector = APT_ProductAttributeValuesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__ProductAttributeValue__c\\b').matcher(soql).find(), 'Resulting query does not select from product attribute value');

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors method is returning the correct query result
     */
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, false)[0];
        insert prodConfig;

        Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, false)[0];
        insert lineItem;

        Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, false)[0];
        insert pav;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        // Getting the record by passing the LineItem record id
        APT_ProductAttributeValuesSelector selector = APT_ProductAttributeValuesSelector.newInstance();
        List<Apttus_Config2__ProductAttributeValue__c> results = selector.selectByLineItemId(new Set<id>{lineItem.Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }
    /**
     * Test:
     *  Ensures that the selectors method is returning the correct query result
     */
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectPAVRecord() {

        // =====================================
        // Data Preparation
        // =====================================

        Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, false)[0];
        insert prodConfig;

        Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, false)[0];
        insert lineItem;

        Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, false)[0];
        insert pav;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        // Getting the record by passing the product attribute record id
        APT_ProductAttributeValuesSelector selector = APT_ProductAttributeValuesSelector.newInstance();
        List<Apttus_Config2__ProductAttributeValue__c> results = selector.selectByPavID(new List<id>{pav.Id}); 
        Map<Id, Apttus_Config2__ProductAttributeValue__c> results1 = selector.selectByconfigIDAndLineType(new List<id>{prodConfig.Id});        
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }


}