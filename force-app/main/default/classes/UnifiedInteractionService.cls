/**
 * @description Service class to provide common fuctionalities for Interaction objects such as Chat, Voice and ContactRequest
 * @author George Nguyen
 * @date 2024-09-24
 * @changelog
 * 2024-09-24 - George Nguyen - Created.
 */
public with sharing class UnifiedInteractionService {

	public static final Map<SObjectType, SObjectField> MAPPED_STANDARD_FIELDS = new Map<SObjectType, SObjectField>{
		ContactRequest.SobjectType => ContactRequest.WhatId,
		VoiceCall.SobjectType => VoiceCall.RelatedRecordId
	};

	// Map the case lookup fieds per interaction objects
	public static final Map<SObjectType, SObjectField> MAPPED_CASE_FIELDS = new Map<SObjectType, SObjectField>{
		LiveChatTranscript.SObjectType => LiveChatTranscript.CaseId, 
		ContactRequest.SObjectType => ContactRequest.Case__c,
		VoiceCall.SObjectType => VoiceCall.Case__c
	};

	public static UnifiedInteractionService getInstance() {
		return (UnifiedInteractionService)Application.Utilities.getInstance(UnifiedInteractionService.class);
	}

	/**
	 * This method will retrieve the related case lookup field of the interaction record and returns a map
	 */
	public Map<Id, SObject> retrieveInteractionRecords(Map<SObjectType, Set<Id>> mappedObjectTypeAndIds) {
		Map<Id, SObject> result = new Map<Id, SObject>();
		
		if(mappedObjectTypeAndIds.containsKey(LiveChatTranscript.SObjectType) == true && mappedObjectTypeAndIds.get(LiveChatTranscript.SObjectType).isEmpty() == false) {
			// adding the related LiveChatTranscript from the set of Ids. The CaseId field is included on the Selector
			result.putAll(LiveChatTranscriptsSelector.newInstance().selectByIds(new Set<Object>(), mappedObjectTypeAndIds.get(LiveChatTranscript.SObjectType)));
		}

		if(mappedObjectTypeAndIds.containsKey(ContactRequest.SObjectType) == true && mappedObjectTypeAndIds.get(ContactRequest.SObjectType).isEmpty() == false) {
			// adding the related ContactRequest from the set of Ids. The Case__c field is included on the Selector
			result.putAll(ContactRequestsSelector.newInstance().selectByIds(new Set<Object>(), mappedObjectTypeAndIds.get(ContactRequest.SObjectType)));
		}

		if(mappedObjectTypeAndIds.containsKey(VoiceCall.SObjectType) == true && mappedObjectTypeAndIds.get(VoiceCall.SObjectType).isEmpty() == false) {
			// adding the related VoiceCall from the set of Ids. The Case__c field is included on the Selector
			result.putAll(VoiceCallsSelector.newInstance().selectByIds(new Set<Object>(), mappedObjectTypeAndIds.get(VoiceCall.SObjectType)));
		}

		return result;
	}

	/**
	 * This method will update the Case__c field on the AgentWork record with the Case Id assigned to the Case Lookup field on the related interaction record
	 */
	public void populateCaseFieldOnAgentWorks(Map<Id, SObject> workItems, List<AgentWork> agentWorkRecords, ApplicationUnitOfWork uow, String source) {
		List<AgentWork> updateableRecords = new List<AgentWork>();
		
		// iterate through the agent work records selected 
		// TODO: We might need to be more selective in the records we return from the selector as some of these records will likely not need to be updated
		for(AgentWork agentWorkRecord : agentWorkRecords) {
			if(workItems.containsKey(agentWorkRecord.WorkItemId) == true && MAPPED_CASE_FIELDS.containsKey(agentWorkRecord.WorkItemId.getSObjectType()) == true) {
				SObjectField caseField = MAPPED_CASE_FIELDS.get(agentWorkRecord.WorkItemId.getSObjectType());

				Id caseId = (Id)workItems.get(agentWorkRecord.WorkItemId).get(caseField);
				if(agentWorkRecord.Case__c != caseId) {
					updateableRecords.add(new AgentWork(Id = agentWorkRecord.Id, Case__c = caseId));
				}
			}
		}

		if(updateableRecords.isEmpty() == false) {
			uow.registerDirty(updateableRecords, new List<SObjectField>{AgentWork.Case__c}, false, source);
		}
	}
}