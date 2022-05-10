/**
* @author Mathew Jose
* @date 2022-01-22
* @group Tests
* @tag Domain
* @tag CampaignMembersDomain
* @domain Core
* @description Test class for campaign members domain
* @changelog
* 2022-01-22 - Mathew Jose - Created
*/
@IsTest
private class CampaignMembersDomain_Test {
	@IsTest
	private static void testMethods() {
        		
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, true);
        
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

        List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id);

		
		ApplicationDomain.IConstructable constructableDomain = new CampaignMembersDomain.Constructor();
		CampaignMembersDomain domain = (CampaignMembersDomain)constructableDomain.construct(campaignMembers);
		
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(campaignMembers[0].Id, domain.records[0].Id, 'Expected campaignmembers record');
	}
}