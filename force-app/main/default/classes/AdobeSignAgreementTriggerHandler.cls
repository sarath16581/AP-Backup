/**
 * Created by hasan on 19/02/2024.
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
		return new List<SObjectType>{};
	}
}