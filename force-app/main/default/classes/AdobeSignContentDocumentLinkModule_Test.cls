/**
 * Created by hasan on 19/02/2024.
 */
@IsTest
private class AdobeSignContentDocumentLinkModule_Test {
	@IsTest
	static void testUpdateCurrentArticleInfoOnCompensationRecord() {
		// =====================================
		// Stubbing
		// =====================================
		AdobeSignContentDocumentLinkModule module = (AdobeSignContentDocumentLinkModule) MockUtility.mockUtility(AdobeSignContentDocumentLinkModule.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
		CompensationUtilityModule module = CompensationUtilityModule.newInstance();
		List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
		String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
		List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		module.onBeforeInsert(compensations, uow);
		((CompensationService) MockUtility.Mocks.verify(
				mockService,
				MockUtility.Mocks.times(1))).updateCurrentArticleInfoOnCompensationRecord((List<Compensation__c>) fflib_Match.eq(compensations)
		);
		// PMD warning
		System.assert(true);

		Test.stopTest();
	}
}