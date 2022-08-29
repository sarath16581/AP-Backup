/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Trigger class for the ContactPointAddress object
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
trigger ContactPointAddressTrigger on ContactPointAddress (after insert, after update, after delete) {
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(ContactPointAddress.SObjectType))) {
		ContactPointAddressDomainTriggerHandler.newInstance().dispatch();
	}
}