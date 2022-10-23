/**
* @author Pradeep Jaiswal
* @date 2022-05-12
* @group Tests
* @tag Selector
* @tag Apttus_Config2__ProductConfiguration__c SObject
* @domain Apttus
* @description A very simple selector class that sits in the Apttus domain
* @changelog
* 2022-05-12 - Pradeep Jaiswal - Created
* 2022-07-28 - Nasir Jawed - Added code for covering Proposal.
*/
@IsTest
private with sharing class APT_ProductConfigurationsSelector_Test {

    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString(){
        /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
    */       
        Test.startTest();
        APT_ProductConfigurationsSelector selector = APT_ProductConfigurationsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__ProductConfiguration__c\\b').matcher(soql).find(), 'Resulting query does not select from product');
                            
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

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
		//Checking the prod config object returing a record
        APT_ProductConfigurationsSelector selector = APT_ProductConfigurationsSelector.newInstance();
        List<Apttus_Config2__ProductConfiguration__c> results = selector.selectByConfigId(new set<ID>{(ID)prodConfig.id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');

        Test.stopTest();

    }
            /**
     * Test:
     *  Ensures that the selectors method is returning the correct query result
     */
	@IsTest
	private static void testEnsureSelectorMethodsReturnCorrectResult2() {

		MockUtility.disableTriggerExecution();
		// =====================================
		// Data Preparation
		// =====================================
		Account legacyacct = APT_TestUtils.createOrganisation();
		legacyacct.Legacy_Id__c = '60000000';
		legacyacct.Name = 'legacyacct';     
		insert legacyacct;    

		//Create Opportunity       
		Opportunity opp1 = APT_TestUtils.createOpportunity(legacyacct.id);     
		opp1.Is_Superseded_Opportunity__c = true;             
		insert opp1;

		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
		insert priceList;

		Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(legacyacct.id,opp1.Id,'Proposal','Test',priceList.id);
		insert proposal;
		//
		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, false)[0];
		prodConfig.Apttus_QPConfig__Proposald__c =proposal.id;
		insert prodConfig;

		Test.startTest();
		//Checking the prod config object returing a record
		APT_ProductConfigurationsSelector selector = APT_ProductConfigurationsSelector.newInstance(1);
		List<Apttus_Config2__ProductConfiguration__c> results = selector.selectByConfigId(new set<ID>{(ID)prodConfig.id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		//Getting the prod config record by passing the proposal id and checking the result
		APT_ProductConfigurationsSelector selectorProp = APT_ProductConfigurationsSelector.newInstance(1);
		List<Apttus_Config2__ProductConfiguration__c> results1 = selectorProp.selectByProposalId(new set<ID>{proposal.id});
		System.assertEquals(1, results1.size(), 'Expected result size of 1');
		Test.stopTest(); 
    }
}