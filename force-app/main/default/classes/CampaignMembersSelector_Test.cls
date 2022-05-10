/**
* @author Mathew Jose
* @date 2021-02-03
* @group Tests
* @tag Selector
* @tag CampaignMembers
* @domain Core
* @description Test class covering CampaignMembersSelector
* @changelog
* 2021-02-03 - Ashapriya Gadi - Added methods testSelectByCampaignId, testSearchMethod
*/
@IsTest
Private class CampaignMembersSelector_Test {
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

        CampaignMembersSelector selector = CampaignMembersSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom CampaignMember\\b').matcher(soql).find(), 'Resulting query does not select from CampaignMember');
		
        selector = CampaignMembersSelector.newInstance(1);
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom CampaignMember\\b').matcher(soql).find(), 'Resulting query does not select from CampaignMember');

        
        selector = CampaignMembersSelector.newInstance();
        qb = selector.newQueryBuilder(new Set<Object>{CampaignMembersSelector.Options.WITH_CONTACT});
        soql = qb.toSoqlString();

        // make sure there is Owner
        System.assertEquals(true, Pattern.compile('(?ism)Contact.*?\\bfrom CampaignMember\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

        
        //Test for field override
        selector = CampaignMembersSelector.newInstance(1, new Set<SObjectField>{CampaignMember.ContactId, CampaignMember.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)ContactId.*?\\bfrom CampaignMember\\b').matcher(soql).find(), 'Resulting query does not select Description field: ' + soql);

        Test.stopTest();
        
    }

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorSpecificMethods() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
        insert accounts;
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
        insert contacts;
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false);
        insert campaigns;
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, false, campaigns[0].Id, contacts[0].Id);
        insert campaignMembers;
        
		Test.startTest();
        Set<Object> opts = new Set<Object>{CampaignMembersSelector.Options.WITH_CONTACT, CampaignMembersSelector.Options.WITH_CAMPAIGN, CampaignMembersSelector.Options.FILTER_CONTACTS_ONLY};
		Map<SObjectType, Set<SObjectField>> fieldOverride = new Map<SObjectType, Set<SObjectField>>();
        fieldOverride.put(((SObject) Type.forName('Campaign').newInstance()).getSObjectType(), new Set<SobjectField>{Campaign.Id,Campaign.Name});
		fieldOverride.put(((SObject) Type.forName('Contact').newInstance()).getSObjectType(), new Set<SobjectField>{Contact.Name,Contact.Id});
        CampaignMembersSelector selector = CampaignMembersSelector.newInstance();
		selector.setFieldOverrides(fieldOverride);

        List<CampaignMember> campaignMemberList = new List<CampaignMember>();      
        campaignMemberList = selector.selectById(new Set<Id>{campaignMembers[0].Id});
		System.assertEquals(1, campaignMemberList.size(), 'Expected 1 result');

        campaignMemberList = selector.selectById(new Set<Id>{campaignMembers[0].Id},opts);
		System.assertEquals(1, campaignMemberList.size(), 'Expected 1 result');

		Test.stopTest();        
        
    }
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSearchMethod() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;
		
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
		insert contacts;
		
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false);
		insert campaigns;
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, false, campaigns[0].Id, contacts[0].Id);
        campaignMembers[0].Status = 'Not Started';
        insert campaignMembers[0];
		
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Set<Object> opts = new Set<Object>();
		CampaignMembersSelector selector = CampaignMembersSelector.newInstance();
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('campaignIds', new Set<Id>{campaigns[0].Id});
		searchParams.put('contactIds', new Set<Id>{contacts[0].Id});
        searchParams.put('statuses', new Set<String>{'Not Started'});
		List<CampaignMember> cmList = selector.search(searchParams, opts, false);
		System.assertEquals(1, cmList.size(), 'Expected 1 results');
		Test.stopTest();
	}
    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectByCampaignId() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
        insert accounts;
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
        insert contacts;
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, false);
        insert campaigns;
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, false, campaigns[0].Id, contacts[0].Id);
        insert campaignMembers;
        
		Test.startTest();
        Set<Object> opts = new Set<Object>{CampaignMembersSelector.Options.WITH_CONTACT, CampaignMembersSelector.Options.WITH_CAMPAIGN, CampaignMembersSelector.Options.FILTER_CONTACTS_ONLY};
		Map<SObjectType, Set<SObjectField>> fieldOverride = new Map<SObjectType, Set<SObjectField>>();
        fieldOverride.put(((SObject) Type.forName('Campaign').newInstance()).getSObjectType(), new Set<SobjectField>{Campaign.Id,Campaign.Name});
		fieldOverride.put(((SObject) Type.forName('Contact').newInstance()).getSObjectType(), new Set<SobjectField>{Contact.Name,Contact.Id});
        CampaignMembersSelector selector = CampaignMembersSelector.newInstance();
		selector.setFieldOverrides(fieldOverride);

        List<CampaignMember> campaignMemberList = new List<CampaignMember>();      
        campaignMemberList = selector.selectByCampaignId(new Set<Id>{campaigns[0].Id});
		System.assertEquals(1, campaignMemberList.size(), 'Expected 1 result');
		Test.stopTest();        
        
    }

}