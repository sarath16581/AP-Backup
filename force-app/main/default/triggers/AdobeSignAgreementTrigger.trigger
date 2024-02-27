/**
 * Created by hasan on 19/02/2024.
 */

trigger AdobeSignAgreementTrigger on echosign_dev1__SIGN_Agreement__c (after update, before delete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(echosign_dev1__SIGN_Agreement__c.sObjectType))){  // verify if triggers are disabled
		(new AdobeSignAgreementTriggerHandler()).dispatch();
	}
}