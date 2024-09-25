/**
 * @description A class that acts as a module to handle Genesys Voice Call callouts
 * NOTE: 	Synchronises VoiceCall changes to Genesys
 *	- Filters changes in VoiceCall record data (newList => oldMap) VS Genesys Mappings
 *	- Invokes AsyncWorker with required updates
 *	- Contains AsyncWorker logic to perform callouts outside of the trigger context
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @group 	Unified
 * @changelog
 * 	2024-08-27 - Paul Perry - created
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class GenesysVoiceCallModule extends ApplicationModule {
	/**
	 * Chunk size - representing the number of callouts to be performed in a single transaction.
	 */
	private static final Integer CALLOUT_CHUNK_SIZE = 10;

	public static GenesysVoiceCallModule newInstance() {
		return (GenesysVoiceCallModule)Application.Utilities.newInstance(GenesysVoiceCallModule.class);
	}

	/**
	 * Constructor hooking up event handlers for trigger logic
	 */
	public GenesysVoiceCallModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	/**
	 * Handle AfterUpdate
	 * @param records			Records updated in this context
	 * @param existingRecords	Representation of the previous record state
	 * @param uow	Unit of work
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		performGenesysUpdateSync(records, existingRecords, uow);
	}

	/**
	 * Performs a Genesys update sync.
	 * - Given a collection of records, and a map of the records' previous states, it identifies the set of records
	 *	 which require an update.
	 * - Given a set of changed records, it identifies the related ConversationIds and performs a callout to Genesys
	 * 	 using the AsyncWorker.
	 * @param records			Records updated in this context
	 * @param existingRecords	Representation of the previous record state
	 * @param uow	Unit of work
	 */
	public static void performGenesysUpdateSync(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		String routingContext = 'genesysFieldSync';

		List<ApplicationRecursion.RecordState> voiceCallChangedRecords = ApplicationRecursion.getInstance()
			.getProcessableRecords(
				routingContext,
				records,
				existingRecords,
				GenesysConstants.genesysFieldMappings.keySet()
			);

		Set<Id> conversationIds = new Set<Id>();
		List<VoiceCall> syncCandidates = new List<VoiceCall>();

		// Collect all ConversationIds first
		for (ApplicationRecursion.RecordState recordState :voiceCallChangedRecords) {
			syncCandidates.add((VoiceCall)recordState.record);
			conversationIds.add((Id)recordState.record.get(VoiceCall.ConversationId));
		}

		// Filter out all non authoritative voice calls
		syncCandidates = filterSyncCandidates(conversationIds, new Map<Id,VoiceCall>(syncCandidates));

		// None of the sync fields were updated, so we can safely exit
		if (syncCandidates.isEmpty()) {
			return;
		}

		// Kick off the AsyncWorker to perform the art of syncing
		while (!syncCandidates.isEmpty()) {
			// Use a list to match the voiceCallIds property of the AsyncWorker. These values are unique anyways as they come from a map
			List<Id> voiceCallIdSubset = new List<Id>();

			// Create 1 job for each chunk of VoiceCall updates
			// - 1 VoiceCall = 1~2 Callouts
			while (!syncCandidates.isEmpty() && voiceCallIdSubset.size() < CALLOUT_CHUNK_SIZE - 1) {
				voiceCallIdSubset.add(syncCandidates.remove(0).Id);
			}

			// Invoke the AsyncWorker, use Queueable Context for troubleshooting purposes
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(
				AsyncGenesysAttributeSync.class,
				new Map<String,Object>{ 'voiceCallIds' => voiceCallIdSubset }
			));
		}
	}

	/**
	 * Filter out all VoiceCall records that shouldn't be synchronised to Genesys
	 * 	- Based on number of VC's within Conversation
	 *  - Based on Related AgentWork Status and AcceptedDateTime/ClosedDateTime
	 */
	private static List<VoiceCall> filterSyncCandidates(Set<Id> conversationIds, Map<Id,VoiceCall> syncCandidatesMap) {
		List<VoiceCall> result = new List<VoiceCall>();

		Set<SObjectField> vcFields = new Set<SObjectField>{
			VoiceCall.CallDisposition,
			VoiceCall.CallStartDateTime,
			VoiceCall.CallEndDateTime,
			VoiceCall.Id,
			VoiceCall.ConversationId
		};

		// Obtain all related voice call records
		Map<Id,VoiceCall> voiceCallMap = new Map<Id,VoiceCall>(
			VoiceCallsSelector.newInstance(0, vcFields).selectByConversationIds(
				new Set<Object>{ VoiceCallsSelector.Options.ORDER_BY_CREATED_DATE_ASC },
				conversationIds
			)
		);

		// Map a list for all related voicecalls against their parent ConversationId
		Map<Id,List<VoiceCall>> voiceCallsByConversationId = new Map<Id,List<VoiceCall>>();

		for (VoiceCall voiceCall :voiceCallMap.values()) {
			if (!voiceCallsByConversationId.containsKey(voiceCall.ConversationId)) {
				voiceCallsByConversationId.put(voiceCall.ConversationId, new List<VoiceCall>());
			}

			voiceCallsByConversationId.get(voiceCall.ConversationId).add(
				syncCandidatesMap.get(voiceCall.Id) ?? voiceCall
			);
		}

		// Strip all processed VoiceCalls from this list
		for (VoiceCall voiceCall :syncCandidatesMap.values()) {
			Boolean isAuthoritative = isAuthoritativeVoiceCall(voiceCall, voiceCallsByConversationId.get(voiceCall.ConversationId), null);

			if (isAuthoritative == null) {
				continue;
			}

			if (isAuthoritative) {
				result.add(voiceCall);
			}

			syncCandidatesMap.remove(voiceCall.Id);
		}

		// All sorted, no more inconclusive voiceCalls, return filtered list
		if (syncCandidatesMap.isEmpty()) {
			return result;
		}

		// Fetch Related AgentWork items
		Set<SObjectField> awFields = new Set<SObjectField>{
			AgentWork.Id,
			AgentWork.CreatedDate,
			AgentWork.WorkItemId,
			AgentWork.Status,
			AgentWork.AcceptDateTime,
			AgentWork.CloseDateTime
		};

		List<AgentWork> agentWorkList = AgentWorkSelector.newInstance(0, awFields)
			.selectByAcceptedWorkItemIds(
				voiceCallMap.keySet(),
				new Set<Object>{}
			);

		Map<Id,AgentWork> agentWorkByVoiceCallId = new Map<Id,AgentWork>();

		for (AgentWork agentWork :agentWorkList) {
			// Obtain the latest AgentWork record for a VoiceCall
			agentWorkByVoiceCallId.put(agentWork.WorkItemId, agentWork);
		}

		for (VoiceCall voiceCall :syncCandidatesMap.values()) {
			if (isAuthoritativeVoiceCall(voiceCall, voiceCallsByConversationId.get(voiceCall.ConversationId), agentWorkByVoiceCallId)) {
				result.add(voiceCall);
			}
		}

		return result;
	}

	/**
	 * Examine whether or not provided syncVoiceCall is the authoritative VoiceCall for its parent Conversation
	 * As soon as the voiceCall fits a scenario, we can tell whether it is or not
	 * - #1: There is only one call for the parent conversation
	 * - #2: Single active voice call found (can't rely on VoiceCall.CalDisposition (call status) at this time)
	 * - #3: Based on related AgentWork records used for Omni routing
	 * - #3.1: Related "Opened" AgentWork records (matching the oldest AcceptedDateTime)
	 * - #3.2: Related "Closed" AgentWork records (matching the most recent CloseDateTime)
	 */
	public static Boolean isAuthoritativeVoiceCall(
		VoiceCall syncVoiceCall, List<VoiceCall> relatedVoiceCalls, Map<Id,AgentWork> agentWorkByVoiceCallId
	) {
		// Let's see if we can pull this off without fetching related AgentWork records first

		// Scenario #1: It is the only voice call, so yes this one is the authoritative one
		if (relatedVoiceCalls.size() == 1) {
			return relatedVoiceCalls[0].Id == syncVoiceCall.Id;
		} else if (agentWorkByVoiceCallId == null) {
			// return inconclusive, come back with AgentWork map for next check
			return null;
		}

		// Scenario #3: Compare AgentWork
		List<AgentWork> agentWorkList = new List<AgentWork>();

		for (VoiceCall relatedVoiceCall :relatedVoiceCalls) {
			if (agentWorkByVoiceCallId.containsKey(relatedVoiceCall.Id)) {
				agentWorkList.add(agentWorkByVoiceCallId.get(relatedVoiceCall.Id));
			}
		}

		// Filter by Status = 'Opened' and order by AcceptedDate ASC (oldest first)
		List<AgentWork> openWorkList = (List<AgentWork>)ComparableSObjectWrapper.sortRecords(
			filterList(agentWorkList, new Map<SObjectField,Object>{ AgentWork.Status => 'Opened' }),
			AgentWork.AcceptDateTime
		);

		// Scenario 3.1: one or more related AgentWork records are in status 'Opened'
		if (!openWorkList.isEmpty()) {
			// Return true if the syncVoiceCall is the one with the oldest AcceptDateTime
			return openWorkList[0].WorkItemId == syncVoiceCall.Id;
		}

		// Filter by Status = 'Closed' and order by CloseDateTime DESC (most recent first)
		List<AgentWork> closedWorkList = (List<AgentWork>)ComparableSObjectWrapper.sortRecords(
			filterList(agentWorkList, new Map<SObjectField,Object>{ AgentWork.Status => 'Closed' }),
			AgentWork.CloseDateTime,
			'DESC'
		);

		// Scenario 3.2: one or more related AgentWork records are in status 'Closed'
		if (!closedWorkList.isEmpty()) {
			// Return true if the syncVoiceCall is the one with the latest CloseDateTime
			return closedWorkList[0].WorkItemId == syncVoiceCall.Id;
		}

		// Ending up here is impossible according to our sources. Probably caused by a bug in
		//  Genesys or Omni channel. Let's hit the brakes here:
		throw new NoDataFoundException();
	}

	public with sharing class AsyncGenesysAttributeSync extends ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts {
		public Set<Id> conversationIds;
		public List<Id> voiceCallIds;

		public override void execute(ApplicationUnitOfWork uow) {
			try {
				processGenesysCallouts();
			} catch(Exception ex) {
				// Error Logged to Exception object for analysis
				ApplicationLogger.getInstance().logException(
					new ApplicationLogger.ExceptionWrapper(ex),
					'Genesys Attribute Synchronisation',
					'GenesysVoiceCallModule',
					'processGenesysCallouts',
					'VoiceCallTriggerHandler',
					ApplicationLogger.LoggingLevel.ERROR
				);
			}
		}

		public override Type getClassType() {
			return AsyncGenesysAttributeSync.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return VoiceCall.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				Map<String,Object> params =
					(Map<String,Object>)JSON.deserializeUntyped(
						serialisedParams
					);

				if (params.containsKey('voiceCallIds')) {
					voiceCallIds = (List<Id>)JSON.deserialize(
						JSON.serialize(params.get('voiceCallIds')),
						List<Id>.class
					);
				}
			}
		}

		public void processGenesysCallouts() {
			Set<SObjectField> voiceCallFieldSet = new Set<SObjectField>{
				VoiceCall.Id,
				VoiceCall.VendorCallKey,
				VoiceCall.Division__c,
				VoiceCall.CustomerParticipantId__c,
				VoiceCall.ConversationId
			};

			voiceCallFieldSet.addAll(GenesysConstants.genesysFieldMappings.keySet());

			// Retrieve the voice call records
			Map<Id,VoiceCall> voiceCallMap = new Map<Id,VoiceCall>(
				VoiceCallsSelector.newInstance(0, voiceCallFieldSet).selectByIds(
					new Set<Object>{ VoiceCallsSelector.Options.ORDER_BY_CREATED_DATE_ASC },
					new Set<Id>(voiceCallIds)
				)
			);

			Map<String,GenesysSyncRequest> syncRequests = new Map<String,GenesysSyncRequest>();

			for (VoiceCall voiceCall :voiceCallMap.values()) {
				Map<String,Object> genesysUpdates = new Map<String,Object>();

				for (SObjectField field :GenesysConstants.genesysFieldMappings.keySet()) {
					genesysUpdates.put(GenesysConstants.genesysFieldMappings.get(field), voiceCall.get(field));
				}

				String conversationId = extractConversionId(voiceCall.VendorCallKey);

				if (!syncRequests.containsKey(conversationId)) {
					syncRequests.put(conversationId, new GenesysSyncRequest(
						conversationId,
						voiceCall.customerParticipantId__c,
						voiceCall.ConversationId
					));
				}

				// In case of >1 updates on the same call interaction, accumulate accordingly
				GenesysSyncRequest genesysRecord = syncRequests.get(conversationId);
				genesysRecord.customAttributes.putAll(genesysUpdates);
				genesysRecord.customAttributes.putAll(
					applyAdditionbalBusinessRules(genesysUpdates, voiceCall.Division__c)
				);
			}

			List<String> errorList = new List<String>();

			// Process the callouts
			for (GenesysSyncRequest syncRequest :syncRequests.values()) {
				try {
					processGenesysUpdate(syncRequest);
				} catch (GenesysIntegrationService.GenesysResponseException grException) {
					errorList.add(String.format(
						'Unable to sync interaction {0} with values {1} to Genesys\nReason: {2}',
						new String[] {
							syncRequest.conversationId,
							JSON.serialize(syncRequest.customAttributes),
							grException.getMessage()
						}
					));
				}
			}

			if (!errorList.isEmpty()) {
				ApplicationLogger.getInstance().logGenericMessage(
					errorList,
					'Genesys Attribute Synchronisation',
					'GenesysInteractionSyncQueueable',
					'processGenesysCallouts',
					'GenesysVoiceCallModule',
					ApplicationLogger.LoggingLevel.ERROR
				);
			}
		}
	}

	/**
	 * Extract the conversation Id from the VendorCallKey which is formatted like this:
	 * 	[agent-participantid]:[conversationId]
	 * @param vendorCallKey as String
	 * @return conversationId as string
	 */
	private static String extractConversionId(String vendorCallKey) {
		String result = vendorCallKey;

		if (String.isNotBlank(vendorCallKey) && vendorCallKey.contains(':')) {
			result = vendorCallKey.split(':', 2)[1];
		}

		return result;
	}

	/**
	 * Wrapper class for the actual sync request
	 */
	public class GenesysSyncRequest {
		public Map<String,Object> customAttributes;
		public String conversationId;
		public String sfConversationId;
		public String participantId;

		public GenesysSyncRequest(String conversationId, String participantId, String sfConversationId) {
			this.sfConversationId = sfConversationId;
			this.conversationId = conversationId;
			this.participantId = participantId;
			this.customAttributes = new Map<String,Object>();
		}
	}

	/**
	 * Process GenesysUpdate by invoking callouts to Genesys
	 * - Fetch the actual conversation details
	 * - Compare and decide if an update to existing call interaction is needed
	 * - Finally call Genesys Interaction API to update the record
	 * @param request	Contains the conversationId and the attribute values
	 */
	public static void processGenesysUpdate(GenesysSyncRequest request) {
		GenesysIntegrationService genesysIntegrationService = GenesysIntegrationService.newInstance();
		Map<String,Object> requiredUpdates = request.customAttributes;
		String participantId = request.participantId;

		// For all regular inbound and outbound calls, the participantId is already provided by Genesys in the VoiceCall record
		if (String.isBlank(participantId)) {
			Map<String,Object> currentInteraction = genesysIntegrationService.fetchConversationCallDetail(request.conversationId);

			// Participant purpose depends on call type
			List<String> participantPurposes = new List<String>{
				'customer',		// default inbound call including consult / transfer
				'external',		// outbound call wo/ queue selected
				'agent'			// call from agent to other agent
			};

			Map<String,Object> participantDetail;

			for(String participantPurpose :participantPurposes) {
				participantDetail = (Map<String,Object>)findWithinObjectArrray(
					(List<Object>)currentInteraction.get('participants'),
					new Map<String,Object>{ 'purpose' => participantPurpose }
				);

				if (participantDetail != null) {
					break;
				}
			}

			Map<String,Object> existingAttributeValues = (Map<String,Object>)participantDetail?.get('attributes');

			// No participant details found, not likely to happen. Simply prevent further execution to prevent Exception
			if (existingAttributeValues == null) {
				return;
			}

			participantId = String.valueOf(participantDetail.get('id'));

			// Compare existing attribute values
			requiredUpdates = getDeltaMap(existingAttributeValues, requiredUpdates);
		}

		if (!requiredUpdates.isEmpty()) {
			genesysIntegrationService.patchConversationParticipantAttributes(
				request.conversationId,
				participantId,
				requiredUpdates
			);
		}
	}

	/**
	 * Compares the values in the new map with the old map filtering out the ones with matching values
	 * @param oldMap		Old map of key value pairs
	 * @param newMap		New map of key value pairs
	 * @return Map of key value pairs where the new values are different from the old values
	 */
	private static Map<String,Object> getDeltaMap(Map<String,Object> oldMap, Map<String,Object> newMap) {
		Map<String,Object> result = new Map<String,Object>();

		for (String key :newMap.keySet()) {
			if (oldMap.get(key) != newMap.get(key)) {
				result.put(key, newMap.get(key));
			}
		}

		return result;
	}

	/**
	 * Finds the object within a list of objects that matches the search criteria
	 * @param keyValuePairArray		List of objects
	 * @param searchCriteria		Map of key value pairs to search for
	 * @return Object or null if no match was found
	 */
	private static Object findWithinObjectArrray(List<Object> keyValuePairArray, Map<String,Object> searchCriteria) {
		for (Object obj :keyValuePairArray) {
			Map<String,Object> objMap = (Map<String,Object>)obj;
			Boolean qualifies = true;

			for (String key :searchCriteria.keySet()) {
				Object value = searchCriteria.get(key);

				if (objMap.get(key) != value) {
					qualifies = false;
					break;
				}
			}

			if (qualifies) {
				return obj;
			}
		}

		return null;
	}

	/**
	 * Contains the additional business logic to be applied when updating Genesys
	 * When a call gets transferred from Unified (SCV) to OpenCTI (classic):
	 * - TrackingNumber gets captured in a different attribute for divisions AP/ST
	 * @param setCustomAttributes	The custom attributes to be synced to Genesys
	 * @param division	Division from the Call Log (AP/ST)
	 *
	 * @return Map of key value pairs to be updated including additional attributes added by business rules
	 */
	public static Map<String,Object> applyAdditionbalBusinessRules(Map<String,Object> setCustomAttributes, String division) {
		// Mapping details are configured below
		Map<String,Map<String,String>> mappingsByDivision = new Map<String,Map<String,String>>{
			'AP' => new Map<String,String>{
				'Tracking_ID' => 'Tracking_Number'
			},
			'ST' => new Map<String,String>{
				'Consignment' => 'Tracking_Number'
			}
		};

		Map<String,Object> result = new Map<String,Object>();

		for (String key :setCustomAttributes.keySet()) {
			// update null values to empty string values as Genesys doesn't pickup on null values
			if (setCustomAttributes.get(key) == null)	 {
				result.put(key, '');
			}
		}

		if (mappingsByDivision.containsKey(division)) {
			for (String attribTarget :mappingsByDivision.get(division).keySet()) {
				String attribSource = mappingsByDivision.get(division).get(attribTarget);

				if (setCustomAttributes.containsKey(attribSource)) {
					// Provide empty string when set to null
					result.put(attribTarget, setCustomAttributes.get(attribSource) ?? '');
				}
			}
		}

		// Whenever we clear out CaseId, also clear out the Case_Number value so OpenCTI doesn't pick it up
		if (setCustomAttributes.containsKey('CaseId')) {
			// Reset the Case_N umber potentially stamped by OpenCTI (classic)
			result.put('Case_Number', '');
		}

		return result;
	}

	public static List<SObject> filterList(List<SObject> records, Map<SObjectField,Object> criteria) {
		List<SObject> result = new List<SObject>();

		for (SObject record :records) {
			Boolean meetsCriteria = false;

			for (SObjectField field :criteria.keySet()) {
				Object value = criteria.get(field);
				Object recordValue = record.get(field);

				if (value instanceOf Set<String>) {
					meetsCriteria = ((Set<String>)value).contains(String.valueOf(recordValue));
				} else {
					meetsCriteria = value == recordValue;
				}

				if (!meetsCriteria) {
					break;
				}
			}

			if (meetsCriteria) {
				result.add(record);
			}
		}

		return result;
	}
}