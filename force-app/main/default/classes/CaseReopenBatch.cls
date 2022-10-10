/**
* @author Alex Volkov
* @date 02/12/2021
* @tag Batch
* @tag Case SObject
* @domain SSSW
* @description Batch job responsible for reopening cases waiting on hold
* @changelog
* 02/12/2021 - Alex Volkov - Initial creation
* 28/09/2022 - Mahesh Parvathaneni - DDS-12732 - Included the exception checker logic
*/

public with sharing class CaseReopenBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

	private static final Integer BATCH_SIZE = 25;

	/**
	 * @description Overridable query
	 * @return Database.QueryLocator
	 */
	public virtual Database.QueryLocator getEligibleCases(){
		Date vReopenUpToDate = System.today().addDays(1);
		return (Database.QueryLocator)SSSWCasesSelector.newInstance().selectCasesEligibleForReopenByOwnerAndDate(new Set<String>{GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSWConstants.QUEUE_NAME_REOPEN_Q}).values()[0].Id}, Datetime.newInstance(vReopenUpToDate.year(), vReopenUpToDate.month(), vReopenUpToDate.day()), new Set<Object>{SSSWCasesSelector.Options.RETURN_QUERY_LOCATOR});
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return getEligibleCases();
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		try {
			Map<Id, List<Case>> articleToCasesMap = new Map<Id, List<Case>>();
			List<Case> caseListWithArticles = new List<Case>();
			List<Case> caseListWithoutArticles = new List<Case>();

			// loop through cases associated with/without articles
			for (Case c : (List<Case>) scope) {
				if (c.ArticleTest__c != null) {
					List<Case> clist = articleToCasesMap.get(c.ArticleTest__c);
					if (clist == null) {
						clist = new List<Case>();
					}
					clist.add(c);
					articleToCasesMap.put(c.ArticleTest__c, clist);
					caseListWithArticles.add(c);
				} else {
					caseListWithoutArticles.add(c);
				}
			}

			//process the exception checker logic for cases with articles
			if (articleToCasesMap.size() > 0) {
				handleExceptionCheckerOnCases(articleToCasesMap);
			}

			//process the consignments to allocate to queue
			if (caseListWithoutArticles.size() > 0) {
				ExceptionCheckerService.getInstance().assignCasesToAgentQueue(caseListWithoutArticles);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Case Reopen', CaseReopenBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	//schedular for processing cases waiting on hold
	public void execute(SchedulableContext sc) {
		Database.executeBatch(this, BATCH_SIZE);
	}

	/**
	 * handle the exception checker logic
	 */
	private void handleExceptionCheckerOnCases(Map<Id, List<Case>> articleToCasesMap) {
		Map<String, Id> trackingIdToArticleMap = new Map<String, Id>();
		Map<String, List<ExceptionCheckerService.EventMessageDTO>> trackingIdToEventMessageWrapperMap = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();
		Map<Id,EventMessage__c> eventMessageMap = EventMessagesSelector.newInstance().selectByArticleId(articleToCasesMap.keySet());

			for (EventMessage__c em : eventMessageMap.values()) {
				//populate trackingIdToEventMessageWrapperMap
				if (!trackingIdToEventMessageWrapperMap.containsKey(em.TrackingID__c)) {
					trackingIdToEventMessageWrapperMap.put(em.TrackingID__c, new List<ExceptionCheckerService.EventMessageDTO>());
				}
				if (String.isNotBlank(em.EventType__c)) {
					ExceptionCheckerService.EventMessageDTO emDto = new ExceptionCheckerService.EventMessageDTO();
					emDto.eventType = em.EventType__c;
					emDto.actualDateTime = em.ActualDateTime__c;
					trackingIdToEventMessageWrapperMap.get(em.TrackingID__c).add(emDto);
				}
				//populate trackingIdToArticleMap
				if (!trackingIdToArticleMap.containsKey(em.TrackingID__c)) {
					trackingIdToArticleMap.put(em.TrackingID__c, em.Article__c);
				}
			}

			if (trackingIdToEventMessageWrapperMap.size() > 0) {
				//call the exception checker service
				runExceptionChecker(trackingIdToEventMessageWrapperMap, articleToCasesMap, trackingIdToArticleMap);	
			}
	}

	/**
	 * Run the exception checker logic on cases to assign to agent queue and close the cases
	 */
	private void runExceptionChecker(Map<String, List<ExceptionCheckerService.EventMessageDTO>> trackingIdToEventMessageWrapperMap, Map<Id, List<Case>> articleToCasesMap, Map<String, Id> trackingIdToArticleMap) {
		List<Case> exceptionCases = new List<Case>();
		List<Case> noExceptionCases = new List<Case>();
		List<Case> agentQueueCases = new List<Case>();
		List<Case> casesToClose = new List<Case>();

		Map<String, ExceptionCheckerService.ExceptionResultDTO> exceptionResult = ExceptionCheckerService.getInstance().isExceptionApplies(trackingIdToEventMessageWrapperMap);
		//loop through tracking ids if exceptions
		for (String trackingId : trackingIdToEventMessageWrapperMap.keySet()) {
			if (exceptionResult.containsKey(trackingId) && exceptionResult.get(trackingId).isException) {
				//get the cases
				exceptionCases.addAll(articleToCasesMap.get(trackingIdToArticleMap.get(trackingId)));
			} else {
				noExceptionCases.addAll(articleToCasesMap.get(trackingIdToArticleMap.get(trackingId)));
			}
		}
		agentQueueCases.addAll(exceptionCases);

		for (Case neCase : noExceptionCases) {
			if (neCase.CaseOriginator__c == ChasConstants.SENDER) {
				agentQueueCases.add(neCase);
			} else {
				casesToClose.add(neCase);
			}
		}
		//assign the cases to queue
		ExceptionCheckerService.getInstance().assignCasesToAgentQueue(exceptionCases);
		//close the cases for lost in transit
		ExceptionCheckerService.getInstance().closeCases(casesToClose);
	}

}