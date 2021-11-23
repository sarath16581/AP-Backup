/*------------------------------------------------------------
Author:		Adrian Recio
Company:	   Accenture
Description:   ContentVersion object main trigger
Test Class:	ContentVersionTriggerHandler_Test
History
<Date>	  <Authors Name>	 <Brief Description of Change>
6-Sep-2018  Adrian Recio	   Initial version which contains after insert and after update trigger handler events.

* @changelog
* 2020-07-23 - Nathan Franklin - Adding Option to Bypass Trigger
------------------------------------------------------------*/
trigger ContentVersionTrigger on ContentVersion (after insert, after update) {
	if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
		// trigger after
		if (trigger.isAfter) {
			// trigger insert
			if (trigger.isInsert) {
				// reference main trigger handler class
				ContentVersionTriggerHandler.onAfterInsert(trigger.new);
			} else if (trigger.isUpdate) {
				// reference main trigger handler class
				ContentVersionTriggerHandler.onAfterUpdate(trigger.new);
			}
		}
	}
}