/**
* @author Paul Perry
* @date 15/08/2024
* @group Tests
* @tag Util 
*
* @description
*	One-time Status Sync will be used by SCV to align CTI Status with Omni presence status
*/
@IsTest
global with sharing class GenesysStatusSyncUtil_Test {
    @isTest
	public static void runTest() {
		/**
		 * TEST Data
		 */		
		// Genesys Agent Status Statuses
		GenesysAgentStatusIdMapping__c testAgentStatus = new GenesysAgentStatusIdMapping__c(
			Id = fflib_IDGenerator.generate(GenesysAgentStatusIdMapping__c.SObjectType),
			Name = 'AWAY',
			StatusId__c = 'GEN-AWAY-Id',
			Source__c = 'Genesys'
		);

		GenesysAgentStatusIdMappingsSelector mockAgentStatusId = (GenesysAgentStatusIdMappingsSelector)MockUtility.mockSelector(GenesysAgentStatusIdMappingsSelector.class);		
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		/**
		 * STUBBING
		 */
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks
			.when(mockAgentStatusId.selectBySource((String)fflib_Match.anyString()))
			.thenReturn(new List<GenesysAgentStatusIdMapping__c>{ testAgentStatus });

		MockUtility.Mocks
			.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks
			.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
			
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

		MockUtility.Mocks.stopStubbing();

		/**
		 * Test
		 */
		Test.startTest();

		GenesysStatusSyncUtil.syncGenesysStatuses();

		Test.stopTest();

		/**
		 * Verify test results
		 */
		fflib_ArgumentCaptor insertedRecordsCaptor = fflib_ArgumentCaptor.forClass(List<GenesysAgentStatusIdMapping__c>.class);

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert(
			(List<GenesysAgentStatusIdMapping__c>)insertedRecordsCaptor.capture()
		);

		List<Object> insertedRecordsArray = (List<Object>)insertedRecordsCaptor.getAllValues();
		List<GenesysAgentStatusIdMapping__c> insertedRecords = (List<GenesysAgentStatusIdMapping__c>)insertedRecordsArray[0];

		System.assert(!insertedRecords.isEmpty(), 'No records inserted');
    }

	global class MockHttpResponseGenerator implements HttpCalloutMock {
		// Implement this interface method
		global HTTPResponse respond(HTTPRequest req) {
			String body;

			if (req.getEndpoint().contains('systempresences')) {
				body = JSON.serialize(new List<Object>{
					new Map<String,Object>{
						'id' => '6a3af858-942f-489d-9700-5f9bcdcdae9b',
						'name' => 'AVAILABLE'
					},
					new Map<String,Object>{
						'id' => '5e5c5c66-ea97-4e7f-ac41-6424784829f2',
						'name' => 'AWAY'
					}
				});
			} else {
				body = JSON.serialize(new Map<String,Object>{
					'access_token' => 'fake-access-token'
				});
			}

			// Create a fake response
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(body);
			res.setStatusCode(200);
			return res;
		}
	}
}