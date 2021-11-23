/**************************************************
Description:    Test LDAP_UserAccount_v1
History:
--------------------------------------------------
2019-08-09  ajudd@salesforce.com            In test_queryUserAccountFound change to reflect CNumber coming from UserAccountId not CustomerNumber
**************************************************/

@isTest
public class LDAP_UserAccount_v1_Test {

    class EchoHttpMock implements HttpCalloutMock
    {
        public HttpResponse res;

        EchoHttpMock(HttpResponse response)
        {
            res = response;
        }

        public HttpResponse respond(HttpRequest req)
        {
            return res;
        }
    }

    @TestSetup
    static void setupEnvironment()
    {
        AusPostSettings__c cs = new AusPostSettings__c();
        cs.Name = LDAP_UserAccount_v1.CS_BAM_LDAP_USERACCOUNT;
        cs.URL__c = 'https://www.test.com';
        cs.URL2__c = 'https://www.test.com';
        insert cs;
    }

    @isTest
    static void test_queryUserAccountNotFoundError()
    {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(500);

        Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res) );
        Test.startTest();
        String cnumber = LDAP_UserAccount_v1.queryUserAccount('', 'Test');
        System.assertEquals(null, cnumber, 'Expected to fail, instead got c-number ' + cnumber);

        Test.stopTest();
    }

    @isTest
    static void test_queryUserAccountBlankError()
    {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res) );
        Test.startTest();
        String cnumber = LDAP_UserAccount_v1.queryUserAccount('', 'Test');
        System.assertEquals(null, cnumber, 'Expected to fail, instead got c-number ' + cnumber);

        Test.stopTest();
    }

    @isTest
    static void test_queryUserAccountFound()
    {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        String userId = '12345';
        String username = 'Tester';
        String testCnumber = '00001111';
        String responseBody = '<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Header>' +
                '<ns:InterfaceHeader xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ns="http://www.auspost.com.au/Schema/CommonDataModel/Common:v1" xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<ns:InterfaceName>UserAccount</ns:InterfaceName>' +
                '<ns:InterfaceVersion>1.1</ns:InterfaceVersion>' +
                '<ns:MessageType>Reply</ns:MessageType>' +
                '<ns:BusinessReferenceID>5855911993</ns:BusinessReferenceID>' +
                '<ns:SourceSystemID>TIBCOESB</ns:SourceSystemID><ns:Timestamp>2019-06-07T11:43:04.53+10:00</ns:Timestamp>' +
                '</ns:InterfaceHeader>' +
                '</SOAP-ENV:Header>' +
                '<SOAP-ENV:Body>' +
                '<ns0:queryUserAccountResponse xmlns:ns0="http://www.auspost.com.au/Schema/CommonDataModel/Operations/UserAccount:v1">' +
                '<ns0:UserAccount>' +
                '<ns0:UserName>' + username + '</ns0:UserName>' +
                '<ns0:UserAccountID>' + testCnumber + '</ns0:UserAccountID>' +
                '<ns0:CustomerNumber>0123456</ns0:CustomerNumber>' +
                '<ns0:EmailID>test@example.com</ns0:EmailID>' +
                '<ns0:FirstName>Test</ns0:FirstName>' +
                '<ns0:LastName>Test</ns0:LastName>' +
                '<ns0:isActive>true</ns0:isActive>' +
                '</ns0:UserAccount>' +
                '<ns0:ReturnMessage>' +
                '<ns0:Code>ESB-30000</ns0:Code>' +
                '<ns0:Description>FinishedOK</ns0:Description>' +
                '</ns0:ReturnMessage>' +
                '</ns0:queryUserAccountResponse>' +
                '</SOAP-ENV:Body>' +
                '</SOAP-ENV:Envelope>';
        res.setBody(responseBody);
        Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res) );
        Test.startTest();
        String cnumber = LDAP_UserAccount_v1.queryUserAccount(userId, username);
        System.assertEquals(testCnumber, cnumber, 'Expected to get a cnumber, instead got  ' + cnumber);
        Test.stopTest();
    }

}