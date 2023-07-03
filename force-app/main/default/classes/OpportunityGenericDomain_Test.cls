/***
 * @description Test class for OpportunityGenericDomain.
 * @author Ranjeewa Silva
 * @date 2023-05-18
 * @group Tests
 * @domain Core
 * @changelog
 * 2023-05-18 - Ranjeewa Silva - Created.
 */
@IsTest
private class OpportunityGenericDomain_Test {
	@IsTest
	private static void testOpportunityDomain() {
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(1, account.Id, true);
		OpportunityGenericDomain domain = OpportunityGenericDomain.newInstance(opportunities);
		domain.registerModules();
		System.assertEquals(1, domain.records.size(), 'Expected Opportunity Record');
		System.assertEquals(opportunities[0].Id, domain.records[0].Id, 'Expected Opportunity record');
	}
}