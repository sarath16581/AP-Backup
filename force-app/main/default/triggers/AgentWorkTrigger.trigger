/***
 * @description Trigger class for AgentWork
 * @author George Nguyen
 * @group AgentWork
 * @tag AgentWork
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - updated. This class was created a while back but does not follow the framework. I have updated to use our framework
 * 2024-07-22 - Ranjeewa Silva - Uplifted to use the new domain less trigger dispatch framework. Removed directly calling
 *							   'AgentWorkTriggerHandler.assignDeclinedRemindersToQueue(...)'  from trigger as this is now
 *							   invoked via an ApplicationModule.
 */
trigger AgentWorkTrigger on AgentWork (before insert, before update,after insert,after update, after delete) {

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(AgentWork.SObjectType))) {
		new AgentWorkTriggerHandler().dispatch();
	}
}