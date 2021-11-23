/**
 * @author alexvolkov
 * @date 23/1/20
 * @description Test class for TH_RecommendationTrigger
 */
/**
--------------------------------------- History --------------------------------------------------
23.01.2020    alex.volkov@auspost.com.au    Initial creation
**/

@IsTest
private with sharing class TH_RecommendationTriggerTest
{
	/**
	* @description Test data setup
	*/
	@TestSetup
	static void setupData()
	{
		/** Create a test badge */
		Database.insert(new trailheadapp__Badge__c(trailheadapp__API_Name__c='Test_API_Name', trailheadapp__Description__c='Test', trailheadapp__Icon__c = 'Test', trailheadapp__Namespace__c = 'Test', trailheadapp__URL__c = 'about:blank'));
	}
	/**
	 * @description Basic DML operations test
	 */
	@IsTest
	static void testRecommendations()
	{
		trailheadapp__Badge__c vBadge = [SELECT Id FROM trailheadapp__Badge__c LIMIT 1];
		List<TH_Recommendation__c> vListToInsert = new List<TH_Recommendation__c>();
		/** Instantiate 2 recommendations for a positive and a negative test */
		vListToInsert.add(new TH_Recommendation__c(Object_API_Name__c = 'Account', Field_Name_Constraint__c = 'Name', Field_Value_Constraint__c='Test', Badge__c = vBadge.Id));
		vListToInsert.add(new TH_Recommendation__c(Object_API_Name__c = 'non_existent_object_for_test'));
		Test.startTest();
		/** Insert with allOrNothing = false and assert that only the record for existing object was created */
		Database.insert(vListToInsert, false);
		System.assertEquals(1, [SELECT COUNT() FROM TH_Recommendation__c], 'Incorrect number of recommendations created');
		TH_Recommendation__c vRecToUpdate = [SELECT Field_Name_Constraint__c FROM TH_Recommendation__c LIMIT 1];
		/** Attempt to update the field name to a non-existent one and assert that the update failed */
		vRecToUpdate.Field_Name_Constraint__c = 'non_existent_field_for_test';
		Database.update(vRecToUpdate, false);
		Test.stopTest();
		System.assertEquals('Name', [SELECT Field_Name_Constraint__c FROM TH_Recommendation__c WHERE Id = :vRecToUpdate.Id].Field_Name_Constraint__c, 'Field name was updated with incorrect value');
	}
}