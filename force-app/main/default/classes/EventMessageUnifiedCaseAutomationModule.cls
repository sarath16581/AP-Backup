/**
 * @description Module to handle automation specific to Unified cases on receiving event messages (scan event automation).
 * @author Ranjeewa Silva
 * @date 2024-08-31
 * @test EventMessageUnifiedCaseAutoModule_Test
 * @changelog
 */
public inherited sharing class EventMessageUnifiedCaseAutomationModule extends ApplicationModule {

	// unified case record enquiry sub types eligible for automation on receiving event messages.
	@TestVisible private static final Set<String> AUTOMATION_ENABLED_ENQUIRY_SUB_TYPES = new Set<String>{'Late Item'};

	// case reassignment code to use when multiple reassignment eligible event messages are received and there are
	// more than one impacted articles linked to the case.
	@TestVisible private static final String CASE_REASSIGNMENT_REASON_DIFFERENT_EVENT_TRIGGERS = 'Multiple articles with different event triggers';
	// case reassignment code to use when multiple reassignment eligible event messages are received and there is only
	// one impacted articles linked to the case.
	@TestVisible private static final String CASE_REASSIGNMENT_REASON_SINGLE_ARTICLE_DIFFERENT_EVENT_TRIGGERS = 'Review Scans';

	// unified case record types eligible for automation on receiving event messages
	private static final Set<Id> AUTOMATION_ENABLED_UNIFIED_CASE_RECORDTYPES {
		get {
			if (AUTOMATION_ENABLED_UNIFIED_CASE_RECORDTYPES == null) {
				AUTOMATION_ENABLED_UNIFIED_CASE_RECORDTYPES = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{
						SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME
				}).keySet();
			}
			return AUTOMATION_ENABLED_UNIFIED_CASE_RECORDTYPES;
		}
		set;
	}

	// event message type definitions that are eligible for case automation
	@TestVisible private static Map<String, EventMessageTypeMapping__mdt> automationEligibleEventTypeDefinitions {
		get {
			if (automationEligibleEventTypeDefinitions == null) {
				Map<String, EventMessageTypeMapping__mdt> results = new Map<String, EventMessageTypeMapping__mdt>();
				for (EventMessageTypeMapping__mdt eventMessageTypeMapping: EventMessageTypeMapping__mdt.getAll().values()) {
					if (((eventMessageTypeMapping.IsCaseClosureEligible__c?.startsWith('Yes')) ?? false)
							|| ((eventMessageTypeMapping.IsCaseReassignmentEligible__c?.startsWith('Yes') ?? false))) {
						results.put(eventMessageTypeMapping.Label, eventMessageTypeMapping);
					}
				}
				automationEligibleEventTypeDefinitions = results;
			}
			return automationEligibleEventTypeDefinitions;
		}
		set;
	}

	public EventMessageUnifiedCaseAutomationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			// parent article ids of newly inserted event messages
			Set<Id> parentArticleIds = new Set<Id>();
			// newly inserted event messages eligible for case automation based on the configuration in custom metadata
			List<EventMessage__c> automationEligibleEventMessages = new List<EventMessage__c>();
			for (EventMessage__c eventMessage : (List<EventMessage__c>) records) {
				if (automationEligibleEventTypeDefinitions.containsKey(eventMessage.EventType__c)) {
					// event message is eligible for case automation.
					parentArticleIds.add(eventMessage.Article__c);
					automationEligibleEventMessages.add(eventMessage);
				}
			}

			if (!automationEligibleEventMessages.isEmpty()) {
				// automation eligible event messages have been inserted. if event messages are for impacted articles
				// on automation eligible open unified cases (see AUTOMATION_ENABLED_ENQUIRY_SUB_TYPES), select impacted article details.

				// mapping of parent article id to impacted articles linked to eligible unified cases. key - article id, value - list of impacted articles
				Map<Id, List<ImpactedArticle__c>> impactedArticlesMapping = selectImpactedArticlesForAutomationEligibleUnifiedCases(parentArticleIds);

				Map<Id, UnifiedCaseAutomationAsyncWorkerParam> unifiedCaseAutomationAsyncWorkerParams = new Map<Id, UnifiedCaseAutomationAsyncWorkerParam>();

				for (EventMessage__c eventMessage : automationEligibleEventMessages) {
					if (impactedArticlesMapping.containsKey(eventMessage.Article__c)) {
						// event message is linked to an impacted article having an open case
						for (ImpactedArticle__c impactedArticle : impactedArticlesMapping.get(eventMessage.Article__c)) {
							// check if the case is for 'StarTrack' products.
							Boolean isStarTrackCase = CaseUnifiedAutomationService.isStarTrackCase(impactedArticle.Case__r);
							// check if the event message is eligible for case automation considering business unit.
							if (isCaseAutomationEligibleEventMessage(EventMessageTypeMapping__mdt.IsCaseClosureEligible__c, eventMessage, isStarTrackCase)) {
								// event message is eligible for closure automation for case
								UnifiedCaseAutomationAsyncWorkerParam param = getUnifiedCaseAutomationAsyncWorkerParamInstance(impactedArticle.Case__c, unifiedCaseAutomationAsyncWorkerParams);
								param.closureEventTypes.add(eventMessage.EventType__c);
							} else if (isCaseAutomationEligibleEventMessage(EventMessageTypeMapping__mdt.IsCaseReassignmentEligible__c, eventMessage, isStarTrackCase)) {
								// event message is eligible for reassignment automation for case
								UnifiedCaseAutomationAsyncWorkerParam param = getUnifiedCaseAutomationAsyncWorkerParamInstance(impactedArticle.Case__c, unifiedCaseAutomationAsyncWorkerParams);
								param.reassignmentEventTypes.add(eventMessage.EventType__c);
							}
						}
					}
				}

				if (!unifiedCaseAutomationAsyncWorkerParams.isEmpty()) {
					// we have identified eligible cases for closure/reassignment automation based on newly inserted event messages
					// register async work to process these cases.
					uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncEventMessageUnifiedCaseAutomationWorker.class, unifiedCaseAutomationAsyncWorkerParams));
				}
			}

		} catch (Exception e) {
			// log error in ExceptionLog__c object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), SSSWConstants.UNIFIED_APP, EventMessageUnifiedCaseAutomationModule.class.getName(), 'onAfterInsert', 'EventMessage__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Select impacted articles linked to automation eligible unified cases. Unified cases are eligible for automation if
	 * below conditions are true:
	 * - Case record is open
	 * - Record Type is UnifiedInvestigation
	 * - Enquiry sub type is 'Late Item' (See AUTOMATION_ENABLED_ENQUIRY_SUB_TYPES)
	 *
	 * @param articleIds article ids
	 *
	 * @return impacted articles mapping for supplied article ids. key - article id, value - list of impacted articles
	 */
	private static Map<Id, List<ImpactedArticle__c>> selectImpactedArticlesForAutomationEligibleUnifiedCases(Set<Id> articleIds) {
		List<ImpactedArticle__c> openCaseImpactedArticles = ((ImpactedArticlesSelector)ImpactedArticlesSelector.newInstance().setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.IsClosed, Case.ProductSubCategory__c, Case.RecordTypeId},
				ImpactedArticle__c.SObjectType => new Set<SObjectField>{ImpactedArticle__c.Article__c, ImpactedArticle__c.Case__c, ImpactedArticle__c.ArticleId__c}
		})).search(new Map<String, Object>{
				'articleIds' => articleIds,
				'caseRecordTypeIds' => AUTOMATION_ENABLED_UNIFIED_CASE_RECORDTYPES,
				'caseEnquirySubTypes' => AUTOMATION_ENABLED_ENQUIRY_SUB_TYPES,
				'isCaseOpen' => true
		}, new Set<Object>{ImpactedArticlesSelector.Options.WITH_CASE}, true);

		Map<Id, List<ImpactedArticle__c>> impactedArticlesMapping = new Map<Id, List<ImpactedArticle__c>>();
		for (ImpactedArticle__c impactedArticle: openCaseImpactedArticles) {
			List<ImpactedArticle__c> impactedArticlesForArticleId = impactedArticlesMapping.get(impactedArticle.Article__c) ?? new List<ImpactedArticle__c>();
			if (impactedArticlesForArticleId.isEmpty()) {
				impactedArticlesMapping.put(impactedArticle.Article__c, impactedArticlesForArticleId);
			}
			impactedArticlesForArticleId.add(impactedArticle);
		}
		return impactedArticlesMapping;
	}

	/**
	 * Check if the event message is eligible for case automation based on the configuration in custom metadata.
	 *
	 * @param eventTypeDefinitionField custom metadata type field with the automation eligibility configuration
	 * @param eventMessage event message record to check
	 * @param isStarTrackCase if the event message's parent article is linked to a StarTrack Case.
	 *
	 * @return true if eligible, false otherwise.
	 */
	private Boolean isCaseAutomationEligibleEventMessage(SObjectField eventTypeDefinitionField, EventMessage__c eventMessage, Boolean isStarTrackCase) {
		String automationEligibility = (String)automationEligibleEventTypeDefinitions.get(eventMessage.EventType__c)?.get(eventTypeDefinitionField) ?? '';
		if (automationEligibility.equalsIgnoreCase('Yes')
				|| (automationEligibility.equalsIgnoreCase('Yes - ST Only') && isStarTrackCase)
				|| (automationEligibility.equalsIgnoreCase('Yes - AP Only') && !isStarTrackCase)) {

			return true;
		}
		return false;
	}

	private UnifiedCaseAutomationAsyncWorkerParam getUnifiedCaseAutomationAsyncWorkerParamInstance(Id caseId, Map<Id, UnifiedCaseAutomationAsyncWorkerParam> unifiedCaseAutomationAsyncWorkerParams) {
		UnifiedCaseAutomationAsyncWorkerParam param = unifiedCaseAutomationAsyncWorkerParams.get(caseId);
		if (param == null) {
			param = new UnifiedCaseAutomationAsyncWorkerParam();
			param.caseId = caseId;
			unifiedCaseAutomationAsyncWorkerParams.put(caseId, param);
		}
		return param;
	}

	/**
	 * Async worker for processing cases identified for automation based on newly inserted event messages.
	 */
	public inherited sharing class AsyncEventMessageUnifiedCaseAutomationWorker extends ApplicationUnitOfWork.AsyncWorker {

		private Map<Id, UnifiedCaseAutomationAsyncWorkerParam> params = new Map<Id, UnifiedCaseAutomationAsyncWorkerParam>();

		public override void execute(ApplicationUnitOfWork uow) {
			// select existing cases with child contact requests and impacted articles
			Map<Id, Case> cases = ((CasesSelector) CasesSelector.newInstance().setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
					Case.SObjectType => new Set<SObjectField>{
							Case.Id, Case.OwnerId, Case.IsClosed, Case.PreferredAgentExpiry__c, Case.BusinessHoursId, Case.Status,
							Case.Exclude_Subscription_Automation__c, Case.ContactEmail
					},
					ContactRequest.SObjectType => new Set<SObjectField>{ContactRequest.Id},
					ImpactedArticle__c.SObjectType => new Set<SObjectField>{ImpactedArticle__c.Id, ImpactedArticle__c.Article__c, ImpactedArticle__c.Case__c}
			})).selectById(params.keySet(), new Set<Object>{
					CasesSelector.Options.WITH_CONTACT_REQUESTS, CasesSelector.Options.WITH_IMPACTED_ARTICLES
			});

			// for cases identified for closure, we need to check if closure event message is received for each impacted
			// article linked to the case. this should consider all existing event messages too.
			// select articles with child event messages for cases identified for closure.
			Map<Id, Article__c> articles = selectArticlesWithEventMessagesOnCasesThatMayBeClosed(cases);

			// list of case closure parameters to be passed into service class
			List<CaseUnifiedAutomationService.RecordWrapper> caseClosureServiceParams = new List<CaseUnifiedAutomationService.RecordWrapper>();
			// list of case reassign parameters to be passed into service class
			List<CaseUnifiedAutomationService.RecordWrapper> caseReassignServiceParams = new List<CaseUnifiedAutomationService.RecordWrapper>();
			for (UnifiedCaseAutomationAsyncWorkerParam param: params.values()) {
				CaseUnifiedAutomationService.RecordWrapper caseAutomationServiceParam = new CaseUnifiedAutomationService.RecordWrapper();
				caseAutomationServiceParam.caseRecord = cases.get(param.caseId);
				caseAutomationServiceParam.srcObjectType = EventMessage__c.SObjectType;
				if (!param.closureEventTypes.isEmpty() && !cases.get(param.caseId).IsClosed) {
					// open case has received closure event messages. check if we have closure events common across all impacted articles.
					Set<String> commonClosureEventTypes = findCommonEventTypesAcrossImpactedArticles(param.closureEventTypes, cases.get(param.caseId), articles);
					if (commonClosureEventTypes.size() == 1) {
						// we have found one common closure code across impacted articles. case need to be passed into service for closure.
						EventMessageTypeMapping__mdt eventTypeDefinition = automationEligibleEventTypeDefinitions.get(commonClosureEventTypes.iterator().next());
						caseAutomationServiceParam.newRootCause = eventTypeDefinition.CaseAutomationRootCause__c;
						caseAutomationServiceParam.newResolutionCode = eventTypeDefinition.CaseAutomationResolutionCode__c;
						caseClosureServiceParams.add(caseAutomationServiceParam);
					} else {
						// either we haven't found common closure codes across impacted articles or there are more than one common closure codes.
						// case need to be passed into service for reassignment.
						caseAutomationServiceParam.newReassignmentReason = (cases.get(param.caseId).ImpactedArticles__r.size() == 1 ?
								CASE_REASSIGNMENT_REASON_SINGLE_ARTICLE_DIFFERENT_EVENT_TRIGGERS : CASE_REASSIGNMENT_REASON_DIFFERENT_EVENT_TRIGGERS);
						caseReassignServiceParams.add(caseAutomationServiceParam);
					}
				} else if (!param.reassignmentEventTypes.isEmpty() && !cases.get(param.caseId).IsClosed) {
					// open case has received reassignment event messages.
					if (param.reassignmentEventTypes.size() == 1) {
						EventMessageTypeMapping__mdt eventTypeDefinition = automationEligibleEventTypeDefinitions.get(param.reassignmentEventTypes.iterator().next());
						caseAutomationServiceParam.newReassignmentReason = eventTypeDefinition?.CaseAutomationReassignmentReason__c;
					} else {
						caseAutomationServiceParam.newReassignmentReason = (cases.get(param.caseId).ImpactedArticles__r.size() == 1 ?
								CASE_REASSIGNMENT_REASON_SINGLE_ARTICLE_DIFFERENT_EVENT_TRIGGERS : CASE_REASSIGNMENT_REASON_DIFFERENT_EVENT_TRIGGERS);
					}
					caseReassignServiceParams.add(caseAutomationServiceParam);
				}
			}

			if (!caseReassignServiceParams.isEmpty()) {
				CaseUnifiedAutomationService.getInstance().processForCaseReassignment(caseReassignServiceParams, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, uow);
			}

			if (!caseClosureServiceParams.isEmpty()) {
				CaseUnifiedAutomationService.getInstance().processForCaseClosure(caseClosureServiceParams, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, uow);
			}
		}

		private Map<Id, Article__c> selectArticlesWithEventMessagesOnCasesThatMayBeClosed(Map<Id, Case> cases) {
			// from impacted articles for cases marked for closure, select articles and event messages (check if we can only retrieve closure events only)
			Set<Id> parentArticleIds = new Set<Id>();
			for (Case caseRecord: cases.values()) {
				if (!caseRecord.IsClosed && !params.get(caseRecord.Id).closureEventTypes.isEmpty()) {
					for (ImpactedArticle__c impactedArticle: caseRecord.ImpactedArticles__r) {
						parentArticleIds.add(impactedArticle.Article__c);
					}
				}
			}

			if (!parentArticleIds.isEmpty()) {

				return ((ArticlesSelector)ArticlesSelector.newInstance().setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
						Article__c.SObjectType => new Set<SObjectField>{Article__c.Id, Article__c.ArticleID__c},
						EventMessage__c.SObjectType => new Set<SObjectField>{EventMessage__c.EventType__c, EventMessage__c.ActualDateTime__c}
				})).selectById(parentArticleIds, new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_DESC_ORDER});

			}

			return new Map<Id, Article__c>();
		}

		private Set<String> findCommonEventTypesAcrossImpactedArticles(Set<String> eventTypes, Case caseRecord, Map<Id, Article__c> articles) {

			Set<String> commonClosureEventTypes = new Set<String>(eventTypes);
			for (ImpactedArticle__c impactedArticle: caseRecord.ImpactedArticles__r) {
				commonClosureEventTypes.retainAll(getAutomationEligibleArticleEventTypes(articles.get(impactedArticle.Article__c)));
				if (commonClosureEventTypes.isEmpty()) {
					return commonClosureEventTypes;
				}
			}
			return commonClosureEventTypes;
		}

		private Set<String> getAutomationEligibleArticleEventTypes(Article__c article) {
			Set<String> results = new Set<String>();
			for (EventMessage__c eventMessage: article.Event_Messages__r) {
				if (automationEligibleEventTypeDefinitions.containsKey(eventMessage.EventType__c)) {
					results.add(eventMessage.EventType__c);
				}
			}
			return results;
		}

		public override Type getClassType() {
			return AsyncEventMessageUnifiedCaseAutomationWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				try {
					this.params = (Map<Id, UnifiedCaseAutomationAsyncWorkerParam>) JSON.deserialize(serialisedParams, Map<Id, UnifiedCaseAutomationAsyncWorkerParam>.class);
				} catch (Exception e) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Unified Customer Service', AsyncEventMessageUnifiedCaseAutomationWorker.class.getName(),
							'deserialiseParams', String.valueOf(EventMessage__c.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		}
	}

	public class UnifiedCaseAutomationAsyncWorkerParam {
		public Id caseId;
		public Set<String> closureEventTypes = new Set<String>();
		public Set<String> reassignmentEventTypes = new Set<String>();
	}
}