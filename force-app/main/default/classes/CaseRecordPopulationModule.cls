/**
 * @description Module to cover the population of the Case lookup field against relevant objects
 * 				This was created specifically for Omni-Channel AgentWork object to provide Case lookup values against the WorkItem records (contactrequest, voicecall etc..), 
 * 				and also the AgentWork record itself.
 * 
 * 				NOTE: This module is invoked by multiple trigger handlers to centralise the case population logic.
 * 						Performance profiling has been done to ensure there minimal impact to performance
 * @author Nathan Franklin
 * @date 2024-07-31
 * @changelog
 */
public inherited sharing class CaseRecordPopulationModule extends ApplicationModule {
    
	// Setup which triggers this module should respond to
	public CaseRecordPopulationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public static final Map<SObjectType, SObjectField> MAPPED_LOOKUP_FIELDS = new Map<SObjectType, SObjectField>{
		ContactRequest.SobjectType => ContactRequest.WhatId,
		VoiceCall.SobjectType => VoiceCall.RelatedRecordId
	};

	// stores a list of fields (usually should only ever be 1 per object)
	public static final Map<SObjectType, SObjectField> MAPPED_CASE_FIELDS = new Map<SObjectType, SObjectField>{
		ContactRequest.SobjectType => ContactRequest.Case__c,
		VoiceCall.SobjectType => VoiceCall.Case__c
	};
	
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {

			// update the case values on the source records passed in
			assignCaseValues(records, null, uow);

		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {

			// update the case values on the source records passed in
			assignCaseValues(records, existingRecords, uow);

		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Checks whether the case value needs to be populated against the source record
	 * The source record will be one of ContextRequest, VoiceCall or any other objects where this module is implemented
	 * NOTE: LiveChatTranscript would normally be a tracked record, however it's not required since there is a native CaseId field directly on the object so we don't need to monitor it.
	 * NOTE: This method supports passing records of multiple types, although in practice, this would normally be invoked by a trigger meaning most/all the time the records will be of a single type
	 */
	@TestVisible
	private void assignCaseValues(List<SObject> recordList, Map<Id, SObject> oldMap, ApplicationUnitOfWork uow) {

		Map<SObjectType, List<SObject>> updateableRecords = new Map<SObjectType, List<SObject>>();
		List<ApplicationRecursion.RecordState> processableRecords = new List<ApplicationRecursion.RecordState>();
		Map<SObjectType, List<SObject>> monitoredRecords = new Map<SObjectType, List<SObject>>();
		String recursionContext = 'caserecordpopulationvalueonsourcerecord';

		// grab a list of records for each type based on the object types we are monitoring
		// normally there would be only a single iteration here, however, we do support multiple object types in a single call for efficiency
		for(SObject sobjectRecord : recordList) {
			SObjectType sobjectRecordType = sobjectRecord.getSObjectType();
			if(MAPPED_LOOKUP_FIELDS.containsKey(sobjectRecordType)) {
				// this is an object we are wanting to update the case value on
				if(monitoredRecords.get(sobjectRecordType) == null) {
					monitoredRecords.put(sobjectRecordType, new List<SObject>());
				}
				monitoredRecords.get(sobjectRecordType).add(sobjectRecord);
			}
		}

		// build up a list of processable records for each of the object types we are monitoring
		// normally there would be only a single iteration here, however, we do support multiple object types in a single call for efficiency
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			processableRecords.addAll(ApplicationRecursion.getInstance().getProcessableRecords(recursionContext, monitoredRecords.get(monitoredSObjectType), oldMap, new Set<SObjectField>{MAPPED_LOOKUP_FIELDS.get(monitoredSObjectType)}));
		}
		
		for(ApplicationRecursion.RecordState recordState : processableRecords){
			SObject processableRecord = recordState.record;
			SObjectType processableRecordSObjectType = processableRecord.getSObjectType();
			
			Set<SObjectField> changedFields = recordState.changedFields;
			Map<String, Object> previousState = recordState.previousState;	// get old values of case

			if(MAPPED_LOOKUP_FIELDS.get(processableRecordSObjectType) != null) {
				SObjectField fieldToCheck = MAPPED_LOOKUP_FIELDS.get(processableRecordSObjectType);

				Boolean changedValue = false;

				// store the case id if the value has been modified and it equals a case
				// NOTE: this will accurately remove the case value if the field has changed value and no longer has a record id populated
				Id recordId = null;

				if(changedFields.contains(fieldToCheck)) {
					if('500'.equalsIgnoreCase(String.valueOf(processableRecord.get(fieldToCheck))?.substring(0, 3))) {
						recordId = String.valueOf(processableRecord.get(fieldToCheck));
					}

					changedValue = true;
				}

				if(changedValue && MAPPED_CASE_FIELDS.get(processableRecordSObjectType) != null) {
					// since the values on the monitored records have changed, we need to populate the case values
					processableRecord.put(MAPPED_CASE_FIELDS.get(processableRecordSObjectType), recordId);
				}
			}
			
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			ApplicationRecursion.getInstance().updateRecordState(recursionContext, monitoredRecords.get(monitoredSObjectType), new Set<SObjectField>{MAPPED_LOOKUP_FIELDS.get(monitoredSObjectType)});
		}
		
	}

}