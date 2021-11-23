@isTest
private class testCaseCommentTrigger {
    
    @isTest
    static void testCaseCommentTrigger() {
        Case c = TestDataProvider.createCase('subject', 'description', 'SSSWDelivery');
        c.Status = 'Closed';
        c.ResolutionCode__c = 'Network resolution';
        c.Permanent_Close__c  = true;
        insert c;
        Casecomment com = new Casecomment();
        com.parentId=c.Id;
        com.commentbody='test';
        insert com;
    }
}