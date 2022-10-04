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
			runExceptionCheckerOnCases(articleToCasesMap);
		}

		//process the consignments to allocate to queue
		if (caseListWithoutArticles.size() > 0) {
			assignCasesToAgentQueue(caseListWithoutArticles);
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	//schedular for processing cases waiting on hold
	public void execute(SchedulableContext sc) {
		Database.executeBatch(this, BATCH_SIZE);
	}

	private void runExceptionCheckerOnCases(Map<Id, List<Case>> articleToCasesMap) {
		Map<String, Id> trackingIdToArticleMap = new Map<String, Id>();
		Map<String, List<EventMessageWrapper>> trackingIdToEventMessageWrapperMap = new Map<String, List<EventMessageWrapper>>();
		Map<Id,EventMessage__c> eventMessageMap = EventMessagesSelector.newInstance().selectByArticleId(articleToCasesMap.keySet());
		List<Case> exceptionCases = new List<Case>();
		List<Case> noExceptionCases = new List<Case>();
		List<Case> agentQueueCases = new List<Case>();
		List<Case> casesToClose = new List<Case>();

			for (EventMessage__c em : eventMessageMap.values()) {
				//populate trackingIdToEventMessageWrapperMap
				if (!trackingIdToEventMessageWrapperMap.containsKey(em.TrackingID__c)) {
					trackingIdToEventMessageWrapperMap.put(em.TrackingID__c, new List<EventMessageWrapper>());
				}
				if (String.isNotBlank(em.EventType__c)) {
					EventMessageWrapper wrapper = new EventMessageWrapper();
					wrapper.eventType = em.EventType__c;
					wrapper.eventDatetime = em.ActualDateTime__c;
					trackingIdToEventMessageWrapperMap.get(em.TrackingID__c).add(wrapper);
				}
				//populate trackingIdToArticleMap
				if (!trackingIdToArticleMap.containsKey(em.TrackingID__c)) {
					trackingIdToArticleMap.put(em.TrackingID__c, em.Article__c);
				}
			}

			if (trackingIdToEventMessageWrapperMap.size() > 0) {
				//call the exception checker service for any exceptions found
				Map<String, ExceptionResult> exceptionResult = isExceptionApplies(trackingIdToEventMessageWrapperMap);
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
				assignCasesToAgentQueue(exceptionCases);
				//close the cases for lost in transit
				closeCases(casesToClose);	
			}
	}

	//assign cases to agent queue
	private void assignCasesToAgentQueue(List<Case> casesToAgentQueue) {
		List<CaseComment> caseComments = new List<CaseComment>();
		for (Case c: casesToAgentQueue) {
			c.AllocateToQueue__c = true;
			c.Case_Reopen_Date__c = null;
			c.Bypass_Data_enforcement__c = true;
			//add comment
			CaseComment caseComment = new CaseComment();
			caseComment.IsPublished = true;
            caseComment.ParentId = c.Id;
            caseComment.CommentBody = 'Auto-LIT exception: No';
            caseComments.add(caseComment);
		}
		//update cases
		List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToAgentQueue, false);
		UTIL_LoggingService.logDmlResults(vResult, null, casesToAgentQueue, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
		//update case comments
		List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlUpdate(caseComments, false);
		UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
	}

	//close cases for lost in transit
	private void closeCases(List<Case> casesToClose) {
		List<CaseComment> caseComments = new List<CaseComment>();
		for (Case c: casesToClose) {
			c.ClosedBySystem__c = true;
			c.ByPassWorkflowRulesOnCreation__c = true; //populate the filed to trigger the email
			//add comment
			CaseComment caseComment = new CaseComment();
			caseComment.IsPublished = true;
            caseComment.ParentId = c.Id;
            caseComment.CommentBody = 'Auto-LIT exception: Yes';
            caseComments.add(caseComment);
		}
		List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(casesToClose, false);
		UTIL_LoggingService.logDmlResults(vResult, null, casesToClose, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'closeCases',null, LoggingLevel.ERROR);
		//update case comments
		List<Database.SaveResult> commentsResult = ApplicationDatabase.getInstance().dmlUpdate(caseComments, false);
		UTIL_LoggingService.logDmlResults(commentsResult, null, caseComments, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'assignCasesToAgentQueue',null, LoggingLevel.ERROR);
	}

	private Map<String, ExceptionResult> isExceptionApplies(Map<String, List<EventMessageWrapper>> trackingIdToEventMessageWrapperMap){
		Map<String, ExceptionResult> result = new Map<String, ExceptionResult>();
		return result;
	}

	public class EventMessageWrapper {
		public String eventType;
		public Datetime eventDatetime;
	}

	public class ExceptionResult {
		public boolean isException;
	}

}