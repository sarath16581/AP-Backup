@isTest
private class testNPSSurveyTrigger {
    
    @isTest
    static void testNPSSurveyTrigger() {
        Case c = TestDataProvider.createCase('subject', 'description', 'SSSWDelivery');
        c.Status = 'Closed';
        c.ResolutionCode__c = 'Network resolution';
        c.Permanent_Close__c  = true;
        insert c;
        NPSSurvey__c n = new NPSSurvey__c();
        n.case__c = c.Id;
        insert n;
    }
}