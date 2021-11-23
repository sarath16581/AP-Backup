trigger AgentWorkTrigger on AgentWork (after update) {
    if (Trigger.IsUpdate && Trigger.IsAfter) {
        AgentWorkTriggerHandler.assignDeclinedRemindersToQueue(Trigger.Old, Trigger.New);
    }
}