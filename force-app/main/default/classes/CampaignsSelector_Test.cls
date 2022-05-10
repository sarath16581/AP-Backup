/**
* @author Ashapriya Gadi
* @date 2021-02-03
* @group Tests
* @tag Selector
* @tag Campaigns
* @domain Core
* @description Test class covering CampaignsSelector
* @changelog
* 2021-02-03 - Ashapriya Gadi - Created
*/
@IsTest
private class CampaignsSelector_Test {
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
		CampaignsSelector selector = CampaignsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
        
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Campaign\\b').matcher(soql).find(), 'Resulting query not select from Campaign');
	}
    /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		
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
		 //Test for field override
        CampaignsSelector selector = CampaignsSelector.newInstance(1, new Set<SObjectField>{Campaign.Id, Campaign.ContactAssignmentDefaultStatus__c});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Campaign\\b').matcher(soql).find(), 'Resulting query not select from Campaign');
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
		//Create Campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false);
		insert campaigns;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignsSelector selector = CampaignsSelector.newInstance(1);
		List<Campaign> resultList = selector.selectById(new Set<Id>{campaigns[0].Id});
		Test.stopTest();
		System.assertEquals(1, resultList.size(), 'Campaign is not returned');
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

        CampaignsSelector selector = CampaignsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CampaignsSelector.Options.WITH_CAMPAIGNMEMBERS});
        String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Select.*?\\(Select.*?\\bfrom CampaignMembers\\b.*?\\).*?\\bfrom Campaign\\b').matcher(soql).find(), 'Resulting query does not select CampaignMembers fields');

        qb = selector.newQueryBuilder(new Set<Object>{CampaignsSelector.Options.WITH_CONTACTASSIGMENTS});
        soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Select.*?\\(Select.*?\\bfrom Campaign_Contact_Assignments__r\\b.*?\\).*?\\bfrom Campaign\\b').matcher(soql).find(), 'Resulting query does not select Campaign_Contact_Assignments__r fields');

        Test.stopTest();
    }
}