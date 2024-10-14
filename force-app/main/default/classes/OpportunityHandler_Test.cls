@IsTest
public class OpportunityHandler_Test{
    
    @TestSetup
    static void setupTestData() {
        // Create test data for opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1)
            );
            oppList.add(opp);
        }
        insert oppList;
    }
    
    @IsTest
    static void testAfterUpdateAction() {
        // Fetch existing opportunities
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE StageName = 'Prospecting'];
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>(oppList);

        // Simulate update to trigger the afterUpdateAction method
        for (Opportunity opp : oppList) {
            opp.StageName = 'Negotiation/Review';
        }

        Test.startTest();
        OpportunityHandler.afterUpdateAction(oppList, oldRecMap);
        Test.stopTest();

        // Assert that recursion flag is set
        System.assertEquals(TRUE, OpportunityHandler.isRunAfterUpdate, 'Recursion control failed for afterUpdate.');
    }
    
    @IsTest
    static void testBeforeUpdateAction() {
        // Fetch existing opportunities
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE StageName = 'Prospecting'];
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>(oppList);

        // Simulate update to trigger the beforeUpdateAction method
        for (Opportunity opp : oppList) {
            opp.StageName = 'Closed Won';
        }

        Test.startTest();
        OpportunityHandler.beforeUpdateAction(oppList, oldRecMap);
        Test.stopTest();

        // Assert that recursion flag is set
        System.assertEquals(TRUE, OpportunityHandler.isRunBeforeUpdate, 'Recursion control failed for beforeUpdate.');
    }
}