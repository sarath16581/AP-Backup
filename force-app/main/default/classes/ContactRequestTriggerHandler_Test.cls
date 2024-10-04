/*
Test class for ContactRequestTriggerHandler
Changelog:
2024-08-23	George Nguyen	Created
*/
@IsTest
class ContactRequestTriggerHandler_Test {
    @IsTest
	private static void getUnitOfWorkSObjectTypes() {

		ContactRequestTriggerHandler handler = new ContactRequestTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(ContactRequest.SObjectType, handler.getsObjectType(), 'Should return ContactRequest sobject type');

		List<SObjectType> types = ContactRequestTriggerHandler.getUnitOfWorkSObjectTypes();

		System.assert(types.contains(AgentWork.SObjectType), 'Should have AgentWork sobject type');
	}

	/*
		Making sure that the right modules are registered with the right filters
	*/
	@IsTest
	private static void registerModules() {

		ContactRequestTriggerHandler handler = new ContactRequestTriggerHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(ContactRequestTriggerHandler.class.getName());
		System.assert(recordFilterIndexes.containsKey(CaseRecordPopulationModule.class), 'It should have CaseRecordPopulationModule class registered');
	}

}