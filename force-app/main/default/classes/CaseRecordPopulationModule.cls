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
			if(InteractionService.MAPPED_STANDARD_FIELDS.containsKey(sobjectRecordType)) {
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
			processableRecords.addAll(ApplicationRecursion.getInstance().getProcessableRecords(
																			recursionContext, 
																			monitoredRecords.get(monitoredSObjectType), 
																			oldMap, 
																			new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(monitoredSObjectType)}
																		));
		}

		for(ApplicationRecursion.RecordState recordState : processableRecords){
			SObject processableRecord = recordState.record;
			SObjectType processableRecordSObjectType = processableRecord.getSObjectType();
			
			Set<SObjectField> changedFields = recordState.changedFields;

			if(InteractionService.MAPPED_STANDARD_FIELDS.get(processableRecordSObjectType) != null) {
				SObjectField fieldToCheck = InteractionService.MAPPED_STANDARD_FIELDS.get(processableRecordSObjectType);

				// store the case id if the value has been modified and it equals a case
				// NOTE: this will accurately remove the case value if the field has changed value and no longer has a record id populated
				Id caseId = null;

				if(changedFields.contains(fieldToCheck)) {
					if('500'.equalsIgnoreCase(String.valueOf(processableRecord.get(fieldToCheck))?.substring(0, 3))) {
						caseId = String.valueOf(processableRecord.get(fieldToCheck));
					}
				}

				if(InteractionService.MAPPED_CASE_FIELDS.get(processableRecordSObjectType) != null) {
					// since the values on the monitored records have changed, we need to populate the case values
					processableRecord.put(InteractionService.MAPPED_CASE_FIELDS.get(processableRecordSObjectType), caseId);
				}
			}
		}

		// reset the recursion state to ensure any changes we have made in this method won't retrigger on next pass (if there is one)
		// its usually unlikely we need to do this, but it is a best practice just incase we ever introduce changes above to update fields we are monitoring
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			ApplicationRecursion.getInstance().updateRecordState(recursionContext, monitoredRecords.get(monitoredSObjectType), new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(monitoredSObjectType)});
		}
	}

	/**
	 * This is used to populate agent work records with the associated case id from a channel based interaction integrated into omni channel
	 * This is used to allow for easy case access on the agent work record for things like preferred agent identification or accessing case attributes directly
	 */
	@TestVisible
	private void backfillAgentWorkRecords(List<SObject> recordList, Map<Id, SObject> oldMap, ApplicationUnitOfWork uow) {

		Map<Id, SObject> workItems = new Map<Id, SObject>();
		List<ApplicationRecursion.RecordState> processableRecords = new List<ApplicationRecursion.RecordState>();
		Map<SObjectType, List<SObject>> monitoredRecords = new Map<SObjectType, List<SObject>>();
		String recursionContext = 'CaseRecordPopulationModule.backfillAgentWorkRecords';

		// grab a list of records for each type based on the object types we are monitoring
		// normally there would be only a single iteration here, however, we do support multiple object types in a single call for efficiency
		for(SObject sobjectRecord : recordList) {
			SObjectType sobjectRecordType = sobjectRecord.getSObjectType();
			if(InteractionService.MAPPED_CASE_FIELDS.containsKey(sobjectRecordType)) {
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
			processableRecords.addAll(ApplicationRecursion.getInstance().getProcessableRecords(recursionContext, monitoredRecords.get(monitoredSObjectType), oldMap, new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(monitoredSObjectType)}));
		}

		for(ApplicationRecursion.RecordState recordState : processableRecords){
			SObject processableRecord = recordState.record;
			SObjectType processableRecordSObjectType = processableRecord.getSObjectType();
			
			Set<SObjectField> changedFields = recordState.changedFields;

			if(InteractionService.MAPPED_CASE_FIELDS.get(processableRecordSObjectType) != null) {
				SObjectField fieldToCheck = InteractionService.MAPPED_CASE_FIELDS.get(processableRecordSObjectType);

				if(changedFields.contains(fieldToCheck)) {
					workItems.put(processableRecord.Id, processableRecord);
				}
			}
		}

		if(workItems.isEmpty() == false) {
			List<AgentWork> agentWorkRecords = AgentWorkSelector.newInstance().selectByWorkItemIds(workItems.keySet(), new Set<Object>{});
			InteractionService.getInstance().populateCaseFieldOnAgentWorks(workItems, agentWorkRecords, uow, recursionContext);
		}

		// reset the recursion state to ensure changes any changes we have made in this method won't retrigger on next pass (if there is one)
		// its usually unlikely we need to do this, but it is a best practice just incase we ever introduce changes above to update fields we are monitoring
		for(SObjectType monitoredSObjectType : monitoredRecords.keySet()) {
			ApplicationRecursion.getInstance().updateRecordState(recursionContext, monitoredRecords.get(monitoredSObjectType), new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(monitoredSObjectType)});
		}

	}

}