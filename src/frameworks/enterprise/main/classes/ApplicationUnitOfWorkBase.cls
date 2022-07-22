/**
 * Provides an implementation of the Enterprise Application Architecture Unit Of Work, as defined by Martin Fowler
 *   http://martinfowler.com/eaaCatalog/unitOfWork.html
 *
 * "When you're pulling data in and out of a database, it's important to keep track of what you've changed; otherwise,
 *  that data won't be written back into the database. Similarly you have to insert new objects you create and
 *  remove any objects you delete."
 *
 * "You can change the database with each change to your object model, but this can lead to lots of very small database calls,
 *  which ends up being very slow. Furthermore it requires you to have a transaction open for the whole interaction, which is
 *  impractical if you have a business transaction that spans multiple requests. The situation is even worse if you need to
 *  keep track of the objects you've read so you can avoid inconsistent reads."
 *
 * "A Unit of Work keeps track of everything you do during a business transaction that can affect the database. When you're done,
 *  it figures out everything that needs to be done to alter the database as a result of your work."
 *
 * In an Apex context this pattern provides the following specific benefits
 *  - Applies bulkfication to DML operations, insert, update and delete
 *  - Manages a business transaction around the work and ensures a rollback occurs (even when exceptions are later handled by the caller)
 *  - Honours dependency rules between records and updates dependent relationships automatically during the commit
 *
 * Please refer to the testMethod's in this class for example usage
 *
 * TODO: Need to complete the 100% coverage by covering parameter exceptions in tests
 * TODO: Need to add some more test methods for more complex use cases and some unexpected (e.g. registerDirty and then registerDeleted)
 *
 */
