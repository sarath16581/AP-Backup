/**
 * @description       : This is Contact Point Email Trigger
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
 **/
trigger ContactPointEmailTrigger on ContactPointEmail(after insert, after update, after delete) {
	if (!TriggerHelper.isTriggerDisabled(String.valueOf(ContactPointEmail.SObjectType))) {
		(new ContactPointEmailDomainTriggerHandler()).dispatch();
	}
}