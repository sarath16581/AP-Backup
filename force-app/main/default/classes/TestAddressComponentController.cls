@isTest
private class TestAddressComponentController {

    static testMethod void TestAddressComponentController() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        AusPostSettings__c a = new AusPostSettings__c(Token__c='ABC',Name='AddressValidation');
        insert a;
        String token = AddressValidationService.getToken();
        AddressComponentController ac = new AddressComponentController();
        string addUrl = ac.addressURL;
        string detalUrl = ac.detailsURL;
        string tk = ac.token;
        
    }
    
}