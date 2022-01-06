/***
 * @author Disha kariya
 * @date 2020-08-24
 * @group Tests
 * @tag Selector
 * @tag Network SObject
 * @domain Core
 * @description Test Class covering NetworksSelector
 * @changelog
 * 2020-08-24 - Disha Kariya - Created
 * 2020-09-23 - Disha Kariya - Updated for select by Org Id method
 * 2021-03-15 - Seth Heang - Add code coverage for selectByNameAndOrgId(), selectByNetworkNameAndOrgIdAndNotID
 * 2021-07-20 - seth.heang@auspost.com.au - Add code coverage for selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING()
 * 2021-07-27 - naveen.rajanna@auspost.com.au - Add code coverage for selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE()
 */
@IsTest
public with sharing class NetworksSelector_Test {

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

        NetworksSelector selector = NetworksSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        // make sure there is RecordType.DeveloperName condition
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom network__c\\b').matcher(soql).find(), 'Resulting query does not select from Network');

        selector = NetworksSelector.newInstance();
        qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();

        // make sure there is Owner
        System.assertEquals(true, Pattern.compile('(?ism)Owner.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

        selector = NetworksSelector.newInstance();
        qb = selector.newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_RECORDTYPE});
        soql = qb.toSoqlString();

        // make sure there is RecordType
        System.assertEquals(true, Pattern.compile('(?ism)RecordType.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select from RecordType');

        //Test for field override
        selector = NetworksSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Network__c.SObjectType => new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id}
        });
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

        selector = NetworksSelector.newInstance(0, new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

        selector = NetworksSelector.newInstance(new Set<SObjectField>{Network__c.Network_Manager__c, Network__c.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Network_Manager__c.*?\\bfrom Network__c\\b').matcher(soql).find(), 'Resulting query does not select Network_Manager__c field: ' + soql);

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


        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(3, false);
        networks[0].Org_ID__c = '12345';
        networks[0].Org_Unit_Type__c = 'LPO';
        networks[0].Name = 'Melbourne';

        networks[1].Org_ID__c = '55555';
        networks[1].Org_Unit_Type__c = 'ABC';
        networks[1].Name = 'Melbourne DWS';

        insert networks;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        NetworksSelector selector = NetworksSelector.newInstance(20);
        Map<Id, Network__c> results = selector.selectById(new Set<Id>{networks[0].Id, networks[1].Id, networks[2].Id});
        Map<Id, Network__c> orgIdResults = selector.selectByOrgId(new Set<String>{'12345'});
        System.assertEquals(3, results.size(), 'Expected result size of 3');
        System.assertEquals(1, orgIdResults.size(), 'Expected result size of 1');

        Map<Id, Network__c> resultNameAndOrgId = selector.selectByNameAndOrgId(new Set<String>{networks[0].Name}, new Set<String>{networks[0].Org_ID__c});
        Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID = selector.selectByNetworkNameAndOrgIdAndNotID(networks[0].Name, new Set<String>{networks[0].Org_Unit_Type__c}, new Set<String>{networks[1].Id, networks[2].Id});
        Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID_OR_DWS = selector.selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING(networks[1].Name, new Set<String>{networks[1].Org_Unit_Type__c}, new Set<String>{networks[0].Id,networks[2].Id}, 'DWS');
        Map<Id, Network__c> resultNameAndOrgUnitCodeAndNotID_OR_DWS_OR_WORKCENTRE = selector.selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(networks[1].Org_ID__c, new Set<String>{networks[1].Org_Unit_Type__c}, new Set<String>{networks[0].Id}, 'DWS');
        System.assertEquals(1, resultNameAndOrgId.size(), 'Expected result size of 1');
        System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID.size(), 'Expected result size of 1');
        System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID_OR_DWS.size(), 'Expected result size of 1');
        System.assertEquals(1, resultNameAndOrgUnitCodeAndNotID_OR_DWS_OR_WORKCENTRE.size(), 'Expected result size of 1');
    
        Test.stopTest();

    }
}