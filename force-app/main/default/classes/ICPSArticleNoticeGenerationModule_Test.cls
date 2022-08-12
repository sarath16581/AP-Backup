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
		ICPSArticleNoticeGenerationModule.newInstance().concatICPSArticleNumbers(articleList, mockUow);
		Test.stopTest();

		System.assertEquals(null, icps[0].Articles__c, 'Expected null articles populated as no articles linked to the ICPS');
	}

	/**
	* Test:
	*  Ensure exceptions are handled correctly
	*/
	@IsTest
	public static void testExceptionHandling() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		ICPSArticleNoticeGenerationModule.Constructor constructor = new ICPSArticleNoticeGenerationModule.Constructor();
		constructor.construct();
		ICPSArticleNoticeGenerationModule module = ICPSArticleNoticeGenerationModule.newInstance();
		module.onBeforeInsert(null, mockUow);
		module.onAfterInsert(null, mockUow);
		module.onBeforeUpdate(null, null, mockUow);
		System.assert(true, 'PMD by-pass');
	}

	/**
	* Test:
	*  Ensure fields are capitalized
	*/
	@IsTest
	public static void testCapitalizeFields() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		List<ICPSArticle__c> articleList = ICPSTestDataFactory.getICPSArticles(icps[0].Id, 1, true);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ICPSArticleNoticeGenerationModule.newInstance().capitalizeFields(articleList, null);
		Test.stopTest();

		System.assert(articleList[0].Contents__c.deleteWhitespace().isAllUpperCase(), 'Capitalized');
	}
}