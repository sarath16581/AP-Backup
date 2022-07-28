/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Trigger class for the ContactPointPhone object
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
trigger ContactPointPhoneTrigger on ContactPointPhone (before insert, before update,after insert,after update, after delete) {
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(ContactPointPhone.SObjectType))) {
		(new ContactPointPhoneDomainTriggerHandler()).dispatch();
	}
}