/**
 * @description       :
 * @author            : Sreenish Krishnan
 * @domain            :
 * @last modified on  : 06-29-2022
 * @last modified by  : Sreenish Krishnan
 **/
trigger ContactPointEmailTrigger on ContactPointEmail(after insert, after update, after delete) {
	if (!TriggerHelper.isTriggerDisabled(String.valueOf(ContactPointEmail.SObjectType))) {
		(new ContactPointEmailDomainTriggerHandler()).dispatch();
	}
}