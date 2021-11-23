/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag OpportunityTeamMember
 * @domain Core
 * @description Test Class covering OpportunityTeamMemberSelectore
 * @changelog
 * 2020-10-06 - arjun.singh@austpost.com.au - Created
 */
 @IsTest
public with sharing class OpportunityTeamMembersSelector_Test {
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

	OpportunityTeamMembersSelector selector = OpportunityTeamMembersSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom OpportunityTeamMember\\b').matcher(soql).find(), 'Resulting query does not select from OpportunityTeamMember');

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

        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;

        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
        insert opportunityRecord;  

        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;

        OpportunityTeamMember oppTeamMember = ApplicationTestDataFactory.getOpportunityTeamMembers(1, opportunityRecord.Id, uRecord.Id, 'Direct Contribution', 'Edit', false)[0];      
        insert oppTeamMember;

        Set<Id> oppTeamIds = new Set<Id>{oppTeamMember.Id};

        Set<Id> oppIds = new Set<Id>{opportunityRecord.Id};

        Set<Id> usrIds = new Set<Id>{uRecord.Id};

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
            OpportunityTeamMembersSelector selector = OpportunityTeamMembersSelector.newInstance(1);
            Map<Id, OpportunityTeamMember> results = selector.selectById(oppTeamIds);            
	        System.assertEquals(1, results.size(), 'Expected result size of 1');
            results = selector.selectById(oppTeamIds);
	        System.assertEquals(1, results.size(), 'Expected result size of 1');

            Map<Id, OpportunityTeamMember> resultsWithOppId = selector.selectByOpportunity(oppIds);            
	        System.assertEquals(1, resultsWithOppId.size(), 'Expected result size of 1');
            resultsWithOppId = selector.selectByOpportunity(oppIds);
	        System.assertEquals(1, resultsWithOppId.size(), 'Expected result size of 1');

            Map<Id, OpportunityTeamMember> resultsWithOppAndUsr = selector.selectByOpportunityAndUsers(oppIds, usrIds);            
	        System.assertEquals(1, resultsWithOppAndUsr.size(), 'Expected result size of 1');
            resultsWithOppAndUsr = selector.selectByOpportunityAndUsers(oppIds, usrIds);
	        System.assertEquals(1, resultsWithOppAndUsr.size(), 'Expected result size of 1');
        Test.stopTest();
    }
}