/**
* @author Ashapriya Gadi
* @date 2021-12-22
* @group Tests
* @tag Selector
* @tag CampaignContactAssignments
* @domain Core
* @description Test class covering CampaignContactAssignmentsDomain
* @changelog
* 2021-12-22 - Ashapriya Gadi - Created
*/
@IsTest
private class 	CampaignContactAssignmentsDomain_Test {
	@IsTest
	private static void testMethods() {
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, true);
		
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true);
		
		ApplicationDomain.IConstructable constructableDomain = new CampaignContactAssignmentsDomain.Constructor();
		CampaignContactAssignmentsDomain domain = (CampaignContactAssignmentsDomain)constructableDomain.construct(campaignContactAssignments);
		
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(campaignContactAssignments[0].Id, domain.records[0].Id, 'Expected campaignContactAssignments record');
	}
}