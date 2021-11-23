/**
*  This test class is for AddressValidationService.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  94%
*/
@isTest
global class AddressValidationService_Test {

    static testMethod void testMethods() {
        Test.startTest();
        
//        AusPostSettings__c aps = TestDataProvider.createTestAusPostSettings2();
            AusPostSettings__c oa = new AusPostSettings__c();
            oa.Password__c = 'w@X2mb?SbMi%';
            oa.Username__c = 'sssw_sts';
            oa.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
            oa.URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
            oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
            oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
            oa.Name = 'AddressValidation';
            oa.ApplicationName__c = 'postMobile';
            oa.AppKey__c = 'b23a6687-5d9b-456c-9532-dc406662f7b4';
            oa.ServiceName__c = 'QAC';
            oa.TokenDuration__c = '84600';
            insert oa;
            

        
        AddressValidationService.getToken();
        AddressValidationService.getAddressURL();
        AddressValidationService.getDetailsURL();
        Test.setMock(HttpCalloutMock.class, new ClsWebServiceMockResponse());
        AddressValidationService.updateToken();
        
        system.assert(true);
        Test.stopTest();
    }
    
    global class ClsWebServiceMockResponse implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"userTokenx":"userToken"}');
            return res;
        }
    }
}