/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description Test class for CompensationUtilityModule
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
@IsTest
private class CompensationUtilityModule_Test {

    @IsTest
    static void testUpdateCurrentArticleInfoOnCompensationRecord() {

        CompensationService mockService = (CompensationService) MockUtility.mockUtility(CompensationService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);

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