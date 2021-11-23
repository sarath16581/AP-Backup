@isTest
public class ChasSetCaseWithinEDDOnHoldTest {
    @testSetup
    public static void setupTestData()
    {
        List<String> groupNames = new List<String>{'SSSW Awaiting Reopen'};
            Profile adminProf = [select Id from Profile where Name = 'System Administrator'];
        
        // use runAs to bypass the DML with Group limitations
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)) {
            //Create the related Groups
            List<Group> groupsToAdd = new List<Group>();
            for (String gn : groupNames) {
                groupsToAdd.add(new Group(Name = gn, Type = 'Queue'));
            }
            insert groupsToAdd;
        }
    }
    @isTest
    public static void test_AssignCase()
    {
        List<Group> reopenQ = [SELECT Id, Name FROM Group WHERE developerName =: SSSWConstants.QUEUE_NAME_REOPEN_Q];
        Id queueId = reopenQ[0].Id;
        Case testCase = TestDataProvider.createTestCase();
        testCase.EstimatedDelivery__c = System.Today();
        insert testCase;
        Id caseId = testCase.Id;
        
        Test.startTest();
        ChasSetCaseWithinEDDOnHold assignJob = new ChasSetCaseWithinEDDOnHold(testCase);
        System.enqueueJob(assignJob);
        Test.stopTest();
        List<Case> results = [
                SELECT Id, OwnerId
                FROM Case
                WHERE Id =: caseId
        ];
        System.assertEquals(results[0].OwnerId, queueId, 'Expected Case to be assigned to Network Queue, ' + results[0]);
    }
}