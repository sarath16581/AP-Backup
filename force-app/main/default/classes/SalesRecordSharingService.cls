/**
 * @description Service layer responsible for implementing Apex managed sharing for sales team. Sales team access is
 *              segmented based on the Sales Team Type (i.e. Direct, Intermediary and Holding). Sales team members in
 *              Direct and Intermediary roles are only granted access to relevant SObject records based on the SalesTeamType__c
 *              on the parent Account.
 *
 *              IMPORTANT: Only supports SObjects having a lookup relationship to Account.
 *
 *              Sharing is configured via two custom metadata types:
 *                  - SalesSharingObjectMapping__mdt : Configure SObject types supported by programmatic sharing solution
 *                                                     for Sales Team. Holds configuration of SObject, Lookup Field and sharing reason.
 *                  - SalesSharingGroupMapping__mdt : Configure public groups to grant access through programmatic sharing solution
 *                                                    for Sales Team. Looks up to SalesSharingObjectMapping__mdt and holds
 *                                                    configuration of Sales Team Type, public group name and access level..
 *
 * @author Ranjeewa Silva
 * @group Service
 * @tag Sales Record Sharing
 * @Test SalesRecordSharingService_Test
 * @domain Sales
 * @changelog
 * 2022-12-01 - Ranjeewa Silva - Created
 */
