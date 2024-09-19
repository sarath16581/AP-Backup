/**
 * @description Article Subscription Module process Impacted Articles from Insert Trigger in a specified batch size
 *			And sends the subscription notification to SAP via SOAP API service
 * @author Seth Heang
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
	 * @description Called After an insert and validate case for 3 days and 5 days case monitoring scheduled action
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
	 * @param records
	 * @param uow
	 */
	private void processArticleSubscription(List<ImpactedArticle__c> records, ApplicationUnitOfWork uow){

		// query impacted articles with related case
		List<ImpactedArticle__c> impactedArticles = ImpactedArticlesSelector.newInstance(SELECTOR_FIELDS).selectById(
				new Map<Id, ImpactedArticle__c>(records).keySet(), // impactedArticle Ids set
				new Set<Object> { ImpactedArticlesSelector.Options.WITH_CASE } // related cases

		);

		//split the list into sublist of 100 as per batch size
		List<List<ImpactedArticle__c>> impactedArticlesWithSubList = splitList(impactedArticles, ARTICLE_SUBSCRIPTION_BATCH_SIZE);

		for (List<ImpactedArticle__c> impactedArticlesInBatch : impactedArticlesWithSubList) {
			// AsyncArticleSubscriptionActionWorker fire 100 at a time in batch
			ArticleSubscriptionActionsParam params = new ArticleSubscriptionActionsParam(impactedArticlesInBatch);
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncArticleSubscriptionActionWorker.class, params));
		}
	}

	/**
	 * @description Wrapper to be passed as parameters to the Async Worker Framework for scheduled action automation
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
	 * @param originalList
	 * @param chunkSize
	 *
	 * @return
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
			return Case.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				this.params = (ArticleSubscriptionActionsParam) JSON.deserialize(serialisedParams, ArticleSubscriptionActionsParam.class);
			}
		}
	}
}