/*------------------------------------------------------------
Author:		Chester Borbon
Company:	   Accenture
Description:   ContentDocumentLink object main trigger
Test Class:	ContentDocumentLinkTriggerHandler_Test
History
<Date>	  <Authors Name>	 <Brief Description of Change>
6-Sep-2018   Chester Borbon	Initial version which contains after insert and delete trigger handler events.

* @changelog
* 2020-07-23 - Nathan Franklin - Adding Option to Bypass Trigger
------------------------------------------------------------*/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert, before delete,after delete) {

	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ContentDocumentLink.sObjectType))){  // verify if triggers are disabled
		(new ContentDocumentLinkTriggerHandler2()).dispatch();
	}
	if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
		// trigger before
		if (trigger.isBefore) {
			// trigger insert
			if (trigger.isInsert) {
				// reference main trigger handler class
				ContentDocumentLinkTriggerHandler.onAfterInsert(trigger.new);
			}
		}
		// trigger after
		if (trigger.isAfter) {
			if (trigger.isDelete) {
				// reference main trigger handler class
				ContentDocumentLinkTriggerHandler.onAfterDelete(trigger.old);
			}
		}
	}
}