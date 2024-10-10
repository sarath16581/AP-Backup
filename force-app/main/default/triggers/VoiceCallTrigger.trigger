/**
  * @author	Nathan Franklin
  * @date 2024-07-31
  * @description Trigger for handling VoiceCall object
  * @changelog
  */
trigger VoiceCallTrigger on VoiceCall (before insert, before update, after insert, after update) {

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(VoiceCall.sObjectType))){	 // verify if triggers are disabled
		(new VoiceCallTriggerHandler()).dispatch();
	}

}