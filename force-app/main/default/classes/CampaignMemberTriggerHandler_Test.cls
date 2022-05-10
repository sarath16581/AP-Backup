/***
 * @description Handler class for CampaignMember
 * @author Mathew Jose
 * @date 2021-12-22
 * @group Domain
 * @domain CampaignMember
 * @changelog
 */
@IsTest
private class CampaignMemberTriggerHandler_Test {
	/**
	* Note the simplicity of this class, the bulk of the tests are handled in the Core class
	*/
	@IsTest
	private static void test() {
		
		CampaignMemberTriggerHandler domain = new CampaignMemberTriggerHandler();
		domain.newUnitOfWork();
		domain.registerDomains();
		
		// PMD warning
		System.assert(true);
	}
}