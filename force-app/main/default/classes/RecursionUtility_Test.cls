/**************************************************
Description:    Test Class to cover RecursionUtility class
History:
--------------------------------------------------
2019-02-23  nathan.franklin@auspost.com.au  Created
2019-03-12  gunith.devasurendra@auspost.com.au  Updated test
**************************************************/
@IsTest
public class RecursionUtility_Test {

    /**
     * Scenario:
     *  Test to make sure that each time we pass a list in with the same context that it will remove any items that have already been 'processed' (passed through this method)
     */
    public static testMethod void testUnprocessedRecords() {

        List<Case> cases = new List<Case>{
                new Case(Id = '500000000000000'),
                new Case(Id = '500000000000001'),
                new Case(Id = '500000000000002')
        };

        List<Case> unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
        System.assertEquals(3, unprocessedCases.size());

        unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
        System.assertEquals(0, unprocessedCases.size());

        cases.add(new Case(Id = '500000000000003'));
        unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases);
        System.assertEquals(1, unprocessedCases.size());

    }

    /**
     * Scenario:
     *  Test to ensure that when we are tracking specific field values, that any records that have already been processed and the tracked field values haven't changed we make sure these records aren't returned
     */
    public static testMethod void testTrackedValues() {

        List<Case> cases = new List<Case>{
                new Case(Id = '500000000000000', ReferenceID__c = 'test123456', Subject = 'Subject #1'),
                new Case(Id = '500000000000001', ReferenceID__c = 'test123789', Subject = 'Subject #2'),
                new Case(Id = '500000000000002', ReferenceID__c = 'test34542342', Subject = 'Subject #3')
        };

        List<Case> unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
        System.assertEquals(3, unprocessedCases.size());

        unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
        System.assertEquals(0, unprocessedCases.size());

        // this test is catch the changed values (records 1 and 2 since the field values have changed)
        cases = new List<Case>{
                new Case(Id = '500000000000000', ReferenceID__c = 'test123456', Subject = 'Changed Subject #1'),
                new Case(Id = '500000000000001', ReferenceID__c = 'Changed test123789', Subject = 'Subject #2'),
                new Case(Id = '500000000000002', ReferenceID__c = 'test34542342', Subject = 'Subject #3'),
                new Case(Id = '500000000000003', ReferenceID__c = 'test4354555', Subject = 'New Subject #4')
        };

        unprocessedCases = (List<Case>)RecursionUtility.getUnprocessedRecords('testContext', cases, new Set<String>{'ReferenceID__c', 'Subject'});
        System.assertEquals(3, unprocessedCases.size());

        Map<Id, SObject> unprocessed = new Map<Id, SObject>(unprocessedCases);
        System.assertEquals(true, unprocessed.containsKey('500000000000000'));
        System.assertEquals(true, unprocessed.containsKey('500000000000001'));
        System.assertEquals(true, unprocessed.containsKey('500000000000003'));
    }

}