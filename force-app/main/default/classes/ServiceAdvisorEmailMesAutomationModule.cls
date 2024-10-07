/**
 * @description Application Module generic for Service Advisor Case Email Messages Automation
 * @author Naveen Rajanna
 * @date 2022-10-25
 * @group Modules
 * @domain EmailMessageCasesDomain
 * @test ServiceAdvisorEmailMesAutomationMd_Test
 * @changelog
 * 2022-10-25 - Naveen Rajanna - Created - REQ2859152
 */
public inherited sharing class ServiceAdvisorEmailMesAutomationModule extends ApplicationModule {

	// Setup which triggers this module should respond to
	public ServiceAdvisorEmailMesAutomationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	/**
	 * Methods to invoke on after insert trigger context
	 * @param records Email Messages in Trigger.New
	 * @param uow
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			Map<Id, Case> caseMap = retrieveCases(records, new Set<Object>());
			createTasks(records, caseMap, uow);
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(e),
					BGSConstants.SERVICE_DELIVERY_NAME,
					ServiceAdvisorEmailMesAutomationModule.class.getName(),
					'onAfterInsert',
					'EmailMessage',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * This is called from onAfterInsert(), creates Activity/Task under the case for bounce email
	 */
	private void createTasks(List<EmailMessage> records, Map<Id, Case> caseMap, ApplicationUnitOfWork uow) {
		List<Task> taskList = new List<Task>();
		for (EmailMessage em : records) {
			Case parent = caseMap.containsKey(em.ParentId) ? caseMap.get(em.ParentId) : null;
			// If Parent is a 'Closed Service Delivery Case assigned to an User' then create a Activity
			if (
				em.Incoming &&
				EmailMessageUtil.STATUS_NEW.equals(em.Status) &&
				parent != null &&
				('Closed').equals(parent.Status) &&
				!parent.Owner_is_Queue__c
			) {
				// Define a task record which needs to be created
				Task bounceTask = new Task();
				bounceTask.ActivityDate = (parent.ClosedDate != null) ? parent.ClosedDate.Date() : null;
				bounceTask.Description = 'An automatic email response email has been sent to the customer who had requested an update for this Closed Case.';
				bounceTask.Email__c = em.FromAddress;
				bounceTask.Status = 'Completed';
				bounceTask.WhatId = em.ParentId;
				bounceTask.OwnerId = parent.OwnerId;
				bounceTask.Subject = 'Bounce Email Sent to Customer';
				bounceTask.Priority = 'Normal';
				taskList.add(bounceTask);
			}
		}
		if (!taskList.isEmpty()) {
			//register with the UOW and the work will be committed in ApplicationDomainTriggerHandler
			uow.registerNew(taskList, false, 'ServiceAdvisorEmailMesAutomationModule');
		}
	}

	/**
	 * This will retrieve Parent Case data from Email messages
	 */
	private Map<Id, Case> retrieveCases(List<EmailMessage> records, Set<Object> selectorOptions) {
		// retrieve Parent Case Ids from Email messages
		Set<Id> caseIdSet = getCaseIds(records);
		// retrieve Case Map filtering only Service Advisor Cases
		return ServiceAdvisorsCasesSelector.newInstance().selectById(caseIdSet, selectorOptions);
	}

	/**
	 * This method is for getting Case ids from email records
	 */
	private Set<Id> getCaseIds(List<EmailMessage> records) {
		Set<Id> ids = new Set<Id>();
		// IMPORTANT - Please not null check for ParentId is not added as it is already taken care in the EmailMessageCasesDomain domain class
		for (EmailMessage em : records) {
			ids.add(em.ParentId);
		}
		return ids;
	}
}