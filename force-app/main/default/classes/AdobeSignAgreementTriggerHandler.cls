/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Hasantha Liyanage
 * @date 2023-02-19
 * @changelog
 */

public with sharing class AdobeSignAgreementTriggerHandler extends ApplicationTriggerHandler {
	public override void registerModules() {
		registerModule(AdobeSignAgreementModule.class);
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override SObjectType getSObjectType() {
		return echosign_dev1__SIGN_Agreement__c.SObjectType;
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Account.SObjectType,
				ContentDocument.SObjectType
		};
	}
}