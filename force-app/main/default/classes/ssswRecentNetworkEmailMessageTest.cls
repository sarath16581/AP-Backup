@isTest
private class ssswRecentNetworkEmailMessageTest 
{
    // Test Coverage: 100%    
    static testMethod void testEmailTemplate() 
    {
        // create a Case
        Case c = new Case(Type ='Domestic Item Search', Subject='ssswRecentNetworkEmailMessageTest');
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

        // pass Case Id into controller and let it fetch the most recent network emailMessage
        ssswRecentNetworkEmailMessage disCont = new ssswRecentNetworkEmailMessage();
        disCont.caseId = c.Id;
    }
    

}