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
	private static void testImpactedArticleTriggerHandlerMethods() {
		ImpactedArticleTriggerHandler mockModule = (ImpactedArticleTriggerHandler)MockUtility.mockUtility(ImpactedArticleTriggerHandler.class);
		Case caseTest = ApplicationTestDataFactoryCase.getCases(1, false)[0];
		insert caseTest;
		Article__c articleTest = ApplicationTestDataFactory.getArticles(1, false)[0];
		insert articleTest;
		ImpactedArticle__c impactedArticle = ApplicationTestDataFactory.getImpactedArticles(1, caseTest.Id, articleTest.Id, false)[0];
		insert impactedArticle;

		Assert.areEqual(true, Pattern.compile('\\bImpactedArticleTriggerHandler\\b').matcher(mockModule.toString()).find(), 'ImpactedArticleTriggerHandler should get called');
		Assert.areEqual(true, Pattern.compile('\\bArticleSubscriptionModule\\b').matcher(mockModule.toString()).find(), 'ArticleSubscriptionModule should get called');

		ImpactedArticleTriggerHandler handler = new ImpactedArticleTriggerHandler();
		handler.registerModules();

		Assert.areEqual(ImpactedArticle__c.SObjectType, handler.getSObjectType());
		List<SObjectType> sObjectTypes = new List<SObjectType>{
			ImpactedArticle__c.SObjectType,
			Case.SObjectType,
			Article__c.SObjectType
		};
		Assert.areEqual(sObjectTypes, ImpactedArticleTriggerHandler.getUnitOfWorkSObjectTypes(), 'SObjectType should match but instead got: ' + ImpactedArticleTriggerHandler.getUnitOfWorkSObjectTypes());
	}
}