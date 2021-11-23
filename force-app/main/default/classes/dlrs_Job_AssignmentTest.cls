/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Job_AssignmentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Job_AssignmentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Job_Assignment__c());
    }
}