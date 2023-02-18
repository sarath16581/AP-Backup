/***
 * @description Trigger class for AgentWork
 * @author George Nguyen
 * @group AgentWork
 * @tag AgentWork
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - updated. This class was created a while back but does not follow the framework. I have updated to use our framework
 */
trigger AgentWorkTrigger on AgentWork (before insert, before update,after insert,after update, after delete) {

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(AgentWork.SObjectType))) {
		AgentWorkTriggerHandler.newInstance().dispatch();
	}

	/*
	* NOTE: This is existing method. Should be moved to the framework
	*/
	if (Trigger.IsUpdate && Trigger.IsAfter) {
        AgentWorkTriggerHandler.assignDeclinedRemindersToQueue(Trigger.Old, Trigger.New);
	}
}