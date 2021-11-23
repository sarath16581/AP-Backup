@isTest
global class QASAddressValidationController_Test {
    
    @testSetup public static void setup(){
    	AusPostSettings__c setting = new AusPostSettings__c();
        setting.Name = 'AddressValidation';
        setting.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
        setting.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
        setting.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
        insert setting;
    }
	
    @isTest 
    public static void LookupController_searchAddress(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new webServiceMockResponse());
       	String url = QASAddressValidationController.searchAddress('111 Bourke Street'); 
        Test.stopTest();
    }
    
    @isTest
    public static void LookupController_getAddressDetails(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new webServiceMockResponse());
       	String url = QASAddressValidationController.getAddressDetails('111 Bourke Street'); 
        Test.stopTest();
    }
    
    global class webServiceMockResponse implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"userTokenx":"userToken"}');
            return res;
        }
    }
    
}