/**
* @author SteveL
* @date 2023-11-15
* @description This batch is used to close off the related records when a Consumer Account get archived

* @changelog
* 2023-11-15 - SteveL - Created
*/

public inherited sharing class ConsumerAccountClosureBatch implements Database.Batchable<SObject>,Schedulable {
	public final Integer nDaysAgo;
	public final Integer batchSize;
	public ConsumerAccountClosureSettings__c settings = ConsumerAccountClosureSettings__c.getInstance();
	public final List<SObjectType> sObjectTypesForDeletion = new List<SObjectType>{
			Account.SObjectType, Case.SObjectType, Attachment.SObjectType, Task.SObjectType, Event.SObjectType, AuthorisedContacts__c.SObjectType, NPSSurvey__c.SObjectType
	};

	public ConsumerAccountClosureBatch() {
		this.nDaysAgo = settings.NDaysAgo__c == null ? 3 : Integer.valueOf(settings.NDaysAgo__c);
		this.batchSize = settings.BatchSize__c == null ? 1 : Integer.valueOf(settings.BatchSize__c);
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
		AccountsSelector accountsSelector = AccountsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Account.SObjectType => new Set<SObjectField>{Account.Id}
		});

		return accountsSelector.selectArchivedAccountsByClosureDateLessThanEqualNDaysAgo(nDaysAgo, new Set<Object>());
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(this,batchSize);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope){
		try {
			ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypesForDeletion);

			Map<Id,Account> accountsMap = new Map<Id,Account>();
			for (SObject record : scope) {
				accountsMap.put(record.Id, (Account)record);
			}

			doDeletion(accountsMap, uow);
			uow.registerDeleted(accountsMap.values(), true, 'ConsumerAccountClosureBatch'); // at this point the accounts with open cases associated should have been removed by the doDeletion method, also turning throwOnError to be true so the catch block can catch it
			uow.commitWork();
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ConsumerAccountClosureBatch', ConsumerAccountClosureBatch.class.getName(), 'execute', 'ConsumerAccountClosureBatch', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * @param accountsMap Map<Id,Account>
	 * @param uow ApplicationUnitOfWork uow
	 * @description 1: filters out the account with open cases associated
	 *              2: use selectors to select the associated records by the given accounts
	 *              3: perform deletion on the records from step 2
	 */
	private void doDeletion(Map<Id,Account> accountsMap, ApplicationUnitOfWork uow) {
		//historical cases
		SSSWCasesSelector casesSelector = SSSWCasesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.Id}
		});
		Map<Id,Case> accountOpenCases = casesSelector.getOpenCasesByAccountIds(accountsMap.keySet(), new Set<Object>());
		Set<Id> openCaseAccountIds = new Set<Id>();
		for (Case kase : accountOpenCases.values()) {
			openCaseAccountIds.add(kase.AccountId); //remove all account ids with open case associated
		}

		for (Id accountId : accountsMap.keySet()) {
			if (openCaseAccountIds.contains(accountId)) {
				accountsMap.remove(accountId);
			}
		}

		Map<Id,Case> historicalCases = new Map<Id,Case>((List<Case>) Database.query(casesSelector.getClosedCasesByAccountIds(accountsMap.keySet(), new Set<Object>()).toSoqlString()));

		// Notes and Attachments
		List<Attachment> attachments = AttachmentsSelector.newInstance().selectByParentId(accountsMap.keySet());

		// Open Activities (Tasks, Events)
		List<Task> tasks = TasksSelector.newInstance().selectByWhatId(accountsMap.keySet())?.values();
		List<Event> events = EventsSelector.newInstance().selectByWhatId(accountsMap.keySet())?.values();

		// Activity History will be deleted by the deletion of Tasks and Events

		// Compensation, this has a Master-Detail relationship to Cases, so the deletion will be handled by the Case deletion

		// Related Contacts (AuthorisedContacts__c), select these by Case Id
		List<AuthorisedContacts__c> authorisedContacts = AuthorisedContactsSelector.newInstance().selectByCaseId(historicalCases.keySet());

		//NPS Survey, select these by Case Id
		List<NPSSurvey__c> npsSurveys = NPSSurveysSelector.newInstance().selectByCaseId(historicalCases.keySet());

		// delete them
		uow.registerDeleted(historicalCases.values(), true, 'ConsumerAccountClosureBatch');
		uow.registerDeleted(attachments, true, 'ConsumerAccountClosureBatch');
		uow.registerDeleted(tasks, true, 'ConsumerAccountClosureBatch');
		uow.registerDeleted(events, true, 'ConsumerAccountClosureBatch');
		uow.registerDeleted(authorisedContacts, true, 'ConsumerAccountClosureBatch');
		uow.registerDeleted(npsSurveys, true, 'ConsumerAccountClosureBatch');

	}

	public void finish(Database.BatchableContext BC) { }
}