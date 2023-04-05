/**
 * @description			: Test class for FeedCommentTriggerHandler2
 * @author 				: Mahesh Parvathaneni
 * @changelog
 * 2023-04-04 - Mahesh Parvathaneni - created
 **/

@IsTest
private class FeedCommentTriggerHandler2_Test {

	/**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		FeedCommentTriggerHandler2 handler = new FeedCommentTriggerHandler2();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(FeedComment.SObjectType, handler.getSObjectType(), 'Expected FeedComment sobject type');
		System.assert(FeedCommentTriggerHandler2.getUnitOfWorkSObjectTypes().contains(FeedComment.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(FeedCommentTriggerHandler2.getUnitOfWorkSObjectTypes().contains(CaseInvestigation__c.SObjectType), 'Expected valid list of sobject types to be returned');
	}
	
}