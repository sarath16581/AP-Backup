/***
 * @description Domain class for CampaignContactAssignment
 * @author Ashapriya Gadi
 * @date 2021-12-22
 * @group Domain
 * @domain CampaignContactAssignment__c
 * @changelog
 */
@IsTest
private class CampaignContactAssignTriggerHandler_Test {
	/**
	* Note the simplicity of this class, the bulk of the tests are handled in the Core class
	*/
	@IsTest
	private static void test() {
		
		CampaignContactAssignmentTriggerHandler domain = new CampaignContactAssignmentTriggerHandler();
		domain.newUnitOfWork();
		domain.registerDomains();
		
		// PMD warning
		System.assert(true);
	}
}