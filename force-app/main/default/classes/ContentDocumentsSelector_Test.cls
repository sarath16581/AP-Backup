/***
 * @description Test Class covering ContentDocumentsSelector
 * @author avula.jansirani@auspost.com.au
 * @date 2021-04-29
 * @group Tests
 * @domain Core
 * @changelog
 */
@IsTest
private class ContentDocumentsSelector_Test {
    /**
* Executes a query to ensure it returns expected results with actual inserted data
*/

    @IsTest
    private static void testSelectById()
    {
        // =====================================
        // Data Preparation
        // =====================================
        ContentDocument cd = new ContentDocument();
        ApplicationTestDataFactory.generateRecordIds(new List<SObject> {cd});

        // =====================================
        // Stubbing
        // =====================================
        ContentDocumentsSelector selector = ContentDocumentsSelector.newInstance();


        Test.startTest();
        Map<Id, ContentDocument> result = selector.selectById(new Set<Id> {cd.Id});
        System.assertNotEquals(null, result, 'Expected a result: ' + result);
        Test.stopTest();

    }
}