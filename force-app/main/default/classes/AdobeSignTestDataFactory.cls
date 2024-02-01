/**
 * @author Hasantha Liyanage
 * @date 2024-01-31
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2024/01/31 - hasantha.liyanage@auspost.com.au - Created
 */

@IsTest
public  class AdobeSignTestDataFactory extends TestDataFactoryCommons{
	public static List<echosign_dev1__SIGN_Agreement__c> getSignAgreements(Integer count, Id accountId, String contractId, Boolean generateIds) {
		return (List<echosign_dev1__SIGN_Agreement__c>)maybeGenerateIds(populateSObjects(echosign_dev1__SIGN_Agreement__c.SObjectType, new Map<SObjectField, Object> {
				echosign_dev1__SIGN_Agreement__c.echosign_dev1__Name__c => 'Test Name %count%',
				echosign_dev1__SIGN_Agreement__c.ApttusContract__c => contractId,
				echosign_dev1__SIGN_Agreement__c.echosign_dev1__Account__c => accountId
		}, count), generateIds);
	}

}