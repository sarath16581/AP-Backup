/* @author Pradeep Jaiswal
* @date 2022-05-18
* @group Selector
* @tag Selector
* @tag Apttus_Config2__UsagePriceTier__c
* @domain Apttus
* @description APT_UsagePriceTierSelector_Test to validate price tier
*/
@IsTest
public class APT_UsagePriceTierSelector_Test {

     @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString(){
        /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/       
        Test.startTest();
        APT_UsagePriceTierSelector selector = APT_UsagePriceTierSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_Config2__UsagePriceTier__c\\b').matcher(soql).find(), 'Resulting query does not select from product');
                            
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

		Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, false)[0];
		insert lineItem;
        
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__LineItemId__c = lineItem.ID;
        upt.Apttus_Config2__Sequence__c = 1;
        insert upt;

		//Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, false)[0];
		//insert pav;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		APT_UsagePriceTierSelector selector = APT_UsagePriceTierSelector.newInstance(1);
        Map<Id, Apttus_Config2__UsagePriceTier__c> results = selector.selectByLineItemId(new List<ID> {lineItem.id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}