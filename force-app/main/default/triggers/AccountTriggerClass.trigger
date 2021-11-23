/**
  * @author       : eugene.jandusay@auspst.com.au
  * @date         : 26/07/2016
  * @description  : Trigger on Account Object to call the Handler class to perform necessary action
  */
trigger AccountTriggerClass on Account (before insert, before delete, before update,after insert, after update, after delete, after undelete ) {
    

    AccountTriggerHandler.execute();  // Case handler dispatches appropriate event
}