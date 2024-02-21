/**
 * @description 
 * @author Boris Bachovski
 * @date 2024-02-21
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2024-02-21 - Boris Bachovski - Created
 */
@IsTest
public with sharing class ApplicationTestDataFactoryAdobeSign {
	public static List<echosign_dev1__SIGN_Agreement__c> getDraftAgreementsForAccount(Integer count, Id accountId, Boolean generateIds) {
		return (List <echosign_dev1__SIGN_Agreement__c>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(echosign_dev1__SIGN_Agreement__c.SObjectType, new Map<SObjectField, Object> {
				echosign_dev1__SIGN_Agreement__c.echosign_dev1__Name__c => 'Test Name %count%',
				echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c => 'Draft',
				echosign_dev1__SIGN_Agreement__c.echosign_dev1__Account__c => accountId
		}, count), generateIds);
	}

	public static List <echosign_dev1__SIGN_Agreement__c> getDraftAgreementsForApttusContract(Integer count, Id apttusContractId, Boolean generateIds) {
		return (List <echosign_dev1__SIGN_Agreement__c>) ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(echosign_dev1__SIGN_Agreement__c.SObjectType, new Map <SObjectField, Object> {
			echosign_dev1__SIGN_Agreement__c.echosign_dev1__Name__c => 'Test Name %count%',
			echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c => 'Draft',
			echosign_dev1__SIGN_Agreement__c.ApttusContract__c => apttusContractId
		}, count), generateIds);
	}
}