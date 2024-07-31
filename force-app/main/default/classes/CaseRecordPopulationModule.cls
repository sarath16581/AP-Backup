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
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate();
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
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onBeforeInsert', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {

			// update the case values on the source records passed in
			assignCaseValues(records, existingRecords, uow);

		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onBeforeUpdate', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {

			// when the interaction records are updated and when the case has been populated on the record, 
			// we need to backfill the agent work records to provide a nice easy way to link the agent work records to the case
			backfillAgentWorkRecords(records, null, uow);

		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onBeforeUpdate', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {

			// when the interaction records are updated and when the case has been populated on the record, 
			// we need to backfill the agent work records to provide a nice easy way to link the agent work records to the case
			backfillAgentWorkRecords(records, existingRecords, uow);

		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseRecordPopulationModule.class.getName(), 'onAfterUpdate', '', ApplicationLogger.LoggingLevel.ERROR);
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

		List<ApplicationRecursion.RecordState> processableRecords = new List<ApplicationRecursion.RecordState>();
		Map<SObjectType, List<SObject>> monitoredRecords = new Map<SObjectType, List<SObject>>();
		String recursionContext = 'CaseRecordPopulationModule.assignCaseValues';

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

		// reset the recursion state to ensure changes any changes we have made in this method won't retrigger on next pass (if there is one)
		// its usually unlikely we need to do this, but it is a best practice just incase we ever introduce changes above to update fields we are monitoring
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			ApplicationRecursion.getInstance().updateRecordState(recursionContext, monitoredRecords.get(monitoredSObjectType), new Set<SObjectField>{MAPPED_LOOKUP_FIELDS.get(monitoredSObjectType)});
		}
		
	}

	/**
	 * This is used to populate agent work records with the associated case id from a channel based interaction integrated into omni channel
	 * This is used to allow for easy case access on the agent work record for things like preferred agent identification or accessing case attributes directly
	 */
	private void backfillAgentWorkRecords(List<SObject> recordList, Map<Id, SObject> oldMap, ApplicationUnitOfWork uow) {

		Map<Id, Id> processableWorkItemIds = new Map<Id, Id>();
		List<ApplicationRecursion.RecordState> processableRecords = new List<ApplicationRecursion.RecordState>();
		Map<SObjectType, List<SObject>> monitoredRecords = new Map<SObjectType, List<SObject>>();
		String recursionContext = 'CaseRecordPopulationModule.backfillAgentWorkRecords';

		// grab a list of records for each type based on the object types we are monitoring
		// normally there would be only a single iteration here, however, we do support multiple object types in a single call for efficiency
		for(SObject sobjectRecord : recordList) {
			SObjectType sobjectRecordType = sobjectRecord.getSObjectType();
			if(MAPPED_CASE_FIELDS.containsKey(sobjectRecordType)) {
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
			processableRecords.addAll(ApplicationRecursion.getInstance().getProcessableRecords(recursionContext, monitoredRecords.get(monitoredSObjectType), oldMap, new Set<SObjectField>{MAPPED_CASE_FIELDS.get(monitoredSObjectType)}));
		}
		
		for(ApplicationRecursion.RecordState recordState : processableRecords){
			SObject processableRecord = recordState.record;
			SObjectType processableRecordSObjectType = processableRecord.getSObjectType();
			
			Set<SObjectField> changedFields = recordState.changedFields;

			if(MAPPED_CASE_FIELDS.get(processableRecordSObjectType) != null) {
				SObjectField fieldToCheck = MAPPED_CASE_FIELDS.get(processableRecordSObjectType);

				// NOTE: We only get records where there is a case value
				//			This could possibly lead to data integrity issues, however I don't think it's a real world scenario (where a case is removed from an interaction record)
				if(changedFields.contains(fieldToCheck) && !String.isEmpty(String.valueOf(processableRecord.get(fieldToCheck)))) {
					processableWorkItemIds.put(processableRecord.Id, (Id)processableRecord.get(fieldToCheck));
				}
			}
		}

		if(!processableWorkItemIds.isEmpty()) {
			// we have our list of work item / interaction record ids and the cases that should be associated to them.
			// we need to backfill the case id value on the associated agent work records
			List<AgentWork> updateableRecords = new List<AgentWork>();
			Set<SObjectField> fieldOverrides = new Set<SObjectField>{AgentWork.Id, AgentWork.WorkItemId, AgentWork.Case__c};
			List<AgentWork> agentWorkRecords = AgentWorkSelector.newInstance(0, fieldOverrides).selectByWorkItemIds(processableWorkItemIds.keySet(), new Set<Object>{});
			
			// iterate through the agent work records selected 
			// TODO: We might need to be more selective in the records we return from the selector as some of these records will likely not need to be updated
			for(AgentWork agentWorkRecord : agentWorkRecords) {
				if(agentWorkRecord.Case__c != processableWorkItemIds.get(agentWorkRecord.WorkItemId)) {
					// only update the record if the correct case has not already been populated
					updateableRecords.add(new AgentWork(Id = agentWorkRecord.Id, Case__c = processableWorkItemIds.get(agentWorkRecord.WorkItemId)));
				}
			}

			if(!updateableRecords.isEmpty()) {
				uow.registerDirty(updateableRecords, new List<SObjectField>{AgentWork.Case__c}, false, recursionContext);
			}

		}

		// reset the recursion state to ensure changes any changes we have made in this method won't retrigger on next pass (if there is one)
		// its usually unlikely we need to do this, but it is a best practice just incase we ever introduce changes above to update fields we are monitoring
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			ApplicationRecursion.getInstance().updateRecordState(recursionContext, monitoredRecords.get(monitoredSObjectType), new Set<SObjectField>{MAPPED_LOOKUP_FIELDS.get(monitoredSObjectType)});
		}

	}

}