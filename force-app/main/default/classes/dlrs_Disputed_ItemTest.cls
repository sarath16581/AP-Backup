/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Disputed_ItemTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Disputed_ItemTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Disputed_Item__c());
    }
}