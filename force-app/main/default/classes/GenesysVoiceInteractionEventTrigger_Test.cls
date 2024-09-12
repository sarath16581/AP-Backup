/**
 * @description Testclass for GenesysVoiceInteractionEvent trigger
 * NOTE: 	Executes synchronisation from VoiceCall to Genesys when published
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @changelog
 * 2024-08-27 - Paul Perry - created
 */
@IsTest
public with sharing class GenesysVoiceInteractionEventTrigger_Test {
    @IsTest
	public static void runTest() {
		Test.startTest();
		// TODO: publish platform events
		EventBus.publish(new List<GenesysVoiceInteraction__e>{ });
		Test.stopTest();

		// TODO: verify platform events delivery
		Test.getEventBus().deliver();
	}
}