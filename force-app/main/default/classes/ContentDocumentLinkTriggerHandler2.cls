/**
 * @description Trigger handler for ContentDocumentLink Trigger
 * @author Hasantha L
 * @date 2024-01-23
 * @group TriggerHandler
 * @domain Core
 * @changelog
*/
public with sharing class ContentDocumentLinkTriggerHandler2 extends ApplicationTriggerHandler {
	public override void registerModules() {
		registerModule(AdobeSignContentDocumentLinkModule.class);
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override SObjectType getSObjectType() {
		return ContentDocumentLink.SObjectType;
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Account.SObjectType,
				ContentDocument.SObjectType,
				ContentDocumentLink.SObjectType,
				ContentVersion.SObjectType
		};
	}
}