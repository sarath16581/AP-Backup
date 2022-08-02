@isTest
public with sharing class ICPSArticleTrigger_Test {
	@IsTest
	public static void testTrigger() {
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		insert icps;
		List<ICPSArticle__c> articleList = ICPSTestDataFactory.getICPSArticles(icps[0].Id, 1, false);
		insert articleList;
	}
}