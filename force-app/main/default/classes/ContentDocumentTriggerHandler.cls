/**************************************************
Description:  trigger handler for ContentDocument trigger
History:
--------------------------------------------------
2024-02-12 - H Liyanage - Created
**************************************************/

public with sharing class ContentDocumentTriggerHandler extends ApplicationTriggerHandler {
	public override void registerModules() {
		registerModule(AdobeSignContentDocumentModule.class);
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override SObjectType getSObjectType() {
		return ContentDocument.SObjectType;
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ContentDocument.SObjectType};
	}
}