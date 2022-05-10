/**
 * @description Trigger on APR__c Object to call the domain based trigger dispatch to perform necessary action
 * @author Naveen Rajanna
 * @date 2022.04.15
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 */

trigger APRTrigger on APR__c(
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete
) {
	// verify if triggers are disabled
	if (!TriggerHelper.isTriggerDisabled(String.valueOf(APR__c.sObjectType))) {
		(new APRTriggerHandler()).dispatch(); // invoke domain based trigger dispatch
	}
}