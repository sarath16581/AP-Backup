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
		ServicePresenceStatus sfPresenceAvailableVoice = new ServicePresenceStatus(
			Id = fflib_IDGenerator.generate(ServicePresenceStatus.SObjectType),
			MasterLabel = 'Available for Voice',
			DeveloperName = 'Available_for_Voice'
		);

		ServicePresenceStatus sfPresenceAvailable =new ServicePresenceStatus(
			Id = fflib_IDGenerator.generate(ServicePresenceStatus.SObjectType),
			MasterLabel = 'Available',
			DeveloperName = 'Available'
		);

		List<ServicePresenceStatus> testServicePresenceStatuses = new List<ServicePresenceStatus>{
			sfPresenceAvailableVoice, sfPresenceAvailable
		};

		// Genesys Agent Status Statuses
		GenesysAgentStatusIdMapping__c genStatusAway = new GenesysAgentStatusIdMapping__c(
			Id = fflib_IDGenerator.generate(GenesysAgentStatusIdMapping__c.SObjectType),
			Name = 'Away',
			StatusId__c = 'GEN-Away-Id',
			Source__c = 'Genesys'
		);

		GenesysAgentStatusIdMapping__c genStatusAvailable = new GenesysAgentStatusIdMapping__c(
			Id = fflib_IDGenerator.generate(GenesysAgentStatusIdMapping__c.SObjectType),
			Name = 'Available',
			StatusId__c = 'GEN-Available-Id',
			Source__c = 'Genesys'
		);

		List<GenesysAgentStatusIdMapping__c> testAgentStatus = new List<GenesysAgentStatusIdMapping__c>{
			genStatusAway, genStatusAvailable
		};

		// System Mappings SF => Genesys + Genesys => SF
		Map<String,GenesysAgentStatusMapping__mdt> systemMappings = getSystemMappings(
			new Map<String,Map<String,Object>>{
				// Mappings Genesys => Salesforce
				'genesysStatusChange' => new Map<String,Object>{
					// 'AVAILABLE' => 'AVAILABLE FOR VOICE'
					genStatusAvailable.Name => sfPresenceAvailableVoice.DeveloperName
				},

				// Mappings Salesforce => Genesys
				'salesforceStatusChange' => new Map<String,Object>{
					// 'AVAILABLE' => 'AWAY'
					sfPresenceAvailable.DeveloperName => genStatusAway.Name
				}
			}
		);

		// Emulate the input parameter payload from the genesyscloud.GenesysSCVExtension.Status interface
		final String eventData = JSON.serialize(
			new Map<String,Object>{
				'salesforceStatus' => new Map<String,Object>{
					'targetStatus' => new Map<String,Object>{
						'statusName' => sfPresenceAvailable.DeveloperName,
						'statusId' => sfPresenceAvailable.Id
					}
				},
				'genesysCloudStatus' => new Map<String,Object>{
					'targetStatus' => new Map<String,Object>{
						'systemPresence' => genStatusAvailable.Name,
						'id' => genStatusAvailable.StatusId__c
					}
				}
			}
		);

		ServicePresenceStatusSelector mockPresenceStatus = (ServicePresenceStatusSelector)MockUtility.mockSelector(ServicePresenceStatusSelector.class);
		GenesysAgentStatusIdMappingsSelector mockAgentStatusId = (GenesysAgentStatusIdMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusIdMappingsSelector.class);
		GenesysAgentStatusMappingsSelector mockAgentStatusMapping = (GenesysAgentStatusMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusMappingsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks
			.when(mockPresenceStatus.selectActiveStatuses())
			.thenReturn(testServicePresenceStatuses);

		MockUtility.Mocks
			.when(mockAgentStatusId.selectBySource((String)fflib_Match.anyString()))
			.thenReturn(testAgentStatus);

		MockUtility.Mocks
			.when(mockAgentStatusMapping.selectByDeveloperName((Set<String>)fflib_Match.anyObject()))
			.thenReturn(systemMappings);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		GenesysSCVStatusSyncManager syncManagerInstance = new GenesysSCVStatusSyncManager();
		String toSalesforce = syncManagerInstance.onGenesysCloudStatusChange(eventData);
		String toGenesys = syncManagerInstance.onSalesforceStatusChange(eventData);

		System.debug(String.join(new String[]{ toSalesforce, toGenesys }, '\n'));

		System.assertNotEquals(null, toGenesys, 'Response message expected');
		System.assertNotEquals(null, toSalesforce, 'Response message expected');

		String salesforceTargetStatusId = GenesysSCVStatusSyncManager.getTargetStatus(
			GenesysSCVStatusSyncManager.StatusOrigin.GENESYS,
			genStatusAvailable.Name,
			genStatusAvailable.StatusId__c
		);

		System.assertEquals(sfPresenceAvailableVoice.Id, salesforceTargetStatusId, 'Incorrect Status Mapping to Salesforce');

		String genesysTargetStatusId = GenesysSCVStatusSyncManager.getTargetStatus(
			GenesysSCVStatusSyncManager.StatusOrigin.SALESFORCE,
			sfPresenceAvailable.MasterLabel,
			sfPresenceAvailable.Id
		);

		System.assertEquals(genStatusAway.StatusId__c, genesysTargetStatusId, 'Incorrect Status Mapping to Genesys');

		try{
			GenesysSCVStatusSyncManager.getTargetStatus(null, 'UNAVAILABLE', null);
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