public virtual inherited sharing class ApplicationUnitOfWorkBase {

	public static String LOGGING_APP_NAME = 'ApplicationUnitOfWork';

	// A unit of work can be configured to throw lock errors only
	// In this scenario, any row level config (log errors, throw exceptions etc..) are all ignored in favour of this global override
	// This is predominately used internally by the async worker processing queue
	// The end user/developer should not need to use this global override
	public Boolean throwLockErrors = false;

	/**
	 * If this UOW was registered in a trigger context it will register the state which is can be used for various debugging and tracing
	 */
	public enum REGISTERED_TRIGGER_STATE {
		BEFORE_INSERT,
		AFTER_INSERT,
		BEFORE_UPDATE,
		AFTER_UPDATE,
		BEFORE_DELETE,
		AFTER_DELETE
	}

	@TestVisible
	protected List<Schema.SObjectType> m_sObjectTypes = new List<Schema.SObjectType>();

	protected Map<String, List<SObject>> m_newListByType = new Map<String, List<SObject>>();

	// Used to provide the opportunity for an exception to be generated if a record save fails
	protected Map<String, List<Boolean>> m_newListByTypeThrowException = new Map<String, List<Boolean>>();

	// allows a trace to be added to show where a record was added from
	// this is used for error logging where a record fails but is not marked to throw an exception
	protected Map<String, List<String>> m_newListByTypeHistory = new Map<String, List<String>>();

	protected Map<String, Map<Id, SObject>> m_dirtyMapByType = new Map<String, Map<Id, SObject>>();

	// Used to provide the opportunity for an exception to be generated if a record save fails
	protected Map<String, Map<Id, Boolean>> m_dirtyMapByTypeThrowException = new Map<String, Map<Id, Boolean>>();

	// allows a trace to be added to show where a record was added from
	// this is used for error logging where a record fails but is not marked to throw an exception
	protected Map<String, Map<Id, List<String>>> m_dirtyMapByTypeHistory = new Map<String, Map<Id, List<String>>>();

	protected Map<String, Map<Id, SObject>> m_deletedMapByType = new Map<String, Map<Id, SObject>>();

	// Used to provide the opportunity for an exception to be generated if a record deletion fails
	protected Map<String, Map<Id, Boolean>> m_deletedMapByTypeThrowException = new Map<String, Map<Id, Boolean>>();

	// allows a trace to be added to show where a record was added from
	// this is used for error logging where a record fails but is not marked to throw an exception
	protected Map<String, Map<Id, String>> m_deletedMapByTypeHistory = new Map<String, Map<Id, String>>();

	protected Map<String, Relationships> m_relationships = new Map<String, Relationships>();

	//protected Map<String, List<SObject>> m_publishBeforeListByType = new Map<String, List<SObject>>();
	protected Map<String, List<SObject>> m_publishAfterSuccessListByType = new Map<String, List<SObject>>();
	//protected Map<String, List<SObject>> m_publishAfterFailureListByType = new Map<String, List<SObject>>();

	// These are errors that have occurred where no exception is generated
	// At the conclusion of the UOW, these logs will be stored in the database (only if no exception has been thrown)
	protected List<DatabaseError> m_ErrorLogs = new List<DatabaseError>();

	//	@TestVisible
	//	protected IEmailWork m_emailWork = new SendEmailWork();
	//
	//	protected IDML m_dml;

	//	/**
	//	 * Constructs a new UnitOfWork to support work against the given object list
	//	 *
	//	 * @param sObjectList A list of objects given in dependency order (least dependent first)
	//	 */
	//	public ApplicationSObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes) {
	//		this(sObjectTypes, new SimpleDML());
	//	}

	public void registerSObjectTypes(List<Schema.SObjectType> sObjectTypes) { //}, IDML dml) {
		m_sObjectTypes = sObjectTypes.clone();

		for (Schema.SObjectType sObjectType : m_sObjectTypes) {
			// register the type
			handleRegisterType(sObjectType);
		}

		//m_relationships.put(Messaging.SingleEmailMessage.class.getName(), new Relationships());
	}

	// default implementations for commitWork events
	public virtual void onRegisterType(Schema.SObjectType sObjectType) {}
	public virtual void onCommitWorkStarting() {}

	protected virtual void onDMLStarting() {}
	protected virtual void onDMLFinished() {}

	/**
	 * Registers the type to be used for DML operations
	 *
	 * @param sObjectType - The type to register
	 *
	 */
	private void handleRegisterType(Schema.SObjectType sObjectType) {
		String sObjectName = String.valueOf(sObjectType);

		// add type to dml operation tracking
		m_newListByType.put(sObjectName, new List<SObject>());
		m_newListByTypeThrowException.put(sObjectName, new List<Boolean>());
		m_newListByTypeHistory.put(sObjectName, new List<String>());

		m_dirtyMapByType.put(sObjectName, new Map<Id, SObject>());
		m_dirtyMapByTypeThrowException.put(sObjectName, new Map<Id, Boolean>());
		m_dirtyMapByTypeHistory.put(sObjectName, new Map<Id, List<String>>());

		m_deletedMapByType.put(sObjectName, new Map<Id, SObject>());
		m_deletedMapByTypeThrowException.put(sObjectName, new Map<Id, Boolean>());
		m_deletedMapByTypeHistory.put(sObjectName, new Map<Id, String>());

		m_relationships.put(sObjectName, new Relationships());

		//m_publishBeforeListByType.put(sObjectName, new List<SObject>());
		m_publishAfterSuccessListByType.put(sObjectName, new List<SObject>());
		//m_publishAfterFailureListByType.put(sObjectName, new List<SObject>());

		// give derived class opportunity to register the type
		onRegisterType(sObjectType);
	}


	//	/**
	//	 * Registers the given email to be sent during the commitWork
	//	 **/
	//	public void registerEmail(Messaging.Email email) {
	//		m_emailWork.registerEmail(email);
	//	}

	/**
	 * Register a newly created SObject instance to be inserted when commitWork is called
	 *
	 * @param record A newly created SObject instance to be inserted during commitWork
	 **/
	public SObject registerNew(SObject record) {
		return registerNew(record, null, null, false, '');
	}

	/**
	 * Register a list of newly created SObject instances to be inserted when commitWork is called
	 *
	 * @param records A list of newly created SObject instances to be inserted during commitWork
	 **/
	public List<SObject> registerNew(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerNew(record, null, null, false, ''));
		}
		return output;
	}

	/**
	 * Register a newly created SObject instance to be inserted when commitWork is called
	 * @param record The record to insert
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 *
	 * @return A reference to the record queued for inserting
	 */
	public SObject registerNew(SObject record, Boolean throwOnError, String source) {
		return registerNew(record, null, null, throwOnError, source);
	}

	/**
	 * Register a list of newly created SObject instances to be inserted when commitWork is called
	 *
	 * @param records A list of newly created SObject instances to be inserted during commitWork
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public List<SObject> registerNew(List<SObject> records, Boolean throwOnError, String source) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerNew(record, null, null, throwOnError, source));
		}
		return output;
	}

	/**
	 * Register a newly created SObject instance to be inserted when commitWork is called,
	 *   you may also provide a reference to the parent record instance (should also be registered as new separately)
	 *
	 * @param record A newly created SObject instance to be inserted during commitWork
	 * @param relatedToParentField A SObjectField reference to the child field that associates the child record with its parent
	 * @param relatedToParentRecord A SObject instance of the parent record (should also be registered as new separately)
	 **/
	public SObject registerNew(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
		return registerNew(record, relatedToParentField, relatedToParentRecord, false, '');
	}

	/**
	 * Register a newly created SObject instance to be inserted when commitWork is called,
	 *   you may also provide a reference to the parent record instance (should also be registered as new separately)
	 *
	 * @param record A newly created SObject instance to be inserted during commitWork
	 * @param relatedToParentField A SObjectField reference to the child field that associates the child record with its parent
	 * @param relatedToParentRecord A SObject instance of the parent record (should also be registered as new separately)
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public SObject registerNew(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord, Boolean throwOnError, String source) {
		if (record.Id != null)
			throw new UnitOfWorkException('Only new records can be registered as new');

		String sObjectType = String.valueOf(record.getSObjectType());

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_newListByType, sObjectType);

		m_newListByType.get(sObjectType).add(record);
		m_newListByTypeThrowException.get(sObjectType).add(throwOnError);
		m_newListByTypeHistory.get(sObjectType).add(source);
		if (relatedToParentRecord != null && relatedToParentField != null)
			registerRelationship(record, relatedToParentField, relatedToParentRecord);

		return record;
	}

	/**
	 * Register a relationship between two records that have yet to be inserted to the database. This information will be
	 *  used during the commitWork phase to make the references only when related records have been inserted to the database.
	 *
	 * @param record An existing or newly created record
	 * @param relatedToField A SObjectField reference to the lookup field that relates the two records together
	 * @param relatedTo A SObject instance (yet to be committed to the database)
	 */
	public void registerRelationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
		String sObjectType = String.valueOf(record.getSObjectType());

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_newListByType, sObjectType);

		m_relationships.get(sObjectType).add(record, relatedToField, relatedTo);
	}

	//	/**
	//	 * Registers a relationship between a record and a Messaging.Email where the record has yet to be inserted
	//	 *  to the database.  This information will be
	//	 *  used during the commitWork phase to make the references only when related records have been inserted to the database.
	//	 *
	//	 * @param a single email message instance
	//	 * @param relatedTo A SObject instance (yet to be committed to the database)
	//	 */
	//	public void registerRelationship(Messaging.SingleEmailMessage email, SObject relatedTo) {
	//		m_relationships.get(Messaging.SingleEmailMessage.class.getName()).add(email, relatedTo);
	//	}

	/**
	 * Registers a relationship between a record and a lookup value using an external ID field and a provided value. This
	 * information will be used during the commitWork phase to make the lookup reference requested when inserted to the database.
	 * Wraps putSObject, creating a new instance of the lookup sobject using the external id field and value.
	 */
	public void registerRelationship(SObject record, String relatedToRelationshipName, Schema.SObjectField relatedToField, SObjectType relatedToSObject, Schema.SObjectField externalIdField, Object externalId) {
		// NOTE: Due to the lack of ExternalID references on Standard Objects, this method can not be provided a standardized Unit Test. - Rick Parker
		String sObjectType = String.valueOf(record.getSObjectType());

		if (!m_newListByType.containsKey(sObjectType))
			throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this unit of work', new String[]{
					sObjectType
			}));

		m_relationships.get(sObjectType).add(record, relatedToRelationshipName, relatedToField, relatedToSObject, externalIdField, externalId);
	}

	//	/**
	//     * Registers a relationship between a record and a lookup value using an external ID field and a provided value. This
	//     * information will be used during the commitWork phase to make the lookup reference requested when inserted to the database.
	//     *
	//     * @param record An existing or newly created record
	//     * @param relatedToField A SObjectField reference to the lookup field that relates the two records together
	//     * @param externalIdField A SObjectField reference to a field on the target SObject that is marked as isExternalId
	//     * @param externalId A Object representing the targetted value of the externalIdField in said lookup
	//     *
	//     * Usage Example: uow.registerRelationship(recordSObject, record_sobject__c.relationship_field__c, lookup_sobject__c.external_id__c, 'abc123');
	//     *
	//     * Wraps putSObject, creating a new instance of the lookup sobject using the external id field and value.
	//     */
	//	public void registerRelationship(SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId)
	//	{
	//		// NOTE: Due to the lack of ExternalID references on Standard Objects, this method can not be provided a standardized Unit Test. - Rick Parker
	//		String sObjectType = String.valueOf(record.getSObjectType());
	//
	//		if(!m_newListByType.containsKey(sObjectType))
	//			throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this unit of work', new String[] { sObjectType }));
	//
	//		m_relationships.get(sObjectType).add(record, relatedToField, externalIdField, externalId);
	//	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 *
	 * @param record An existing record
	 **/
	public SObject registerDirty(SObject record) {
		return registerDirty(record, new List<SObjectField>(), false, '');
	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 *
	 * @param record An existing record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public SObject registerDirty(SObject record, Boolean throwOnError, String source) {
		return registerDirty(record, new List<SObjectField>(), throwOnError, source);
	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 *
	 * @param record An existing record
	 * @param dirtyFields Fields to include in the record
	 **/
	public SObject registerDirty(SObject record, List<SObjectField> dirtyFields) {
		return registerDirty(record, dirtyFields, false, '');
	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 * TODO: Bulkify better
	 *
	 * @param record An existing record
	 * @param dirtyFields Fields to include in the record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public List<SObject> registerDirty(List<SObject> records, List<SObjectField> dirtyFields, Boolean throwOnError, String source) {
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			output.add(registerDirty(record, dirtyFields, throwOnError, source));
		}
		return output;
	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 * TODO: Bulkify better
	 *
	 * @param record An existing record
	 * @param dirtyFields Fields to include in the record
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public List<SObject> registerDirty(List<SObject> records, List<SObjectField> dirtyFields, String source) {
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			output.add(registerDirty(record, dirtyFields, false, source));
		}
		return output;
	}

	/**
	 * Register an existing record to be updated during the commitWork method
	 *
	 * @param record An existing record
	 * @param dirtyFields Fields to include in the record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public SObject registerDirty(SObject record, List<SObjectField> dirtyFields, Boolean throwOnError, String source) {
		if(record.Id == null) {
			throw new UnitOfWorkException('New records cannot be registered as dirty');
		}

		String sObjectType = String.valueOf(record.getSObjectType());

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_dirtyMapByType, sObjectType);

		// If record isn't registered as dirty, or no dirty fields to drive a merge
		SObject registeredRecord = m_dirtyMapByType.get(sObjectType).get(record.Id);
		if(registeredRecord == null && (dirtyFields == null || dirtyFields.isEmpty())) {
			registeredRecord = record;
		} else if (registeredRecord != null && (dirtyFields == null || dirtyFields.isEmpty())) {

			// bring across all the fields to the existing registered record (this may override some of the existing fields)
			Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
			for(String fieldName : populatedFields.keySet()) {
				if(!(populatedFields.get(fieldName) instanceof SObject) && !(populatedFields.get(fieldName) instanceof List<SObject>)) {
					registeredRecord.put(fieldName, populatedFields.get(fieldName));
				}
			}

		} else {

			// register a new record if one has not already been registered
			if(registeredRecord == null) {
				registeredRecord = record.getSObjectType().newSObject(record.Id);
			}

			// Update the registered record's fields
			for (SObjectField dirtyField : dirtyFields) {
				registeredRecord.put(dirtyField, record.get(dirtyField));
			}
		}

		m_dirtyMapByType.get(sObjectType).put(record.Id, registeredRecord);

		// only change the value if it's not already true
		//throwOnError param might be true
		if(m_dirtyMapByTypeThrowException.get(sObjectType).get(record.Id) != true) {
			m_dirtyMapByTypeThrowException.get(sObjectType).put(record.Id, throwOnError);
		}

		// add a new history item for logging purposes
		if(!String.isEmpty(source)) {
			if(m_dirtyMapByTypeHistory.get(sObjectType).get(record.Id) == null) {
				m_dirtyMapByTypeHistory.get(sObjectType).put(record.Id, new List<String>());
			}
			m_dirtyMapByTypeHistory.get(sObjectType).get(record.Id).add(source);
		}

		// return a reference to the record if the caller needs it
		return registeredRecord;
	}

//	/**
//	 * Register an existing record to be updated when commitWork is called,
//	 *   you may also provide a reference to the parent record instance (should also be registered as new separately)
//	 *
//	 * @param record A newly created SObject instance to be inserted during commitWork
//	 * @param relatedToParentField A SObjectField reference to the child field that associates the child record with its parent
//	 * @param relatedToParentRecord A SObject instance of the parent record (should also be registered as new separately)
//	 **/
//	public SObject registerDirty(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
//		if (record.Id == null)
//			throw new UnitOfWorkException('New records cannot be registered as dirty');
//
//		String sObjectType = String.valueOf(record.getSObjectType());
//
//		assertForNonEventSObjectType(sObjectType);
//		assertForSupportedSObjectType(m_dirtyMapByType, sObjectType);
//
//		m_dirtyMapByType.get(sObjectType).put(record.Id, record);
//		if (relatedToParentRecord != null && relatedToParentField != null)
//			registerRelationship(record, relatedToParentField, relatedToParentRecord);
//
//		return record;
//	}

	/**
	 * Register a list of existing records to be updated during the commitWork method
	 *
	 * @param records A list of existing records
	 **/
	public List<SObject> registerDirty(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerDirty(record));
		}
		return output;
	}

	/**
	 * Register a list of existing records to be updated during the commitWork method
	 *
	 * @param records An existing record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public List<SObject> registerDirty(List<SObject> records, Boolean throwOnError, String source) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerDirty(record, throwOnError, source));
		}
		return output;
	}


	/**
	 * Register a new or existing record to be inserted/updated during the commitWork method
	 *
	 * @param record A new or existing record
	 **/
	public SObject registerUpsert(SObject record) {
		if (record.Id == null) {
			return registerNew(record, null, null, false, '');
		} else {
			return registerDirty(record, new List<SObjectField>(), false, '');
		}
	}

	/**
	 * Register a new or existing record to be inserted/updated during the commitWork method
	 *
	 * @param record A new or existing record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public SObject registerUpsert(SObject record, Boolean thrownOnError, String source) {
		if (record.Id == null) {
			return registerNew(record, null, null, thrownOnError, source);
		} else {
			return registerDirty(record, new List<SObjectField>(), thrownOnError, source);
		}
	}

	/**
	 * Register a list of mix of new and existing records to be inserted updated during the commitWork method
	 *
	 * @param records A list of mix of new and existing records
	 **/
	public List<SObject> registerUpsert(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerUpsert(record));
		}
		return output;
	}

	/**
	 * Register a new or existing record to be inserted/updated during the commitWork method
	 *
	 * @param records A list of mix of new and existing records
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public List<SObject> registerUpsert(List<SObject> records, Boolean thrownOnError, String source) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			output.add(registerUpsert(record, thrownOnError, source));
		}
		return output;
	}

	/**
	 * Register an existing record to be deleted during the commitWork method
	 *
	 * @param record An existing record
	 **/
	public void registerDeleted(SObject record) {
		registerDeleted(record, false, '');
	}

	/**
	 * Register an existing record to be deleted during the commitWork method
	 *
	 * @param record An existing record
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public void registerDeleted(SObject record, Boolean throwOnError, String source) {
		if (record.Id == null)
			throw new UnitOfWorkException('New records cannot be registered for deletion');

		String sObjectType = String.valueOf(record.getSObjectType());

		assertForNonEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_deletedMapByType, sObjectType);

		m_deletedMapByType.get(sObjectType).put(record.Id, record);
		m_deletedMapByTypeThrowException.get(sObjectType).put(record.Id, throwOnError);
		m_deletedMapByTypeHistory.get(sObjectType).put(record.Id, source);
	}

	/**
	 * Register a list of existing records to be deleted during the commitWork method
	 *
	 * @param records A list of existing records
	 **/
	public void registerDeleted(List<SObject> records) {
		for (SObject record : records) {
			this.registerDeleted(record);
		}
	}

	/**
	 * Register a list of existing records to be deleted during the commitWork method
	 *
	 * @param records A list of existing records
	 * @param throwOnError Throw an exception if this record fails and rollback the entire UOW
	 * @param source Where this method was called from, in the event when an error occurs
	 **/
	public void registerDeleted(List<SObject> records, Boolean throwOnError, String source) {
		for (SObject record : records) {
			this.registerDeleted(record, throwOnError, source);
		}
	}

	//	/**
	//	 * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
	//	 *
	//	 * @param record A newly created SObject (Platform Event) instance to be inserted during commitWork
	//	 **/
	//	public void registerPublishBeforeTransaction(SObject record) {
	//		String sObjectType = String.valueOf(record.getSObjectType());
	//
	//		assertForEventSObjectType(sObjectType);
	//		assertForSupportedSObjectType(m_publishBeforeListByType, sObjectType);
	//
	//		m_publishBeforeListByType.get(sObjectType).add(record);
	//	}
	//
	//	/**
	//	 * Register a list of newly created SObject (Platform Event) instance to be published when commitWork is called
	//	 *
	//	 * @param records A list of existing records
	//	 **/
	//	public void registerPublishBeforeTransaction(List<SObject> records) {
	//		for (SObject record : records) {
	//			this.registerPublishBeforeTransaction(record);
	//		}
	//	}

	/**
	 * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
	 *
	 * @param record A newly created SObject (Platform Event) instance to be inserted during commitWork
	 **/
	public void registerPublishAfterSuccessTransaction(SObject record) {
		String sObjectType = String.valueOf(record.getSObjectType());

		assertForEventSObjectType(sObjectType);
		assertForSupportedSObjectType(m_publishAfterSuccessListByType, sObjectType);

		m_publishAfterSuccessListByType.get(sObjectType).add(record);
	}

	/**
	 * Register a list of newly created SObject (Platform Event) instance to be published when commitWork is called
	 * NOTE: DML operations that fail which result in an error being logged and not an exception being thrown are still considered a success and a platform event would be published
	 *
	 * @param records A list of existing records
	 **/
	public void registerPublishAfterSuccessTransaction(List<SObject> records) {
		for (SObject record : records) {
			this.registerPublishAfterSuccessTransaction(record);
		}
	}
	//	/**
	//	 * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
	//	 *
	//	 * @param record A newly created SObject (Platform Event) instance to be inserted during commitWork
	//	 **/
	//	public void registerPublishAfterFailureTransaction(SObject record) {
	//		String sObjectType = String.valueOf(record.getSObjectType());
	//
	//		assertForEventSObjectType(sObjectType);
	//		assertForSupportedSObjectType(m_publishAfterFailureListByType, sObjectType);
	//
	//		m_publishAfterFailureListByType.get(sObjectType).add(record);
	//	}
	//
	//	/**
	//	 * Register a list of newly created SObject (Platform Event) instance to be published when commitWork is called
	//	 *
	//	 * @param records A list of existing records
	//	 **/
	//	public void registerPublishAfterFailureTransaction(List<SObject> records) {
	//		for (SObject record : records) {
	//			this.registerPublishAfterFailureTransaction(record);
	//		}
	//	}

	/**
	 * Takes all the work that has been registered with the UnitOfWork and commits it to the database
	 **/
	public void commitWork() {
		Savepoint sp = Database.setSavepoint();
		Boolean wasSuccessful = false;
		try {
			doCommitWork();
			wasSuccessful = true;

			// if records have failed to be processed and an exception was not thrown (only if throwOnError is set to true when registering the record)
			// we log these errors into an error log for further investigation
			logErrors();

		} catch (Exception e) {
			// in the event where a record was marked to throw an exception,
			// a UnitOfWorkDatabaseException will be generated and thrown
			// even though we are throwing an exception after the rollback, we still rollback as we dont know where commitWork was called from...
			//          perhaps the caller itself is catching exceptions
			Database.rollback(sp);
			throw e;
		} finally {
			doAfterCommitWorkSteps(wasSuccessful);
		}
	}

	private void doCommitWork() {
		onCommitWorkStarting();
		//		onPublishBeforeEventsStarting();
		//		publishBeforeEventsStarting();
		//		onPublishBeforeEventsFinished();

		onDMLStarting();
		insertDmlByType();
		updateDmlByType();
		deleteDmlByType();
		//resolveEmailRelationships();
		onDMLFinished();
	}

	private void doAfterCommitWorkSteps(Boolean wasSuccessful) {
		if (wasSuccessful) {
			publishAfterSuccessEvents();
		}
	}

	private void insertDmlByType() {
		List<DatabaseError> exceptionErrors = new List<DatabaseError>();
		for(Schema.SObjectType sObjectType : m_sObjectTypes) {
			String sObjectName = String.valueOf(sObjectType);

			m_relationships.get(sObjectName).resolve();
			if(m_newListByType.get(sObjectName).isEmpty())
				continue;

			List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlInsert(m_newListByType.get(sObjectName), false);

			for(Integer i=0;i<saveResults.size();i++) {
				Database.SaveResult result = saveResults[i];

				// A unit of work can be configured to force throwing lock errors specifically
				// In this scenario, any row level config (log errors, throw exceptions etc..) are all ignored in favour of this global override (just when lock errors occur)
				// This is predominately used internally by the async worker processing queue where retries are initiated
				// The regular consumer of a UOW should never need to worry about setting this variable directly since it's really only useful within the async framework
				if(!result.isSuccess() && throwLockErrors && isLockErrorResults(result)) {
					// throw lock exception immediately since no other processing needs to be done
					throw new UnitOfWorkDatabaseException(new List<DatabaseError>{new DatabaseError(m_newListByType.get(sObjectName)[i], result.getErrors(), new List<String>{m_newListByTypeHistory.get(sObjectName)[i]}, 'insert')});
				} else if(!result.isSuccess() && m_newListByTypeThrowException.get(sObjectName)[i]) {
					exceptionErrors.add(new DatabaseError(m_newListByType.get(sObjectName)[i], result.getErrors(), new List<String>{m_newListByTypeHistory.get(sObjectName)[i]}, 'insert'));
				} else if(!result.isSuccess()) {
					m_ErrorLogs.add(new DatabaseError(m_newListByType.get(sObjectName)[i], result.getErrors(), new List<String>{m_newListByTypeHistory.get(sObjectName)[i]}, 'insert'));
				}
			}


		}
		if(!exceptionErrors.isEmpty()) {
			throw new UnitOfWorkDatabaseException(exceptionErrors);
		}
	}

	private void updateDmlByType() {
		List<DatabaseError> exceptionErrors = new List<DatabaseError>();
		for (Schema.SObjectType sObjectType : m_sObjectTypes) {
			String sObjectName = String.valueOf(sObjectType);
			if(m_dirtyMapByType.get(sObjectName).isEmpty())
				continue;

			List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(m_dirtyMapByType.get(sObjectName).values(), false);
			System.debug(JSON.serialize(saveResults));
			for(Integer i=0;i<saveResults.size();i++) {
				Database.SaveResult result = saveResults[i];
				Id recordId = m_dirtyMapByType.get(sObjectName).values()[i].Id;

				// A unit of work can be configured to force throwing lock errors specifically
				// In this scenario, any row level config (log errors, throw exceptions etc..) are all ignored in favour of this global override (just when lock errors occur)
				// This is predominately used internally by the async worker processing queue where retries are initiated
				// The regular consumer of a UOW should never need to worry about setting this variable directly since it's really only useful within the async framework
				if(!result.isSuccess() && throwLockErrors && isLockErrorResults(result)) {
					// throw lock exception immediately since no other processing needs to be done
					throw new UnitOfWorkDatabaseException(new List<DatabaseError>{new DatabaseError(m_dirtyMapByType.get(sObjectName).get(recordId), result.getErrors(), m_dirtyMapByTypeHistory.get(sObjectName).get(recordId), 'update')});
				} else if(!result.isSuccess() && m_dirtyMapByTypeThrowException.get(sObjectName).get(recordId) != null && m_dirtyMapByTypeThrowException.get(sObjectName).get(recordId)) {
					exceptionErrors.add(new DatabaseError(m_dirtyMapByType.get(sObjectName).get(recordId), result.getErrors(), m_dirtyMapByTypeHistory.get(sObjectName).get(recordId), 'update'));
				} else if(!result.isSuccess()) {
					m_ErrorLogs.add(new DatabaseError(m_dirtyMapByType.get(sObjectName).get(recordId), result.getErrors(), m_dirtyMapByTypeHistory.get(sObjectName).get(recordId), 'update'));
				}
			}
		}
		if(!exceptionErrors.isEmpty()) {
			throw new UnitOfWorkDatabaseException(exceptionErrors);
		}
	}

	private void deleteDmlByType() {
		List<DatabaseError> exceptionErrors = new List<DatabaseError>();
		Integer objectIdx = m_sObjectTypes.size() - 1;
		while (objectIdx >= 0) {
			String sObjectType = String.valueOf(m_sObjectTypes[objectIdx--]);
			if(m_deletedMapByType.get(sObjectType).isEmpty())
				continue;

			List<Database.DeleteResult> deleteResults = ApplicationDatabase.getInstance().dmlDelete(m_deletedMapByType.get(sObjectType).values(), false);
			for(Integer i=0;i<deleteResults.size();i++) {
				Database.DeleteResult result = deleteResults[i];
				Id recordId = m_deletedMapByType.get(sObjectType).values()[i].Id;

				// A unit of work can be configured to force throwing lock errors specifically
				// In this scenario, any row level config (log errors, throw exceptions etc..) are all ignored in favour of this global override (just when lock errors occur)
				// This is predominately used internally by the async worker processing queue where retries are initiated
				// The regular consumer of a UOW should never need to worry about setting this variable directly since it's really only useful within the async framework
				if(!result.isSuccess() && throwLockErrors && isLockErrorResults(result)) {
					// throw lock exception immediately since no other processing needs to be done
					throw new UnitOfWorkDatabaseException(new List<DatabaseError>{new DatabaseError(m_deletedMapByType.get(sObjectType).get(recordId), result.getErrors(), new List<String>{m_deletedMapByTypeHistory.get(sObjectType).get(recordId)}, 'delete')});
				} else if(!result.isSuccess() && m_deletedMapByTypeThrowException.get(sObjectType).get(recordId) != null && m_deletedMapByTypeThrowException.get(sObjectType).get(recordId)) {
					exceptionErrors.add(new DatabaseError(m_deletedMapByType.get(sObjectType).get(recordId), result.getErrors(), new List<String>{m_deletedMapByTypeHistory.get(sObjectType).get(recordId)}, 'delete'));
				} else if(!result.isSuccess()) {
					m_ErrorLogs.add(new DatabaseError(m_deletedMapByType.get(sObjectType).get(recordId), result.getErrors(), new List<String>{m_deletedMapByTypeHistory.get(sObjectType).get(recordId)}, 'delete'));
				}
			}
		}
		if(!exceptionErrors.isEmpty()) {
			throw new UnitOfWorkDatabaseException(exceptionErrors);
		}
	}

	//	private void resolveEmailRelationships()
	//	{
	//		m_relationships.get(Messaging.SingleEmailMessage.class.getName()).resolve();
	//	}

	private void publishAfterSuccessEvents() {
		if(!m_publishAfterSuccessListByType.isEmpty()) {
			for (Schema.SObjectType sObjectType : m_sObjectTypes) {
				if (!m_publishAfterSuccessListByType.get(String.valueOf(sObjectType)).isEmpty()) {
					ApplicationDatabase.getInstance().eventPublish(m_publishAfterSuccessListByType.get(String.valueOf(sObjectType)));
				}
			}
		}
	}

	/**
	 * Log an errors that have occurred during database operations after commitWork is called
	 * Logs will only be added if the caller does not register to throw an exception on failure
	 */
	private void logErrors() {
		List<String> messages = new List<String>();
		List<String> references = new List<String>();
		for(DatabaseError errorLog : m_ErrorLogs) {
			messages.add(errorLog.toString());
			references.add(errorLog.getSource());
		}

		if(!messages.isEmpty()) {
			ApplicationLogger.getInstance().logMessage(messages, references, LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWorkBase.class), 'logErrors', '', ApplicationLogger.LoggingLevel.ERROR);
		}

		m_ErrorLogs.clear();
	}

	/**
	 * Determines whether a lock error has occurred in the save results.
	 * This is used in conjunction with throwLockErrors variable
	 */
	private Boolean isLockErrorResults(Database.SaveResult result) {
		return isDatabaseErrorUnableToLockRow(result.getErrors());
	}

	/**
	 * Determines whether a lock error has occurred in the save results.
	 * This is used in conjunction with throwLockErrors variable
	 */
	private Boolean isLockErrorResults(Database.DeleteResult result) {
		return isDatabaseErrorUnableToLockRow(result.getErrors());
	}

	private static Boolean isDatabaseErrorUnableToLockRow(List<Database.Error> errors) {
		if(errors == null) {
			return false;
		}
		for(Database.Error error : errors) {
			if(error.getStatusCode() == System.StatusCode.UNABLE_TO_LOCK_ROW) {
				return true;
			}
		}

		return false;
	}

	//	private void publishAfterFailureEvents() {
	//		for (Schema.SObjectType sObjectType : m_sObjectTypes) {
	//			ApplicationDatabase.getInstance().eventPublish(m_publishAfterFailureListByType.get(String.valueOf(sObjectType)));
	//		}
	//	}

	private void assertForNonEventSObjectType(String sObjectType) {
		if (sObjectType.length() > 3 && sObjectType.right(3) == '__e') {
			throw new UnitOfWorkException(String.format('SObject type {0} must use registerPublishBeforeTransaction or registerPublishAfterTransaction methods to be used within this unit of work', new List<String>{sObjectType}));
		}
	}

	private void assertForEventSObjectType(String sObjectType) {
		if (sObjectType.length() > 3 && sObjectType.right(3) != '__e') {
			throw new UnitOfWorkException(String.format('SObject type {0} is invalid for publishing within this unit of work', new List<String>{sObjectType}));
		}
	}

	private void assertForSupportedSObjectType(Map<String, Object> theMap, String sObjectType) {
		if (!theMap.containsKey(sObjectType)) {
			throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this unit of work', new List<String>{sObjectType}));
		}
	}

	private class Relationships {
		private List<IRelationship> m_relationships = new List<IRelationship>();

		public void resolve() {
			// Resolve relationships
			for (IRelationship relationship : m_relationships) {
				//relationship.Record.put(relationship.RelatedToField, relationship.RelatedTo.Id);
				relationship.resolve();
			}

		}

		public void add(SObject record, String relatedToRelationshipName, Schema.SObjectField relatedToField, SObjectType relatedToSObject, Schema.SObjectField externalIdField, Object externalId) {

			if (relatedToField == null) {
				throw new UnitOfWorkException('Invalid argument: relatedToField.');
			}

			if (String.isBlank(relatedToRelationshipName)) {
				throw new UnitOfWorkException('Invalid argument: relatedToField. Field supplied is not a relationship field.');
			}

			RelationshipByExternalId relationship = new RelationshipByExternalId();
			relationship.Record = record;
			relationship.RelatedToField = relatedToField;
			relationship.RelatedTo = relatedToSObject;
			relationship.RelationshipName = relatedToRelationshipName;
			relationship.ExternalIdField = externalIdField;
			relationship.ExternalId = externalId;
			m_relationships.add(relationship);

		}


		//        public void add(SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId)
		//        {
		//            if (relatedToField == null) {
		//                throw new UnitOfWorkException('Invalid argument: relatedToField.');
		//            }
		//
		//            String relationshipName = relatedToField.getDescribe().getRelationshipName();
		//            if (String.isBlank(relationshipName)) {
		//                throw new UnitOfWorkException('Invalid argument: relatedToField. Field supplied is not a relationship field.');
		//            }
		//
		//            List<Schema.SObjectType> relatedObjects = relatedToField.getDescribe().getReferenceTo();
		//            Schema.SObjectType relatedObject = relatedObjects[0];
		//
		//	        // Removing validation checking to prevent the need to use describe
		//			//            String externalIdFieldName = String.valueOf(externalIdField);
		//			//            Boolean relatedHasExternalIdField = relatedObject.getDescribe().fields.getMap().keySet().contains(externalIdFieldName.toLowerCase());
		//			//            Boolean externalIdFieldIsValid = externalIdField.getDescribe().isExternalId();
		//			//
		//			//            if (!relatedHasExternalIdField) {
		//			//                throw new UnitOfWorkException('Invalid argument: externalIdField. Field supplied is not a known field on the target sObject.');
		//			//            }
		//			//
		//			//            if (!externalIdFieldIsValid) {
		//			//                throw new UnitOfWorkException('Invalid argument: externalIdField. Field supplied is not a marked as an External Identifier.');
		//			//            }
		//
		//            RelationshipByExternalId relationship = new RelationshipByExternalId();
		//            relationship.Record = record;
		//            relationship.RelatedToField = relatedToField;
		//            relationship.RelatedTo = relatedObject;
		//            relationship.RelationshipName = relationshipName;
		//            relationship.ExternalIdField = externalIdField;
		//            relationship.ExternalId = externalId;
		//            m_relationships.add(relationship);
		//        }

		public void add(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
			// Relationship to resolve
			Relationship relationship = new Relationship();
			relationship.Record = record;
			relationship.RelatedToField = relatedToField;
			relationship.RelatedTo = relatedTo;
			m_relationships.add(relationship);
		}

		//		public void add(Messaging.SingleEmailMessage email, SObject relatedTo)
		//		{
		//			EmailRelationship emailRelationship = new EmailRelationship();
		//			emailRelationship.email = email;
		//			emailRelationship.relatedTo = relatedTo;
		//			m_relationships.add(emailRelationship);
		//		}
	}

	private interface IRelationship {
		void resolve();
	}

	private class RelationshipByExternalId implements IRelationship {
		public SObject Record;
		public Schema.SObjectField RelatedToField;
		public Schema.SObjectType RelatedTo;
		public String RelationshipName;
		public Schema.SObjectField ExternalIdField;
		public Object ExternalId;

		public void resolve() {
			SObject relationshipObject = this.RelatedTo.newSObject();
			relationshipObject.put(String.valueOf(ExternalIdField), this.ExternalId);
			this.Record.putSObject(this.RelationshipName, relationshipObject);
		}
	}

	private class Relationship implements IRelationship {
		public SObject Record;
		public Schema.SObjectField RelatedToField;
		public SObject RelatedTo;

		public void resolve() {
			this.Record.put(this.RelatedToField, this.RelatedTo.Id);
		}
	}

	//	private class EmailRelationship implements IRelationship
	//	{
	//		public Messaging.SingleEmailMessage email;
	//		public SObject relatedTo;
	//
	//		public void resolve()
	//		{
	//			this.email.setWhatId( this.RelatedTo.Id );
	//		}
	//	}

	/**
	 * UnitOfWork Exception
	 **/
	public class UnitOfWorkException extends Exception { }
	public class UnitOfWorkDatabaseException extends Exception {
		public List<DatabaseError> errors;

		public UnitOfWorkDatabaseException(List<DatabaseError> errors) {
			this.errors = errors;
		}

		// This is used as a way to extract any UNABLE_TO_LOCK_ROW errors from the exception
		// This is used in conjunction with throwLockErrors variable
		public Boolean containsLockError() {
			for(DatabaseError error : errors) {
				if(error.containsLockError()) {
					return true;
				}
			}
			return false;
		}

		public override String getMessage() {
			List<String> errorsList = new List<String>();
			for(DatabaseError error : this.errors) {
				errorsList.add(error.toString());
			}
			return String.join(errorsList, '\n');
		}
	}

	public class DatabaseError {
		public SObject record;
		public List<Database.Error> errors;
		public List<String> source;
		public String operation;

		public DatabaseError(SObject record, List<Database.Error> errors, List<String> source, String operation) {
			this.record = record;
			this.errors = errors;
			this.source = source;
			this.operation = operation;
		}

		public Boolean containsLockError() {
			return isDatabaseErrorUnableToLockRow(errors);
		}

		public override String toString() {
			String message = '';
			if(errors != null) {
				for(Database.Error error : errors) {
					String fields = String.join(error.getFields(),', ');
					message += error.getMessage() + ' (' + fields + ')';
					message += '\n\n';
				}
			}
			return message;
		}

		public String getSource() {
			return String.join((source != null ? source : new List<String>()), '\n');
		}
	}

	//	/**
	//	 * Internal implementation of Messaging.sendEmail, see outer class registerEmail method
	//	 **/
	//	public interface IEmailWork extends IDoWork
	//	{
	//		void registerEmail(Messaging.Email email);
	//	}
	//
	//	private class SendEmailWork implements IEmailWork
	//	{
	//		private List<Messaging.Email> emails;
	//
	//		public SendEmailWork()
	//		{
	//			this.emails = new List<Messaging.Email>();
	//		}
	//
	//		public void registerEmail(Messaging.Email email)
	//		{
	//			this.emails.add(email);
	//		}
	//
	//		public void doWork()
	//		{
	//			if (emails.size() > 0) Messaging.sendEmail(emails);
	//		}
	//	}
}