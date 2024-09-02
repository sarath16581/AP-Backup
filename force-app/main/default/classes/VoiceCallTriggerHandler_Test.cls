/*
Test class for VoiceCallTriggerHandler
Changelog:
2024-08-23	George Nguyen	Created
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

	/*
		Making sure that the right modules are registered with the right filters
	*/
	@IsTest
	private static void registerModules() {

		VoiceCallTriggerHandler handler = new VoiceCallTriggerHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(VoiceCallTriggerHandler.class.getName());
		System.assert(recordFilterIndexes.containsKey(CaseRecordPopulationModule.class), 'It should have CaseRecordPopulationModule class registered');
	}

}