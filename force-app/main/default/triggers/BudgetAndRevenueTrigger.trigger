/**
  * @author	   : Ken McGuire
  * @date		 : 31/10/2023
  * @description  : Trigger on Budget_and_Revenue__c Object to call the Handler class to perform necessary action
  */
trigger BudgetAndRevenueTrigger on Budget_and_Revenue__c (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
        if(!TriggerHelper.isTriggerDisabled(String.valueOf(Budget_and_Revenue__c.SObjectType))) {  // verify if triggers are disabled
			(new BudgetAndRevenueTriggerHandler()).dispatch();
		}

}