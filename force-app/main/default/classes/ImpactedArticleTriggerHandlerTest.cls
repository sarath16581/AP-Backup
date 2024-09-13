/***
 * @description Test class for ImpactedArticleTriggerHandler
 * @author Seth Heang
 * @date 2024-09-13
 * @changelog
 * 2024-09-13 - Seth Heang - Created
 */
@IsTest
private class ImpactedArticleTriggerHandlerTest {

	@IsTest
	private static void testForCoverage() {
		ImpactedArticleTriggerHandler handler = new ImpactedArticleTriggerHandler();
		handler.registerModules();

		System.assertEquals(ImpactedArticle__c.SObjectType, handler.getSObjectType());
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			ImpactedArticle__c.SObjectType,
			Case.SObjectType,
			Article__c.SObjectType
		};
		System.assertEquals(sObjectTypes, ImpactedArticleTriggerHandler.getUnitOfWorkSObjectTypes(), 'SObjectType should match but instead got: ' + ImpactedArticleTriggerHandler.getUnitOfWorkSObjectTypes());
	}
}