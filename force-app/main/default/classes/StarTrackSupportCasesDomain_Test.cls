/**
* @description Test class for StarTrackSupportCasesDomain
* @author Madhusudhan
* @date 2021-06-17
* @group Domains
* @changelog
*/
@IsTest
private class StarTrackSupportCasesDomain_Test {

	@IsTest
	private static void testMethods() {
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.casestarTrackDeliveryEnquiryRecordType;

		ApplicationDomain.IConstructable constructableDomain = new StarTrackSupportCasesDomain.Constructor();
		StarTrackSupportCasesDomain domain = (StarTrackSupportCasesDomain)constructableDomain.construct(cases);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected StarTrack record');
	}

}