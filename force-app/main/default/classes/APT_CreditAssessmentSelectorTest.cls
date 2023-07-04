/**
* @author Yatika bansal
* @date 2023-21-03
* @group Tests
* @domain Apttus
* @description A test class for APT_CreditAssessmentSelector
*/
@IsTest
public class APT_CreditAssessmentSelectorTest {

    /**
	 * Test:Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {		
		Test.startTest();

		APT_CreditAssessmentSelector selector = APT_CreditAssessmentSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Test.stopTest();
        
        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APT_Credit_Assessment__c\\b').matcher(soql).find(), 'Resulting query does not select from Credit Assessment');
	}
    
    
	/**
	 * Test: Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
        Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0]; 
        APT_Charge_Account__c chargeAcc = ApplicationTestDataFactory.getApttusChargeAccountRequest(1, true)[0];
        APT_Credit_Assessment__c credAssess = ApplicationTestDataFactory.getApttusCreditsAssessment(1, null, false)[0];
		insert credAssess;
	
		Test.startTest();

        List<APT_Credit_Assessment__c> creditAssess = APT_CreditAssessmentSelector.newInstance(1)
               .selectByProposalAndAssessStatus(new Set<Id>{quote.Id}, 
                                                        new Set<String> {'Approved'});
		Test.stopTest();
        
        System.assertEquals(0, creditAssess.size(), 'Result count was correct');   
	}
}