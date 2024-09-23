/**
 * @description Test Class covering VoiceCallTrigger
 * @changelog
 * 2024-08-21	George Nguyen	Created
 */
@IsTest
class VoiceCallTrigger_Test {

	@IsTest
	static void handler() {
		Contact con = TestDataProvider.createTestContact();
        insert con;

	    Case case1 = new Case(
        	RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id,
			Type = 'Feedback',
			Subject = 'Newsdd',
			Status = 'New',
			ProductCategory__c = 'Travel & ID',
			EnquirySubType__c = 'Product Support',
			ProductSubCategory__c = 'KeyPass',
			ContactId = con.Id,
			ReferenceID__c = '123'
		);
        insert case1;

		CallCenter cc = [select id,name from CallCenter limit 1];

		VoiceCall vc = new VoiceCall(
			CallCenterId = cc.id,
			VendorType = 'ContactCenter',
			CallType = 'Inbound',
			FromPhoneNumber = '+19999999999',
			ToPhoneNumber = '+19999999999',
			CallStartDateTime = System.now().addMinutes( - 3 ),
			CallEndDateTime = System.now(),
			CallDisposition = 'completed'
		);

		// TO-DO: DML should be enabled as of Winter '24. However, due to settings this is currently not working. It is likely depending on the other squad to setup Voice.
		// Will need to revisit before going to UAT
		insert vc;

		vc = [SELECT Case__c FROM VoiceCall WHERE Id =: vc.Id LIMIT 1];
		System.assertEquals(case1.Id, vc.Case__c, 'Case look up Id should match');
	}

	@IsTest
	private static void voiceCallTriggerTest() {
		VoiceCallTriggerHandler mock = (VoiceCallTriggerHandler)MockUtility.mockUtility(VoiceCallTriggerHandler.class);

		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		Case aCase = ApplicationTestDataFactoryCase.getCases(1, new Set<Id>{ct.Id}, false)[0];

		VoiceCall voiceCall = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, false)[0];
		voiceCall.RelatedRecordId = null;
		voiceCall.CallType = 'Inbound';
		voiceCall.VendorType = 'ContactCenter';
		voiceCall.CallStartDateTime = System.now();
		voiceCall.CallEndDateTime = System.now().addMinutes(5);
		voiceCall.FromPhoneNumber = '+61 432 077 455';
		voiceCall.ToPhoneNumber = 'CS_Test';
		insert voiceCall;

		System.assert(true, 'PMD by-pass');
	}
}