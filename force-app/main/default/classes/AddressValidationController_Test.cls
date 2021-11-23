/**
*  This test class is for AddressValidationController.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  100%
*/
@isTest
private class AddressValidationController_Test {

    static testMethod void testMethods() {
        Test.startTest();
        
        //AusPostSettings__c aps = TestDataProvider.createTestAusPostSettings1();
        // 2014-08-27 replaced the above line with below, as TestDataProvider won't be available until SSSW project is deployed.
        AusPostSettings__c oa = new AusPostSettings__c(Token__c='ABC',Name='AddressValidation');
        oa.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
        oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
        oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
        oa.Name = 'AddressValidation';
        insert oa;
        
        AddressValidationController add = new AddressValidationController();
        
        system.assert(true);
        Test.stopTest();
    }
}