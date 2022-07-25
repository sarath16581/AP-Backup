/***
 * @description test class for ICPSArticleDomain
 * @author Harry Wang
 * @date 2022-07-08
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-07-08 - Harry Wang - Created
 */
@IsTest
private class ICPSArticleDomain_Test {
	@IsTest
	private static void test() {

		List<ICPS__c> icpsList = ICPSTestDataFactory.getICPS(1, true);
		List<ICPSArticle__c> articleList = ICPSTestDataFactory.getICPSArticles(icpsList[0].Id, 1, true);

		ApplicationDomain.IConstructable constructableDomain = new ICPSArticleDomain.Constructor();
		ICPSArticleDomain domain = (ICPSArticleDomain)constructableDomain.construct(articleList);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(articleList[0].Id, domain.records[0].Id, 'Expected ICPS article record');
	}
}