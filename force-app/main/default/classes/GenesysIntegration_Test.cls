/**
 * Test class for Genesys Integration that asserts processing callouts and its different responses
 * @author Paul Perry
 * @date 27/08/2024
 * @group Tests
 * @tag SCV/Unified
 */
@IsTest
public with sharing class GenesysIntegration_Test {
	@IsTest
	private static void testHappyFlow() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

		Test.startTest();

		GenesysIntegration instance = GenesysIntegration.newInstance();
		String conversationId = String.valueOf(UUID.randomUUID());
		String participantId = String.valueOf(UUID.randomUUID());

		Map<String,Object> response = instance.fetchConversationCallDetail(conversationId);
		System.assert(
			response != null,
			'response expected'
		);

		System.assert(
			instance.patchConversationParticipantAttributes(
				conversationId, participantId,
				new Map<String,Object>{ 'Tracking_Number' => '12345678' }
			).contains('Tracking_Number'),
			'response expected'
		);

		Test.stopTest();
	}

	@IsTest
	private static void testBlueMoonFlow() {
		List<Integer> responseCodes = new List<Integer>{
			200, 	// Authentication token response
			404,	// fetchConversationCallDetail response
			200, 	// Authentication token response
			429		// unable to patch Conversation Participant Attributres
		};

		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseCodes));

		String conversationId = String.valueOf(UUID.randomUUID());

		Test.startTest();
		GenesysIntegration instance = GenesysIntegration.newInstance();

		try {
			// Scenario where the conversation attributes cannot be retrieved from Genesys
			instance.fetchConversationCallDetail(conversationId);
			System.assert(false, 'Exception expected');
		} catch (GenesysIntegration.GenesysResponseException grEx) {
			System.assert(true, 'Exception expected');
		}

		try {
			String participantId = String.valueOf(UUID.randomUUID());
			Map<String,Object> attributes = new Map<String,Object>{
				'Tracking_Number' => '12345678'
			};

			// Scenario where the conversation attributes cannot be patched to Genesys due to limit-reached exception
			instance.patchConversationParticipantAttributes(conversationId, participantId, attributes);
			System.assert(false, 'Exception expected');
		} catch (GenesysIntegration.GenesysResponseException grEx) {
			System.assert(true, 'Exception expected');
		}

		Test.stopTest();
	}

    public class MockHttpResponseGenerator implements HttpCalloutMock {
		private List<Integer> responseCodes;

		@SuppressWarnings('PMD.EmptyStatementBlock')
		public MockHttpResponseGenerator() { }
		public MockHttpResponseGenerator(List<Integer> responseCodes) {
			this();
			this.responseCodes = responseCodes;
		}

		// Implement this interface method
		public HTTPResponse respond(HTTPRequest req) {
			String body;
			Integer responseCode;

			if (this.responseCodes != null && !this.responseCodes.isEmpty()) {
				responseCode = this.responseCodes.remove(0);
			}

			if (req.getEndpoint().contains('/participants/')) {
				if (responseCode == null) {
					responseCode = 202;
				}

				body = req.getBody();
			} else if (req.getEndpoint().contains('conversations/calls/')) {
				if (responseCode == null) {
					responseCode = 200;
				}

				body = MOCKRESPONSECALLLOG;
			}

			// Create a fake response
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(body);
			res.setStatusCode(responseCode);
			return res;
		}
	}

	public static final String MOCKRESPONSECALLLOG = String.join(new String[]{
		'{ "id": "48c45fba-1298-4028-b6b5-968fffe9222e", "participants": [ { "id": "1412a2c0-271b-462b-b911-1',
		'd36ab744d8f", "name": "Mobile Number, Australia", "address": "tel:+61431598408", "startTime": "2024-',
		'08-29T23:44:33.314Z", "connectedTime": "2024-08-29T23:44:33.363Z", "endTime": "2024-08-29T23:46:29.9',
		'75Z", "purpose": "customer", "state": "terminated", "direction": "inbound", "disconnectType": "endpo',
		'int", "held": false, "wrapupRequired": false, "mediaRoles": [ "full" ], "queue": { "id": "ec8d6c17-2',
		'bda-4281-b242-4db99a3ca5f9", "selfUri": "/api/v2/routing/queues/ec8d6c17-2bda-4281-b242-4db99a3ca5f9',
		'" }, "attributes": { "Enquiry_Type": "Local Track", "Product_Category": "Parcel", "Customer_Particip',
		'ant": "1412a2c0-271b-462b-b911-1d36ab744d8f", "FSUID": "abcd-1234-defg-5678", "Product_Sub_Category"',
		': "eParcel", "Tracking_ID": "XYZ", "scv_f24dd6d2-6ae6-4d75-b961-18b9d033e72b:48c45fba-1298-4028-b6b5',
		'-968fffe9222e": "accepted", "Consignment": "123456789", "Customer_Segment": "Training", "CaseId": "5',
		'00AD00000HBy3vYAD", "SF_URLPop": "apex/OpenCTI?action=close", "Tracking_Number": "XYZ", "Dim_Attribu',
		'te_1": "Pricing", "phoneNumber": "tel:+61431598408", "Product_Subcategory": "eParcel", "Enquiry_Subt',
		'ype": "Missing Parcel", "Service_Type": "Domestic Parcels", "Division": "AP", "Service_Subtype": "Pa',
		'rcel Post", "VoiceCall_Id": "", "Enquiry_Sub_Type": "Missing Parcel", "Dim_Attribute_2": "General En',
		'quiry", "Release_Party": "PEER", "scv_externalObjectId": "0LQAD0000017bNF", "shouldThrow": "true", "',
		'Recording_Paused": "No" }, "provider": "Edge", "externalContact": { "id": "0f31c249-327e-4137-822a-3',
		'0baa99986e5", "selfUri": "/api/v2/externalcontacts/contacts/0f31c249-327e-4137-822a-30baa99986e5" },',
		' "muted": false, "confined": false, "recording": false, "recordingState": "none", "ani": "tel:+61431',
		'598408", "dnis": "tel:+61380072332", "securePause": false }, { "id": "6c93e24f-0c3f-45da-b799-9de54d',
		'e8d8c2", "name": "SFDC Testing Line", "address": "sip:5c8a47f1-4298-4c98-9895-8176c1dfb4c3@127.0.0.1',
		';language=en-US;user=ivr", "startTime": "2024-08-29T23:44:33.330Z", "connectedTime": "2024-08-29T23:',
		'44:33.340Z", "endTime": "2024-08-29T23:44:38.605Z", "purpose": "ivr", "state": "terminated", "direct',
		'ion": "inbound", "disconnectType": "transfer", "held": false, "wrapupRequired": false, "mediaRoles":',
		' [], "attributes": {}, "provider": "Edge", "wrapup": { "code": "d1a4e3d8-4c1a-49cc-b7fd-c5a6549b64dc',
		'", "tags": [], "durationSeconds": 7, "endTime": "2024-08-29T23:46:36.522Z", "notes": "" }, "peer": "',
		'ac62337a-d712-433c-813e-07821696fdea", "muted": false, "confined": false, "recording": false, "recor',
		'dingState": "none", "ani": "tel:+61431598408", "dnis": "sip:5c8a47f1-4298-4c98-9895-8176c1dfb4c3@127',
		'.0.0.1;language=en-US;user=ivr", "securePause": false }, { "id": "dae90a58-48d1-47cd-b400-f0437c0be7',
		'90", "name": "CS_Test", "address": "sip:ec8d6c17-2bda-4281-b242-4db99a3ca5f9@127.0.0.1;language=en-A',
		'U;user=acd", "startTime": "2024-08-29T23:44:38.612Z", "connectedTime": "2024-08-29T23:44:38.621Z", "',
		'endTime": "2024-08-29T23:45:05.919Z", "purpose": "acd", "state": "terminated", "direction": "inbound',
		'", "disconnectType": "transfer", "held": false, "wrapupRequired": false, "mediaRoles": [], "queue": ',
		'{ "id": "ec8d6c17-2bda-4281-b242-4db99a3ca5f9", "selfUri": "/api/v2/routing/queues/ec8d6c17-2bda-428',
		'1-b242-4db99a3ca5f9" }, "attributes": {}, "provider": "Edge", "peer": "ac62337a-d712-433c-813e-07821',
		'696fdea", "conversationRoutingData": { "queue": { "id": "ec8d6c17-2bda-4281-b242-4db99a3ca5f9", "sel',
		'fUri": "/api/v2/routing/queues/ec8d6c17-2bda-4281-b242-4db99a3ca5f9" }, "priority": 0, "skills": [],',
		' "scoredAgents": [], "label": "631f0939-be32-495a-baf9-970abb039192" }, "muted": false, "confined": ',
		'false, "recording": false, "recordingState": "none", "ani": "tel:+61431598408", "dnis": "sip:ec8d6c1',
		'7-2bda-4281-b242-4db99a3ca5f9@127.0.0.1;language=en-AU;user=acd", "securePause": false }, { "id": "a',
		'3af6647-8e14-4d9a-ba67-fd7f82f70266", "address": "sip:6695cb087b162c32279c7803+australiapost1.orgspa',
		'n.com;tgrp=2e1968f9-06a1-4b1c-98e2-f71c128a0af4;trunk-context=australiapost1@localhost", "startTime"',
		': "2024-08-29T23:44:38.796Z", "endTime": "2024-08-29T23:44:59.135Z", "purpose": "agent", "state": "t',
		'erminated", "direction": "inbound", "disconnectType": "client", "held": false, "wrapupRequired": fal',
		'se, "wrapupPrompt": "mandatory", "mediaRoles": [ "full" ], "user": { "id": "dc4698b7-8aa2-490d-a869-',
		'b1e44c1cf9de", "selfUri": "/api/v2/users/dc4698b7-8aa2-490d-a869-b1e44c1cf9de" }, "queue": { "id": "',
		'ec8d6c17-2bda-4281-b242-4db99a3ca5f9", "selfUri": "/api/v2/routing/queues/ec8d6c17-2bda-4281-b242-4d',
		'b99a3ca5f9" }, "attributes": { "Release_Party": "CLIENT", "scv_externalObjectId": "0LQAD0000017bNF",',
		' "shouldThrow": "true", "Recording_Paused": "No" }, "script": { "id": "70cfdbff-7a82-4118-86b1-c8e0b',
		'1ceda57", "selfUri": "/api/v2/scripts/70cfdbff-7a82-4118-86b1-c8e0b1ceda57" }, "alertingTimeoutMs": ',
		'20000, "provider": "Edge", "peer": "ac62337a-d712-433c-813e-07821696fdea", "muted": false, "confined',
		'": false, "recording": false, "recordingState": "none", "ani": "sip:+61431598408@10.47.7.132;user=ph',
		'one", "dnis": "sip:6695cb087b162c32279c7803+australiapost1.orgspan.com;tgrp=2e1968f9-06a1-4b1c-98e2-',
		'f71c128a0af4;trunk-context=australiapost1@localhost", "securePause": false }, { "id": "bbdf2059-7944',
		'-4707-8a3c-5002aa63691e", "address": "sip:66318b4e4990871be4a61c5f+australiapost1.orgspan.com;tgrp=2',
		'e1968f9-06a1-4b1c-98e2-f71c128a0af4;trunk-context=australiapost1@localhost", "startTime": "2024-08-2',
		'9T23:45:01.367Z", "connectedTime": "2024-08-29T23:45:05.912Z", "endTime": "2024-08-29T23:46:29.978Z"',
		', "purpose": "agent", "state": "terminated", "direction": "inbound", "disconnectType": "peer", "held',
		'": false, "wrapupRequired": true, "wrapupPrompt": "mandatory", "mediaRoles": [ "full" ], "user": { "',
		'id": "dc4698b7-8aa2-490d-a869-b1e44c1cf9de", "selfUri": "/api/v2/users/dc4698b7-8aa2-490d-a869-b1e44',
		'c1cf9de" }, "queue": { "id": "ec8d6c17-2bda-4281-b242-4db99a3ca5f9", "selfUri": "/api/v2/routing/que',
		'ues/ec8d6c17-2bda-4281-b242-4db99a3ca5f9" }, "attributes": { "Release_Party": "PEER" }, "script": { ',
		'"id": "70cfdbff-7a82-4118-86b1-c8e0b1ceda57", "selfUri": "/api/v2/scripts/70cfdbff-7a82-4118-86b1-c8',
		'e0b1ceda57" }, "alertingTimeoutMs": 20000, "provider": "Edge", "wrapup": { "code": "d1a4e3d8-4c1a-49',
		'cc-b7fd-c5a6549b64dc", "notes": "", "tags": [], "durationSeconds": 7, "endTime": "2024-08-29T23:46:3',
		'6.522Z" }, "peer": "ac62337a-d712-433c-813e-07821696fdea", "startAcwTime": "2024-08-29T23:46:29.978Z',
		'", "endAcwTime": "2024-08-29T23:46:36.522Z", "muted": false, "confined": false, "recording": false, ',
		'"recordingState": "none", "ani": "sip:+61431598408@10.47.7.132;user=phone", "dnis": "sip:66318b4e499',
		'0871be4a61c5f+australiapost1.orgspan.com;tgrp=2e1968f9-06a1-4b1c-98e2-f71c128a0af4;trunk-context=aus',
		'traliapost1@localhost", "securePause": false } ], "otherMediaUris": [], "recentTransfers": [ { "id":',
		' "dd580423-044e-4916-b89f-5f666a5e2c41", "state": "Failed", "dateIssued": "2024-08-29T23:44:38.749Z"',
		', "initiator": {}, "modifiedBy": {}, "destination": { "userId": "0e4e57e0-d4f5-44c8-8b64-08bf26214a4',
		'2", "address": "sip:vikas.malchalam%40auspost.com.au@localhost" }, "transferType": "Attended" }, { "',
		'id": "25dc068e-8312-4af4-ac01-44c594a3fb5c", "state": "Complete", "dateIssued": "2024-08-29T23:45:01',
		'.313Z", "initiator": {}, "modifiedBy": {}, "destination": { "userId": "dc4698b7-8aa2-490d-a869-b1e44',
		'c1cf9de", "address": "sip:paul.perry5%40auspost.com.au@localhost" }, "transferType": "Attended" } ],',
		' "utilizationLabelId": "631f0939-be32-495a-baf9-970abb039192", "recordingState": "none", "securePaus',
		'e": false, "selfUri": "/api/v2/conversations/calls/48c45fba-1298-4028-b6b5-968fffe9222e" }"'
	}, '');
}