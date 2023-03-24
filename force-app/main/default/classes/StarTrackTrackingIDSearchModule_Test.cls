/**
 * Created by hasan on 22/03/2023.
 */

@IsTest
public class StarTrackTrackingIDSearchModule_Test {

    testMethod public static void testCoverageOnly() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
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

        StarTrackTrackingIDSearchModule.Constructor constructor = new StarTrackTrackingIDSearchModule.Constructor();
        constructor.construct();
        Test.stopTest();

    }
}