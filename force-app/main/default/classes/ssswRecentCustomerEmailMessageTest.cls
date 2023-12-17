/**************************************************
    Type:         Test class for controllers sswRecentCustomerEmailMessage
    History:
    NOTE:         N/A
    --------------------------------------------------
    2014-09-24    Louis Wang (Bluewolf)        Created for Customer message.
    2023-10-18    Swati Mogadala               INC2198494: Updated testclass
    **************************************************/

@isTest
private class ssswRecentCustomerEmailMessageTest 
{    
    static testMethod void testEmailTemplate() 
    {
        Case c = new Case(Type ='Domestic Item Search', Subject='ssswRecentCustomerEmailMessageTest');
        insert c;

        // create a customer emailMessage
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'fromaddress@test.com';
        em.HTMLBody ='Test Email message for customer milestone';
        em.ParentId = c.Id;
        insert em;

        // create a custom setting
        QM__c configSetting = new QM__c();
        configSetting.CusEmail__c = 'fromaddress@test.com';
        insert configSetting;
        
        // pass Case Id into controller and let it fetch the most recent customer emailMessage
        ssswRecentCustomerEmailMessage disCont = new ssswRecentCustomerEmailMessage();
        disCont.caseId = c.Id;
    }

}