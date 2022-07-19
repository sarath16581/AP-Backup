/***
 * @description test class for ICPSDomain
 * @author Harry Wang
 * @date 2022-06-21
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-21 - Harry Wang - Created
 */
@IsTest
private class ICPSDomain_Test {
	@IsTest
	private static void test() {

		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(1, true);

		ApplicationDomain.IConstructable constructableDomain = new ICPSDomain.Constructor();
		ICPSDomain domain = (ICPSDomain)constructableDomain.construct(icpsList);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(icpsList[0].Id, domain.records[0].Id, 'Expected ICPS record');
	}
}