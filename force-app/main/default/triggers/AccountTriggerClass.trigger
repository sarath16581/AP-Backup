/**
  * @author       : eugene.jandusay@auspst.com.au
  * @date         : 26/07/2016
  * @description  : Trigger on Account Object to call the Handler class to perform necessary action
  * @Test AccountTrigger_Test
  * @changelog
  * 2022-10-04 Noel Lim part of relabelling from PersonAccountDomain to AccountDomain.
  
  */
trigger AccountTriggerClass on Account (before insert, before delete, before update,after insert, after update, after delete, after undelete ) {
    
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Account.SObjectType))) {
		  AccountDomainTriggerHandler.newInstance().dispatch(); 
	  }

    AccountTriggerHandler.execute();  // Case handler dispatches appropriate event
}