@isTest
private class ssswRecentCustomerEmailMessageTest 
{
    // Test Coverage: 100%    
    static testMethod void testEmailTemplate() 
    {
        // create a Case
        Case c = new Case(Type ='Domestic Item Search', Subject='ssswRecentCustomerEmailMessageTest');
        insert c;

        // create a network emailMessage
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'fromaddress@test.com';
        em.ParentId = c.Id;
        insert em;

        // create a custom setting
        QM__c configSetting = new QM__c();
        configSetting.NetworkEmail__c = 'fromaddress@test.com';
        insert configSetting;

        // pass Case Id into controller and let it fetch the most recent customer emailMessage
        ssswRecentCustomerEmailMessage disCont = new ssswRecentCustomerEmailMessage();
        disCont.caseId = c.Id;
    }
    

}