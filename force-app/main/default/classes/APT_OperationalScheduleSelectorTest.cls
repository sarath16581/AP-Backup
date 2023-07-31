/**
* @author Yatika bansal
* @date 2023-25-04
* @group Tests
* @domain Apttus
* @description A test class for APT_OperationalScheduleSelector
2023.04.19 Ken McGuire  Proposal field migration to opportunity
*/
@IsTest
public class APT_OperationalScheduleSelectorTest {

	/**
	 * Test:Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {		
		Test.startTest();

		APT_OperationalScheduleSelector selector = APT_OperationalScheduleSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Test.stopTest();
		
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APT_Operational_Schedule__c\\b').matcher(soql).find(), 'Resulting query does not select from Operational Schedule');
	}
	
	
	/**
	 * Test: Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		//Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, true)[0];
		/*APT_Operational_Schedule__c os = new APT_Operational_Schedule__c(APT_Contract__c = apttusContracts.id);
		insert os;*/
		
		Test.startTest();

		List<APT_Operational_Schedule__c> os = APT_OperationalScheduleSelector.newInstance(1)
			   .selectByContractId(new Set<Id>{apttusContracts.Id});
		Test.stopTest();
		
		System.assertEquals(0, os.size(), 'Result count was correct');   
	}
}