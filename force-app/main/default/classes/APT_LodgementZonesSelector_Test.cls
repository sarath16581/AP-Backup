/* @author Nasir Jawed
* @date 2022-07-27
* @tag APT_Lodgement_Zone__c
* @domain Apttus
* @description APT_LodgementZonesSelector_Test to validate Zone Structure
*/
@IsTest
public class APT_LodgementZonesSelector_Test {

     @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString(){
        /**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	*/       
        Test.startTest();
        APT_LodgementZonesSelector selector = APT_LodgementZonesSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        
        System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_Lodgement_Zone__c\\b').matcher(soql).find(), 'Resulting query does not select from LodgementZone');
                            
        Test.stopTest();                    
              
    }
    
        	/**
	 * Test:
	 *  Ensures that the selectors method is returning the correct query result
	 */
	@IsTest
	private static void testLodgementZoneSelector() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		APT_Lodgement_Zone__c lz = APT_TestDataFactory.getAPTLodgementZone(1, false)[0];
		insert lz;	
        
		Test.startTest();

		APT_LodgementZonesSelector selector = APT_LodgementZonesSelector.newInstance();       
        Map<Id, APT_Lodgement_Zone__c> results = new Map<Id, APT_Lodgement_Zone__c>(selector.selectByZoneStructure(new Set<String>{lz.APT_Zone_Structure__c},new Set<String>{lz.APT_Postcode__c}));
		

		Test.stopTest();

	}
}