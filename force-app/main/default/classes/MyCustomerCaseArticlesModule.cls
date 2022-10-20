/**
 * @description
 * Domain Module to handle the Article related functionality on a SSSW case.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Nathan Franklin
 * @date 2020-07-22
 * @group Domain
 * @domain SSSW
 * @changelog
 * 10.04.2020		Naseer Abbasi		Added logic to determine case queues once ArticleTest__c is populated
 * 30.06.2021	Steve.judd6@auspost.com.au  Added debug statement, description changes for extra cover.
 * 20.04.2022   SaiSwetha Pingali - Removed logic for SnapIT cases as it is no longer required.
 *
 */
public inherited sharing class MyCustomerCaseArticlesModule extends ApplicationDomain.Module {

	public static MyCustomerCaseArticlesModule newInstance() {
		return (MyCustomerCaseArticlesModule)Application.Utilities.newInstance(MyCustomerCaseArticlesModule.class);
	}

	/**
	 * List of cases that have already been enqueued for processing in this transaction
	 * This is to prevent enqueuing the same case id's where values may change multiple times across the transaction
	 */
	private static Set<Id> m_enqueuedCaseIds;

	/**
	 * List of article id's that have already been enqueued into an async operation for processing in this transaction
	 */
	private static Set<Id> m_enqueuedArticleSubscriptionIds;

	// RECURSION STOPPER!!
	// used only as a failsafe to ensure that a queueable doesn't enqueue another queueable under any circumstances
	// this may occur if SAP-EM is down or an article isn't found when the queueable runs.
	private static Boolean preventRecursiveReschedule = false;

	// RECURSION STOPPER!!
	// used only as a failsafe to ensure that a queueable doesn't enqueue another queueable under any circumstances
	private static Boolean preventRecursiveArticleReschedule = false;

	private static Map<String, Id> m_trackingReferenceIdMappingsCache;
	private static Map<Id, String> m_trackingArticleIdMappingsCache;
	private static Map<String, MiniCaseFieldMapping__c> m_sapCategoryMappings;

	static {
		m_enqueuedCaseIds = new Set<Id>();
		m_enqueuedArticleSubscriptionIds = new Set<Id>();
		m_trackingReferenceIdMappingsCache = new Map<String, Id>();
		m_trackingArticleIdMappingsCache = new Map<Id, String>();
		m_sapCategoryMappings = new Map<String, MiniCaseFieldMapping__c>();
	}

	// Setup which triggers this module should respond to
	public MyCustomerCaseArticlesModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate().enableAfterUpdate();
	}

	//	public override Set<SObjectField> getTriggerMonitoredFields() {
	//		return new Set<SObjectField>{Case.RecordTypeId, Case.ArticleTest__c, Case.ReferenceID__c};
	//	}

	/**
	 * Called when a new Case is being inserted.
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			System.debug('MyCustomerCaseArticlesModule:onBeforeInsert');

			Set<String> processableReferenceIds = new Set<String>();
			Set<Id> processableArticleIds = new Set<Id>();
			List<Case> casesToLinkReferencesTo = new List<Case>();
			List<Case> casesToLinkArticlesTo = new List<Case>();

			// loop through our records to figure out what actions need to be taken
			for (Case c : (List<Case>) records) {

				if (!String.isEmpty(c.ReferenceID__c)) {

					// the reference id was specified
					// this means we need to find the article id and link it to the case
					// if the article doesn't exist in SF it will queue a job that will query SAP-EM
					casesToLinkArticlesTo.add(c);
					processableReferenceIds.add(c.ReferenceID__c);

				} else if (c.ArticleTest__c != null) {

					// reference id was not specified but the article id was
					// this means we need to grab the reference id from the article and apply it to the case
					casesToLinkReferencesTo.add(c);
					processableArticleIds.add(c.ArticleTest__c);

				}

			}

			// grab the existing articles in SF to link the case that can be linked
			System.debug('casesToLinkReferencesTo: ' + casesToLinkReferencesTo);
			System.debug('casesToLinkArticlesTo: ' + casesToLinkArticlesTo);
			if (!casesToLinkReferencesTo.isEmpty() || !casesToLinkArticlesTo.isEmpty()) {

				// grab a list of existing articles to see if we can match them up to the cases that have been passed in
				// this will also populate m_trackingReferenceIdMappings and m_trackingReferenceIdMappings cache which we use here
				Map<Id, Article__c> articles = selectArticles(processableReferenceIds, processableArticleIds);

				// apply article field id value to the case where possible
				// this is where a record has a ReferenceID__c. (The existence of ArticleTest__c is irrelevant since ReferenceID__c always takes priority)
				populateCaseArticleIds(casesToLinkArticlesTo, articles, m_trackingReferenceIdMappingsCache);

				// apply a reference id to cases that require it
				// the is where ArticleTest__c has a value and there is no ReferenceID__c
				// m_trackingArticleIdMappingsCache was populated in selectArticles calls
				populateCaseReferences(casesToLinkReferencesTo, m_trackingArticleIdMappingsCache);

				// apply default values to case fields based on any articles linked to cases
				List<Case> casesToDefault = new List<Case>();
				casesToDefault.addAll(casesToLinkArticlesTo);
				casesToDefault.addAll(casesToLinkReferencesTo);
				applyCaseArticleDefaults(casesToDefault, articles);

			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, MyCustomerCaseArticlesModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * After insert trigger to process records that have a Reference ID without an Article field populated
	 * This will occur if the article linked to the ReferenceID does not already exist in Salesforce
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			System.debug('MyCustomerCaseArticlesModule:onAfterInsert');

			// note we pass a list of reference ids into the queueable so we don't need to run a soql until after the integration callout
			Set<String> referencesToEnqueue = new Set<String>();
			Set<Id> casesToEnqueue = new Set<Id>();

			for(Case c : (List<Case>)records) {
				if(!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c == null) {
					// NOTE: If article field is not null, we can rely on the value being accurate from the previous trigger coe that was run in the before triggers
					casesToEnqueue.add(c.Id);
					referencesToEnqueue.add(c.ReferenceID__c);
				}
			}

			if(!casesToEnqueue.isEmpty()) {
				ensureQueryJobEnqueued(casesToEnqueue, referencesToEnqueue);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, MyCustomerCaseArticlesModule.class.getName(), 'onAfterInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Called when a Case is being updated.
	 * Records that match the following criteria will be passed in:
	 * 1. Where the Record Type starts with SSSW (Defined in MyCustomerCases.filter)
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			System.debug('MyCustomerCaseArticlesModule:onBeforeUpdate');

			Set<String> processableReferenceIds = new Set<String>();
			Set<Id> subscribedArticleIds = new Set<Id>();
			Set<Id> processableArticleIds = new Set<Id>();
			List<Case> casesToLinkReferencesTo = new List<Case>();
			List<Case> casesToLinkArticlesTo = new List<Case>();

			Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Case.ReferenceID__c, Case.ArticleTest__c, Case.Subscribed__c});
			System.debug('changedRecords: ' + changedRecords);

			// loop through our records to figure out what actions need to be taken
			for(Case c : (List<Case>)records) {
				Set<SObjectField> changed = changedRecords.get(c.Id);
				if(changed == null) changed = new Set<SObjectField>();

				// process any changed records
				//	  OR any scenario where the articleTest field is empty (and hasn't already been queued for processing)...
				//		  (this might be because an article was deleted and the reference was removed from the case).... this will ensure the article details will be redownloaded from SAP-EM
				// We only have to process case records that arent already in the 'queue' for processing asynchronously
				if(!m_enqueuedCaseIds.contains(c.Id) && (!changed.isEmpty() || (!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c == null))) {

					if(String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c != null && changed.contains(Case.ReferenceID__c)) {

						// the reference id value was removed which means we need to remove the articletest value too
						// no need to use unit of work here since we are updating the current record in a before trigger
						c.ArticleTest__c = null;

					} else if(!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c == null && changed.contains(Case.ArticleTest__c)) {

						// the article id was removed so we need to remove the reference id
						// no need to use unit of work here since we are updating the current record in a before trigger
						c.ReferenceID__c = null;

					} else if((!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c == null) || changed.contains(Case.ReferenceID__c)) {

						// the article id is currently not linked to the case based on the reference id or the reference id has changed
						// we need to query the database to determine whether this article exists or not
						// NOTE: this won't be called in a recursion scenario where the case is already queued for processing in an async context.
						//		  Courtesy of !m_enqueuedCaseIds.contains(c.Id) above
						// NOTE: reference id should always been given priority and dealt with first since this is the primary way contact centre will enter data
						casesToLinkArticlesTo.add(c);
						processableReferenceIds.add(c.ReferenceID__c);

					} else if(!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c != null && m_trackingReferenceIdMappingsCache.get(nullToString(c.ReferenceID__c).toUpperCase()) == c.ArticleTest__c) {

						// we don't need to do anything here if the reference id  and article fields are already in sync with each other.
						// we utilise cache (if it exists) to confirm these values are in sync
						System.debug('Found Case in Sync with Article');

					} else if(changed.contains(Case.ArticleTest__c)) {

						// article field was change so we need to update the reference field on the case to reflect the change
						casesToLinkReferencesTo.add(c);
						processableArticleIds.add(c.ArticleTest__c);

					}

				}

				// Subscribed__c is set in SSSW - Article Subscription workflow rule after the Article Subscribe outbound message is queued
				// set this false now so it may be used again in the future if the article on the case ever changes
				// this is a little bit dodgy but the outbound message is tied to Case object and no funding is available to uplift Tibco endpoint to an alternate solution
				if(c.Subscribed__c && c.ArticleTest__c != null) {
					c.Subscribed__c = false;

					// update the Article__c record to mark it as Subscribed since the outbound message is now queued for processing
					subscribedArticleIds.add(c.ArticleTest__c);
				}

			}

			// check if there is work to be done
			System.debug('casesToLinkReferencesTo: ' + casesToLinkReferencesTo);
			System.debug('casesToLinkArticlesTo: ' + casesToLinkArticlesTo);
			if(!casesToLinkReferencesTo.isEmpty() || !casesToLinkArticlesTo.isEmpty()) {
				// grab a list of existing articles to see if we can match them up to the cases that have been passed in
				// this will also populate m_trackingReferenceIdMappings and m_trackingReferenceIdMappings cache which we use here
				Map<Id, Article__c> articles = selectArticles(processableReferenceIds, processableArticleIds);

				// loop through all processable cases and apply the article field id value to the case where possible
				// m_trackingReferenceIdMappingsCache was populated in selectArticles call
				// this returns a List<Case> but it's not necessary to do anything with it since we are in a before trigger
				populateCaseArticleIds(casesToLinkArticlesTo, articles, m_trackingReferenceIdMappingsCache);

				// apply a reference id to cases that require it
				// m_trackingArticleIdMappingsCache was populated in selectArticles calls
				populateCaseReferences(casesToLinkReferencesTo, m_trackingArticleIdMappingsCache);

			}

			// marked the articles where the outbond message has been fired as subscribed
			// this is based on the workflow SSSW - Article Subscription
			if(!subscribedArticleIds.isEmpty()) {
				// ensure all articles linked to these case are marked as subscribed
				setArticlesSubscribed(subscribedArticleIds, uow);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, MyCustomerCaseArticlesModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * After Update trigger to process records that have a Reference ID without an Article field populated
	 * This would occur in the following scenarios:
	 * 1. Reference ID field changed and the article did not already exist in Salesforce
	 * 2. Article record was deleted in salesforce and case was later updated
	 * 3. Article id field on Case was removed or already empty
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			System.debug('MyCustomerCaseArticlesModule:onAfterUpdate');

			// note we pass a list of reference ids into the queueable so we don't need to run a soql until after the integration callout
			Set<String> referencesToEnqueue = new Set<String>();
			Set<Id> casesToEnqueue = new Set<Id>();

			for(Case c : (List<Case>)records) {
				if(!String.isEmpty(c.ReferenceID__c) && c.ArticleTest__c == null) {
					casesToEnqueue.add(c.Id);
					referencesToEnqueue.add(c.ReferenceID__c);
				}
			}

			if(!casesToEnqueue.isEmpty()) {
				ensureQueryJobEnqueued(casesToEnqueue, referencesToEnqueue);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, MyCustomerCaseArticlesModule.class.getName(), 'onAfterUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * This will ensure that a SAP-EM query job will be enqueued for all the cases in the list.
	 * This will be in the scenario where no article was found in SF for the ReferenceID listed on the case
	 * This method will ensure that the case is only enqueued once to limit scenarios where recursion may occur
	 *
	 * NOTE: referenceIds is also passed in so a soql does not need to be run prior to the integration callout to retrieve article details
	 *          It's the callers responsibility to pass in a synchronised list of caseids/referenceids
	 */
	private void ensureQueryJobEnqueued(Set<Id> caseIds, Set<String> referenceIds) {
		// if the queueable has already fired or if we are already in an async context then we prevent the execution of a subsequent queueable from being fired.
		if(preventRecursiveReschedule || System.isQueueable() || System.isFuture() || System.isBatch() || System.isScheduled()) {
			return;
		}

		caseIds.removeAll(m_enqueuedCaseIds);
		if(!caseIds.isEmpty()) {
			m_enqueuedCaseIds.addAll(caseIds);

			// NOTE: when routing is attempted is SSSW_Routing, we may hit a rule that requries an article to be linked to the case (Strategic routing)
			// In this scenario SSSW_Routing stores a list of cases where routing needs to be reattempted after an article is linked
			// We pass these into the queueable so we know which cases we need to attempt to reroute
			Integer i = 0;


			// given we are now in an 'after' trigger cycle, these records will now have an Id attached to them
			// we use this to populate the id on the map that contains the original variables at the time was case routing was triggered
			List<Case> casesForReroutingAttempt = SSSW_Routing.getAttemptableReroutableCases();

			List<Map<String, Object>> caseOriginalValues = SSSW_Routing.getCaseOriginalValuesForReroutingAttempt();
			Map<Id, Map<String, Object>> caseOriginalValuesForQueueable = new Map<Id, Map<String, Object>>();
			if(!casesForReroutingAttempt.isEmpty()) {
				for(Case reroutableCase : casesForReroutingAttempt) {
					// we only pass the records in that need to be processed within this iteration
					// this protects us from passing in the wrong records for rerouting
					if(caseIds.contains(reroutableCase.Id)) {

						// populate the case Id since we are now in an after trigger cycle
						caseOriginalValues[i].put('Id', reroutableCase.Id);
         				caseOriginalValuesForQueueable.put(reroutableCase.Id, caseOriginalValues[i]);
					}

					i++;
				}
			}

			// TODO: Refactor this into a better enqueueing model
			// enqueue the job here
			System.debug('Enqueuing SAP-EM query: ' + caseIds);
			System.debug('Enqueuing SAP-EM query: ' + caseOriginalValues);
			AsyncLinkArticlesToCasesQueueable job = new AsyncLinkArticlesToCasesQueueable(caseIds, referenceIds, caseOriginalValuesForQueueable.values());
			System.enqueueJob(job);

		}
	}

	/**
	 * Trigger an update to the Article__c to mark these articles as subscribed
	 * This method ensures that this update will always occur in an Async context
	 *
	 * TODO convert this into an Async Platform Event architecture
	 */
	public void setArticlesSubscribed(Set<Id> articleIds, ApplicationUnitOfWork uow) {
		// if the queueable has already fired or if we are already in an async context then we prevent the execution of a subsequent queueable from being fired.
		if(preventRecursiveReschedule || preventRecursiveArticleReschedule || System.isQueueable() || System.isFuture() || System.isBatch() || System.isScheduled()) {
			// do not enqueue a job to handle this since we are already in an async context
			for(Id articleId : articleIds) {
				Article__c article = new Article__c(Id = articleId, Subscribed__c = true);
				uow.registerDirty(article, false, 'MyCustomerCaseArticlesModule.setArticlesSubscribed');
			}
		} else {
			// Defer the updating of Article__c into Queueable context so the case transaction completes quicker
			articleIds.removeAll(m_enqueuedArticleSubscriptionIds);
			if(!articleIds.isEmpty()) {
				m_enqueuedArticleSubscriptionIds.addAll(articleIds);

				System.debug('Enqueuing Article Subscription job: ' + articleIds);
				AsyncSubscribeArticlesQueueable job = new AsyncSubscribeArticlesQueueable(articleIds);
				System.enqueueJob(job);
			}
		}
	}

	/**
	 * Apply any default values from the newly set article
	 */
	public void applyCaseArticleDefaults(List<Case> cases, Map<Id, Article__c> articles) {

		// build a list of clearview code mappings incase they are required when applying our defaults
		Set<String> articleProductKeys = new Set<String>();
		for(Article__c article : articles.values()) {
			String key = (String.isEmpty(article.ProductCategory__c) ? '' : article.ProductCategory__c.trim()) + (String.isEmpty(article.SubProduct__c) ? '' : article.SubProduct__c.trim()).toUpperCase();
			if(!String.isEmpty(key)) {
				articleProductKeys.add(key);
			}
		}

		for(Case c : cases) {
			if(c.ArticleTest__c != null && articles.get(c.ArticleTest__c) != null) {
				Article__c a = articles.get(c.ArticleTest__c);

				// ensure no validation rules will fire on this data
				c.Bypass_Data_enforcement__c = true;

				if (a.ActualWeight__c != null && c.ArticleWeight__c == null) {
					c.ArticleWeight__c = a.ActualWeight__c;
				}
				if (a.ArticleLodgementDate__c != null && c.DatePosted__c == null) {
					c.DatePosted__c = a.ArticleLodgementDate__c;
				}
				if (a.ArticleTransitAmountValue__c != null && c.Service_Value__c == null) {
					c.Service_Value__c = a.ArticleTransitAmountValue__c;
				}
				if (a.ArticleCount__c != null && String.isBlank(c.ArticleQuantity__c)) {
					c.ArticleQuantity__c = String.valueOf(a.ArticleCount__c);
				}
				if (a.ConsignmentParcelCount__c != null && String.isBlank(c.ConsignmentParcelCount__c)) {
					c.ConsignmentParcelCount__c = String.valueOf(a.ConsignmentParcelCount__c);
				}
				if (a.DeliveryInstructions__c != null && String.isBlank(c.DeliveryInstructions__c)) {
					c.DeliveryInstructions__c = a.DeliveryInstructions__c;
				}
				if (a.ServiceCode__c != null && c.ServiceCode__c == null) {
					c.ServiceCode__c = a.ServiceCode__c;
				}
				if (a.SenderName__c != null && String.isBlank(c.Primary_Name__c)) {
					c.Primary_Name__c = a.SenderName__c;
				}
				if (a.SenderCompany__c != null && String.isBlank(c.Primary_Company__c)) {
					c.Primary_Company__c = a.SenderCompany__c;
				}
				if (a.SenderEmail__c != null && String.isBlank(c.Primary_Email__c)) {
					c.Primary_Email__c = a.SenderEmail__c;
				}
				if (a.SenderAddress__c != null && String.isBlank(c.Address1__c)) {
					c.Address1__c = a.SenderAddress__c;
				}
				if (a.SenderPostcode__c != null && String.isBlank(c.Address1Postcode__c)) {
					c.Address1Postcode__c = a.SenderPostcode__c;
				}
				if (a.ReceiverName__c != null && String.isBlank(c.Secondary_Contact__c)) {
					c.Secondary_Contact__c = a.ReceiverName__c;
				}
				if (a.ReceiverCompany__c != null && String.isBlank(c.Secondary_Companry__c)) {
					c.Secondary_Companry__c = a.ReceiverCompany__c;
				}
				if (a.ReceiverEmail__c != null && String.isBlank(c.SecondaryEmail__c) && validateEmail(a.ReceiverEmail__c)) {
					c.SecondaryEmail__c = a.ReceiverEmail__c;
				}
				if (a.ReceiverAddress__c != null && String.isBlank(c.Address2__c)) {
					c.Address2__c = a.ReceiverAddress__c;
				}
				if (a.ReceiverPostcode__c != null && String.isBlank(c.Address2Postcode__c)) {
					c.Address2Postcode__c = a.ReceiverPostcode__c;
				}
				if (a.RecordType != null) {
					c.ArticleRecordType__c = a.RecordType.Name;
				}

				
			}
		}
	}

	/**
	 * Process the scenarios that require a link to an article id. This is only where an article already exists in the Article__c object. If an article isn't found, the case will be queued for async processing in the onAfter trigger handlers
	 */
	public List<Case> populateCaseArticleIds(List<Case> cases, Map<Id, Article__c> queriedArticles, Map<String, Id> existingReferenceIdMappings) {
		System.debug('populateCaseArticleIds:cases: ' + cases);
		System.debug('populateCaseArticleIds:queriedArticles: ' + queriedArticles);
		System.debug('populateCaseArticleIds:existingReferenceIdMappings: ' + existingReferenceIdMappings);

		List<Case> updateable = new List<Case>();
		for(Case c : cases) {
			if(existingReferenceIdMappings.get(nullToString(c.ReferenceID__c).toUpperCase()) != null) {

				//the article for the case reference id already exists in Article__c table so the article id on case can be synced to the existing record
				Article__c article = queriedArticles.get(existingReferenceIdMappings.get(nullToString(c.ReferenceID__c).toUpperCase()));

				if(article.RecordType != null && article.RecordType.DeveloperName == 'Consignment' && article.Articles__r != null && article.Articles__r.size() == 1) {
					// IMPORTANT!: Business rule of contact centre is that if a consignment reference id was provided and the consignment is a single article consignment, then we switch the reference id and set the article id to the article
					c.ReferenceID__c = nullToString(!String.isEmpty(article.Articles__r[0].TrackingID__c) ? article.Articles__r[0].TrackingID__c : article.Articles__r[0].ArticleID__c).toUpperCase();
					c.ArticleTest__c = article.Articles__r[0].Id;

					// this links a billing account to the case
					// one of the use cases for this field is to enable access to this case in BSP based on the billing account rules defined in BAM
					// tags: BSP, BAM, Merchant Portal, Billing Account
					if(c.Related_Billing_Account__c == null && article.Articles__r[0].Billing_Account__c != null) {
						c.Related_Billing_Account__c = article.Articles__r[0].Billing_Account__c;
					}

					updateable.add(c);
				} else {
					c.ArticleTest__c = article.Id;

					// this links a billing account to the case
					// one of the use cases for this field is to enable access to this case in BSP based on the billing account rules defined in BAM
					if(c.Related_Billing_Account__c == null && article.Billing_Account__c != null) {
						c.Related_Billing_Account__c = article.Billing_Account__c;
					}

					updateable.add(c);
				}
			} else if(c.ArticleTest__c != null) {
				// remove the reference to the passed in article since it is incorrect (doesn't line up with the ReferenceID passed in)
				c.ArticleTest__c = null;

				updateable.add(c);
			}
		}

		return updateable;
	}
	/**
	 * Where an article id was provided but a reference id was not, loop through and set the reference id
	 * given the article field is populated it means it will always exist in our selector so we can reliably retrieve the corresponding reference id to attach to the case
	 */
	private void populateCaseReferences(List<Case> cases, Map<Id, String> existingArticleIdMappings) {
		System.debug('populateCaseArticleIds:cases: ' + cases);
		System.debug('populateCaseArticleIds:existingArticleIdMappings: ' + existingArticleIdMappings);

		for(Case c : cases) {
			// cache was populated in selectAndCacheArticles method call above
			c.ReferenceID__c = existingArticleIdMappings.get(c.ArticleTest__c);
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
		System.debug('queried articles: ' + articles);
		System.debug('processableReferenceIds: ' + processableReferenceIds);

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

	//Simply validates if the email is in the x@x.x format. It doesn't validate if 'x' contains only allowable characters.
	private Boolean validateEmail(String email) {
		if (String.isNotBlank(email)) {
			return Pattern.matches('.+@.+\\..+', email);
		}

		return false;
	}

	private without sharing class AsyncLinkArticlesToCasesQueueable implements Queueable, Database.AllowsCallouts {
		Set<Id> caseIds;
		Set<String> referenceIds;
		List<Map<String, Object>> casesForReroutingAttempt;

		public AsyncLinkArticlesToCasesQueueable(Set<Id> caseIds, Set<String> referenceIds, List<Map<String, Object>> casesForReroutingAttempt) {
			this.caseIds = caseIds;
			this.referenceIds = referenceIds;
			this.casesForReroutingAttempt = casesForReroutingAttempt;
		}

		public void execute(QueueableContext context) {
			try {
				System.debug('Executing AsyncLinkArticlesToCasesQueueable Queueable');
				System.debug('>> Processing IDs: ' + caseIds);
				System.debug('>> Processing casesForReroutingAttempt: ' + casesForReroutingAttempt);

				// as a failsafe, set this to ensure no more queueable instances will be created
				// this is for example if an article isn't found or Tibco errors or some other type of error.
				preventRecursiveReschedule = true;

				if(!referenceIds.isEmpty()) {
					// trigger a search into SAP-EM
					// for any found articles, the article service will populate the Article__c table
					// TODO: Revisit the TIBCO Search service....
					TIBCOArticleService.getInstance().search(new List<String>(referenceIds), true, false, false, false, true);

					// NOTE: We run this soql after the integration callout so we have the latest data on the record when processing it
					//      (Integration callout could take 5 or 10 seconds or sometimes more)
				Map<Id, Case> cases = SSSWCasesSelector.newInstance(new Set<SObjectField>{
					Case.Id, Case.ReferenceID__c, Case.Origin, Case.ArticleTest__c, Case.Related_Billing_Account__c,
					Case.ArticleWeight__c, Case.DatePosted__c, Case.Service_Value__c, Case.ArticleQuantity__c,
					Case.ConsignmentParcelCount__c, Case.DeliveryInstructions__c, Case.ServiceCode__c,
					Case.Primary_Name__c, Case.Primary_Company__c, Case.Primary_Email__c, Case.Address1__c, Case.Address1Postcode__c,
					Case.Secondary_Contact__c, Case.Secondary_Companry__c, Case.Subject,
					Case.SecondaryEmail__c, Case.Address2__c, Case.Address2Postcode__c, Case.ArticleRecordType__c, Case.ProductCategory__c,
					Case.ProductSubcategory__c, Case.EnquirySubType__c, Case.ParentId, Case.LastRoutingRuleIsStrategic__c
				}).selectById(caseIds);

					// TODO: This should be routed via the Domain class rather than invoked directly
					MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();

					// grab a list of existing articles to see if we can match them up to the cases that have been passed in
					// this will also populate m_trackingReferenceIdMappings cache which we use here
					Map<Id, Article__c> articles = module.selectArticles(referenceIds);

					// loop through all processable cases and apply the article field id value to the case where possible
					// m_trackingReferenceIdMappingsCache was populated in selectArticles call
					Map<Id, Case> updateable = new Map<Id, Case>(module.populateCaseArticleIds(cases.values(), articles, m_trackingReferenceIdMappingsCache));
					system.debug('updateable before rerouting: '+updateable);
					// attempt to reroute the cases with Article linked
					// and original routing field values
					updateable = rerouteCases(updateable);
                    system.debug(updateable.values());

					// apply and default values that are currently not already populated on the case
					module.applyCaseArticleDefaults(updateable.values(), articles);
					System.debug('AsyncLinkArticlesToCases >> ' + updateable);

					if(!updateable.isEmpty()) {
						// as an added saftey measure, ensure that validation rules are bypassed and this update is allowed to occur
						for (Case c : updateable.values()) {
							c.Bypass_Data_enforcement__c = true;
						}
						System.debug('May be Row lock issue???');
						List<Database.SaveResult> srList = ApplicationDatabase.getInstance().dmlUpdate(updateable.values(), false);

						for (Database.SaveResult sr : srList) {
							if (sr.isSuccess()) {
								System.debug('Successfully updated: ' + sr.getId());
							} else {
								for (Database.Error err : sr.getErrors()) {
									System.debug('The following error has occurred.');
									System.debug(err.getStatusCode() + ': ' + err.getMessage());
									System.debug('Case fields that affected this error: ' + err.getFields());
								}
							}
						}
					}
				}
			} catch(Exception ex) {
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, AsyncLinkArticlesToCasesQueueable.class.getName(), 'execute', '', LoggingLevel.ERROR);
			}
		}

		/**
		 * Reattempt to route cases that need it now that an article has been linked to the case
		 * @param - Map of cases with article linked
		 * @return - Map of cases (with Owner Id updated based on Original routing field values)
		 */
		private Map<Id, Case> rerouteCases(Map<Id, Case> casesWithArticlePopulated) {
			// NOTE The try/catch block as a fail safe, catch this error here will ensure the routing errors do not cause the whole transaction to fail
			try {
				if(!casesForReroutingAttempt.isEmpty()) {
					// we need to first convert the map of case values into a list of case object
					// NOTE: its stored as a map since some of the values we needed were formula fields not directly writable
					Map<Id, Case> deserialisedCases = new Map<Id, Case>((List<Case>) JSON.deserialize(JSON.serialize(casesForReroutingAttempt), List<Case>.class));
					System.debug('Deserialised cases for rerouting attempt: ' + deserialisedCases);

					List<Case> reroutableCases = new List<Case>();
					for (Id caseId : casesWithArticlePopulated.keySet()) {
						// filtering out child cases from reroutable cases
						if (deserialisedCases.containsKey(caseId) && casesWithArticlePopulated.get(caseId).ParentId == null) {
							// TODO: only exclude child if parent is a SSSW case
							Case deserialisedCase = deserialisedCases.get(caseId);

							//make sure the case owner is null
							deserialisedCase.OwnerId = null;

							// TODO: dodgy override to ensure the correct routing logic is triggered
							deserialisedCase.AllocateToQueue__c = true;

							// make sure that the newly linked case details are passed into the routing code to check for a strategic account mapping based on ArticleTest__c
							deserialisedCase.ReferenceID__c = casesWithArticlePopulated.get(caseId).ReferenceID__c;
							deserialisedCase.ArticleTest__c = casesWithArticlePopulated.get(caseId).ArticleTest__c;
							deserialisedCase.LastRoutingRuleIsStrategic__c = casesWithArticlePopulated.get(caseId).LastRoutingRuleIsStrategic__c;
							reroutableCases.add(deserialisedCase);
						}
					}

					// attempt to reroute the newly article linked cases to see if the article belongs to a strategic customer or extra cover applies or not
					System.debug('Cases for rerouting attempt before assignment: ' + reroutableCases);
					SSSW_Routing.assignCasesAndDescription(reroutableCases, null, false, true, true);
					System.debug('Cases for rerouting attempt after assignment: ' + reroutableCases);

					// the routing rules have been rerun and the newly set owner id will be added to the case
					// NOTE: we only want the owner id and not any othe fields as they might be out of date or irrelevant
					for (Case reroutedCase : reroutableCases) {
						if (reroutedCase.OwnerId != null) {
							casesWithArticlePopulated.get(reroutedCase.Id).OwnerId = reroutedCase.OwnerId;
							casesWithArticlePopulated.get(reroutedCase.Id).HasExtraCover__c = reroutedCase.HasExtraCover__c;

							// setting flag on case since selected routing rule is a strategic one
                            // its required to avoid triggering the specific workflow rules that might reset the case owner
							casesWithArticlePopulated.get(reroutedCase.Id).LastRoutingRuleIsStrategic__c = reroutedCase.LastRoutingRuleIsStrategic__c;
			}
		}
	}
			} catch(Exception ex) {
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, AsyncLinkArticlesToCasesQueueable.class.getName(), 'rerouteCases', '', LoggingLevel.ERROR);
			}

			return casesWithArticlePopulated;
		}
	}

	/**
	 * Queueable to mark the Article__c records as subscribed
	 * This will occur when a new article is assigned to a case and article is not currently marked as subscribed
	 * We process this in an async operation to increase the performance of the originating Case transaction
	 */
	private without sharing class AsyncSubscribeArticlesQueueable implements Queueable, Database.AllowsCallouts {
		Set<Id> articleIds;

		public AsyncSubscribeArticlesQueueable(Set<Id> articleIds) {
			this.articleIds = articleIds;
		}

		public void execute(QueueableContext context) {
			try {
				System.debug('Executing AsyncSubscribeArticlesQueueable Queueable');
				System.debug('>> Processing IDs: ' + articleIds);

				List<Article__c> updateableArticles = new List<Article__c>();

				// as a failsafe, set this to ensure no more queueable instances will be created
				preventRecursiveArticleReschedule = true;

				for(Id articleId : articleIds) {
					Article__c updateable = new Article__c(Id = articleId, Subscribed__c = true);
					updateableArticles.add(updateable);
				}

				List<Database.SaveResult> srList = ApplicationDatabase.getInstance().dmlUpdate(updateableArticles, false);

				for (Database.SaveResult sr : srList) {
					if (sr.isSuccess()) {
						System.debug('Successfully updated: ' + sr.getId());
					} else {
						for (Database.Error err : sr.getErrors()) {
							System.debug('The following error has occurred.');
							System.debug(err.getStatusCode() + ': ' + err.getMessage());
							System.debug('Fields that affected this error: ' + err.getFields());
						}
					}
				}
			} catch(Exception ex) {
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, AsyncSubscribeArticlesQueueable.class.getName(), 'execute', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)MyCustomerCaseArticlesModule.newInstance();
		}
	}
}