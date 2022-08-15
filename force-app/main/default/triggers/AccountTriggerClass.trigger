/**
  * @author       : eugene.jandusay@auspst.com.au
  * @date         : 26/07/2016
  * @description  : Trigger on Account Object to call the Handler class to perform necessary action
  @Test AccountTrigger_Test
  */
trigger AccountTriggerClass on Account (before insert, before delete, before update,after insert, after update, after delete, after undelete ) {
    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Account.SObjectType))) {
		  PersonAccountDomainTriggerHandler.newInstance().dispatch();
	  }

    AccountTriggerHandler.execute();  // Case handler dispatches appropriate event
}