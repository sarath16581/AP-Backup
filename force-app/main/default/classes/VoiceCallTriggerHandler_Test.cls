/**
 * @description Test class for VoiceCallTriggerHandler
 * @author SteveL
 * @date 2024-09-11
 * @changelog
 * 2024-09-11 - SteveL - created
 */

@IsTest
class VoiceCallTriggerHandler_Test {
    @IsTest
	private static void getUnitOfWorkSObjectTypes() {

		VoiceCallTriggerHandler handler = new VoiceCallTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(VoiceCall.SObjectType, handler.getsObjectType(), 'Should return VoiceCall sobject type');

		List<SObjectType> types = VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes();

		System.assert(types.contains(AgentWork.SObjectType), 'Should have AgentWork sobject type');
	}

	@IsTest
	private static void main() {
		VoiceCallTriggerHandler handler = new VoiceCallTriggerHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(VoiceCallTriggerHandler.class.getName());
		System.assert(recordFilterIndexes.containsKey(CaseRecordPopulationModule.class), 'It should have CaseRecordPopulationModule class registered');
		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(VoiceCall.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes().contains(VoiceCall.SObjectType), 'Expected valid list of sobject types to be returned');

		List<VoiceCall> voiceCalls = new List<VoiceCall>();
		voiceCalls.add(new VoiceCall(VendorCallKey = '123456'));
		voiceCalls.add(new VoiceCall(VendorCallKey = '654321'));

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(voiceCalls);
		Assert.areEqual(voiceCalls.size(), filteredGroupRecords.get(VoiceCallTriggerHandler.FILTER_ALLWITHVENDORKEY).size(), 'Expected the records to be filtered into 1 groups with 2 records');
	}

}