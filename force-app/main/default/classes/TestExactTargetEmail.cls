/**
  * @author       : 
  * @date         : 
  * @description  : test class for testing the send email via exactTarget.
--------------------------------------- History --------------------------------------------------                      
14.09.2016 kalpita.d.talwadekar@auspost.com.au    updated to add new method for testing bulk email sends.
**/
@isTest
private class TestExactTargetEmail implements HttpCalloutMock {
    private HttpResponse resp;
    
    /**
      * @description       Constructor for setting the fields, operator and values
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public TestExactTargetEmail(String testBody) {
        resp = new HttpResponse();
        resp.setBody(testBody);
        resp.setStatusCode(200);
    }
    
    /**
      * @description       Constructor for setting the fields, operator and values
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    public HTTPResponse respond(HTTPRequest req) {
        return resp;
    }
    
    /**
      * @description       Constructor for setting the fields, operator and values
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
    static testMethod void ExactTargetEmailTest() {  
        
        String testBody = 'This is a test :-)';
        Exact_Target_LogIn__c ex = new Exact_Target_LogIn__c();
        ex.ClientId__c = 'test';
        ex.ClientSecret__c = 'test';
        ex.Message_EndPoint__c = 'https://test.salesforce.com/messageEndpoint';
        ex.RequestToken_EndPoint__c = 'https://test.salesforce.com';
        ex.Name = 'test';
        insert ex;
        test.startTest();
        HttpCalloutMock mock = new TestExactTargetEmail(testBody);
        Test.setMock(HttpCalloutMock.class, mock);
        
        ExactTargetEmail callout = new ExactTargetEmail();
        callout.isTest = true;
        ExactTargetEmail.ExactTargetSentResult resp = callout.sendSingleMail('test@from.com', 'testfrom', 'test@to.com', 'testto', 'body', 'subject', 'noreply@auspost.com.au');
        
        ExactTargetEmail.ExactTargetSentResult resp2 = callout.sendMailToMultipleAddresses('test@from.com', 'testfrom', new String[]{'test@to.com'}, new String[]{'testto'}, 'body', 'subject', 'noreply@auspost.com.au');
        test.stopTest();
    }
    
    /**
      * @description       Constructor for setting the fields, operator and values
      * @param             NA 
      * @return            NA
      * @throws            NA
      */
     static testMethod void ExactTargetEmailTestBulk() {  
        
        String testBody = '{"requestId":"dd63978e-bca6-4eb8-b3ae-9e98949b8703","responses":[{"recipientSendId":"dd63978e-bca6-4eb8-b3ae-9e98949b8703","hasErrors":false,"messages":["Queued"]}]}';
        Exact_Target_LogIn__c ex = new Exact_Target_LogIn__c();
        ex.ClientId__c = 'test';
        ex.ClientSecret__c = 'test';
        ex.Message_EndPoint__c = 'https://test.salesforce.com/messageEndpoint';
        ex.RequestToken_EndPoint__c = 'https://test.salesforce.com';
        ex.Name = 'test';
        insert ex;
        test.startTest();
        HttpCalloutMock mock = new TestExactTargetEmail(testBody);
        Test.setMock(HttpCalloutMock.class, mock);
        
        ExactTargetEmail callout = new ExactTargetEmail();
        callout.isTest = true;
        //ExactTargetEmail.ExactTargetSentResult resp = callout.sendSingleMail('test@from.com', 'testfrom', 'test@to.com', 'testto', 'body', 'subject', 'noreply@auspost.com.au');
        ExactTargetEmail.ExactTargetSentResult resp2 = callout.sendMailToMultipleAddressesBulk('','test@from.com', 'testfrom', new String[]{'test@to.com'}, 
                                new String[]{'testto'}, new String[]{'body'}, new String[]{'subject'}, new String[]{'noreply@auspost.com.au'});
        ExactTargetEmail.ExactTargetSentResult resp3 = callout.sendBacklog(testBody, false);
        test.stopTest();
    }
}