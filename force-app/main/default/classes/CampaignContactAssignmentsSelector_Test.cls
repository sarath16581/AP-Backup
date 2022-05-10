/**
* @author Ashapriya Gadi
* @date 2021-02-03
* @group Tests
* @tag Selector
* @tag CampaignContactAssignment__c
* @domain Core
* @description Test class covering CampaignContactAssignmentsSelector
* @changelog
* 2021-02-03 - Ashapriya Gadi - Created
*/
@IsTest
private class CampaignContactAssignmentsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		
		// =====================================
		// Data Preparation
		// =====================================
		// None!-
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignContactAssignmentsSelector selector = CampaignContactAssignmentsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom CampaignContactAssignment__c\\b').matcher(soql).find(), 'Resulting query not select from CampaignContactAssignment__c');
	}
    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringFieldOverride() {
		
		// =====================================
		// Data Preparation
		// =====================================
		// None!-
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignContactAssignmentsSelector selector = CampaignContactAssignmentsSelector.newInstance(1,new Set<SObjectField>{CampaignContactAssignment__c.Id,CampaignContactAssignment__c.Contact__c});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom CampaignContactAssignment__c\\b').matcher(soql).find(), 'Resulting query not select from CampaignContactAssignment__c');
	}
    
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	*/
	@IsTest
	private static void testSelectById() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		//Create Campaign
		Campaign campaign = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false)[0];
		insert campaign;
        //Create account
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
        //Create CampaignContactAssignment__c
        CampaignContactAssignment__c cca = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1, account.Id , campaign.Id , false)[0];
		insert cca;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignContactAssignmentsSelector selector = CampaignContactAssignmentsSelector.newInstance(1);
		List<CampaignContactAssignment__c> resultList = selector.selectById(new Set<Id>{cca.Id});
		Test.stopTest();
		System.assertEquals(1, resultList.size(), 'CampaignContactAssignment__c is not returned');
	}
    
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 *
	*/
	@IsTest
	private static void testSelectByCampaignAndContact() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		//Create Campaign
		Campaign campaign = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false)[0];
		insert campaign;
        //Create account
        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
        //Create contact
        Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id , false)[0];
		insert contact;
        //Create CampaignContactAssignment__c
        CampaignContactAssignment__c cca = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1, account.Id , campaign.Id , false)[0];
		cca.Contact__c = contact.Id;
        insert cca;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignContactAssignmentsSelector selector = CampaignContactAssignmentsSelector.newInstance(1);
		List<CampaignContactAssignment__c> resultList = selector.selectByCampaignAndContact(new Set<Id>{campaign.Id},new Set<Id>{contact.Id},new Set<Object>{CampaignContactAssignmentsSelector.Options.WITH_CONTACT} );
		Test.stopTest();
		System.assertEquals(1, resultList.size(), 'CampaignContactAssignment__c is not returned');
	}
    
    /**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

        CampaignContactAssignmentsSelector selector = CampaignContactAssignmentsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CampaignContactAssignmentsSelector.Options.WITH_CONTACT});
        String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Contact__r\\..*?\\bfrom CampaignContactAssignment__c\\b').matcher(soql).find(), 'Resulting query does not select contact fields'+soql);

        qb = selector.newQueryBuilder(new Set<Object>{CampaignContactAssignmentsSelector.Options.WITH_ORGANISATION});
        soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Organisation__r\\..*?\\bfrom CampaignContactAssignment__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation__r fields'+soql);

        Test.stopTest();
    }
}