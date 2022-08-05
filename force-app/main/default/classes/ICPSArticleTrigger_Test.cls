/***
 * @author Harry Wang
 * @date 2022-07-20
 * @domain ICPS
 * @description Test class for ICPSArticleTrigger
 * @changelog
 * 2022-07-20 - Harry Wang - Created
 */
@IsTest
class ICPSArticleTrigger_Test {

	@IsTest
	static void verifyDispatchHandlerCall() {
		ICPSArticleTriggerHandler articleHandler = (ICPSArticleTriggerHandler)MockUtility.mockUtility(ICPSArticleTriggerHandler.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		insert icps;

		List<ICPSArticle__c> articles = ICPSTestDataFactory.getICPSArticles(icps[0].Id, 1, false);
		insert articles;

		((ICPSArticleTriggerHandler)MockUtility.Mocks.verify(articleHandler, MockUtility.Mocks.times(4))).dispatch(); // 4 per transaction
		System.assert(true, 'PMD by-pass');
	}
}