/**
  * @author       : eugene.jandusay@auspst.com.au
  * @date         : 26/07/2016
  * @description  : Trigger on Account Object to call the Handler class to perform necessary action
  @Test AccountTrigger_Test
  */
trigger AccountTriggerClass on Account (before insert, before delete, before update,after insert, after update, after delete, after undelete ) {
    Application.Profiler.start(('AccountTriggerClass_' + Trigger.operationType));

    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Account.SObjectType))) {
      Application.Profiler.start(('AccountTriggerClass_DOMAIN_' + Trigger.operationType));
          AccountDomainTriggerHandler.newInstance().dispatch(); 
      Application.Profiler.stop(('AccountTriggerClass_DOMAIN_' + Trigger.operationType));
      }

    AccountTriggerHandler.execute();  // Case handler dispatches appropriate event
    Application.Profiler.stop(('AccountTriggerClass_' + Trigger.operationType));

}