public without sharing class SalesRecordSharingService {

	// sales team segments
	public static final String SALES_TEAM_TYPE_DIRECT = 'Direct';
	public static final String SALES_TEAM_TYPE_INTERMEDIARY = 'Intermediary';
	public static final String SALES_TEAM_TYPE_HOLDING = 'Holding';

	// name of 'Sales Team Sharing' application feature (ApplicationFeature__c). used to check if this feature is
	// active / inactive based on the custom setting - ApplicationFeature__c.
	public static final String SALES_RECORD_SHARING_FEATURE_NAME = 'SalesTeamSharing';

	// only standard public groups are supported for configuring sharing groups
	@TestVisible private static final Set<String> PUBLIC_GROUP_TYPES_SUPPORTED = new Set<String>{'Regular'};

	// sharing configuration cached for reuse later. sharing configuration is derived from custom metadata and translated into
	// a form suitable for use by this service class and it's clients.
	private static Map<SObjectType, SalesSharingObjectMapping> salesSharingObjectMappingCache = new Map<SObjectType, SalesSharingObjectMapping>();

	// maximum number of child records that can be processed in a single transaction as part of account movement operation.
	// this number is influenced mainly by the governor limit on number records for DML statements in a transaction.
	// allow for sharing recalculation involving delete and insert of share records for the child records.
	@TestVisible private static Integer MAX_ACC_MOVEMENT_RELATED_RECORD_SIZE_PER_TRANSACTION = 4500;

	// cache key setting names for accessing platform cache
	private static final String CACHE_KEY_SALES_SHARING_CONFIGURATION = 'SALES_SHARING_CONFIGURATION';
	private static final String CACHE_KEY_SALES_ACCOUNT_CHILD_REL_NAMES = 'SALES_ACCOUNT_CHILD_REL_NAMES';

	// custom metadata configured. arranged into a map where SObject API name is the key for ease of access.
	@TestVisible private static Map<String, SalesSharingObjectMapping__mdt> salesSharingMetadata {
		get {
			if (salesSharingMetadata == null) {
				Application.Profiler.start('SalesRecordSharingService.salesSharingMetadata(static)');
				// check platform cache
				if (CacheManager.get(CACHE_KEY_SALES_SHARING_CONFIGURATION) != null) {
					// use sharing metadata available in platform cache.
					salesSharingMetadata = (Map<String, SalesSharingObjectMapping__mdt>) CacheManager.get(CACHE_KEY_SALES_SHARING_CONFIGURATION);
				} else {
					// sharing metadata is not available in platform cache. need to be queried.
					Map<String, SalesSharingObjectMapping__mdt> metadata = new Map<String, SalesSharingObjectMapping__mdt>();

					// query metadata including specific fields from EntityDefinition and FieldDefinition types. Note that
					// standard get* methods for accessing custom metadata is avoided so that all the fields required can be
					// queried in one go.
					for (SalesSharingObjectMapping__mdt record : [
							SELECT Id, Object__r.QualifiedApiName, AccountLookup__r.QualifiedApiName,
						AccountLookup__r.RelationshipName, AccountLookup__r.DurableId, SharingReasonName__c,
						(SELECT SalesTeamType__c, GroupName__c, AccessLevel__c FROM SalesSharingGroupMappings__r)
							FROM SalesSharingObjectMapping__mdt
					]) {
						metadata.put(record.Object__r.QualifiedApiName, record);
					}
					salesSharingMetadata = metadata;
					// also populate platform cache so it is available later
					CacheManager.put(CACHE_KEY_SALES_SHARING_CONFIGURATION, metadata);
				}
				Application.Profiler.stop('SalesRecordSharingService.salesSharingMetadata(static)');
			}
			return salesSharingMetadata;
		}
		private set;
	}

	// public group name to id mapping for public groups configured in custom metadata.
	@TestVisible private static Map<String, Id> publicGroupIdMapping {
		get {
			if (publicGroupIdMapping == null) {
				Application.Profiler.start('SalesRecordSharingService.publicGroupIdMapping(static)');

				// collect all group names configured in custom metadata
				Set<String> groupNames = new Set<String>();
				for (SalesSharingObjectMapping__mdt objectMapping: salesSharingMetadata.values()) {
					for (SalesSharingGroupMapping__mdt groupMapping: objectMapping.SalesSharingGroupMappings__r) {
						groupNames.add(groupMapping.GroupName__c);
					}
				}

				Map<String, Id> mappings = new Map<String, Id>();
				if (!groupNames.isEmpty()) {
					// query group names and populate group name to id mapping
					Map<Id, Group> groups = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(PUBLIC_GROUP_TYPES_SUPPORTED, groupNames);
					for (Group g: groups.values()) {
						mappings.put(g.DeveloperName, g.Id);
					}
				}
				publicGroupIdMapping = mappings;
				Application.Profiler.stop('SalesRecordSharingService.publicGroupIdMapping(static)');
			}
			return publicGroupIdMapping;
		}
		private set;
	}

	// derive child relationship names on the Account object (e.g. 'APRs__r').
	// use lookup field definitions captured in SalesSharingObjectMapping__mdt for this.
	// this is required only when we need to process accounts moving sales channels (e.g. Holding to Direct etc).
	@TestVisible private static Map<String, String> accountChildRelationshipNameMapping {
		get {
			if (accountChildRelationshipNameMapping == null) {
				Application.Profiler.start('SalesRecordSharingService.accountChildRelationshipNameMapping(static)');
				// check platform cache first
				if (CacheManager.get(CACHE_KEY_SALES_ACCOUNT_CHILD_REL_NAMES) != null) {
					// use sharing metadata available in platform cache.
					accountChildRelationshipNameMapping = (Map<String, String>) CacheManager.get(CACHE_KEY_SALES_ACCOUNT_CHILD_REL_NAMES);
				} else {

					// collect all lookup fields configured in custom metadata
					Set<String> fieldDefinitionDurableIds = new Set<String>();
					for (SalesSharingObjectMapping__mdt objectMapping : salesSharingMetadata.values()) {
						fieldDefinitionDurableIds.add(objectMapping.AccountLookup__r.DurableId);
					}

					Map<String, String> mappings = new Map<String, String>();
					if (!fieldDefinitionDurableIds.isEmpty()) {
						// query field definitions with 'RelationshipDomains' to extract child relationship names
					for (FieldDefinition f: [SELECT EntityDefinition.QualifiedAPiName, QualifiedApiName, (SELECT RelationshipName FROM RelationshipDomains)
								FROM FieldDefinition
												WHERE DurableId IN :fieldDefinitionDurableIds]) {

							if (!f.RelationshipDomains.isEmpty() && f.RelationshipDomains[0].RelationshipName != null) {
								// found a valid child relationship name.
								mappings.put(f.EntityDefinition.QualifiedAPiName, f.RelationshipDomains[0].RelationshipName);
							}
						}
					}
					accountChildRelationshipNameMapping = mappings;
					// populate platform cache so it is available for later
					CacheManager.put(CACHE_KEY_SALES_ACCOUNT_CHILD_REL_NAMES, mappings);
				}
				Application.Profiler.stop('SalesRecordSharingService.accountChildRelationshipNameMapping(static)');

			}
			return accountChildRelationshipNameMapping;
		}
		private set;
	}

	public static SalesRecordSharingService getInstance() {
		return (SalesRecordSharingService) Application.Utilities.getInstance(SalesRecordSharingService.class);
	}

	/**
	 * Returns sharing configuration defined in custom metadata for the SObjectType passed in.
	 * Throws SalesRecordSharingException in below scenarios:
	 *      - Configuration not defined in custom metadata for the SObjectType
	 *      - At least one public group configured in custom metadata for the SObjectType not available in this environment.
	 *
	 * @param sobjectType SObjectType to retrieve sharing configuration
	 *
	 * @return Sharing configuration for the SObjectType. Throws SalesRecordSharingException if configuration not available or invalid.
	 */
	public SalesRecordSharingService.SalesSharingObjectMapping getSharingConfiguration(SObjectType sobjectType) {
		Application.Profiler.start('SalesRecordSharingService.getSharingConfiguration_'+sobjectType);
		// check if configuration already cached. if configuration for the sobjectType is already available return the cached version.
		if (salesSharingObjectMappingCache.containsKey(sobjectType)) {
			return salesSharingObjectMappingCache.get(sobjectType);
		}

		if (!salesSharingMetadata.containsKey(String.valueOf(sobjectType))) {
			// custom metadata not defined for the sObjectType. throw an exception to be handled by the caller.
			String message = 'Sharing configuration not defined in custom metadata for sobject [' + sobjectType + '].';
			throw new SalesRecordSharingException(message);
		}

		// sharing configuration is not available in the cache. need to build the sharing configuration from custom metadata
		SalesSharingObjectMapping sharingObjectMapping = newObjectMappingFromMetadata(sobjectType, salesSharingMetadata.get(String.valueOf(sobjectType)));

		// cache the configuration for reuse later
		salesSharingObjectMappingCache.put(sobjectType, sharingObjectMapping);
		Application.Profiler.stop('SalesRecordSharingService.getSharingConfiguration_'+sobjectType);
		return sharingObjectMapping;
	}

	/**
	 * Share records of a given SObjectType with the Sales Team based on the 'Sales Team Type' on parent account.
	 * Access level and sharing groups are configured in custom metadata.
	 *
	 * Intended to be used by callers when it doesn't possess a readily available unit of work instance (e.g. batch apex).
	 * Manages uow on behalf of it's callers and delegates to overloaded 'shareRecords' to implement sharing.
	 *
	 * Supports recalculating sharing for existing records via 'recalculate' flag. If this flag is set, any existing share
	 * records having the same apex sharing reason are evaluated. Any existing shares no longer necessary as per the current
	 * sharing requirements are deleted. Similarly any existing share records still required based on the current
	 * sharing requirement are retained.
	 *
	 * When 'recalculate' flag is set to false, service simply creates new share records based on the current sharing
	 * requirements without evaluating any existing shares. This mode should only be used to share records when new records
	 * are created.
	 *
	 * NOTE: This method takes sobjects as a parameter and callers MUST populate account lookup field (e.g. lookup__c)
	 * on the sobject records supplied. If 'SalesTeamType__c' on account reference (lookup__r.SalesTeamType__c) is also
	 * populated the service will use this without querying parent accounts.
	 * This approach was preferred over passing in sobject id's and service having to query sobjects based on ids:
	 *      - Performs slightly better in current use cases (trigger and batch apex), where the callers already have access
	 *        to sobject records with account lookup populated.
	 *      - Makes the service simpler as it does not have to dynamically invoke selectors to query sobject records.
	 *      - Amy other uses of the service other than the current use cases are not known.
	 *
	 * @param objectType SObjectType of the records passed in.
	 * @param records records to be shared with sales team.
	 * @param recalculate recalculates sharing if true. otherwise only create new shares.
	 */
	public void shareRecords(SObjectType objectType, Map<Id, SObject> records, Boolean recalculate) {
		Application.Profiler.start('SalesRecordSharingService.shareRecords_noUoW');

		// manage uow and delegate to overloaded 'shareRecords' method
		ApplicationUnitOfWork uow = newUnitOfWork(new Set<SObjectType>{objectType});

		shareRecords(objectType, records, recalculate, uow);

		// ensure Unit of Work is committed.
		uow.commitWork();
		Application.Profiler.stop('SalesRecordSharingService.shareRecords_noUoW');
	}

	/**
	 * Share records of a given SObjectType with the Sales Team based on the 'Sales Team Type' on parent account.
	 * Access level and sharing groups are configured in custom metadata.
	 *
	 * Intended to be used by callers when it possesses a readily available unit of work instance (e.g. trigger context).
	 * Please use the overloaded shareRecords method if a unit of work instance is not available.
	 *
	 * Supports recalculating sharing for existing records via 'recalculate' flag. If this flag is set, any existing share
	 * records having the same apex sharing reason are evaluated. Any existing shares no longer necessary as per the current
	 * sharing requirements are deleted. Similarly any existing share records still required based on the current
	 * sharing requirement are retained.
	 *
	 * When 'recalculate' flag is set to false, service simply creates new share records based on the current sharing
	 * requirements without evaluating any existing shares. This mode should only be used to share records when new records
	 * are created.
	 *
	 * NOTE: This method takes sobjects as a parameter and callers MUST populate account lookup field (e.g. lookup__c)
	 * on the sobject records supplied. If 'SalesTeamType__c' on account reference (lookup__r.SalesTeamType__c) is also
	 * populated the service will use this without querying parent accounts.
	 * This approach was preferred over passing in sobject id's and service having to query sobjects based on ids:
	 *      - Performs slightly better in current use cases (trigger and batch apex), where the callers already have access
	 *        to sobject records with account lookup populated.
	 *      - Makes the service simpler as it does not have to dynamically invoke selectors to query sobject records.
	 *      - Amy other uses of the service other than the current use cases are not known.
	 *
	 * @param objectType SObjectType of the records passed in.
	 * @param records records to be shared with sales team.
	 * @param recalculate recalculates sharing if true. otherwise only create new shares.
	 * @param uow Unit of Work instance
	 */
	public void shareRecords(SObjectType objectType, Map<Id, SObject> records, Boolean recalculate, ApplicationUnitOfWork uow) { 
		Application.Profiler.start('SalesRecordSharingService.shareRecords');
		if (!isSalesTeamSharingEnabled(new Set<SObjectType>{objectType})) {
			return; // feature is disabled. nothing to do.
		}

		SalesSharingObjectMapping mapping = getSharingConfiguration(objectType);

		// work out required sharing entries as per current 'SalesTeamType' configured on parent account
		Map<String, SObject> requiredSharingEntries = computeRequiredSharingEntries(records, mapping);

		if (recalculate) {

			// sharing recalculation is required. need to work out the new sharing entries required and existing
			// sharing entries to be deleted.

			// query existing shares based on RowCause
			Map<String, SObject> existingSharingEntries = getExistingSharingEntries(records.keySet(), mapping);

			// from the required sharing entries determine what already exists. only need to insert the missing entries.
			Set<String> newSharingEntriesForInsertKeys = requiredSharingEntries.keySet().clone();
			newSharingEntriesForInsertKeys.removeAll(existingSharingEntries.keySet());

			// from the existing sharing entries determine what is no longer required. delete these existing shares.
			Set<String> existingSharingEntriesForDeleteKeys = existingSharingEntries.keySet().clone();
			existingSharingEntriesForDeleteKeys.removeAll(requiredSharingEntries.keySet());

			for (String key: newSharingEntriesForInsertKeys) {
				uow.registerNew(requiredSharingEntries.get(key), false, SalesRecordSharingService.class.getName() + '.shareRecords()');
			}

			for (String key: existingSharingEntriesForDeleteKeys) {
				uow.registerDeleted(existingSharingEntries.get(key), false, SalesRecordSharingService.class.getName() + '.shareRecords()');
			}
		} else if (!requiredSharingEntries.isEmpty()){
			// we have new shares to register
			uow.registerNew(requiredSharingEntries.values(), false, SalesRecordSharingService.class.getName() + '.shareRecords()');
		}
		Application.Profiler.stop('SalesRecordSharingService.shareRecords');
	}

	/**
	 * Recalculate sharing for child sobject records of the accounts passed in. Child sobject types are as configured
	 * in custom metadata.
	 *
	 * Based on child record counts of parent accounts passed in, it works out the accounts that can be processed synchronously.
	 * Processing results returned contains the outcome for each account requested and if it should be retried later in
	 * partial mode (i.e. attempt one child sobject type at a time) instead of attempting to process all child sobject types
	 * at once.
	 *
	 * Intended to be used by callers when it does NOT possesses a readily available unit of work instance.
	 *
	 * @param parentAccountIds parent account ids of child records where sharing is to be recalculated/
	 *
	 * @return Sharing recalculation results
	 */
	public List<AccountChildRecordsSharingRecalculationResult> recalculateChildRecordSharing(Set<Id> parentAccountIds) {
		Application.Profiler.start('SalesRecordSharingService.recalculateChildRecordSharing_noUoW');
		// manage uow and delegate to overloaded 'shareRecords' method
		ApplicationUnitOfWork uow = newUnitOfWork();

		List<AccountChildRecordsSharingRecalculationResult> results = recalculateChildRecordSharing(parentAccountIds, uow);

		uow.commitWork();
		Application.Profiler.stop('SalesRecordSharingService.recalculateChildRecordSharing_noUoW');

		return results;
	}

	/**
	 * Recalculate sharing for child sobject records of the accounts passed in. Child sobject types are as configured
	 * in custom metadata.
	 *
	 * Works out the accounts that can be processed synchronously based on the child record counts of accounts passed in.
	 * Processing results returned contains the outcome for each account requested and if it should be retried later in
	 * partial mode (i.e. attempt one child sobject type at a time) instead of attempting to process all child sobject types
	 * for the account at once.
	 *
	 * Intended to be used by callers when it possesses a readily available unit of work instance (e.g. trigger context).
	 * Please use the overloaded recalculateChildRecordSharing method if a unit of work instance is not available.
	 *
	 * @param parentAccountIds parent account ids of child records where sharing is to be recalculated/
	 * @param uow unit of work instance
	 *
	 * @return Sharing recalculation results
	 */
	public List<AccountChildRecordsSharingRecalculationResult> recalculateChildRecordSharing(Set<Id> parentAccountIds, ApplicationUnitOfWork uow) {
		Application.Profiler.start('SalesRecordSharingService.recalculateChildRecordSharing');
		if (!isSalesTeamSharingEnabled(new Set<SObjectType>())) {
			return new List<AccountChildRecordsSharingRecalculationResult>(); // feature is disabled. nothing to do.
		}

		// retrieve sharing configuration for all objects configured in metadata
		Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMappings = getSharingConfiguration();

		// query parent accounts with child records for object types configured in metadata
		Map<Id, Account> parentAccountsWithRelatedRecords = selectParentAccountsWithChildRecords(parentAccountIds, sharingObjectMappings);

		List<AccountChildRecordsSharingRecalculationResult> results = new List<AccountChildRecordsSharingRecalculationResult>();

		// collect accounts to be processed in current context. rest of the accounts are returned with "processed"=false in results.
		Map<Id, Account> currentContextProcessableAccounts = new Map<Id, Account>();
		// running total of child records count for accounts marked for processing in current context
		Integer currentContextProcessableChildRecordCount = 0;

		for (Account parentAccount: parentAccountsWithRelatedRecords.values()) {

			// obtain child record counts for this account - total and also the child record count for each sobject type.
			Map<SObjectType, Integer> childSObjectRecordCounts = new Map<SObjectType, Integer>();
			Integer totalChildRecordCount = countChildRecords(parentAccount, sharingObjectMappings, childSObjectRecordCounts);

			// check if all child records of current parent account can be processed synchronously
			if ((currentContextProcessableChildRecordCount + totalChildRecordCount) < MAX_ACC_MOVEMENT_RELATED_RECORD_SIZE_PER_TRANSACTION) {
				// current account's related records can be processed in synchronously in current context.
				currentContextProcessableChildRecordCount += totalChildRecordCount;
				currentContextProcessableAccounts.put(parentAccount.Id, parentAccount);
				// populate result to return at the end.
				results.add(new AccountChildRecordsSharingRecalculationResult(parentAccount.Id, parentAccount.SalesTeamType__c, true, false, new Map<SObjectType, Integer>()));
			} else {
				// current parent account's child records cannot be processed synchronously in current transaction together with
				// all the other accounts marked for processing in this transaction.
				// next check if current parent account's child records by it self would go beyond the limit.
				if (totalChildRecordCount > MAX_ACC_MOVEMENT_RELATED_RECORD_SIZE_PER_TRANSACTION) {
					// child records of this parent account cannot be processed in a single transaction due to the volume
					// do not process now and return 'retryInPartialMode=true' so the caller can retry partially (each sobject type in a separate transaction).
					results.add(new AccountChildRecordsSharingRecalculationResult(parentAccount.Id, parentAccount.SalesTeamType__c, false, true, childSObjectRecordCounts));
				} else {
					// account does not need to be split per sobject type
					results.add(new AccountChildRecordsSharingRecalculationResult(parentAccount.Id, parentAccount.SalesTeamType__c, false, false, childSObjectRecordCounts));
				}
			}
		}

		if (!currentContextProcessableAccounts.isEmpty()) {
			// we have accounts to be processed in current context.
			doShareChildRecords(currentContextProcessableAccounts, sharingObjectMappings, uow);
		}
		Application.Profiler.stop('SalesRecordSharingService.recalculateChildRecordSharing');
		return results;
	}

	/**
	 * Enqueue a queueable to process child record sharing of the accounts passed in
	 *
	 * @param accountIds account ids
	 */
	public void enqueueChildRecordsSharingHandlerQueueable(Set<Id> accountIds) {

		if (!isSalesTeamSharingEnabled(new Set<SObjectType>())) {
			return; // feature is disabled. nothing to do.
		}

		// recalculate sharing for child records for the accounts in an async process
		ApplicationDatabase.getInstance().enqueueJob(new SalesAccountChildRecordsSharingHandlerQueueable(accountIds));
	}

	/**
	 * Build sharing configuration for the SObjectType using the custom metadata instance passed in.
	 * Throws SalesRecordSharingException if at least one public group configured in custom metadata for the SObjectType
	 * not available in this environment.
	 *
	 * @param sobjectType SObjectType to build sharing configuration
	 * @param sharingConfigurationMetadata custom metadata instance that defines the configuration
	 *
	 * @return Sharing configuration for the SObjectType. Throws SalesRecordSharingException if configuration in metadata is invalid.
	 */
	private SalesSharingObjectMapping newObjectMappingFromMetadata(SObjectType sobjectType, SalesSharingObjectMapping__mdt sharingConfigurationMetadata) {

		SObjectField lookupField =  sobjectType.getDescribe().fields.getMap().get(sharingConfigurationMetadata.AccountLookup__r.QualifiedApiName);
		SalesSharingObjectMapping sharingObjectMapping = new SalesSharingObjectMapping(sobjectType, lookupField, sharingConfigurationMetadata.AccountLookup__r.RelationshipName, sharingConfigurationMetadata.SharingReasonName__c);

		for (SalesSharingGroupMapping__mdt groupMetadata: sharingConfigurationMetadata.SalesSharingGroupMappings__r) {
			Id sharingGroupId = publicGroupIdMapping.get(groupMetadata.GroupName__c);
			if (sharingGroupId == null) {
				// specified group does not exist. throw an exception for the callers to handle
				String msg = 'Cannot find public group [' + groupMetadata.GroupName__c +'] configured in custom metadata for Sales Team Type ['
						+ groupMetadata.SalesTeamType__c + '] for object [' + sobjectType + ']';
				throw new SalesRecordSharingException(msg);
			}
			sharingObjectMapping.addGroupMapping(new SalesSharingGroupMapping(groupMetadata.SalesTeamType__c, sharingGroupId, groupMetadata.GroupName__c, groupMetadata.AccessLevel__c));
		}

		return sharingObjectMapping;
	}

	/**
	 *  Returns a mapping of Sales Team Type applicable for sobjects passed in. Id of the SObject is set as the map key.
	 *  If Sales Team Type cannot be determined for an SObject (e.g. SObject is not related to a parent account), Ids of
	 *  such sobjects are not included in the map returned.
	 *
	 * @param records SObjects to determine the Sales Team Type
	 * @param sharingObjectMapping sharing object mapping applicable for the records passed in.
	 *
	 * @return Sales Team Type mapping for sobjects. SObject Id is set as the map key.
	 */
	@TestVisible private Map<Id, String> getSalesTeamTypeMapping(Map<Id, SObject> records, SalesRecordSharingService.SalesSharingObjectMapping sharingObjectMapping) {

		//TODO consider caching this ??
		Map<Id, String> salesTeamTypeMapping = new Map<Id, String>();

		// map of sobject id to parent account id's to be queried
		Map<Id, Id> parentAccountIdsToQuery = new Map<Id, Id>();

		for (SObject record: records.values()) {
			// get parent account reference from sobject
			Account parentAccount = (Account) record.getSObject(sharingObjectMapping.lookupRelationshipName);
			// if parent account reference in sobject is available check if 'SalesTeamType__c' field is set.
			if (parentAccount != null && parentAccount.isSet(Account.SalesTeamType__c)) {
				// 'SalesTeamType__c' is set on the account reference. populate the sales team type mapping with this.
				salesTeamTypeMapping.put(record.Id, String.valueOf(parentAccount.get(Account.SalesTeamType__c)));
			} else if (record.get(sharingObjectMapping.lookupField) != null) {
				// parent account reference is not populated OR 'SalesTeamType__c' is not set on parent account reference
				// parent account id (lookup field) is populated - add this to the set of parent accounts to be queried.
				parentAccountIdsToQuery.put(record.Id, (Id) record.get(sharingObjectMapping.lookupField));
			}
		}

		if (!parentAccountIdsToQuery.isEmpty()) {
			// found parent account ids to be queried. query parent accounts for 'SalesTeamType__c'.
			Map<Id, Account> parentAccountsQueried = BusinessAccountsSelector.newInstance(0, new Set<SObjectField>{Account.SalesTeamType__c}).selectById(new Set<Id>(parentAccountIdsToQuery.values()));
			for (Id recordId: parentAccountIdsToQuery.keySet()) {
				Id parentAccountId = parentAccountIdsToQuery.get(recordId);
				// populate sales team type mapping with queried SalesTeamType values
				salesTeamTypeMapping.put(recordId, (String) parentAccountsQueried.get(parentAccountId)?.get(Account.SalesTeamType__c));
			}
		}

		return salesTeamTypeMapping;
	}

	/**
	 * Calculate the sharing entries required as per current 'SalesTeamType' configured on parent account. Note that this
	 * method computes the required sharing entries without taking into account any existing entries.
	 *
	 * IMPORTANT - returned <SObject>Share records are indexed by a unique key to make it easier to compare with existing
	 * <SObject>Shares.Unique key is derived from ParentId (SObject Id) + UserOrGroupId + AccessLevel.
	 *
	 * @param records SObject records for which sharing has to be computed
	 * @param sharingObjectMapping Sharing configuration for calculating required sharing
	 *
	 * @return Map of <SObject>Share records indexed by a unique key. Unique key is derived from SObjectId + GroupId + AccessLevel.
	 */
	private Map<String, SObject> computeRequiredSharingEntries(Map<Id, SObject> records, SalesSharingObjectMapping sharingObjectMapping) {
		Map<String, SObject> recordShares = new Map<String, SObject>();

		// generate a mapping of record id to sales team type for each record
		Map<Id, String> salesTeamTypeMappings = getSalesTeamTypeMapping(records, sharingObjectMapping);

		Map<String, List<Id>> excludedRecordsBySalesTeamType = new Map<String, List<Id>>();

		for (Id recordId: salesTeamTypeMappings.keySet()) {

			// sales team type as configured in parent account
			String  salesTeamType = salesTeamTypeMappings.get(recordId);

			// retrieve sharing groups configured for sales team type
			List<SalesSharingGroupMapping> sharingGroups = sharingObjectMapping.getGroupMappings(salesTeamType);

			if (sharingGroups.isEmpty()) {
				// no sharing groups found for sales team type. add to excluded records log and continue to next record.
				addToExcludedRecordsLog(excludedRecordsBySalesTeamType, salesTeamType, recordId);
				continue;
			}

			for (SalesSharingGroupMapping sharingGroup: sharingObjectMapping.getGroupMappings(salesTeamType)) {
				SObject share = sharingObjectMapping.shareObjectType.newSObject();
				share.put('ParentId', recordId);
				share.put('RowCause', sharingObjectMapping.sharingReason);
				share.put('AccessLevel', sharingGroup.accessLevel);
				share.put('UserOrGroupId',  sharingGroup.groupId);
				recordShares.put(getShareRecordKey(share), share);
			}
		}

		// log any excluded records
		if (!excludedRecordsBySalesTeamType.isEmpty()) {
			logExcludedRecords(excludedRecordsBySalesTeamType);
		}

		return recordShares;
	}

	/**
	 * Query existing entries in share table for the sobjects in the collection. Only share table entries created by
	 * sales team sharing service is returned (filtered by apex sharing reason).
	 *
	 * @param recordIds sobject records to query existing sharing entries
	 * @param mapping configuration applicable for the SObjectType of the records passed in
	 *
	 * @return existing share records
	 */
	private Map<String, SObject> getExistingSharingEntries(Set<Id> recordIds, SalesSharingObjectMapping mapping) {

		// query existing shares for the records passed in having the sharing reason specified.
		List<SObject> existingShares = SObjectSharesSelector.newInstance(mapping.shareObjectType).selectByParentIdAndRowCause(
				recordIds, new Set<String>{mapping.sharingReason}
		);

		// construct into a map using a key to make it easier to compare with the required sharing entries to compute
		// the balance.
		Map<String, SObject> result = new Map<String, SObject>();
		for (SObject share: existingShares) {
			result.put(getShareRecordKey(share), share);
		}
		return result;
	}

	/**
	 * Recalculate sharing for child records of the specified SObjectType for the accounts passed in. This is to be
	 * used when child record counts on a given account exceeds the limit in total.
	 *
	 * @param parentAccountIds parent account ids of child records where sharing is to be recalculated/
	 * @param sobjectType child sobject type to recalculate sharing
	 */
	 public void recalculateChildRecordSharing(Set<Id> parentAccountIds, SObjectType sobjectType) {

		 if (!isSalesTeamSharingEnabled(new Set<SObjectType>{sobjectType})) {
			 return; // feature is disabled. nothing to do.
		 }

		ApplicationUnitOfWork uow = newUnitOfWork(new Set<SObjectType>{sobjectType});

		// retrieve sharing configuration for the specified sobject type
		SalesRecordSharingService.SalesSharingObjectMapping sharingObjectMapping = getSharingConfiguration(sobjectType);

		if (sharingObjectMapping != null) {
			Map<SObjectType,SalesSharingObjectMapping> mappings = new Map<SObjectType,SalesSharingObjectMapping>{sobjectType => sharingObjectMapping};
			Map<Id, Account> parentAccountsWithRelatedRecords = selectParentAccountsWithChildRecords(parentAccountIds, mappings);
			doShareChildRecords(parentAccountsWithRelatedRecords, mappings, uow);
		}

		// commit unit of work at the end.
		uow.commitWork();
	}

	private void doShareChildRecords(Map<Id, Account> parentAccountsWithRelatedRecords, Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMappings, ApplicationUnitOfWork uow) {
		Map<SObjectType, List<SObject>> sharableRecords = getChildRecords(parentAccountsWithRelatedRecords, sharingObjectMappings);

		for (SObjectType objectType: sharableRecords.keySet()) {
			if (!sharableRecords.get(objectType).isEmpty()) {
				shareRecords(objectType, new Map<Id,SObject>(sharableRecords.get(objectType)), true, uow);
			}
		}
	}

	private Integer countChildRecords(Account parentAccount, Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMappings, Map<SObjectType, Integer> childSObjectRecordCounts) {

		Integer totalCount = 0;

		for (SalesRecordSharingService.SalesSharingObjectMapping sharingObjectMapping: sharingObjectMappings.values()) {
			String childRelationShipName = accountChildRelationshipNameMapping.get(String.valueOf(sharingObjectMapping.objectType));
			if (childRelationShipName != null && parentAccount.getSObjects(childRelationShipName) != null) {
				Integer recordCount = parentAccount.getSObjects(childRelationShipName).size();
				if (recordCount > 0) {
					childSObjectRecordCounts.put(sharingObjectMapping.objectType, recordCount);
					totalCount += recordCount;
				}
			}
		}

		return totalCount;
	}

	private Map<SObjectType, List<SObject>> getChildRecords(Map<Id, Account> parentAccountsWithRelatedRecords, Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMappings){
		Map<SObjectType, List<SObject>> results = new Map<SObjectType, List<SObject>>();

		for (Account parentAccount: parentAccountsWithRelatedRecords.values()) {
			for (SalesRecordSharingService.SalesSharingObjectMapping sharingObjectMapping: sharingObjectMappings.values()) {
				String childRelationShipName = accountChildRelationshipNameMapping.get(String.valueOf(sharingObjectMapping.objectType));
				if (childRelationShipName != null && parentAccount.getSObjects(childRelationShipName) != null) {
					if (!results.containsKey(sharingObjectMapping.objectType)) {
						results.put(sharingObjectMapping.objectType, new List<SObject>());
					}
					for (SObject relatedObject: parentAccount.getSObjects(childRelationShipName)) {
						relatedObject.putSObject(sharingObjectMapping.lookupRelationshipName, new Account(Id=parentAccount.Id, SalesTeamType__c=parentAccount.SalesTeamType__c));
						results.get(sharingObjectMapping.objectType).add(relatedObject);
					}
				}
			}
		}

		return results;
	}

	private Map<Id, Account> selectParentAccountsWithChildRecords(Set<Id> parentAccountIds, Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMappings) {
		Map<SObjectType, String> childRelationships = new Map<SObjectType, String>();
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>> {
				Account.getSObjectType() => new Set<SObjectField>{Account.Id, Account.SalesTeamType__c, Account.Sales_Segment__c}
		};

		for (SalesSharingObjectMapping mapping: sharingObjectMappings.values()) {
			childRelationships.put(mapping.objectType, accountChildRelationshipNameMapping.get(String.valueOf(mapping.objectType)));
			fieldOverrides.put(mapping.objectType, new Set<SObjectField>{mapping.lookupField});
		}

		return new Map<Id, Account>(BusinessAccountsSelector.newInstance(0, fieldOverrides).selectByIdWithChildRecords(parentAccountIds, childRelationships));
	}

	/**
	 * Returns a key for the share record that can be used to compare existing shares with required shares.
	 * @param share SObject record from a 'Share' table
	 *
	 * @return sharing record key
	 */
	private String getShareRecordKey(SObject share) {
		return String.valueOf(share.get('ParentId')) + String.valueOf(share.get('UserOrGroupId')) + String.valueOf(share.get('AccessLevel'));
	}

	/**
	 * Unit of work that encapsulates the specified sobject types.
	 *
	 * @return unit or work instance
	 */
	private ApplicationUnitOfWork newUnitOfWork(Set<SObjectType> sObjectTypes) {
		List<SObjectType> shareObjectTypes = new List<SObjectType>();
		for (SObjectType sObjectType: sObjectTypes) {
			SalesSharingObjectMapping mapping = getSharingConfiguration(sObjectType);
			shareObjectTypes.add(mapping.shareObjectType);
		}

		return ApplicationUnitOfWork.newInstance(shareObjectTypes);
	}

	/**
	 * Unit of work that encapsulates all the required objects for this Service.
	 *
	 * @return unit or work instance
	 */
	private ApplicationUnitOfWork newUnitOfWork() {
		return newUnitOfWork(getSharingConfiguration().keySet());
	}

	/**
	 * Add to the collection of excluded records. This is to ensure excluded records can be logged (in bulk) at the end
	 * of processing.
	 *
	 * @param excludedRecordsBySalesTeamType excluded records collected so far
	 * @param salesTeamType  Sales Team Type
	 * @param recordId Id of the record excluded
	 */
	private void addToExcludedRecordsLog(Map<String, List<Id>> excludedRecordsBySalesTeamType, String salesTeamType, Id recordId) {
		if (!excludedRecordsBySalesTeamType.containsKey(salesTeamType)) {
			excludedRecordsBySalesTeamType.put(salesTeamType, new List<Id>());
		}
		excludedRecordsBySalesTeamType.get(salesTeamType).add(recordId);
	}

	/**
	 * Generate log entries from the excluded records collected while processing.
	 *
	 * @param excludedRecordsBySalesTeamType excluded records to generate log entries.
	 */
	private void logExcludedRecords(Map<String, List<Id>> excludedRecordsBySalesTeamType) {

		List<String> messages = new List<String>();
		List<String> additionalInfo = new List<String>();

		for (String salesTeamType: excludedRecordsBySalesTeamType.keySet()) {
			List<Id> ignoredRecordIds = excludedRecordsBySalesTeamType.get(salesTeamType);
			SObjectType objectType = ignoredRecordIds[0].getSobjectType();
			messages.add('No sharing groups are configured for Sales Team Type [' + salesTeamType + ']. Ignoring [' + objectType + '] records.');
			additionalInfo.add('Ignored records : ' + ignoredRecordIds.toString());
		}

		ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'Sales', SalesRecordSharingService.class.getName(), 'computeRequiredSharingEntries', '', ApplicationLogger.LoggingLevel.ERROR);
	}

	private Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> getSharingConfiguration() {

		Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping> sharingObjectMapping = new Map<SObjectType, SalesRecordSharingService.SalesSharingObjectMapping>();


		for (String objectAPIName: salesSharingMetadata.keySet()) {
			SObjectType sObjectType = ((SObject)Type.forName(objectAPIName).newInstance()).getSObjectType();
			sharingObjectMapping.put(sObjectType, getSharingConfiguration(sObjectType));
		}

		return sharingObjectMapping;
	}

	/**
	 * Check if Sales record sharing feature is enabled / disabled. Supports enable / disable of the feature through
	 * configuration in ApplicationFeature__c custom setting. Feature can be enabled / disabled globally for all
	 * sobject types OR selectively for specific sobject types.
	 *
	 * @param sobjectTypes check feature is enabled for all of the sobject types supplied
	 *
	 * @return false if feature is disable globally or disabled for at least one of the sobject types specified. true otherwise.
	 */
	private Boolean isSalesTeamSharingEnabled(Set<SObjectType> sobjectTypes) {

		// check if Sales record sharing feature is enabled globally.
		Boolean isActive = ApplicationFeatures.getInstance().isFeatureActive(SALES_RECORD_SHARING_FEATURE_NAME);

		// if the feature is Active globally, next check the status for specified sobject types one at a time.
		if (isActive && sobjectTypes != null && !sobjectTypes.isEmpty()) {
			for (SObjectType sobjectType: sobjectTypes) {
				isActive = isActive && ApplicationFeatures.getInstance().isFeatureActive(SALES_RECORD_SHARING_FEATURE_NAME + '_' + sobjectType);
			}
		}

		return isActive;
	}

	/**
	 * Queueable class to recalculate sharing of child records related to the account id's passed in.
	 * Supports specifying account ids together with a list of SObjectTypes where sharing recalculation is attempted
	 * for each sobject type in separate queueable contexts.
	 */
	public without sharing class SalesAccountChildRecordsSharingHandlerQueueable implements Queueable {

		// account ids to recalculate sharing of child records.
		@TestVisible private Set<Id> accountIds;
		// account ids to attempt sharing recalculation separately per each sobject type (due to volume)
		@TestVisible private Map<Id, List<SObjectType>> accountIdsForPartialProcessing;

		public SalesAccountChildRecordsSharingHandlerQueueable(Set<Id> accountIds) {
			this.accountIds = accountIds;
			this.accountIdsForPartialProcessing = new Map<Id, List<SObjectType>>();
		}

		@TestVisible private SalesAccountChildRecordsSharingHandlerQueueable(Set<Id> accountIds, Map<Id, List<SObjectType>> accountIdsForPartialProcessing) {
			this.accountIds = accountIds;
			this.accountIdsForPartialProcessing = accountIdsForPartialProcessing;
		}

		public void execute(QueueableContext ctx) {
			Application.Profiler.start('SalesAccountChildRecordsSharingHandlerQueueable.execute');

			if (this.accountIds != null && !this.accountIds.isEmpty()) {
				// TODO consider chunking account ids
				List<AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(this.accountIds.clone());

				// go through the results and check if everything is processed.
				Map<Id, List<SObjectType>> accountsForPartialProcessing = new Map<Id, List<SObjectType>>();
				for (AccountChildRecordsSharingRecalculationResult result: results) {
					if (result.processed) {
						// account has been processed, remove it from accounts to be processed.
						this.accountIds.remove(result.accountId);
					} else if (result.retryInPartialMode) {
						// account has been attempted but not processed. this is due to child record volumes.
						// remove it from account id's collection and mark it for partial processing on retry
						this.accountIds.remove(result.accountId);
						List<SObjectType> validSobjectTypesForPartialProcessing = validateRelatedRecordVolumesForPartialProcessing(result.unprocessedChildSObjectTypes);
						accountsForPartialProcessing.put(result.accountId, validSobjectTypesForPartialProcessing);
					}
				}

				if (!accountsForPartialProcessing.isEmpty()) {
					this.accountIdsForPartialProcessing.putAll(accountsForPartialProcessing);
				}

			} else if (accountIdsForPartialProcessing != null && !accountIdsForPartialProcessing.isEmpty()) {
				// we have accounts that has been attempted previously and marked for partial processing per sobject type.
				// these need to be processed one sobject type per each account.
				// get first record in the collection.
				Id parentAccountId = accountIdsForPartialProcessing.keySet().iterator().next();
				if (accountIdsForPartialProcessing.get(parentAccountId).size() > 0) {
					// attempt to process one sobject type for this account. rest will be enqueued into a another chained queueable
					// instance at the end.
					SObjectType objectType = accountIdsForPartialProcessing.get(parentAccountId).remove(0);
					SalesRecordSharingService.getInstance().recalculateChildRecordSharing(new Set<Id>{parentAccountId}, objectType);

					// check if we have processed all sobject types for this account. if so remove the account as it has now been
					// processed in full.
					if (accountIdsForPartialProcessing.get(parentAccountId).isEmpty()) {
						accountIdsForPartialProcessing.remove(parentAccountId);
					}
				}
			}

			if ((this.accountIds != null && !this.accountIds.isEmpty()) || (this.accountIdsForPartialProcessing != null && !this.accountIdsForPartialProcessing.isEmpty())) {
				// we got more to process. enqueue another queueable.
				ApplicationDatabase.getInstance().enqueueJob(new SalesAccountChildRecordsSharingHandlerQueueable(this.accountIds, this.accountIdsForPartialProcessing));
			}
			Application.Profiler.stop('SalesAccountChildRecordsSharingHandlerQueueable.execute');			
		}

		private List<SObjectType> validateRelatedRecordVolumesForPartialProcessing(Map<SObjectType, Integer> childRecordCount) {
			List<SObjectType> sobjectTypesForPartialProcessing = new List<SObjectType>();
			for (SObjectType sobjectType: childRecordCount.keySet()) {
				if (childRecordCount.get(sobjectType) <= MAX_ACC_MOVEMENT_RELATED_RECORD_SIZE_PER_TRANSACTION) {
					sobjectTypesForPartialProcessing.add(sobjectType);
				}
			}
			return sobjectTypesForPartialProcessing;
		}
	}

	// exception thrown by the service
	public class SalesRecordSharingException extends Exception {}

	/**
	 * Holds sharing configuration for a single SObjectType supported by this service and sharing group mappings for
	 * that SObjectType. Sharing groups are created for sales team type / public group combinations.
	 * Based on the configuration held in custom metadata. Translated into a form that can be used by the service and it's
	 * clients.
	 */
	public class SalesSharingObjectMapping {
		public SObjectType objectType {get; private set;}
		public SObjectField lookupField {get; private set;}
		public String lookupRelationshipName {get; private set;}
		@TestVisible private String sharingReason {get; set;}
		@TestVisible private SObjectType shareObjectType {get; set;}
		// list of sharing group mappings for this sobject.
		@TestVisible private List<SalesSharingGroupMapping> groupMappings {get;set;}

		@TestVisible private SalesSharingObjectMapping(SObjectType objectType, SObjectField lookupField, String lookupRelationshipName, String sharingReason) {
			this.objectType = objectType;
			this.lookupField = lookupField;
			this.lookupRelationshipName = lookupRelationshipName;
			this.sharingReason = sharingReason;
			this.groupMappings = new List<SalesSharingGroupMapping>();
			this.shareObjectType = getShareObjectForSObject(objectType);
		}

		/**
		 * Adds a sharing group for this custom object
		 *
		 * @param groupMapping details of the sharing group such as sales team, access level and the public group name to provide access.
		 */
		private void addGroupMapping(SalesSharingGroupMapping groupMapping) {
			this.groupMappings.add(groupMapping);
		}

		/**
		 * Retrieve sharing groups applicable for a given sales team type.
		 * @param salesTeamType sales team type to retrieve groups
		 *
		 * @return list of sharing groups
		 */
		private List<SalesSharingGroupMapping> getGroupMappings(String salesTeamType) {
			List<SalesSharingGroupMapping> result = new List<SalesSharingGroupMapping>();

			for (SalesSharingGroupMapping groupMapping: this.groupMappings) {
				if (groupMapping.salesTeamType.equalsIgnoreCase(salesTeamType)) {
					result.add(groupMapping);
				}
			}

			return result;
		}

		/**
		 * Return the Share object type (e.g. XYZ__Share, XYZShare) for specified sobject
		 * @param sobjectType sobject type such as XYZ__c, XYZ
		 *
		 * @return SObject Type of the Share object (e.g. XYZ__Share, XYZShare).
		 */
		private SObjectType getShareObjectForSObject(SObjectType sobjectType) {
			String qualifiedApiName = String.valueOf(sobjectType);
			// derive share object API name from qualified api name of sobject.
			String shareObjectApiName = (qualifiedApiName.endsWith('__c') ?  qualifiedApiName.replace('__c' , '__Share') : (qualifiedApiName + 'Share'));

			Type t = Type.forName(shareObjectApiName);
			// check if the Share object type exists. Objects on the detail side of a master-detail relationship do not
			// have an associated sharing object.
			if (t == null) {
				String message = 'Share object [' + shareObjectApiName + '] does not exist for SObjectType [' + sobjectType + ']. Please review sharing model for this SObjectType.';
				throw new SalesRecordSharingException(message);
			}
			return ((SObject) t.newInstance()).getSObjectType();
		}
	}

	/**
	 * Holds configuration of a sharing group for a given sobject tye. Sharing groups are created for sales team type / public group combinations.
	 * Based on the configuration held in custom metadata. Translated into a form that can be used by the service and it's
	 * clients.
	 */
	private class SalesSharingGroupMapping {

		private String salesTeamType {get; set;}
		private String groupName {get; set;}
		private Id groupId {get; set;}
		private String accessLevel {get; set;}

		private SalesSharingGroupMapping(String salesTeamType, Id groupId, String groupName, String accessLevel) {
			this.salesTeamType = salesTeamType;
			this.groupId = groupId;
			this.groupName = groupName;
			this.accessLevel = accessLevel;
		}
	}

	public class AccountChildRecordsSharingRecalculationResult {
		public Id accountId {get; private set;}
		public Boolean processed {get; private set;}
		public Boolean retryInPartialMode {get; private set;}
		public Map<SObjectType, Integer> unprocessedChildSObjectTypes {get; private set;}
		public String salesTeamType {get; private set;}

		@TestVisible private AccountChildRecordsSharingRecalculationResult(Id accountId, String salesTeamType, Boolean processed, Boolean retryInPartialMode, Map<SObjectType, Integer> unprocessedSObjectTypes) {
			this.accountId = accountId;
			this.salesTeamType = salesTeamType;
			this.processed = processed;
			this.retryInPartialMode = retryInPartialMode;
			this.unprocessedChildSObjectTypes = unprocessedSObjectTypes;
		}
	}
}