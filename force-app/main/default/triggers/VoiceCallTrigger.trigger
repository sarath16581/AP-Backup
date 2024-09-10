/**
 * @description VoiceCall trigger 
 * NOTE: invokes all the logic upon DML for the VoiceCall object
 * @author Paul Perry
 * @date 2024-08-27
 * @group Unified
 * @test VoiceCallTrigger_Test
 * @changelog
 * 2024-08-27 Paul - created
 */
trigger VoiceCallTrigger on VoiceCall (after update, before insert, before update, before delete, after insert, after delete, after undelete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(VoiceCall.SObjectType))) {
		// domain base trigger dispatch
		(new VoiceCallTriggerHandler()).dispatch();
	}
}