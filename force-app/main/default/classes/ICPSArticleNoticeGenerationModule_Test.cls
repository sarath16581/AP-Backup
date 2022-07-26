/**
 * @description Test class for ICPS Module
 * @author Harry Wang
 * @date 2022-07-08
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-07-08 - Harry Wang - Created
*/
@IsTest
private class ICPSArticleNoticeGenerationModule_Test {
	/**
	* Test:
	*  Ensure article names are joined correctly
	*/
	@IsTest
	public static void testConcatICPSArticleNumbers() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		List<ICPSArticle__c> articleList = ICPSTestDataFactory.getICPSArticles(icps[0].Id, 1, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ICPSSelector selector = (ICPSSelector)MockUtility.mockSelector(ICPSSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(selector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(icps);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPSArticleNoticeGenerationModule.Constructor constructor = new ICPSArticleNoticeGenerationModule.Constructor();
		constructor.construct();
		ICPSArticleNoticeGenerationModule module = ICPSArticleNoticeGenerationModule.newInstance();
		module.onAfterInsert(articleList, mockUow);

		// test exception
		try {
			module.onAfterInsert(null, mockUow);
		} catch (Exception e) {
			System.assert(e.getMessage()!= null, 'Expected exception caught');
		}

		Test.stopTest();

		System.assertEquals(null, icps[0].Articles__c, 'Expected null articles populated as no articles linked to the ICPS');
	}
}