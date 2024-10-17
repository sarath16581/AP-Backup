/**
 * @description
 * 	Test class Omni Presence status synchronisation to Genesys CTI status and vice versa between
 *	Genesys Cloud Platform and Salesforce.
 * @author		Paul Perry
 * @date		15/08/2024
 * @changelog
 */
@isTest
public with sharing class GenesysStatusSyncManager_Test {
	private static String genAdminStatusId = UUID.randomUUID().toString();
	private static String genOnQueueStatusId = UUID.randomUUID().toString();
	private static String genAvailableStatusId = UUID.randomUUID().toString();
	private static String genBusyStatusId = UUID.randomUUID().toString();
	private static String genUnknownStatusId = UUID.randomUUID().toString();

	private static String sfDevNameAvailableForVoice = 'AvailableForVoice';
	private static String sfDevNameAvailableForCase = 'AvailableForCase';
	private static String sfDevNameAdmin = 'Admin';
	private static String sfDevNameBusy = 'Busy';
	private static String sfDevNameNotMapped = 'NotMapped';

	private static Map<Id,ServicePresenceStatus> servicePresencesById = new Map<Id,ServicePresenceStatus>();
	private static Map<String,ServicePresenceStatus> servicePresencesByDevName = new Map<String,ServicePresenceStatus>();
	private static Map<String,GenesysAgentStatusMapping__mdt> mappingsBySFStatusName = new Map<String,GenesysAgentStatusMapping__mdt>();
	private static Map<String,GenesysAgentStatusMapping__mdt> mappingsByGenesysStatusId = new Map<String,GenesysAgentStatusMapping__mdt>();

	@isTest
	public static void genesysStatusSyncManagerTest() {
		// Test Data set for mappings and Omni Presence Status
		initialiseTestValues();

		// Mock selector classes
		// Mocking
		GenesysAgentStatusMappingsSelector statusMappingsSelector = (GenesysAgentStatusMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusMappingsSelector.class);
		ServicePresenceStatusSelector servicePresencesSelector = (ServicePresenceStatusSelector)MockUtility.mockSelector(ServicePresenceStatusSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();

		// Provide all the mocked responses

		// Add each mapping record by requested SF TargetStatus Name
		for (String sfTargetStatusName :mappingsBySFStatusName.keySet()) {
			MockUtility.Mocks.when(
				statusMappingsSelector.selectBySalesforcePresenceStatus(
					(String)fflib_Match.eqString(sfTargetStatusName),
					(Set<Object>)fflib_Match.isNull()
				)
			).thenReturn(mappingsBySFStatusName.get(sfTargetStatusName));
		}

		for (String genesysTargetStatusId :mappingsByGenesysStatusId.keySet()) {
			MockUtility.Mocks.when(
				statusMappingsSelector.selectByGenesysStatusId(
					(String)fflib_Match.eqString(genesysTargetStatusId),
					(Set<Object>)fflib_Match.isNull()
				)
			).thenReturn(mappingsByGenesysStatusId.get(genesysTargetStatusId));
		}

		for (String spDevName :servicePresencesByDevName.keySet()) {
			MockUtility.Mocks.when(
				servicePresencesSelector.selectByDeveloperName(
					(String)fflib_Match.eqString(spDevName),
					(Set<Object>)fflib_Match.isNull()
				)
			).thenReturn(
				servicePresencesByDevName.get(spDevName)
			);
		}

		((ApplicationLogger)MockUtility.Mocks.doAnswer(
			new DoNothingAnswer(), mockLogger
		)).logException(
			(ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(),
			(String)fflib_Match.anyString(), (String)fflib_Match.anyString(),
			(String)fflib_Match.anyString(), (String)fflib_Match.anyString(),
			(ApplicationLogger.LoggingLevel)fflib_Match.anyObject()
		);

		MockUtility.Mocks.stopStubbing();

		GenesysStatusSyncManager statusSyncInstance = new GenesysStatusSyncManager();
		Map<String,String> processedPayloadMap;

		// Scenario 1: Salesforce to Genesys Status Mappings
		processedPayloadMap = extractPayload(
			statusSyncInstance.onSalesforceStatusChange(
				generatePayload(sfDevNameAvailableForVoice, null)
			)
		);
		System.assertEquals(genOnQueueStatusId, processedPayloadMap.get('GenesysTargetStatusId'), 'Incorrect GenesysStatusId');

		processedPayloadMap = extractPayload(
			statusSyncInstance.onSalesforceStatusChange(
				generatePayload(sfDevNameAdmin, null)
			)
		);
		System.assertEquals(genAdminStatusId, processedPayloadMap.get('GenesysTargetStatusId'), 'Incorrect GenesysStatusId');

		// Expected to use the override status as specified in GenesysOutboundOverrideStatusId__c
		// SF: AvailableForCase => Gen: Available
		processedPayloadMap = extractPayload(
			statusSyncInstance.onSalesforceStatusChange(
				generatePayload(sfDevNameAvailableForCase, null)
			)
		);
		System.assertEquals(genAvailableStatusId, processedPayloadMap.get('GenesysTargetStatusId'), 'Incorrect GenesysStatusId');

		System.assertEquals(
			null,
			statusSyncInstance.onGenesysCloudStatusChange(
				generatePayload(sfDevNameNotMapped, null)
			),
			'Status mapping does not exist for this mapping'
		);

		// Scenario 2: Genesys to Salesforce Status Mappings
		processedPayloadMap = extractPayload(
			statusSyncInstance.onGenesysCloudStatusChange(
				generatePayload(null, genAvailableStatusId)
			)
		);
		System.assertEquals(
			String.valueOf(servicePresencesByDevName.get(sfDevNameAvailableForCase).Id),
			processedPayloadMap.get('SalesforceTargetStatusId'),
			'Incorrect SalesforceStatusId'
		);

		processedPayloadMap = extractPayload(
			statusSyncInstance.onGenesysCloudStatusChange(
				generatePayload(null, genBusyStatusId)
			)
		);
		System.assertEquals(
			String.valueOf(servicePresencesByDevName.get(sfDevNameBusy).Id),
			processedPayloadMap.get('SalesforceTargetStatusId'),
			'Incorrect SalesforceStatusId'
		);

		processedPayloadMap = extractPayload(
			statusSyncInstance.onGenesysCloudStatusChange(
				generatePayload(null, genOnQueueStatusId)
			)
		);
		System.assertEquals(
			String.valueOf(servicePresencesByDevName.get(sfDevNameAvailableForVoice).Id),
			processedPayloadMap.get('SalesforceTargetStatusId'),
			'Incorrect SalesforceStatusId'
		);

		System.assertEquals(
			null,
			statusSyncInstance.onGenesysCloudStatusChange(
				generatePayload(null, genUnknownStatusId)
			),
			'Status mapping does not exist for this mapping'
		);

		// Verify that 2 errors have been logged due to not mapped status updates
		((ApplicationLogger)MockUtility.Mocks.verify(
			mockLogger,
			MockUtility.Mocks.times(2)
		)).logException(
			(ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(),
			(String)fflib_Match.anyObject(), (String)fflib_Match.anyObject(),
			(String)fflib_Match.anyObject(), (String)fflib_Match.anyObject(),
			(ApplicationLogger.LoggingLevel)fflib_Match.anyObject()
		);
	}

	private static String generatePayload(String newSalesforceName, String newGenesysStatusId) {
		return JSON.serialize(new Map<String,Object>{
			'genesysCloudStatus' => new Map<String,Object>{
				'targetStatus' => new Map<String,Object>{
					'systemPresence' => mappingsByGenesysStatusId.get(newGenesysStatusId)?.GenesysStatusLabel__c,
					'id' => newGenesysStatusId
				},
				'currentStatus' => new Map<String,Object>{
					'systemPresence' => 'NOT APPLICABLE',
					'id' => UUID.randomUUID()
				}
			},
			'salesforceStatus' => new Map<String,Object>{
				'targetStatus' => new Map<String,Object>{
					'statusName' => newSalesforceName,
					'statusId' => servicePresencesByDevName.get(newSalesforceName)?.Id,
					'statusApiName' => newSalesforceName
				},
				'currentStatus' => new Map<String,Object>{
					'statusName' => 'Not Applicable',
					'statusId' => fflib_IDGenerator.generate(ServicePresenceStatus.SObjectType),
					'statusApiName' => 'NOT APPLICABLE'
				}
			}
		});
	}

	private static Map<String,String> extractPayload(String payload) {
		Map<String,String> result = new Map<String,String>();
		Map<String,Object> payloadMap = (Map<String,Object>)JSON.deserializeUntyped(payload);

		Map<String,String> extractMappings = new Map<String,String>{
			'GenesysTargetStatusId' => 'genesysCloudStatus.targetStatus.id',
			'GenesysTargetStatusName' => 'genesysCloudStatus.targetStatus.systemPresence',
			'SalesforceTargetStatusName' => 'salesforceStatus.targetStatus.statusApiName',
			'SalesforceTargetStatusId' => 'salesforceStatus.targetStatus.statusId'
		};

		for (String key :extractMappings.keySet()) {
			result.put(key, String.valueOf(GenesysStatusSyncManager.getObjectAttribute(extractMappings.get(key), payloadMap)));
		}

		return result;
	}

	private static void initialiseTestValues() {
		Set<String> sfPresenceStatusDeveloperNames = new Set<String>{
			sfDevNameAvailableForVoice, sfDevNameAvailableForCase, sfDevNameAdmin, sfDevNameBusy
		};

		for (String sfDevName :sfPresenceStatusDeveloperNames) {
			ServicePresenceStatus spStatus = (ServicePresenceStatus)ApplicationTestDataFactory.setUnwritableFields(
				new ServicePresenceStatus(),
				convertFieldMap(new Map<SObjectField,Object>{
					ServicePresenceStatus.Id => fflib_IDGenerator.generate(ServicePresenceStatus.SObjectType),
					ServicePresenceStatus.DeveloperName => sfDevName
				})
			);

			servicePresencesById.put(spStatus.Id, spStatus);
			servicePresencesByDevName.put(sfDevName, spStatus);
		}

		List<List<String>> genesysStatusDefinitions = new List<List<String>>{
			// Values in this order:
			new List<String>{ sfDevNameAvailableForVoice, 'On Queue', genOnQueueStatusId },
			new List<String>{ sfDevNameAdmin, 'Administration', genAdminStatusId },
			new List<String>{ sfDevNameAvailableForCase, 'Available for Case', genAvailableStatusId },
			new List<String>{ sfDevNameBusy, 'Busy', genBusyStatusId }
		};

		for (List<String> genStatusDef :genesysStatusDefinitions){
			GenesysAgentStatusMapping__mdt statusMapping = (GenesysAgentStatusMapping__mdt)ApplicationTestDataFactory.setUnwritableFields(
				new GenesysAgentStatusMapping__mdt(),
				convertFieldMap(new Map<SObjectField,Object>{
					GenesysAgentStatusMapping__mdt.Id => fflib_IDGenerator.generate(GenesysAgentStatusMapping__mdt.SObjectType),
					GenesysAgentStatusMapping__mdt.DeveloperName => genStatusDef[0],
					GenesysAgentStatusMapping__mdt.SalesforcePresenceStatus__c => genStatusDef[0],
					GenesysAgentStatusMapping__mdt.GenesysStatusLabel__c => genStatusDef[1],
					GenesysAgentStatusMapping__mdt.GenesysStatusId__c => genStatusDef[2]
				})
			);

			mappingsBySFStatusName.put(statusMapping.DeveloperName, statusMapping);
			mappingsByGenesysStatusId.put(statusMapping.GenesysStatusId__c, statusMapping);
		}
	}
	/**
	 * Converts a Map of SObjectFields to a Map of FieldApiNames with values
	 * @param objectMap input map
	 * @return Map where SObjectField keys are turned into String keys
	 */
	private static Map<String,Object> convertFieldMap(Map<SObjectField,Object> objectMap) {
		Map<String,Object> result = new Map<String,Object>();

		for (SObjectField field :objectMap.keySet()) {
			result.put(String.valueOf(field), objectMap.get(field));
		}

		return result;
	}

	public class DoNothingAnswer implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			return null;
		}
	}
}