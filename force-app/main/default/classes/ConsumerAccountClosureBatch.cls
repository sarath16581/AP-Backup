/**
* @author SteveL
* @date 2023-11-15
* @description This batch is used to delete the related records when a Consumer Account gets archived

* @changelog
* 2023-11-15 - SteveL - Created
*/

public inherited sharing class ConsumerAccountClosureBatch implements Database.Batchable<SObject>,Schedulable {
	public static final Integer DEFAULT_N_DAYS = 3; // this is the default value if the Custom Setting value is null
	public static final Integer DEFAULT_BATCH_SIZE = 1; // the default batch size if the Custom Setting value is null

	public final Integer nDaysAgo; // this number will be used in the N_DAYS_AGO SOQL literal to compare with Account.ArchivedDateTime__pc, and is populated by the Custom Setting value or DEFAULT_N_DAYS
	public final Integer batchSize;
	public ConsumerAccountClosureSettings__c settings = ConsumerAccountClosureSettings__c.getInstance();
	public final List<SObjectType> sObjectTypesForDeletion = new List<SObjectType>{
			 Attachment.SObjectType, Task.SObjectType, Event.SObjectType, AuthorisedContacts__c.SObjectType, NPSSurvey__c.SObjectType,Case.SObjectType,Account.SObjectType
	};

	public ConsumerAccountClosureBatch() {
		this.nDaysAgo = settings.NDaysAgo__c == null ? DEFAULT_N_DAYS : Integer.valueOf(settings.NDaysAgo__c);
		this.batchSize = settings.BatchSize__c == null ? DEFAULT_BATCH_SIZE : Integer.valueOf(settings.BatchSize__c);
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

			selectRelatedRecordsForDeletion(accountsMap, uow);
			uow.commitWork();

			List<Database.DeleteResult> accDeleteResults = new List<Database.DeleteResult>();
			accDeleteResults = ApplicationDatabase.getInstance().dmlDelete(accountsMap.values(), false); // at this point the accounts with open cases associated should have been removed from the collection by the selectRelatedRecordsForDeletion method, also turning throwOnError to be true so the catch block can catch it
			for (Database.DeleteResult sr : accDeleteResults) {
				if (!sr.isSuccess()) {
					ApplicationLogger.getInstance().logFailedDatabaseResults(accDeleteResults, 'ConsumerAccountClosureBatch.deleteAccount', CaseRoutingService.class.getName(), 'execute', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'ConsumerAccountClosureBatch', ConsumerAccountClosureBatch.class.getName(), 'execute', 'ConsumerAccountClosureBatch', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * @param accountsMap Map<Id,Account>
	 * @param uow ApplicationUnitOfWork uow
	 * @description this method performs the selection of related records for the archived accounts.
	 * 				For the related case records, only the closed cases need to be deleted.
	 * 				If the archived account has open cases associated, then it will be removed from the account collection
	 */
	private static void selectRelatedRecordsForDeletion(Map<Id,Account> accountsMap, ApplicationUnitOfWork uow) {
		//historical cases
		CasesSelector caseRecordsSelector = CasesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.Id,Case.AccountId}
		});
		Map<Id,Case> accountOpenCases = caseRecordsSelector.getOpenCasesByAccountIds(accountsMap.keySet(), new Set<Object>());
		Set<Id> openCaseAccountIds = new Set<Id>();
		for (Case caseRecord : accountOpenCases.values()) {
			openCaseAccountIds.add(caseRecord.AccountId);
		}

		for (Id accountId : accountsMap.keySet()) {
			if (openCaseAccountIds.contains(accountId)) {
				accountsMap.remove(accountId);
			}
		}

		Map<Id,Case> historicalCases = new Map<Id,Case>();
		if (!accountsMap.isEmpty()) { // the open case condition could potentially remove all the account records from the start method, so in that case we don't need to query the historical cases
			historicalCases = new Map<Id,Case>((List<Case>) Database.query(caseRecordsSelector.getClosedCasesByAccountIds(accountsMap.keySet(), new Set<Object>()).toSoqlString()));
		}


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
		uow.registerDeleted(historicalCases.values(), true, 'ConsumerAccountClosureBatch.historicalCases');
		uow.registerDeleted(attachments, true, 'ConsumerAccountClosureBatch.attachments');
		uow.registerDeleted(tasks, true, 'ConsumerAccountClosureBatch.tasks');
		uow.registerDeleted(events, true, 'ConsumerAccountClosureBatch.events');
		uow.registerDeleted(authorisedContacts, true, 'ConsumerAccountClosureBatch.authorisedContacts');
		uow.registerDeleted(npsSurveys, true, 'ConsumerAccountClosureBatch.npsSurveys');

	}

	public void finish(Database.BatchableContext BC) { }
}