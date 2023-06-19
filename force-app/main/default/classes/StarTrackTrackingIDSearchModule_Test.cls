/**
 * @description
 * @author Hasantha
 * @date 2022
 * @changelog
 * 2023-06-17 - Nathan Franklin - update for use with ApplicationModule
 */
@IsTest
public class StarTrackTrackingIDSearchModule_Test {

    testMethod public static void testCoverageOnly() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
        //insert case with queue as owner
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

        // =====================================
        // Stubbing
        // =====================================

        // set up our responses
        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.stopStubbing();
        Test.startTest();
        StarTrackTrackingIDSearchModule module = StarTrackTrackingIDSearchModule.newInstance();
        module.onAfterInsert( (List<SObject>)cases, uow);

        
        Test.stopTest();

    }
}