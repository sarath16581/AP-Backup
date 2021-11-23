/**
 * @description Test class covering TH_Assignments and TH_Recommendations
 * This is an addon to Trail Tracker from SalesforceCloudServices (https://github.com/SalesforceCloudServices/Trailhead-Badge-and-Mix-Assignments-LWC)
 *
 */
/**
--------------------------------------- History --------------------------------------------------
23.01.2020    alex.volkov@auspost.com.au    Updated TestTH_Assignments to cover TH_Recommendations.
											Removed report testing as reports won't be utilized.
											Moved test data creation to test setup, added assertions.
**/

@IsTest
private class TH_AssignmentsTest
{
	/**
	* @description Test data setup
	*/
	@TestSetup
	static void setupData()
	{
		//Create Test Data
		//Create Test Account
		Account testAcc = new Account(Name = 'Test Acc');
		Database.insert(testAcc);
		//Create test Trailmix
		trailheadapp__Trailmix__c mix = new trailheadapp__Trailmix__c();
		mix.Name = 'Test Mix';
		mix.trailheadapp__URL__c = 'https://trailhead.salesforce.com/';
		mix.trailheadapp__Slug__c = 'Test-Mix';
		mix.trailheadapp__External_Id__c = '000001111';
		mix.trailheadapp__Created_By_Profile__c = 'https://trailhead.salesforce.com/';
		mix.trailheadapp__Creator_TH_SFID__c = 'SomeText';
		insert(mix);
		//Create test Badge
		trailheadapp__Badge__c badge = new trailheadapp__Badge__c();
		badge.Name = 'Test Badge';
		badge.trailheadapp__Description__c = 'test';
		badge.trailheadapp__URL__c = 'https://trailhead.salesforce.com/';
		badge.trailheadapp__Icon__c = 'https://trailhead.salesforce.com/';
		badge.trailheadapp__API_Name__c = '000001112';
		badge.trailheadapp__Namespace__c = 'namespace';
		insert(badge);
		//Create test trailmix assignment
		trailheadapp__User_Trailmix__c uMix = new trailheadapp__User_Trailmix__c();
		uMix.trailheadapp__Trailmix__c = mix.Id;
		uMix.trailheadapp__User__c = UserInfo.getUserId();
		uMix.trailheadapp__Due_At__c = Datetime.now();
		insert(uMix);
		//Create test badge assignment
		trailheadapp__User_Badge__c uBadge = new trailheadapp__User_Badge__c();
		uBadge.trailheadapp__Badge__c = badge.Id;
		uBadge.trailheadapp__User__c = UserInfo.getUserId();
		uBadge.trailheadapp__Status__c = 'Assigned';
		uBadge.trailheadapp__Due_Date__c = Datetime.now().addDays(1);
		insert(uBadge);
		//Create test recommendations
		Database.insert(new List<TH_Recommendation__c>
		{
				new TH_Recommendation__c(Object_API_Name__c = 'Account', Field_Name_Constraint__c = 'Name', Field_Value_Constraint__c = 'Test Acc', Badge__c = badge.Id),
				new TH_Recommendation__c(Object_API_Name__c = 'Account', Field_Name_Constraint__c = 'Name', Field_Value_Constraint__c = 'Test Acc', Trailmix__c = mix.Id)
		});
	}

	/**
	* @description Test method for all assignment methods
	*/
	@IsTest
	static void TestTH_Assignments()
	{
		/** Query test data */
		Account testAcc = [SELECT Id FROM Account LIMIT 1];
		trailheadapp__Badge__c badge = [SELECT Id FROM trailheadapp__Badge__c LIMIT 1];
		trailheadapp__Trailmix__c mix = [SELECT Id FROM trailheadapp__Trailmix__c LIMIT 1];
		Test.startTest();
		/** Test getAllAssignedTrailEntries for badges, trailmixes and both simultaneously */
		TH_Assignments.TrailheadEntry[] entries = TH_Assignments.getAllAssignedTrailEntries(Label.th_TrailheadTypeBoth);
		entries = TH_Assignments.getAllAssignedTrailEntries(Label.th_TrailheadTypeBadge);
		entries = TH_Assignments.getAllAssignedTrailEntries(Label.th_TrailheadTypeTrailmix);
		/** Test getRecommendedEntries for a particular record and for the user */
		entries = TH_Recommendations.getRecommendedEntries(testAcc.Id, false);
		System.assert(!entries.isEmpty(), 'Recommendations not returned');
		entries = TH_Recommendations.getRecommendedEntries(null, false);
		/** Test badge and trailmix assignment */
		TH_Assignments.addTrailheadModuleAssignment(badge.Id, Datetime.now(), UserInfo.getUserId());
		TH_Assignments.addTrailmixAssignment(mix.Id, Datetime.now(), UserInfo.getUserId());
		Test.stopTest();
		/** Assert assignment results */
		System.assertEquals(2, [SELECT COUNT() FROM trailheadapp__User_Badge__c], 'Module assignment was not created');
		System.assertEquals(1, [SELECT COUNT() FROM trailheadapp__Trailmix_Assignment__c], 'Trailmix assignment was not created');
	}
}