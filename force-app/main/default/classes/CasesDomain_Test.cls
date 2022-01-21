/**
* @author Ashapriya Gadi
* @date 2021-12-08
* @group Tests
* @tag Selector
* @tag Case
* @domain Core
* @description Test class covering CasesDomain
* @changelog
* 2021-12-08 - Ashapriya Gadi - Created
*/
@IsTest
private class CasesDomain_Test {
	@IsTest
	private static void testCasesDomain() {
		
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		
		ApplicationDomain.IConstructable constructableDomain = new CasesDomain.Constructor();
		CasesDomain domain = (CasesDomain)constructableDomain.construct(cases);
		
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected record');
	}
}