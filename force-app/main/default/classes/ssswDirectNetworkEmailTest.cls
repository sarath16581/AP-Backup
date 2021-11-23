@isTest
private class ssswDirectNetworkEmailTest
{
    // Test Coverage: 100%    
    static testMethod void testnetworkEmailTemplate() 
    {
        // create a Case
        Case c = new Case(Type ='Domestic Item Search', Subject='ssswDirectNetworkEmailTest');
        insert c;

        // create a network emailMessage
        EmailMessage em = new EmailMessage();
        em.ToAddress = 'toaddress@test.com';
        em.FromAddress = 'fromaddress@test.com';
        em.ParentId = c.Id;
        insert em;

        // create a custom setting
        QM__c configSetting = new QM__c();
        configSetting.NetworkEmail__c = 'toaddress@test.com';
        insert configSetting;

        // pass Case Id into controller and let it fetch the most recent network emailMessage
        ssswDirectNetworkEmail disCont = new ssswDirectNetworkEmail();
        disCont.caseId = c.Id;
    }
}