/**
* @description Contains all the test data methods for SSO test classes
* @author Nathan Franklin
* @date 2022-05-11
* @changelog
*/
@IsTest
public class SSOTestDataFactory {

	public static List<SSOAttributeMapping__mdt> getSSOAttributeMappings(Integer count, Object networkIdsOrId, Boolean generateIds) {
		return (List<SSOAttributeMapping__mdt>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(SSOAttributeMapping__mdt.SObjectType, new Map<SObjectField, Object> {
			SSOAttributeMapping__mdt.DeveloperName => 'RECORD%count%',
			SSOAttributeMapping__mdt.NetworkId__c => networkIdsOrId,
			SSOAttributeMapping__mdt.FederationField__c => 'FederationIdentifier',
			SSOAttributeMapping__mdt.SubjectAttribute__c => 'email'
		}, count), generateIds);
	}

}