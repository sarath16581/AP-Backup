/***
 * @description
 *      Parse ApiEventAnalysis__c record and build a running tab of all the incoming query integrations coming into Salesforce
 *
 * @author Nathan Franklin
 * @date 2021-03-01
 * @group Integration
 * @changelog
 */
global inherited sharing class IntegrationInboundApiLoggingBatch implements Database.Batchable<sObject>, Database.Stateful {

	private static final Integer MAX_USER_AGENT_LENGTH = 150;

	// TODO
	// Build this into a custom setting / metadata

	// included profiles to monitor (usually just integration profiles)
	private static Set<Id> includedProfileIds = new Set<Id>{'00e90000002FH2P', '00e90000000ip2I', '00e90000000inKp', '00e90000002FGvV', '00e90000001yQOA'};

	// include specific users regardless of their profile
	private static Set<Id> includedUserIds = new Set<Id>{'0059000000Pibe2'};

	// override to exclude any users regardless of their profile assignment
	private static Set<Id> excludedUserIds = new Set<Id>();

	private static final Set<SObjectField> INTEGRATION_KEY_FIELDS = new Set<SObjectField>{
			ApiEventAnalysis__c.User__c, ApiEventAnalysis__c.QueriedEntities__c, ApiEventAnalysis__c.ApiType__c, ApiEventAnalysis__c.Application__c,
			ApiEventAnalysis__c.Client__c, ApiEventAnalysis__c.Operation__c, ApiEventAnalysis__c.Platform__c
	};

	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('>> IntegrationInboundApiLoggingBatch:start');

		// grab the settings to process these records
		IntegrationApiSettings__c settings = IntegrationInboundApiLoggingService.getIntegrationApiSettings();
		Integer maxRecords = Integer.valueOf(settings.InboundQueryApiMaxRowsPerBatchJob__c);

		String query = 'SELECT ApiType__c, ApiVersion__c, Application__c, Client__c, ConnectedApp__c,\n ' +
							'ElapsedTime__c, EvaluationTime__c, EventDate__c, Id, RowsReturned__c, \n ' +
							'Operation__c, Platform__c, QueriedEntities__c, Query__c, RowsProcessed__c,\n ' +
							'SourceIP__c,  User__c, UserAgent__c, Username__c\n ' +
						'FROM ApiEventAnalysis__c\n' +
						'LIMIT :maxRecords\n';

		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<SObject> scope) {

//		try {

		// This is used to minimise the number of times we need to extract the same fields from the same queries
		Map<String, SoqlFieldExtractor.FieldResults> fieldExtractionCache = new Map<String, SoqlFieldExtractor.FieldResults>();

		// use these to find existing records in the SystemIntegration__c object
		// its a dodgy way to get around a maximum key size of 255 chars....
		Map<SObjectField, Set<String>> keyFields = new Map<SObjectField, Set<String>>{
				SystemIntegration__c.ApiIntegrationKey1__c => new Set<String>(),
				SystemIntegration__c.ApiIntegrationKey2__c => new Set<String>(),
				SystemIntegration__c.ApiIntegrationKey3__c => new Set<String>(),
				SystemIntegration__c.ApiIntegrationKey4__c => new Set<String>()
		};

		// we should only be processing the users as per the our configuration
		Set<Id> userIds = new Set<Id>();
		userIds.addAll(includedUserIds);
		userIds.removeAll(excludedUserIds);

		// grab the users by profile and add them to the list of user records we process
		for(User userByProfile : UsersSelector.newInstance().selectByProfileId(includedProfileIds).values()) {
			// ignore any users we need to specifically exclude from the reporting
			if(!excludedUserIds.contains(userByProfile.Id)) {
				userIds.add(userByProfile.Id);
			}
		}

		System.debug('Only processing records for the following users: ');
		System.debug(userIds);

		Set<String> objectFieldUsage = new Set<String>();
		Map<String, ParsedApiResult> parsedResults = new Map<String, ParsedApiResult>();
		for(ApiEventAnalysis__c apiRecord : (List<ApiEventAnalysis__c>)scope) {
//			try {

			// we are only processing the API events associated to the users we want to track
			if (userIds.contains(apiRecord.User__c)) {

				// this will remove all the actual literal values that exist in teh SOQL
				// this pairs the soql back as generic as it can be in the hope it allows us to match it to other individual records of the same soql
				// i'm sure that made alot of sense :S
				String summarisedSoql = summariseSoql(apiRecord.Query__c);

				// we use the objects and fields in the returned list to build a key to an existing record if one already exists
				// NOTE: This uses describe() extensively, it's cached so hopefully it doesn't cause too many performance issues
				SoqlFieldExtractor.FieldResults soqlFieldResults = fieldExtractionCache.get(summarisedSoql);
				if(soqlFieldResults == null) {
					fieldExtractionCache.put(summarisedSoql, new SoqlFieldExtractor(apiRecord.Query__c).parsedFieldUsage);
					soqlFieldResults = fieldExtractionCache.get(summarisedSoql).clone();
				} else {
					System.debug('Reusing field extraction cache.');
				}

				String integrationKey = getIntegrationMapKey(apiRecord, soqlFieldResults.fieldUsage);
				if (parsedResults.get(integrationKey) == null) {
					parsedResults.put(integrationKey, new ParsedApiResult());
				}

				// Make sure we always have 4 elements returned for the key matching
				List<String> splitKey = splitByCount(integrationKey, 255);
				Integer splitKeySize = splitKey.size();
				if (splitKeySize < 4) {
					splitKey.add('');
				}
				if (splitKeySize < 3) {
					splitKey.add('');
				}
				if (splitKeySize < 2) {
					splitKey.add('');
				}

				// store the ApiEvent parsed results so we can access them later
				ParsedApiResult result = parsedResults.get(integrationKey);
				result.dependentFieldsObjects = soqlFieldResults.fieldUsage;

				// NOTE: the name lastSoql.
				// Actual Soql's may vary but if the key matches (essential, same user/platform/object/fields etc..) then the actual soql that is run is less important
				result.lastSoql = summarisedSoql;

				result.lastEventRecord = apiRecord;

				// grab the max event date for this group
				// this is used to help determine where the next batch should kick off from
				result.maxEventDate = (result.maxEventDate == null ? apiRecord.EventDate__c : Datetime.newInstance(Math.max(apiRecord.EventDate__c.getTime(), result.maxEventDate.getTime())));

				// this is what makes up the key. we base it on a string of upto 1k split across 4 fields
				// it's big because of the field names used in the soql
				result.keyData = splitKey;

				result.addUsage(apiRecord.EventDate__c);

				// store a list of the fields used by this integration
				// we use this later on to ensure all of the Data Dictionary Field records are created
				objectFieldUsage.addAll(result.getObjectFieldsInUse());

				// these are the fields that we search the existing records with
				// it's based on a 4 key match of 255 chars.
				keyFields.get(SystemIntegration__c.ApiIntegrationKey1__c).add(splitKey[0]);
				keyFields.get(SystemIntegration__c.ApiIntegrationKey2__c).add(splitKey[1]);
				keyFields.get(SystemIntegration__c.ApiIntegrationKey3__c).add(splitKey[2]);
				keyFields.get(SystemIntegration__c.ApiIntegrationKey4__c).add(splitKey[3]);

				//			} catch(Exception ex) {
				//				// failed to parse the current ApiEvent record
				//
				//			}
			}
		}

		// TODO convert to select class
		// go through each of the parsedResults and reconcile them to records in the database
		Map<Id, SystemIntegration__c> records = new Map<Id, SystemIntegration__c>([SELECT Id, ApiIntegrationKey1__c, ApiIntegrationKey2__c, ApiIntegrationKey3__c, ApiIntegrationKey4__c,
																			(SELECT Id, Usage10AM__c, Usage10PM__c, Usage11AM__c, Usage11PM__c, Usage12AM__c,
																					Usage12PM__c, Usage1AM__c, Usage1PM__c, Usage2AM__c, Usage2PM__c,
																					Usage3AM__c, Usage3PM__c, Usage4AM__c, Usage4PM__c, Usage5AM__c,
																					Usage5PM__c, Usage6AM__c, Usage6PM__c, Usage7AM__c, Usage7PM__c,
																					Usage8AM__c, Usage8PM__c, Usage9AM__c, Usage9PM__c, UsageDate__c
																				FROM IntegrationUsage__r),

																			(SELECT Id, DataDictionaryField__c, DataDictionaryField__r.ObjectFieldKey__c
																				FROM IntegrationFieldUsage__r)
																		FROM SystemIntegration__c
																		WHERE ApiIntegrationKey1__c IN :keyFields.get(SystemIntegration__c.ApiIntegrationKey1__c)
																		AND ApiIntegrationKey2__c IN :keyFields.get(SystemIntegration__c.ApiIntegrationKey2__c)
																		AND ApiIntegrationKey3__c IN :keyFields.get(SystemIntegration__c.ApiIntegrationKey3__c)
																		AND ApiIntegrationKey4__c IN :keyFields.get(SystemIntegration__c.ApiIntegrationKey4__c)
																		AND RecordType.DeveloperName = 'InboundApi']);

		// build an list of the existing records which will be used to merge the usage from this batch run into
		// this will utilise a 4 key structure in order to link existing records
		Map<String, SystemIntegration__c> integrationRecordMap = new Map<String, SystemIntegration__c>();
		for(SystemIntegration__c record : records.values()) {

			// we only want to sequentially build the key. If the key2 is missing but key3 is not, then we shouldn't just skip key2, instead we treat the record as invalid and we will not use it
			if(!String.isEmpty(record.ApiIntegrationKey4__c) && (String.isEmpty(record.ApiIntegrationKey3__c) || String.isEmpty(record.ApiIntegrationKey2__c) || String.isEmpty(record.ApiIntegrationKey1__c))) {
				// ignore the record because it's key structure is invalid
				continue;
			} else if(!String.isEmpty(record.ApiIntegrationKey3__c) && (String.isEmpty(record.ApiIntegrationKey2__c) || String.isEmpty(record.ApiIntegrationKey1__c))) {
				// ignore the record because it's key structure is invalid
				continue;
			} else if(!String.isEmpty(record.ApiIntegrationKey2__c) && String.isEmpty(record.ApiIntegrationKey1__c)) {
				// ignore the record because it's key structure is invalid
				continue;
			} else if(String.isEmpty(record.ApiIntegrationKey1__c)) {
				// ignore the record because it's key structure is invalid
				continue;
			}

			String key = '';
			for(SObjectField keyField : keyFields.keySet()) {
				if (!String.isEmpty(String.valueOf(record.get(keyField)))) {
					key += record.get(keyField);
				} else {
					// don't continue since we found an empty value in the key field sequence
					break;
				}
			}

			integrationRecordMap.put(key, record);
		}

		Id inboundApiRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SystemIntegration__c', new Set<String>{'InboundApi'}).values()[0].Id;

		// create or update the existing records in SystemIntegration__c
		// this is based on the 4 key structure
		List<SystemIntegration__c> updateableIntegreationRecords = new List<SystemIntegration__c>();
		List<SystemIntegration__c> insertableIntegrationRecords = new List<SystemIntegration__c>();
		for(String parsedResultsKey : parsedResults.keySet()) {
			SystemIntegration__c updateableRecord = new SystemIntegration__c();

			String userAgent = parsedResults.get(parsedResultsKey).lastEventRecord.UserAgent__c;
			if(String.isEmpty(userAgent)) userAgent = '';
			userAgent = userAgent.left(MAX_USER_AGENT_LENGTH);

			// add the values to the integration record
			updateableRecord.RecordTypeId = inboundApiRecordTypeId;
			updateableRecord.OperationType__c = parsedResults.get(parsedResultsKey).lastEventRecord.Operation__c;
			updateableRecord.ApiPlatform__c = parsedResults.get(parsedResultsKey).lastEventRecord.Platform__c;
			updateableRecord.ApiType__c = parsedResults.get(parsedResultsKey).lastEventRecord.ApiType__c;
			updateableRecord.ApiVersion__c = parsedResults.get(parsedResultsKey).lastEventRecord.ApiVersion__c.toPlainString();
			updateableRecord.UserClient__c = userAgent;
			updateableRecord.SimplifiedQuery__c = parsedResults.get(parsedResultsKey).lastSoql; // <-- note lastSoql... soql could potentially be different. it's just the fields that are used the are considered in the key
			updateableRecord.QueriedEntities__c = parsedResults.get(parsedResultsKey).lastEventRecord.QueriedEntities__c;
			updateableRecord.IntegrationOwner__c = parsedResults.get(parsedResultsKey).lastEventRecord.User__c;

			// apply the key based on the merged data
			updateableRecord.ApiIntegrationKey1__c = parsedResults.get(parsedResultsKey).keyData[0];
			updateableRecord.ApiIntegrationKey2__c = parsedResults.get(parsedResultsKey).keyData[1];
			updateableRecord.ApiIntegrationKey3__c = parsedResults.get(parsedResultsKey).keyData[2];
			updateableRecord.ApiIntegrationKey4__c = parsedResults.get(parsedResultsKey).keyData[3];

			if(integrationRecordMap.get(parsedResultsKey) != null) {
				// integration record exists
				updateableRecord.Id = integrationRecordMap.get(parsedResultsKey).Id;
				updateableIntegreationRecords.add(updateableRecord);
			} else {
				insertableIntegrationRecords.add(updateableRecord);
			}

			// store a reference to the record in the parsedResults so we can get the ID if we are inserting it
			parsedResults.get(parsedResultsKey).integrationRecord = updateableRecord;
		}

		if(!insertableIntegrationRecords.isEmpty()) {
			ApplicationDatabase.getInstance().dmlInsert(insertableIntegrationRecords);
		}

		if(!updateableIntegreationRecords.isEmpty()) {
			ApplicationDatabase.getInstance().dmlUpdate(updateableIntegreationRecords);
		}

		// update the integration usage
		// this is the number of usages per day within specific hourly blocks
		// this batch run will be merged into what is already existing in the database
		List<SystemIntegrationUsage__c> upsertableIntegrationUsage = new List<SystemIntegrationUsage__c>();
		for(String parsedResultsKey : parsedResults.keySet()) {
			Id integrationRecordId = parsedResults.get(parsedResultsKey).integrationRecord.Id;

			// merge the new usage into the existing usage
			// NOTE: we grab the child records based on the query that was run above (we don't get them from .integrationRecord since that will only contain the integration record itself)
			List<SystemIntegrationUsage__c> usageRecords = parsedResults.get(parsedResultsKey).mergeUsage((records.get(integrationRecordId) == null ? new List<SystemIntegrationUsage__c>() : records.get(integrationRecordId).IntegrationUsage__r));
			upsertableIntegrationUsage.addAll(usageRecords);
		}

		// update/insert all of the usages that appeared in this run
		ApplicationDatabase.getInstance().dmlUpsert(upsertableIntegrationUsage);

		// make sure all the data dictionary field records have been created
		// we do this because the Field Usage that we calculate below is linked to the Data Dictionary records
		// does a DML operation!
		ensureDataDictionaryFieldRecordsCreated(objectFieldUsage);

		// update the field usage records
		// we do this be comparing the field usage records that already exist and the ones that appeared in the parsed results
		// in theory, inserts should only happen once without any other inserts happening in subsequent batches
		// the fieldnames make up part of the key which means if more or less fields are present, it should end up as a new integration record
		// nevertheless, we build this to accommodate a scenario where new fields may appear
		List<SystemIntegrationFieldUsage__c> insertableFieldUsageRecords = new List<SystemIntegrationFieldUsage__c>();
		for(String parsedResultsKey : parsedResults.keySet()) {
			ParsedApiResult parsedResult = parsedResults.get(parsedResultsKey);

			Id integrationRecordId = parsedResult.integrationRecord.Id;

			// pull the current field usage from the preselected data above
			// NOTE: this is not grabbed from .integrationRecord since that reference contains the recent updated record only
			List<SystemIntegrationFieldUsage__c> fieldUsage = (records.get(integrationRecordId) == null ? new List<SystemIntegrationFieldUsage__c>() : records.get(integrationRecordId).IntegrationFieldUsage__r);

			// populate a map of the existing records by Object.Field data
			// this makes it easy to utilise for linking the fields used in this integration
			Map<String, SystemIntegrationFieldUsage__c> integrationFieldUsageMappings = new Map<String, SystemIntegrationFieldUsage__c>();
			for(SystemIntegrationFieldUsage__c fieldUsageRecord : fieldUsage) {

				// we dont process record with empty data dictionary field data
				if(fieldUsageRecord.DataDictionaryField__c == null || String.isEmpty(fieldUsageRecord.DataDictionaryField__r.ObjectFieldKey__c)) {
					continue;
				}

				integrationFieldUsageMappings.put(fieldUsageRecord.DataDictionaryField__r.ObjectFieldKey__c.toLowerCase(), fieldUsageRecord);
			}

			// work out which object field records in use need to be created
			Set<String> parsedObjectFieldsInUse = parsedResult.getObjectFieldsInUse();
			for(String objectFieldInUse : parsedObjectFieldsInUse) {
				if(integrationFieldUsageMappings.get(objectFieldInUse) == null) {
					// we need to insert a field usage record since one does not exist
					insertableFieldUsageRecords.add(new SystemIntegrationFieldUsage__c(Integration__c = integrationRecordId, DataDictionaryField__r = new Data_Dictionary_Field__c(ObjectFieldKey__c = objectFieldInUse)));
				}
			}
		}

		if(!insertableFieldUsageRecords.isEmpty()) {
			ApplicationDatabase.getInstance().dmlInsert(insertableFieldUsageRecords);
		}

		// delete the records from the analysis object we have just processed
		// since these are coming from an audit bigobject, there is no need to retain them after we have finished with them
		//ApplicationDatabase.getInstance().dmlDelete(scope);

//		} catch(Exception exp) {
//			// Error Logged to Exception object for analysis
//			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 'StatusTrackingRollup_Batchable', 'execute', null, LoggingLevel.ERROR);
//		}
	}

	global void finish(Database.BatchableContext BC) {
		System.debug('>> IntegrationInboundApiLoggingBatch:finish');

		// we need to check whether there is more work to be done
		// the async soql that is fired will only capture a certain amount of data (often will be less than a day)
		// this means that the async-soql will usually need

	}

	/**
	 * This method will remove all the literal values and reduce the SOQL down to a summarised value that can be used for grouping together
	 */
	public static String summariseSoql(String soql) {
		Map<String, String> replacementPatterns = new Map<String, String>();

		replacementPatterns.put('(?ism)\'.*?(?<!\\\\)\'', ':param'); // literal values 'eoirfhoeirhf', 'efwef\'wefwef' etc..
		replacementPatterns.put('(?ism)\\b(true|false)\\b', ':param'); // literal values true false
		replacementPatterns.put('(?ism)(?:(\\(|,)\\s*null\\b)', '$1 null'); // literal value either ( or , and null (This is used for IN clauses where NULL is present)
		replacementPatterns.put('(?ism)\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{1,10})?Z', ':param'); // datetime
		replacementPatterns.put('(?ism)\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{1,10})?\\+\\d{1,2}:\\d{1,2}', ':param'); // datetime
		replacementPatterns.put('(?ism)\\d{4}-\\d{2}-\\d{2}', ':param'); // date
		replacementPatterns.put('(?ism)\\s*?=\\s*?null\\b', '= :param'); // literal value null
		replacementPatterns.put('(?ism)\\b\\d{1,100}\\b', ':param'); // literal values 32423423 23423432 etc...
		replacementPatterns.put('(?ism)\\b(YESTERDAY|TODAY|TOMORROW|LAST_WEEK|THIS_WEEK|NEXT_WEEK|LAST_MONTH|THIS_MONTH|NEXT_MONTH|LAST_90_DAYS|NEXT_90_DAYS|THIS_QUARTER|LAST_QUARTER|NEXT_QUARTER|THIS_YEAR|LAST_YEAR|NEXT_YEAR|THIS_FISCAL_QUARTER|LAST_FISCAL_QUARTER|NEXT_FISCAL_QUARTER|THIS_FISCAL_YEAR|LAST_FISCAL_YEAR|NEXT_FISCAL_YEAR)\\b', ':param'); // last_n_days
		replacementPatterns.put('(?ism)\\b(LAST_N_DAYS|NEXT_N_DAYS|NEXT_N_WEEKS|LAST_N_WEEKS|NEXT_N_MONTHS|LAST_N_MONTHS|NEXT_N_QUARTERS|LAST_N_QUARTERS|NEXT_N_YEARS|LAST_N_YEARS|NEXT_N_FISCAL_QUARTERS|LAST_N_FISCAL_QUARTERS|NEXT_N_FISCAL_YEARS|LAST_N_FISCAL_YEARS):\\d{1,100}', ':param');
		replacementPatterns.put('(?ism)\\((?:\\s*?:param\\s*?(?:,)?)+?\\)', ':params'); // literal values (:param) (:param,:param, :param ,:param ,:param, :param) etc..
		replacementPatterns.put('(?ism)\\s{2,50}', ' '); // reducing number of spaces

		for(String pattern : replacementPatterns.keySet()) {
			soql = soql.replaceAll(pattern, replacementPatterns.get(pattern));
		}

		return soql;
	}

	private String getIntegrationMapKey(ApiEventAnalysis__c record, Map<String, Set<String>> dependentFields) {
		String key = '';

		for(SObjectField field : INTEGRATION_KEY_FIELDS) {
			if(!String.isEmpty(String.valueOf(record.get(field)))) {
				String value = String.valueOf(record.get(field));

				// set max length of user agent
				if(field == ApiEventAnalysis__c.UserAgent__c) {
					value = value.left(MAX_USER_AGENT_LENGTH);
				}

				key += (!String.isEmpty(key) ? '|' : '') + value;
			}
		}

		for(String objectName : dependentFields.keySet()) {
			key += (!String.isEmpty(key) ? '|' : '') + objectName + ':';
			key += String.join(new List<String>(dependentFields.get(objectName)), ',');
		}

		return key;
	}

	private List<String> splitByCount(String input, Integer charLimit) {
		//System.assert(false, integrationKey.split('.{1,255}')); <-- blerg
		List<String> output = new List<String>();
		while(!String.isEmpty(input)) {
			Integer length = input.length();
			output.add(input.left(charLimit));
			input = input.substring(Math.min(charLimit, length));
		}

		// make sure at least 1 element exists in the return to mimic how other platforms/languages handle split capability
		if(output.isEmpty()) {
			output.add('');
		}
		return output;
	}

	/**
	 * Ensures that all Data Dictionary Field records are created since they are need to link to the field usage of an integration
	 * This will allow us simply use the external id when creating/updating field usage records
	 */
	private void ensureDataDictionaryFieldRecordsCreated(Set<String> objectFieldsUsed) {

		// TODO convert to selector class
		Map<String, Id> dataDictionaryFieldRecords = new Map<String, Id>();
		for(Data_Dictionary_Field__c fieldRecord : [SELECT Id, ObjectFieldKey__c
														FROM Data_Dictionary_Field__c
														WHERE ObjectFieldKey__c IN :objectFieldsUsed]) {
			dataDictionaryFieldRecords.put(fieldRecord.ObjectFieldKey__c, fieldRecord.Id);
		}

		List<Data_Dictionary_Field__c> insertable = new List<Data_Dictionary_Field__c>();

		for(String field : objectFieldsUsed) {
			System.debug('field: ' + field);
		}

		for(String objectField : objectFieldsUsed) {
			if(dataDictionaryFieldRecords.get(objectField) == null) {
				List<String> fieldParts = objectField.split('\\.');
				insertable.add(new Data_Dictionary_Field__c(Object_API_Name__c = fieldParts[0], Field_API_Name__c = fieldParts[1], ObjectFieldKey__c = objectField));
			}
		}

		if(!insertable.isEmpty()) {
			ApplicationDatabase.getInstance().dmlInsert(insertable);
		}
	}

	private class ParsedApiResult {
		// note: the actual soql might be different from request to request, but if the integration user/platform and selected objects/field match, then we treat it the same...
		// It means that from time to time the soql in the Integration record will change, but that's ok, it's more about the dependent fields/objects
		public String lastSoql;

		public ApiEventAnalysis__c lastEventRecord;

		// since the ParsedApiResult is an aggregation of all the matching records
		// this will store the max date of all the records processed...
		// we use this to update the custom setting in the finish method where the next batch will kick off from
		public Datetime maxEventDate;

		// stores the extracted results based on the parsed
		public Map<String, Set<String>> dependentFieldsObjects;

		// this will store the date of the event and then the specific Hour of operation
		public Map<String, Map<String, Integer>> integrationUsage;

		// This is a dodgy workaround to extend a pseudo key beyond 255 characters.
		// It's how we reconcile the data in these batch jobs back to existing records in SystemIntegration__c
		public List<String> keyData;

		// this is used once an integration record is either inserted or updated
		public SystemIntegration__c integrationRecord;


		public ParsedApiResult() {
			dependentFieldsObjects = new Map<String, Set<String>>();
			integrationUsage = new Map<String, Map<String, Integer>>();
			keyData = new List<String>();
		}

		/**
		 * Increase the usage of this integration within the current batch
		 */
		public void addUsage(Datetime eventDateTime) {
			String eventDate = String.valueOf(eventDateTime.date());
			String timeWindow = eventDateTime.format('ha'); // 12 hour time with AM/PM

			if(integrationUsage.get(eventDate) == null) {
				integrationUsage.put(eventDate, new Map<String, Integer>());
			}

			if(integrationUsage.get(eventDate).get(timeWindow) == null) {
				integrationUsage.get(eventDate).put(timeWindow, 0);
			}

			integrationUsage.get(eventDate).put(timeWindow, integrationUsage.get(eventDate).get(timeWindow) + 1);
		}

		public Set<String> getObjectFieldsInUse() {
			Set<String> output = new Set<String>();

			for(String objectName : dependentFieldsObjects.keySet()) {
				for(String fieldName : dependentFieldsObjects.get(objectName)) {
					output.add(objectName.toLowerCase() + '.' + fieldName.toLowerCase());
				}
			}

			return output;
		}

		/**
		 * Merge the existing usage records with what was captured
		 *
		 * @return
		 */
		public List<SystemIntegrationUsage__c> mergeUsage(List<SystemIntegrationUsage__c> existingUsage) {
			List<SystemIntegrationUsage__c> output = new List<SystemIntegrationUsage__c>();

			if(existingUsage == null) existingUsage = new List<SystemIntegrationUsage__c>();

			// check if the record already existed
			// if it did we grab the usage records fromt he pre-existing record
			// if there was no preexisting record it means there would be no usage records....
			Map<String, SystemIntegrationUsage__c> integrationUsageDateMapping = new Map<String, SystemIntegrationUsage__c>();
			for(SystemIntegrationUsage__c usage : existingUsage) {
				integrationUsageDateMapping.put(String.valueOf(usage.UsageDate__c), usage);
			}

			for(String usageDate : integrationUsage.keySet()) {
				SystemIntegrationUsage__c usageRecord = new SystemIntegrationUsage__c(UsageDate__c = Date.valueOf(usageDate), Integration__c = integrationRecord.Id);
				if(integrationUsageDateMapping.get(usageDate) != null) {
					usageRecord = integrationUsageDateMapping.get(usageDate);
				}

				// timeWindow will contain values like '12AM', '1PM' etc..
				for(String timeWindow : integrationUsage.get(usageDate).keySet()) {
					String fieldName = 'Usage' + timeWindow + '__c';
					if(usageRecord.get(fieldName) != null) {
						usageRecord.put(fieldName, Integer.valueOf(usageRecord.get(fieldName)) + integrationUsage.get(usageDate).get(timeWindow));
					} else {
						usageRecord.put(fieldName, integrationUsage.get(usageDate).get(timeWindow));
					}
				}

				output.add(usageRecord);
			}

			return output;
		}
	}

	public class BatchableException extends Exception {}
}