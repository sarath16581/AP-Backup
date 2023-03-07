/**
 * @description       : This module checks and retrieves Articles from SAP into SF
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-12-13 - Mahesh Parvathaneni - Added beforeInsert trigger event and checkDuplicateCaseInvestigationRecords method
 * 2023-01-30 - George Nguyen - Added retrieveArticles which contains copied code from MyCustomerCaseArticleModule for async retrieval and mapping of the article.
 * 2023-02-21 - Mahesh Parvathaneni - Added recordtype filter for selector selectOpenCaseInvestigationsByCaseArticleNetworkId
 **/
public inherited sharing class STCaseInvestigationArticleModule extends ApplicationDomain.Module {

	/**
	 * List of case investigations that have already been enqueued for processing in this transaction
	 * This is to prevent enqueuing the same case id's where values may change multiple times across the transaction
	 */
	private static Set<Id> m_enqueuedCaseInvestigationIds;

	// RECURSION STOPPER!!
	// used only as a failsafe to ensure that a queueable doesn't enqueue another queueable under any circumstances
	// this may occur if SAP-EM is down or an article isn't found when the queueable runs.
	private static Boolean preventRecursiveReschedule = false;

	// used for caching the search results
	private static Map<String, Id> m_trackingReferenceIdMappingsCache;
	private static Map<Id, String> m_trackingArticleIdMappingsCache;

		static {
		m_enqueuedCaseInvestigationIds = new Set<Id>();
		m_trackingReferenceIdMappingsCache = new Map<String, Id>();
		m_trackingArticleIdMappingsCache = new Map<Id, String>();
	}

	// Get record type for StarTrack MyNetwork record type on case investigation
	public static Id starTrackMyNetworkRecordTypeId {
		get {
			if (starTrackMyNetworkRecordTypeId == null) {
				starTrackMyNetworkRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('CaseInvestigation__c', new Set<String>{ 'StarTrack_MyNetwork' }).values()[0].Id;
			}
			return starTrackMyNetworkRecordTypeId;
		}
		private set;
	}


	public static STCaseInvestigationArticleModule newInstance() {
		return (STCaseInvestigationArticleModule) Application.Utilities.newInstance(STCaseInvestigationArticleModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCaseInvestigationArticleModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow){
		checkDuplicateCaseInvestigationRecords((List<CaseInvestigation__c>) records);
		retrieveArticles((List<CaseInvestigation__c>) records, null, uow);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		queueAsyncArticleToCaseInvestigations((List<CaseInvestigation__c>)records);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		queueAsyncArticleToCaseInvestigations((List<CaseInvestigation__c>)records);
	}

	/**
	 * function to check the duplicate case investigation records being created for same case, article and network.
	 */
	private void checkDuplicateCaseInvestigationRecords(List<CaseInvestigation__c> records){
		Set<Id> caseIds = new Set<Id>();
		Set<Id> networkIds = new Set<Id>();
		Set<String> articleReferences = new Set<String>();
		//case id + article reference id + network id is the key
		Set<String> existingCaseArticleNetworkKeys = new Set<String>();
		Set<String> caseArticleNetworkKeys = new Set<String>();

		for (CaseInvestigation__c ci : records) {
			String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
			if (caseArticleNetworkKeys.contains(key)) {
				//add error if there are duplicate records in the new list
				ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
			} else {
				caseArticleNetworkKeys.add(key);
			}

			if (ci.Case__c != null) {
				caseIds.add(ci.Case__c);
			}
			if (String.isNotBlank(ci.ReferenceID__c)) {
				articleReferences.add(ci.ReferenceID__c);
			}
			if (ci.Network__c != null) {
				networkIds.add(ci.Network__c);
			}
		}

		if (caseIds.size() > 0 || articleReferences.size() > 0 || networkIds.size() > 0) {
			//get existing case investigation related to the case, network and article reference ids
			for (CaseInvestigation__c eci : CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByCaseArticleNetworkId(caseIds, articleReferences, networkIds, new Set<Id>{starTrackMyNetworkRecordTypeId}).values()) {
				String exisitngKey = eci.Case__c + eci.ReferenceID__c + eci.Network__c;
				existingCaseArticleNetworkKeys.add(exisitngKey);
			}

			for (CaseInvestigation__c ci : records) {
				String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
				if (existingCaseArticleNetworkKeys.contains(key)) {
					//add error if there are duplicate records
					ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
				}
			}
		}
	}

	void retrieveArticles(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {

		try {
			Set<String> processableReferenceIds = new Set<String>();
			Set<Id> processableArticleIds = new Set<Id>();
			List<CaseInvestigation__c> caseInvestigationsToLinkReferencesTo = new List<CaseInvestigation__c>();
			List<CaseInvestigation__c> caseInvestigationsToLinkArticlesTo = new List<CaseInvestigation__c>();

			if(existingRecords == null) {
				// loop through our records to figure out what actions need to be taken
				for (CaseInvestigation__c c : records) {

					if (!String.isEmpty(c.ReferenceID__c)) {
						// the reference id was specified
						// this means we need to find the article id and link it to the case
						// if the article doesn't exist in SF it will queue a job that will query SAP-EM
						caseInvestigationsToLinkArticlesTo.add(c);
						processableReferenceIds.add(c.ReferenceID__c);

					} else if (c.Article__c != null) {
						// reference id was not specified but the article id was
						// this means we need to grab the reference id from the article and apply it to the case
						caseInvestigationsToLinkReferencesTo.add(c);
						processableArticleIds.add(c.Article__c);

					}
				}
			} else {

				Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{CaseInvestigation__c.ReferenceID__c, CaseInvestigation__c.Article__c});
				
				// loop through our records to figure out what actions need to be taken
				for(CaseInvestigation__c c : records) {
					Set<SObjectField> changed = changedRecords.get(c.Id);
					if(changed == null) changed = new Set<SObjectField>();

					// process any changed records
					//	  OR any scenario where the article__c field is empty (and hasn't already been queued for processing)...
					//		  (this might be because an article was deleted and the reference was removed from the case investigation).... this will ensure the article details will be redownloaded from SAP-EM
					// We only have to process case records that arent already in the 'queue' for processing asynchronously
					if(!m_enqueuedCaseInvestigationIds.contains(c.Id) && (!changed.isEmpty() || (!String.isEmpty(c.ReferenceID__c) && c.Article__c == null))) {

						if(String.isEmpty(c.ReferenceID__c) && c.Article__c != null && changed.contains(CaseInvestigation__c.ReferenceID__c)) {

							// the reference id value was removed which means we need to remove the articletest value too
							// no need to use unit of work here since we are updating the current record in a before trigger
							c.Article__c = null;

						} else if(!String.isEmpty(c.ReferenceID__c) && c.Article__c == null && changed.contains(CaseInvestigation__c.Article__c)) {

							// the article id was removed so we need to remove the reference id
							// no need to use unit of work here since we are updating the current record in a before trigger
							c.ReferenceID__c = null;

						} else if((!String.isEmpty(c.ReferenceID__c) && c.Article__c == null) || changed.contains(CaseInvestigation__c.ReferenceID__c)) {

							// the article id is currently not linked to the case based on the reference id or the reference id has changed
							// we need to query the database to determine whether this article exists or not
							// NOTE: this won't be called in a recursion scenario where the case is already queued for processing in an async context.
							//		  Courtesy of !m_enqueuedCaseIds.contains(c.Id) above
							// NOTE: reference id should always been given priority and dealt with first since this is the primary way contact centre will enter data
							caseInvestigationsToLinkArticlesTo.add(c);
							processableReferenceIds.add(c.ReferenceID__c);

						} else if(!String.isEmpty(c.ReferenceID__c) && c.Article__c != null && m_trackingReferenceIdMappingsCache.get(nullToString(c.ReferenceID__c).toUpperCase()) == c.Article__c) {

							// we don't need to do anything here if the reference id  and article fields are already in sync with each other.
							// we utilise cache (if it exists) to confirm these values are in sync

						} else if(changed.contains(CaseInvestigation__c.Article__c)) {

							// article field was change so we need to update the reference field on the case to reflect the change
							caseInvestigationsToLinkReferencesTo.add(c);
							processableArticleIds.add(c.Article__c);

						}
					}
				}
			}

			// grab the existing articles in SF to link the case that can be linked
			if (!caseInvestigationsToLinkReferencesTo.isEmpty() || !caseInvestigationsToLinkArticlesTo.isEmpty()) {

				// grab a list of existing articles to see if we can match them up to the case investigations that have been passed in
				// this will also populate m_trackingReferenceIdMappings and m_trackingReferenceIdMappings cache which we use here
				Map<Id, Article__c> articles = selectArticles(processableReferenceIds, processableArticleIds);

				// apply article field id value to the case where possible
				// this is where a record has a ReferenceID__c. (The existence of Article__c is irrelevant since ReferenceID__c always takes priority)
				populateCaseInvestigationArticleIds(caseInvestigationsToLinkArticlesTo, articles, m_trackingReferenceIdMappingsCache);

				// apply a reference id to case investigations that require it
				// the is where Article__c has a value and there is no ReferenceID__c
				// m_trackingArticleIdMappingsCache was populated in selectArticles calls
				populateCaseInvestigationReferences(caseInvestigationsToLinkReferencesTo, m_trackingArticleIdMappingsCache);

			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, STCaseInvestigationArticleModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Process the scenarios that require a link to an article id. This is only where an article already exists in the Article__c object. 
	 * If an article isn't found, the case will be queued for async processing in the onAfter trigger handlers.
	 */
	public List<CaseInvestigation__c> populateCaseInvestigationArticleIds(List<CaseInvestigation__c> caseInvestigations, Map<Id, Article__c> queriedArticles, Map<String, Id> existingReferenceIdMappings) {

		List<CaseInvestigation__c> updateable = new List<CaseInvestigation__c>();
		for(CaseInvestigation__c c : caseInvestigations) {
			if(existingReferenceIdMappings.get(nullToString(c.ReferenceID__c).toUpperCase()) != null) {

				//the article for the reference id already exists in Article__c table so the article id on case can be synced to the existing record
				Article__c article = queriedArticles.get(existingReferenceIdMappings.get(nullToString(c.ReferenceID__c).toUpperCase()));

				if(article.RecordType != null && article.RecordType.DeveloperName == 'Consignment' && article.Articles__r != null && article.Articles__r.size() == 1) {
					// IMPORTANT!: Business rule of contact centre is that if a consignment reference id was provided and the consignment is a single article consignment, then we switch the reference id and set the article id to the article
					c.ReferenceID__c = nullToString(!String.isEmpty(article.Articles__r[0].TrackingID__c) ? article.Articles__r[0].TrackingID__c : article.Articles__r[0].ArticleID__c).toUpperCase();
					c.Article__c = article.Articles__r[0].Id;
					updateable.add(c);
				} else {
					c.Article__c = article.Id;
					updateable.add(c);
				}
			} else if(c.Article__c != null) {
				// remove the reference to the passed in article since it is incorrect (doesn't line up with the ReferenceID passed in)
				c.Article__c = null;
				updateable.add(c);
			} 
		}

		return updateable;
	}

	/**
	 * Where an article id was provided but a reference id was not, loop through and set the reference id
	 * given the article field is populated it means it will always exist in our selector so we can reliably retrieve the corresponding reference id to attach to the case
	 */
	private void populateCaseInvestigationReferences(List<CaseInvestigation__c> caseInvestigations, Map<Id, String> existingArticleIdMappings) {

		for(CaseInvestigation__c c : caseInvestigations) {
			// cache was populated in selectAndCacheArticles method call above
			c.ReferenceID__c = existingArticleIdMappings.get(c.Article__c);
		}
	}

		/**
	 * Select articles based on reference id. Mappings of these articles will be cache across the transaction to verify a reference id links to an article in subsequent trigger calls
	 */
	public Map<Id, Article__c> selectArticles(Set<String> processableReferenceIds) {

		Map<Id, Article__c> articles = new Map<Id, Article__c>(ArticlesSelector.newInstance().selectByTracking(processableReferenceIds, new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_RECORDTYPE}, false));

		// store a cache of the articles so it can be used
		populateCache(articles.values());

		// for single article consignments, add the article into the search results so we can reference it throughout this code
		for(Article__c article : articles.values()) {
			if(article.Articles__r != null && article.Articles__r.size() == 1) {
				articles.put(article.Articles__r[0].Id, article.Articles__r[0]);
			}
		}

		return articles;
	}

	/**
	 * Select articles based on reference id OR article ids. Mappings of these articles will be cache across the transaction to verify a reference id links to an article in subsequent trigger calls
	 */
	public Map<Id, Article__c> selectArticles(Set<String> processableReferenceIds, Set<Id> processableArticleIds) {
		Map<Id, Article__c> articles = ArticlesSelector.newInstance().selectByIdOrTracking(processableReferenceIds, processableArticleIds, new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_RECORDTYPE}, false);

		populateCache(articles.values());

		// for single article consignments, add the article into the search results so we can reference it throughout this code
		for(Article__c article : articles.values()) {
			if(article.Articles__r != null && article.Articles__r.size() == 1) {
				articles.put(article.Articles__r[0].Id, article.Articles__r[0]);
			}
		}

		return articles;
	}

	/**
	 * This is used to store article/reference mappings across the same transaction. This is used to save an additional query in subsequent trigger calls
	 */
	private void populateCache(List<Article__c> articles) {

		for(Article__c article : articles) {
			String trackingId = nullToString(!String.isEmpty(article.TrackingID__c) ? article.TrackingID__c : article.ArticleID__c).toUpperCase();
			m_trackingReferenceIdMappingsCache.put(trackingId, article.Id);
			m_trackingArticleIdMappingsCache.put(article.Id, trackingId);

			if(article.Articles__r != null) {
				for(Article__c childArticle : article.Articles__r) {
					String childTrackingId = nullToString(!String.isEmpty(childArticle.TrackingID__c) ? childArticle.TrackingID__c : childArticle.ArticleID__c).toUpperCase();
					m_trackingReferenceIdMappingsCache.put(childTrackingId, childArticle.Id);
					m_trackingArticleIdMappingsCache.put(childArticle.Id, childTrackingId);
				}
			}
		}
	}

	/**
	 * Process records that have a Reference ID without an Article field populated
	 * This would occur in the following scenarios:
	 * 1. Reference ID field changed and the article did not already exist in Salesforce
	 * 2. Article record was deleted in salesforce and case investigation was later updated
	 * 3. Article id field on Case was removed or already empty
	 */
	@TestVisible 
	private void queueAsyncArticleToCaseInvestigations(List<CaseInvestigation__c> caseInvestigations) {
		// note we pass a list of reference ids into the queueable so we don't need to run a soql until after the integration callout
		Set<String> referencesToEnqueue = new Set<String>();
		Set<Id> caseInvestigationsToEnqueue = new Set<Id>();

		for(CaseInvestigation__c c : caseInvestigations) {
			if(!String.isEmpty(c.ReferenceID__c) && c.Article__c == null) {
				caseInvestigationsToEnqueue.add(c.Id);
				referencesToEnqueue.add(c.ReferenceID__c);
			}
		}

		if(!caseInvestigationsToEnqueue.isEmpty()) {
			ensureQueryJobEnqueued(caseInvestigationsToEnqueue, referencesToEnqueue);
		}
	}

	/**
	 * This will ensure that a SAP-EM query job will be enqueued for all the case investigations in the list.
	 * This will be in the scenario where no article was found in SF for the ReferenceID listed on the case investigation
	 * This method will ensure that the case investigation is only enqueued once to limit scenarios where recursion may occur
	 *
	 * NOTE: referenceIds is also passed in so a soql does not need to be run prior to the integration callout to retrieve article details
	 *		  It's the callers responsibility to pass in a synchronised list of caseids/referenceids
	 */
	private void ensureQueryJobEnqueued(Set<Id> caseInvestigationIds, Set<String> referenceIds) {

		// if the queueable has already fired or if we are already in an async context then we prevent the execution of a subsequent queueable from being fired.
		if(preventRecursiveReschedule || System.isQueueable() || System.isFuture() || System.isBatch() || System.isScheduled()) {
			return;
		}

		caseInvestigationIds.removeAll(m_enqueuedCaseInvestigationIds);
		if(!caseInvestigationIds.isEmpty()) {
			m_enqueuedCaseInvestigationIds.addAll(caseInvestigationIds);

			// TODO: Refactor this into a better enqueueing model
			// enqueue the job here
			AsyncLinkArticlesToCaseInvestigationsQueueable job = new AsyncLinkArticlesToCaseInvestigationsQueueable(caseInvestigationIds, referenceIds);
			System.enqueueJob(job);

		}
	}

	// copied from STCaseInvestigationArticleModule
	private without sharing class AsyncLinkArticlesToCaseInvestigationsQueueable implements Queueable, Database.AllowsCallouts {
		Set<Id> caseInvestigationIds;
		Set<String> referenceIds;

		public AsyncLinkArticlesToCaseInvestigationsQueueable(Set<Id> caseInvestigationIds, Set<String> referenceIds) {
			this.caseInvestigationIds = caseInvestigationIds;
			this.referenceIds = referenceIds;
		}

		public void execute(QueueableContext context) {
			try {
				// as a failsafe, set this to ensure no more queueable instances will be created
				// this is for example if an article isn't found or Tibco errors or some other type of error.
				preventRecursiveReschedule = true;

				if(!referenceIds.isEmpty()) {

					// trigger a search into SAP-EM
					// for any found articles, the article service will populate the Article__c table
					// TODO: Revisit the TIBCO Search service....
					TIBCOArticleService.getInstance().search(new List<String>(referenceIds), true, false, false, false, true);

					// NOTE: We run this soql after the integration callout so we have the latest data on the record when processing it
					//	  (Integration callout could take 5 or 10 seconds or sometimes more).
					Map<Id, CaseInvestigation__c> caseInvestigations = CaseInvestigationsSelector.newInstance().selectById(caseInvestigationIds);

					// TODO: This should be routed via the Domain class rather than invoked directly
					STCaseInvestigationArticleModule module = STCaseInvestigationArticleModule.newInstance();

					// grab a list of existing articles to see if we can match them up to the case investigations that have been passed in
					// this will also populate m_trackingReferenceIdMappings cache which we use here
					Map<Id, Article__c> articles = module.selectArticles(referenceIds);

					// loop through all processable caseInvestigations and apply the article field id value to the case investigation where possible
					// m_trackingReferenceIdMappingsCache was populated in selectArticles call
					Map<Id, CaseInvestigation__c> updateable = new Map<Id, CaseInvestigation__c>(module.populateCaseInvestigationArticleIds(caseInvestigations.values(), articles, m_trackingReferenceIdMappingsCache));

					if(!updateable.isEmpty()) {

						List<CaseInvestigation__c> caseInvestigationsToUpdate = updateable.values();
						List<Database.SaveResult> srList = ApplicationDatabase.getInstance().dmlUpdate(caseInvestigationsToUpdate, false);						

						// Perform 1 DML retry if there are any database errors
						// this can happen due to Row Lock issue between this Queueable and future method CaseMilestoneUtility.setSLA()
						List<CaseInvestigation__c> caseInvestigationsToRetryDML = new List<CaseInvestigation__c>();
						List<Database.SaveResult> srRetryDMLList = new List<Database.SaveResult>();

						for(Integer i=0;i<srList.size();i++){
							if (!srList.get(i).isSuccess()){
								caseInvestigationsToRetryDML.add(caseInvestigationsToUpdate.get(i));
							 }						
						}						
						if(caseInvestigationsToRetryDML.size() > 0){
							srRetryDMLList = ApplicationDatabase.getInstance().dmlUpdate(caseInvestigationsToRetryDML, false);

							for (Database.SaveResult sr : srRetryDMLList) {
								if (!sr.isSuccess()) {	
									for (Database.Error err : sr.getErrors()) {	
										System.debug('The following error has occurred on the DML Retry.');
										System.debug(err.getStatusCode() + ': ' + err.getMessage());
									}
								}
							}
						}						

						if(srRetryDMLList.size() > 0){
							// log any failed updates to ensure we can monitor save errors (especially for checking routing failures)
							ApplicationLogger.getInstance().logFailedDatabaseResults(srRetryDMLList, SSSWConstants.SSSW_APP, AsyncLinkArticlesToCaseInvestigationsQueueable.class.getName(), 'execute', '', ApplicationLogger.LoggingLevel.ERROR);
						}
					}
				}
			} catch(Exception ex) {
				System.debug('>>>>>> Exception: ' + ex.getStackTraceString());
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, AsyncLinkArticlesToCaseInvestigationsQueueable.class.getName(), 'execute', '', LoggingLevel.ERROR);
			} 
		}
	}

}