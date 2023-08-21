/***
 * @author Disha Kariya
 * @date 2020-08-24
 * @group Tests
 * @tag Selector
 * @tag Attachment SObject
 * @domain Core
 * @description Test Class covering AttachmentsSelector
 * @changelog
 * 2020-08-24 - Disha Kariya - Created
 */
@IsTest
public with sharing class AttachmentsSelector_Test {

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        AttachmentsSelector selector = AttachmentsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom attachment\\b').matcher(soql).find(), 'Resulting query does not select from Attachment');

        selector = AttachmentsSelector.newInstance();
        qb = selector.newQueryBuilder(new Set<Object>{AttachmentsSelector.Options.WITH_OWNER});
        soql = qb.toSoqlString();

        // make sure there is Owner
        System.assertEquals(true, Pattern.compile('(?ism)Owner.*?\\bfrom Attachment\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

        //Test for field override
        selector = AttachmentsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
                Attachment.SObjectType => new Set<SObjectField>{Attachment.Description, Attachment.Id}
        });
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Description.*?\\bfrom Attachment\\b').matcher(soql).find(), 'Resulting query does not select Description field: ' + soql);

        selector = AttachmentsSelector.newInstance(0, new Set<SObjectField>{Attachment.Description, Attachment.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Description.*?\\bfrom Attachment\\b').matcher(soql).find(), 'Resulting query does not select Description field: ' + soql);

        selector = AttachmentsSelector.newInstance(new Set<SObjectField>{Attachment.Description, Attachment.Id});
        qb = selector.newQueryBuilder();
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Description.*?\\bfrom Attachment\\b').matcher(soql).find(), 'Resulting query does not select Description field: ' + soql);

        Test.stopTest();

    }

    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert account;

        Attachment attachment = ApplicationTestDataFactory.getAttachments(1, account.Id, false)[0];
        insert attachment;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        AttachmentsSelector selector = AttachmentsSelector.newInstance(1);
        Map<Id, Attachment> results = selector.selectById(new Set<Id>{attachment.Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');


        Test.stopTest();

    }
}