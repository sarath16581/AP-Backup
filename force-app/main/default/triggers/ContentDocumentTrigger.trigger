/**************************************************
Description:  trigger for ContentDocument
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
**************************************************/

trigger ContentDocumentTrigger on ContentDocument (before delete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ContentDocument.sObjectType))){  // verify if triggers are disabled
		(new ContentDocumentTriggerHandler()).dispatch();
	}
}