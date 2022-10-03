/***
 * @date 2022-09-21
 * @group Tests
 * @tag Selector
 * @tag CustomSetting SObject
 * @description Test Class covering CustomsSettingsSelector
 * 2022-09-21 - Swati Mogadala - Created
 */
@IsTest
public with sharing class CustomsSettingsSelector_Test  {
/**
* Test Data setup
*/
    @TestSetup
    static void testDataSetup() {
    SecurityPolicy__c policy = SecurityPolicyTestDataFactory.getSecurityPolicies(1, UserInfo.getOrganizationId(), false, false)[0];
    insert policy;
    }

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
    Set<SObjectField> fields = new Set<SObjectField>{ SecurityPolicy__c.Id, SecurityPolicy__c.Name, SecurityPolicy__c.SetupOwnerid, SecurityPolicy__c.Login_BlockNonWindowsPlatform__c };
    CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(SecurityPolicy__c.SObjectType, fields);
    QueryBuilder qb = selector.newQueryBuilder();
    String soql = qb.toSoqlString();
    System.assertEquals(true, Pattern.compile('(?is)\\bfrom SecurityPolicy__c\\b').matcher(soql).find(), 'Resulting query does not select from Custom settings');
    Test.stopTest();

    }

/**
* Executes a query to ensure it returns expected results with actual inserted data
*/
    @IsTest
    public static void testSelectBySetupOwnerid() {

        // =====================================
        // Data Preparation
        // =====================================
        // =====================================
        // Stubbing
        // =====================================
        // None!
        // =====================================
        // Testing
        // =====================================
    Test.startTest();
    Set<SObjectField> fields = new Set<SObjectField>{ SecurityPolicy__c.Id, SecurityPolicy__c.Name, SecurityPolicy__c.SetupOwnerid, SecurityPolicy__c.Login_BlockNonWindowsPlatform__c };
    CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(SecurityPolicy__c.SObjectType, fields);
    SecurityPolicy__c policy1 = [Select Id,Name,SetupOwnerid from SecurityPolicy__c where SetupOwnerid=:UserInfo.getOrganizationId()];
    List< SObject> results = (List< SObject>) selector.selectBySetupOwnerid(new Set<Id>{policy1.SetupOwnerId});
    System.assertEquals(1, results.size());
    Test.stopTest();
    }
/**
* Executes a query to ensure it returns expected results with actual inserted data
*/
    @IsTest
    public static void testSelectByNames() {

        // =====================================
        // Data Preparation
        // =====================================
        // =====================================
        // Stubbing
        // =====================================
        // None!
        // =====================================
        // Testing
        // =====================================
    Test.startTest();
    Set<SObjectField> fields = new Set<SObjectField>{ SecurityPolicy__c.Id, SecurityPolicy__c.Name, SecurityPolicy__c.SetupOwnerid, SecurityPolicy__c.Login_BlockNonWindowsPlatform__c };
    CustomsSettingsSelector selector = CustomsSettingsSelector.newInstance(SecurityPolicy__c.SObjectType, fields);
    SecurityPolicy__c policy1 = [Select Id,Name,SetupOwnerid from SecurityPolicy__c where SetupOwnerid=:UserInfo.getOrganizationId()];
    Map<String, SObject> results = (Map<String, SObject>) selector.selectByNames(new Set<String>{policy1.Name});
    System.assertEquals(1, results.size());
    Test.stopTest();
    }
}