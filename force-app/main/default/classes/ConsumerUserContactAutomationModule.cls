/**
 * @description
 * Domain module to handle the user permissions for Consumer Help and Suppport Community User
 * NOTE: All users that enter this module will be DDC Consumer Community User
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Naveen Rajanna
 * @date 2022-10-28
 * @changelog
 * 2022-10-28	Naveen Rajanna - created - REQ2992462
 */
public with sharing class ConsumerUserContactAutomationModule extends ApplicationDomain.Module {
	public static ConsumerUserContactAutomationModule newInstance() {
		return (ConsumerUserContactAutomationModule) Application.Utilities.newInstance(ConsumerUserContactAutomationModule.class);
	}

	/**
	 * Setup which trigger events this module should respond to
	 */
	public ConsumerUserContactAutomationModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	/**
	 * Method to invoke on after insert trigger context
	 * @param records User records in Trigger.New
	 * @param uow Application unit of work object
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateContactFields((List<User>) records, null, uow);
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(e),
					'ConsumerUserDomain',
					ConsumerUserContactAutomationModule.class.getName(),
					'onAfterInsert',
					'User',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * Method to invoke on after update trigger context
	 * @param records User records in Trigger.New
	 * @param existingRecords User records in Trigger.Old
	 * @param uow Application unit of work object
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			updateContactFields((List<User>) records, (Map<Id, User>) existingRecords, uow);
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(e),
					'ConsumerUserDomain',
					ConsumerUserContactAutomationModule.class.getName(),
					'onAfterUpdate',
					'User',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * Method will update related contact fields for filtered community users
	 * @param records User records in Trigger.New
	 * @param existingRecords User records in Trigger.Old
	 * @param uow Application unit of work object
	 */
	private void updateContactFields(List<User> records, Map<Id, User> existingRecords, ApplicationUnitOfWork uow) {
		Boolean isInsert = (existingRecords == null);
		Set<Id> contactIds = new Set<Id>();

		for (User userRec : records) {
			// Get old User record if it is update
			User oldUserRec = !isInsert ? existingRecords.get(userRec.Id) : null;

			// Check if Opt_In_For_Marketing__c has been set or Changed
			if (
				userRec.Opt_In_For_Marketing__c &&
				(isInsert || (oldUserRec != null && (oldUserRec.Opt_In_For_Marketing__c != userRec.Opt_In_For_Marketing__c)))
			) {
				contactIds.add(userRec.ContactId);
			}
		}

		// enqueue the worker to process the contact updates
		// NOTE: this has to be done asynchronously because user object and contact object together will cause mix DML
		if (contactIds.isEmpty() == false) {
			Map<String, Object> params = new Map<String, Object>{ 'contactIds' => contactIds };
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncUpdateContactDetailsWorker.class, params));
		}
	}

	/**
	 * Inner class to register a New Async Worker
	 */
	public without sharing class AsyncUpdateContactDetailsWorker extends ApplicationUnitOfWork.AsyncWorker {
		@TestVisible
		Set<Id> contactIds = new Set<Id>();

		public override Type getClassType() {
			return AsyncUpdateContactDetailsWorker.class;
		}

		/**
		 * The primary object that will be manipulated with this Async Worker.
		 * @return  `SObjectType`
		 */
		public override SObjectType getSObjectTypeGroup() {
			return Contact.SObjectType;
		}

		/**
		 * To populate the Object params variable
		 * @param serialisedParams
		 */
		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				Map<String, Set<Id>> params = (Map<String, Set<Id>>) JSON.deserialize(serialisedParams, Map<String, Set<Id>>.class);
				contactIds = params.get('contactIds');
			}
		}

		/**
		 * Perform contact updates for the chosen contactIds passed via params
		 * @param uow
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			List<Contact> updateableContacts = new List<Contact>();
			for (Id contactId : contactIds) {
				updateableContacts.add(new Contact(Id = contactId, Legal_Marketing_Opt_In__c = true));
			}

			if (updateableContacts != null && updateableContacts.isEmpty() == false) {
				uow.registerDirty(
					updateableContacts,
					false, // do not throw exception on error as it is async. It will be logged
					ConsumerUserContactAutomationModule.class.getName() +
					'.' +
					AsyncUpdateContactDetailsWorker.class.getName()
				);
			}
		}
	}
}
