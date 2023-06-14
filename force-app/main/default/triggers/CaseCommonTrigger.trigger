/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 16/06/2015
  * @description  : Trigger on Case Object to call the Handler class to perform necessary action
  * @changelog
  * 2022-02-03 - Nathan Franklin - Added temporary CaseTriggerHandler3
  * 2023-06-12 - Nathan Franklin - Added new Module framework CaseAutomationTriggerHandler
  */
trigger CaseCommonTrigger on Case(before insert,before update,before delete,
									after insert,after update,after delete,after undelete){

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(Case.sObjectType))){	 // verify if triggers are disabled

		(new CaseAutomationTriggerHandler()).dispatch();
		
	}

	// Added by : Adrian Recio
	// Description: I2C specific case trigger handler which is filtered by Enteprise recordtype
	if(trigger.isAfter){
		if(trigger.isUpdate){
			CaseTriggerHandler_IToC.afterUpdateTriggerHandler(trigger.OldMap, trigger.New);
		}
	}

}