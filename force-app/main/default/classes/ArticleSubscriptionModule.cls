/**
 * @description Article Subscription Module processes Impacted Articles from Insert Trigger in a specified batch size
 *		Then, sends the subscription notification to SAP via TIBCOArticleSubscriptionService class
 * @author Seth Heang
 * @test ArticleSubscriptionModuleTest
 * @changelog:
 * 2024-09-05 - Seth Heang - created
 */
public inherited sharing class ArticleSubscriptionModule extends ApplicationModule {
	@TestVisible
	private static final Integer ARTICLE_SUBSCRIPTION_BATCH_SIZE = 100;
	@TestVisible
	private static final Map<SObjectType, Set<SObjectField>> SELECTOR_FIELDS = new Map<SObjectType, Set<SObjectField>>{
			ImpactedArticle__c.SObjectType => new Set<SObjectField>{
					ImpactedArticle__c.Id,
					ImpactedArticle__c.Article__c
			},
			Case.SObjectType => new Set<SObjectField>{
					Case.Id,
					Case.CaseNumber,
					Case.EventCode__c,
					Case.FacilityOrOutletWCC__c,
					Case.LastModifiedDate,
					Case.OwnerUserName__c,
					Case.Subject,
					Case.Type
			},
			Article__c.SObjectType => new Set<SObjectField>{
					Article__c.ArticleID__c
			}
	};

	// Setup which triggers this module should respond to
	public ArticleSubscriptionModule() {
		getTriggerEvents().enableAfterInsert();
	}

	/**
	 * @description Called in After insert context and process article subscription logics
	 * @param records list of new ImpactedArticle__c records from trigger
	 * @param uow
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			processArticleSubscription((List<ImpactedArticle__c>) records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
					.logException(ApplicationLogger.wrapException(ex), 'ArticleSubscription', ArticleSubscriptionModule.class.getName(), 'onAfterInsert', 'ImpactedArticle', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description Process the ImpactedArticle__c records, split into a sublist with specified batch size
	 *			and make SOAP service callout for article subscription via Async Worker Framework
	 * @param records list of ImpactedArticle__c records from trigger
	 * @param uow
	 */
	private void processArticleSubscription(List<ImpactedArticle__c> records, ApplicationUnitOfWork uow){

		// query impacted articles with related parent case and article
		List<ImpactedArticle__c> impactedArticles = ImpactedArticlesSelector.newInstance(SELECTOR_FIELDS).selectById(
				new Map<Id, ImpactedArticle__c>(records).keySet(), // impactedArticle Ids set
				new Set<Object> {
						ImpactedArticlesSelector.Options.WITH_CASE,
						ImpactedArticlesSelector.Options.WITH_ARTICLE
				} // related parent case and article
		);

		// split the list into sublist of 100 as per batch size
		List<List<ImpactedArticle__c>> impactedArticlesWithSubList = splitList(impactedArticles, ARTICLE_SUBSCRIPTION_BATCH_SIZE);

		// each loop will enqueue AsyncArticleSubscriptionActionWorker with a list of 100 impacted articles as per the batch size
		// batch size may be configured as appropriate to reduce or eliminate the timeout issue
		for (List<ImpactedArticle__c> impactedArticlesInBatch : impactedArticlesWithSubList) {
			ArticleSubscriptionActionsParam params = new ArticleSubscriptionActionsParam(impactedArticlesInBatch);
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncArticleSubscriptionActionWorker.class, params));
		}
	}

	/**
	 * @description Wrapper to be passed as parameters to the Async Worker Framework for article subscription service
	 */
	public class ArticleSubscriptionActionsParam {
		@TestVisible
		private List<ImpactedArticle__c> impactedArticles;

		public ArticleSubscriptionActionsParam(List<ImpactedArticle__c> impactedArticles) {
			this.impactedArticles = impactedArticles;
		}
	}

	/**
	 * @description split the list into sublist of specified batch size
	 * @param originalList an original list of objects without size adjustment
	 * @param chunkSize specifies the size limit of sublists
	 *
	 * @return List<List<SObject>> list of many sublists with specified batch size, after the partition of the original list
	 */
	public static List<List<SObject>> splitList(List<SObject> originalList, Integer chunkSize) {
		List<List<SObject>> sublists = new List<List<SObject>>();
		List<SObject> currentSublist = new List<SObject>();

		for (Integer i = 0; i < originalList.size(); i++) {
			currentSublist.add(originalList[i]);

			// If the current sublist reaches the chunk size or we're at the end of the list
			if (currentSublist.size() == chunkSize || i == originalList.size() - 1) {
				sublists.add(currentSublist);
				currentSublist = new List<SObject>(); // Reset sublist for the next chunk
			}
		}
		return sublists;
	}

	/**
	 * Async worker implementation that schedule action for Unified Case proactive monitoring if applicable
	 */
	public without sharing class AsyncArticleSubscriptionActionWorker extends ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts {
		@TestVisible
		private ArticleSubscriptionActionsParam params;

		public override void execute(ApplicationUnitOfWork uow) {
			if (this.params != null) {
				// invoke the SOAP article subscription service
				TIBCOArticleSubscriptionService.newInstance().sendArticleSubscriptionNotifications(params.impactedArticles);
			}
		}

		public override Type getClassType() {
			return AsyncArticleSubscriptionActionWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return ImpactedArticle__c.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				this.params = (ArticleSubscriptionActionsParam) JSON.deserialize(serialisedParams, ArticleSubscriptionActionsParam.class);
			}
		}
	}
}