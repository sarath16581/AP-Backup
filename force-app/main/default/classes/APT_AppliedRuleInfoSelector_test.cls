/* @author Nasir Jawed
* @date 2022-10-10
* @tag Apttus_Config2__AppliedRuleInfo__c
* @domain Apttus
* @description Test class for Apttus_Config2__AppliedRuleInfo__c to get field values
* @changelog: 
* 
* 
*/
@IsTest
public class APT_AppliedRuleInfoSelector_test {
	 @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString(){
        /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/       
        Test.startTest();
        APT_AppliedRuleInfoSelector  selector = APT_AppliedRuleInfoSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__AppliedRuleInfo__c\\b').matcher(soql).find(), 'Resulting query does not select from rule info');
                            
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
        
        Apttus_Config2__AppliedRuleInfo__c ari = new Apttus_Config2__AppliedRuleInfo__c();
        ari.Apttus_Config2__ConfigurationId__c  = prodConfig.ID;
        ari.Apttus_Config2__Invalid__c  = true;
        insert ari;
        
		Test.startTest();

		APT_AppliedRuleInfoSelector  selector = APT_AppliedRuleInfoSelector.newInstance(1);
        List<Apttus_Config2__AppliedRuleInfo__c> results = selector.selectByConfigId(new set<ID> {prodConfig.id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}