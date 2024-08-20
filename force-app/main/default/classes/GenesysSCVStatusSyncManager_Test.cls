/**
 * @author		Genesys, Paul Perry
 * @date		15/08/2024
 * @description
 * 	Test class Omni Presence status synchronisation to Genesys CTI status and vice versa between
 *	Genesys Cloud Platform and Salesforce.
 */
@isTest
public with sharing class GenesysSCVStatusSyncManager_Test {
    @IsTest
	public static void testSyncManager(){
		// Salesforce Service Presence Statuses
		ServicePresenceStatus testServicePresenceStatus = new ServicePresenceStatus(
			Id = fflib_IDGenerator.generate(ServicePresenceStatus.SObjectType),
			MasterLabel = 'Available for Voice',
			DeveloperName = 'AVAILABLE_VOICE'
		);

		// Genesys Agent Status Statuses
		GenesysAgentStatusIdMapping__c testAgentStatus = new GenesysAgentStatusIdMapping__c(
			Id = fflib_IDGenerator.generate(GenesysAgentStatusIdMapping__c.SObjectType),
			Name = 'AWAY',
			StatusId__c = 'GEN-AWAY-Id',
			Source__c = 'Genesys'
		);

		// Emulate the input parameter payload from the genesyscloud.GenesysSCVExtension.Status interface
		final String eventData = JSON.serialize(
			new Map<String,Object>{
				'salesforceStatus' => new Map<String,Object>{
					'targetStatus' => new Map<String,Object>{
						'statusName' => 'AVAILABLE',
						'statusId' => 'SF_AVAILABLE-Id'
					}
				},
				'genesysCloudStatus' => new Map<String,Object>{
					'targetStatus' => new Map<String,Object>{
						'systemPresence' => 'AVAILABLE',
						'id' => 'GEN_AVAILABLE-Id'
					}
				}
			}
		);

		// System Mappings SF => Genesys + Genesys => SF
		Map<String,GenesysAgentStatusMapping__mdt> systemMappings = getSystemMappings(
			new Map<String,Map<String,Object>>{
				// Mappings Genesys => Salesforce
				'genesysStatusChange' => new Map<String,Object>{
					'AVAILABLE' => 'AVAILABLE_VOICE'
				},

				// Mappings Salesforce => Genesys
				'salesforceStatusChange' => new Map<String,Object>{
					'AVAILABLE' => 'AWAY'
				}
			}
		);

		ServicePresenceStatusSelector mockPresenceStatus = (ServicePresenceStatusSelector)MockUtility.mockSelector(ServicePresenceStatusSelector.class);
		GenesysAgentStatusIdMappingsSelector mockAgentStatusId = (GenesysAgentStatusIdMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusIdMappingsSelector.class);
		GenesysAgentStatusMappingsSelector mockAgentStatusMapping = (GenesysAgentStatusMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusMappingsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks
			.when(mockPresenceStatus.selectActiveStatuses())
			.thenReturn(new List<ServicePresenceStatus>{ testServicePresenceStatus });

		MockUtility.Mocks
			.when(mockAgentStatusId.selectBySource((String)fflib_Match.anyString()))
			.thenReturn(new List<GenesysAgentStatusIdMapping__c>{ testAgentStatus });

		MockUtility.Mocks
			.when(mockAgentStatusMapping.selectByDeveloperName((Set<String>)fflib_Match.anyObject()))
			.thenReturn(systemMappings);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		GenesysSCVStatusSyncManager syncManagerInstance = new GenesysSCVStatusSyncManager();
		String toSalesforce = syncManagerInstance.onGenesysCloudStatusChange(eventData);
		String toGenesys = syncManagerInstance.onSalesforceStatusChange(eventData);

		System.assertNotEquals(null, toGenesys, 'Response message expected');
		System.assertNotEquals(null, toSalesforce, 'Response message expected');

		String salesforceTargetStatusId = GenesysSCVStatusSyncManager.getTargetStatus(
			GenesysSCVStatusSyncManager.StatusOrigin.GENESYS,
			'AVAILABLE'
		);

		System.assertEquals(testServicePresenceStatus.Id, salesforceTargetStatusId, 'Incorrect Status Mapping to Salesforce');

		String genesysTargetStatusId = GenesysSCVStatusSyncManager.getTargetStatus(
			GenesysSCVStatusSyncManager.StatusOrigin.SALESFORCE,
			'AVAILABLE'
		);

		System.assertEquals(testAgentStatus.StatusId__c, genesysTargetStatusId, 'Incorrect Status Mapping to Genesys');

		try{
			GenesysSCVStatusSyncManager.getTargetStatus(null, 'UNAVAILABLE');
			System.assert(false, 'Exception should\'ve been thrown');
		} catch (HandledException hEx) {
			System.assert(true, 'Expected caught');
		}

		Test.stopTest();
	}

	/**
	 * Helper method to create a map of the metadata records
	 * @param metadataMappings
	 * @return Map of CustomMetadata records by mappingType name
	 */
	private static Map<String,GenesysAgentStatusMapping__mdt> getSystemMappings(Map<String,Object> metadataMappings) {
		Map<String,GenesysAgentStatusMapping__mdt> result = new Map<String,GenesysAgentStatusMapping__mdt>();

		for (String mappingType :metadataMappings.keySet()) {
			result.put(
				mappingType,
				(GenesysAgentStatusMapping__mdt)JSON.deserialize(
					JSON.serialize(new Map<SObjectField,Object>{
						GenesysAgentStatusMapping__mdt.Id => fflib_IDGenerator.generate(GenesysAgentStatusMapping__mdt.SObjectType),
						GenesysAgentStatusMapping__mdt.DeveloperName => mappingType,
						GenesysAgentStatusMapping__mdt.MappingData__c => JSON.serialize(metadataMappings.get(mappingType)),
						GenesysAgentStatusMapping__mdt.MappingType__c => mappingType
					}),
					GenesysAgentStatusMapping__mdt.class
				)
			);
		}

		return result;
	}
}