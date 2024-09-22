/**
 * @description This is a Trigger Handler class for ImpactedArticle__c
 * @author Seth Heang
 * @test ImpactedArticleTriggerHandlerTest
 * @changelog
 * 2024-09-13 - Seth Heang - created
 **/
public inherited sharing class ImpactedArticleTriggerHandler extends ApplicationTriggerHandler {
	public override SObjectType getSObjectType() {
		return ImpactedArticle__c.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	// register modules for trigger automation
	public override void registerModules() {
		registerModule(ArticleSubscriptionModule.class);
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				ImpactedArticle__c.SObjectType,
				Case.SObjectType,
				Article__c.SObjectType
		};
	}
}