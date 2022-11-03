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
* 19/10/2022 - Thang Nguyen - DDS-13106 - Refactor the code based on the ExceptionCheckerService refactor
*/

public class CaseReopenBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

	private Integer BATCH_SIZE = 25;

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
			Set<Id> articleIdSet = new Set<Id>();
			List<Case> caseListWithArticles = new List<Case>();
			List<Case> caseListWithoutArticles = new List<Case>();

			// loop through cases associated with/without articles
			for (Case c : (List<Case>) scope) {
				if (c.ArticleTest__c != null) {
					articleIdSet.add(c.ArticleTest__c);
					caseListWithArticles.add(c);
				} else {
					caseListWithoutArticles.add(c);
				}
			}

			//process the exception checker logic for cases with articles
			if (articleIdSet.size() > 0) {
				handleExceptionCheckerOnCases(articleIdSet, caseListWithArticles);
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
		//instantiate config variables
		Consumer_Help_and_Support__c config = Consumer_Help_and_Support__c.getOrgDefaults();
		if (config.CaseReopenBatchSize__c != null) {
			this.BATCH_SIZE = Integer.valueOf(config.CaseReopenBatchSize__c);
		} 
		Database.executeBatch(this, BATCH_SIZE);
	}

	/**
	 * handle the exception checker logic
	 */
	private void handleExceptionCheckerOnCases(Set<Id> articleIdSet, List<Case> caseListWithArticles) {
		Map<String, List<ExceptionCheckerService.EventMessageDTO>> articleIdToEventMessageWrapperMap = new Map<String, List<ExceptionCheckerService.EventMessageDTO>>();
		Map<Id,EventMessage__c> eventMessageMap = EventMessagesSelector.newInstance().selectByArticleId(articleIdSet);

			for (EventMessage__c em : eventMessageMap.values()) {
				//populate articleIdToEventMessageWrapperMap
				if (!articleIdToEventMessageWrapperMap.containsKey(em.Article__c)) {
					articleIdToEventMessageWrapperMap.put(em.Article__c, new List<ExceptionCheckerService.EventMessageDTO>());
				}
				if (String.isNotBlank(em.EventType__c)) {
					ExceptionCheckerService.EventMessageDTO emDto = new ExceptionCheckerService.EventMessageDTO();
					emDto.eventType = em.EventType__c;
					emDto.actualDateTime = em.ActualDateTime__c;
					articleIdToEventMessageWrapperMap.get(em.Article__c).add(emDto);
				}
			}

			if (articleIdSet.size() > 0) {
				//call the exception checker service
				runExceptionChecker(articleIdToEventMessageWrapperMap, caseListWithArticles);	
			}
	}

	/**
	 * Run the exception checker logic on cases to assign to agent queue and close the cases
	 */
	private void runExceptionChecker(Map<String, List<ExceptionCheckerService.EventMessageDTO>> articleIdToEventMessageWrapperMap, List<Case> caseListWithArticles) {
		List<Case> exceptionCases = new List<Case>();
		List<Case> casesToClose = new List<Case>();

		List<ExceptionCheckerService.ExceptionCheckDTO> exceptionCheckDTOS = new List<ExceptionCheckerService.ExceptionCheckDTO>();
		//loop through caseListWithArticles and create the List<ExceptionCheckDTO>
		for (Case articleCase : caseListWithArticles) {
			ExceptionCheckerService.ExceptionCheckDTO exceptionCheckDTO = new ExceptionCheckerService.ExceptionCheckDTO();
			// set case, this is to check the receiver
			exceptionCheckDTO.CaseToCheck = articleCase;
			// set event messages
			List<ExceptionCheckerService.EventMessageDTO> eventMessageDTOs =  new List<ExceptionCheckerService.EventMessageDTO>();
			if (articleIdToEventMessageWrapperMap.containsKey(articleCase.ArticleTest__c)) {
				eventMessageDTOs = articleIdToEventMessageWrapperMap.get(articleCase.ArticleTest__c);
			}				
			exceptionCheckDTO.eventMessages = eventMessageDTOs;
			
			//add to dto list
			exceptionCheckDTOS.add(exceptionCheckDTO);
		}

		//call exception checker service
		List<ExceptionCheckerService.ExceptionResultDTO> exceptionResults = ExceptionCheckerService.getInstance().isExceptionApplies(exceptionCheckDTOS);

		for (ExceptionCheckerService.ExceptionResultDTO resultDTO : exceptionResults) {
			if (resultDTO.isException){
				exceptionCases.add(resultDTO.CaseToCheck);
			}else{
				casesToClose.add(resultDTO.CaseToCheck);
			}
		}

		//assign the cases to queue
		ExceptionCheckerService.getInstance().assignCasesToAgentQueue(exceptionCases);

		//close the cases for lost in transit
		ExceptionCheckerService.getInstance().closeCases(casesToClose);
	}

}