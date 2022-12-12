/**
 * @description Test class covering StarTrackAPRDomain
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Tests
 * @tag Domain
 * @tag APR__c
 * @domain Core
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 */

@IsTest
private class StarTrackAPRDomain_Test {
	@IsTest
	private static void testStarTrackAPRDomain() {
		Id starTrackRecTypeId = [Select Id,DeveloperName From RecordType Where SObjectType = 'APR__c' And DeveloperName = 'StarTrack' LIMIT 1].Id;
		List<APR__c> aprList = new List<APR__c>{
			new APR__c(Comments__c = 'APR c1', Type__c = 'StarTrack APR', RecordTypeId=starTrackRecTypeId),
			new APR__c(Comments__c = 'APR c2', Type__c = 'StarTrack APR')
		};

		ApplicationDomain.IConstructable constructableDomain = new StarTrackAPRDomain.Constructor();
		StarTrackAPRDomain domain = (StarTrackAPRDomain) constructableDomain.construct(aprList);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(aprList[0].Id, domain.records[0].Id, 'Expected record');
	}
}