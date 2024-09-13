/**
 * @description A class that acts as a module to handle Genesys Voice Call callouts
 * @author Paul Perry
 * @date 2024-09-10
 * @changelog
 * 2024-09-10 - Paul Perry - created
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class GenesysVoiceCallModule extends ApplicationModule {
	public static GenesysVoiceCallModule newInstance() {
		return (GenesysVoiceCallModule)Application.Utilities.newInstance(GenesysVoiceCallModule.class);
	}

	/**
	 * Constructor
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
	 * Chunk size - representing the number of callouts to be performed in a single transaction.
	 */
	private static final Integer CALLOUT_CHUNK_SIZE = 10;

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

		// Map containing all VoiceCall Ids by ConversationId
		Map<Id,Set<Id>> conversationVoiceCallMap = new Map<Id,Set<Id>>();
		// Map containing a set of changed mapped fields for each VoiceCall
		Map<Id,Set<String>> updatedFieldsByVoiceCallId = new Map<Id,Set<String>>();

		// Collect all the changes, and collect all the VoiceCall Ids by ConversationId
		for(ApplicationRecursion.RecordState recordState :voiceCallChangedRecords) {
			VoiceCall voiceCall = (VoiceCall)recordState.record;
			Map<String,Object> previousState = recordState.previousState;

			if (!conversationVoiceCallMap.containsKey(voiceCall.ConversationId)) {
				conversationVoiceCallMap.put(voiceCall.ConversationId, new Set<Id>());
			}

			// Track each VoiceCall Id by ConversationId
			conversationVoiceCallMap.get(voiceCall.ConversationId).add(voiceCall.Id);

			for (SObjectField field :recordState.changedFields) {
				// Add the field to the set of changed fields for this voicecall, if updated
				if (voiceCall.get(field) != previousState.get(String.valueOf(field))) {
					if (!updatedFieldsByVoiceCallId.containsKey(voiceCall.Id)) {
						updatedFieldsByVoiceCallId.put(voiceCall.Id, new Set<String>());
					}

					updatedFieldsByVoiceCallId.get(voiceCall.Id).add(String.valueOf(field));
				}
			}
		}

		List<Id> conversationIdList = new List<Id>(conversationVoiceCallMap.keySet());

		// Invoke an instance of the async wworker for every chunk of required updates
		while (!conversationIdList.isEmpty()) {
			Map<Id,Set<String>> updateFieldsSubSet = new Map<Id,Set<String>>();
			Integer mapSize = 0;

			// We can have endless voicecalls here, as long as the amount of conversations doesn't exceed the chunk size
			// - 1 Conversation = 1 Callout
			while (!conversationIdList.isEmpty() && mapSize < CALLOUT_CHUNK_SIZE - 1) {
				Id conversationId = conversationIdList.remove(0);

				if (conversationVoiceCallMap.containsKey(conversationId)) {
					for (Id voiceCallId :conversationVoiceCallMap.get(conversationId)) {
						updateFieldsSubSet.put(voiceCallId, updatedFieldsByVoiceCallId.get(voiceCallId));
					}

					mapSize++;
				}
			}

			if (!updateFieldsSubSet.isEmpty()) {
				// Invoke the AsyncWorker, use Queueable Context for troubleshooting purposes
				uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(
					AsyncGenesysAttributeSync.class,
					new Map<String,Object>{
						'updatedFieldsByVoiceCallId' => updateFieldsSubSet
					}
				));
			}
		}
	}

	public with sharing class AsyncGenesysAttributeSync extends ApplicationUnitOfWork.AsyncWorker implements Queueable, Database.AllowsCallouts {
		@TestVisible
		public Set<Id> conversationIds;
		public Map<Id,Set<String>> updatedFieldsByVoiceCallId;
		private Map<Id,Set<Id>> voiceCallIdsByConversationId = new Map<Id,Set<Id>>();

		public override void execute(ApplicationUnitOfWork uow) {
			executeTask();
		}

		public void execute(QueueableContext context) {
			executeTask();
		}

		public void executeTask() {
			try {
				processGenesysCallouts();
			} catch(Exception ex) {
				System.debug(ex.getMessage() + '\r\n' + ex.getStackTraceString());
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

				if (params.containsKey('updatedFieldsByVoiceCallId')) {
					updatedFieldsByVoiceCallId = new Map<Id,Set<String>>();

					Map<String,Object> contents = (Map<String,Object>)(params.get('updatedFieldsByVoiceCallId'));

					for (String recordId :contents.keySet()) {
						Set<String> values = new Set<String>();

						for (Object value :(List<Object>)contents.get(recordId)) {
							values.add((String)value);
						}

						updatedFieldsByVoiceCallId.put(recordId, values);
					}
				}
			}
		}

		public void processGenesysCallouts() {
			// Retrieve the voice call records
			List<VoiceCall> voiceCallMap = VoiceCallsSelector.newInstance().selectByIds(
				new Set<Object>{ VoiceCallsSelector.Options.ORDERBY_OLDTONEW },
				updatedFieldsByVoiceCallId.keySet()
			);

			Map<String,GenesysSyncRequest> syncRequests = new Map<String,GenesysSyncRequest>();
			Map<String,String> genesysFieldMappings = new Map<String,String>();

			for (SObjectField field :GenesysConstants.genesysFieldMappings.keySet()) {
				genesysFieldMappings.put(String.valueOf(field), GenesysConstants.genesysFieldMappings.get(field));
			}


			for (VoiceCall voiceCall :voiceCallMap) {
				Map<String,Object> genesysUpdates = new Map<String,Object>();

				// Populate map of all voice call Ids by Conversation Ids for potential reattempts
				if (!voiceCallIdsByConversationId.containsKey(voiceCall.ConversationId)) {
					voiceCallIdsByConversationId.put(voiceCall.ConversationId, new Set<Id>());
				}

				voiceCallIdsByConversationId.get(voiceCall.ConversationId).add(voiceCall.Id);

				// Populate target map with updated field values against Genesys mapped attributes
				for (String field :updatedFieldsByVoiceCallId.get(voiceCall.Id)) {
					genesysUpdates.put(genesysFieldMappings.get(field), voiceCall.get(field));
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
				} catch (GenesysIntegration.GenesysResponseException grException) {
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
		GenesysIntegration genesysIntegration = GenesysIntegration.newInstance();
		Map<String,Object> requiredUpdates = request.customAttributes;
		String participantId = request.participantId;

		// For all regular inbound and outbound calls, the participantId is already provided by Genesys in the VoiceCall record
		if (String.isBlank(participantId)) {
			Map<String,Object> currentInteraction = genesysIntegration.fetchConversationCallDetail(request.conversationId);

			// Participant purpose depends on call type
			List<String> participantPurposes = new List<String>{
				'customer',		// default inbound call including consult / transfer
				'external',		// outbound call
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

			if (existingAttributeValues == null) {
				// No participant details found
				return;
			}

			participantId = String.valueOf(participantDetail.get('id'));

			// Compare existing attribute values
			requiredUpdates = getDeltaMap(existingAttributeValues, requiredUpdates);
		}

		if (!requiredUpdates.isEmpty()) {
			genesysIntegration.patchConversationParticipantAttributes(
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
}