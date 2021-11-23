/**
 * @author alexvolkov
 * @date 13/2/20
 * @description Test class for TH_GroupAssignmentController
 */

/**
--------------------------------------- History --------------------------------------------------
13.02.2020    alex.volkov@auspost.com.au    Initial creation
**/

@IsTest
private with sharing class TH_GroupAssignmentControllerTest
{
	/**
	* @description Test data setup
	*/
	@TestSetup
	static void setupData()
	{
		/** Create test badges and trailmixes */
		List<trailheadapp__Badge__c> vBadgeList = new List<trailheadapp__Badge__c>();
		List<trailheadapp__Trailmix__c> vMixList = new List<trailheadapp__Trailmix__c>();
		for (Integer i=0; i<3;  i++)
		{
			vBadgeList.add(new trailheadapp__Badge__c(trailheadapp__API_Name__c='Test_API_Name_'+i, trailheadapp__Description__c='Test', trailheadapp__Icon__c = 'Test', trailheadapp__Namespace__c = 'Test', trailheadapp__URL__c = 'about:blank'));
			vMixList.add(new trailheadapp__Trailmix__c(trailheadapp__Created_By_Profile__c = 'Test', trailheadapp__External_Id__c = 'Test_'+i, trailheadapp__Slug__c = 'Test', trailheadapp__URL__c = 'about:blank'));
		}
		Database.insert(vBadgeList);
		Database.insert(vMixList);
	}

	/**
	 * @description Assignment test
	 */
	@IsTest
	static void testAssignTrainingToGroups()
	{
		/** Query a regular group */
		Id vGroupId = [SELECT GroupId FROM GroupMember WHERE Group.Type = 'Regular' LIMIT 1].GroupId;
		/** Get test badges and trailmixes */
		List<Id> vBadgeIds = new List<Id>();
		List<Id> vMixIds = new List<Id>();
		for (trailheadapp__Badge__c b: [SELECT Id FROM trailheadapp__Badge__c LIMIT 3])
		{
			vBadgeIds.add(b.Id);
		}
		for (trailheadapp__Trailmix__c m: [SELECT Id FROM trailheadapp__Trailmix__c LIMIT 3])
		{
			vMixIds.add(m.Id);
		}
		Test.startTest();
		/** Test a single run of the queueable job (recursive runs not allowed in tests) */
		TH_GroupAssignmentController.RUN_RECURSIVELY = false;
		System.enqueueJob(new TH_GroupAssignmentController(new List<Id>{vGroupId}, vBadgeIds, vMixIds, System.now()));
		Test.stopTest();
		/** Assert results */
		System.assert([SELECT COUNT() FROM trailheadapp__User_Badge__c] > 0, 'Badge assignment was not created');
		System.assert([SELECT COUNT() FROM trailheadapp__Trailmix_Assignment__c] > 0, 'Trailmix assignment was not created');
	}
}