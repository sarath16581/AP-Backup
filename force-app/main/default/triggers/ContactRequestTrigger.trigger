/**
  * @author	Nathan Franklin
  * @date 2024-07-31
  * @description Trigger for handling ContactRequest object
  * @Test ContactRequestTrigger_Test
  * @changelog
  */
trigger ContactRequestTrigger on ContactRequest (before insert, before update, after insert, after update) {

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ContactRequest.sObjectType))){	 // verify if triggers are disabled
		(new ContactRequestTriggerHandler()).dispatch();	
	}

}