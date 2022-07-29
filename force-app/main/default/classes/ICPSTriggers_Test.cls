/**
 * @author Harry Wang
 * @date 2022-07-19
 * @group Trigger
 * @domain ICPS
 * @description Test class to cover all ICPS triggers
 * @changelog
 * 2022-07-19 - Harry Wang - Created
 */
@IsTest
public with sharing class ICPSTriggers_Test {
	@IsTest
	public static void testTrigger() {
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		insert icps;
		List<ICPSArticle__c> articleList = ICPSTestDataFactory.getICPSArticles(icps[0].Id, 1, false);
		insert articleList;
	}
}