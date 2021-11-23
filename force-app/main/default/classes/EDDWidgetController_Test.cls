/**
*  This test class is for EDDWidgetController.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 
*/
/**
12/09/2019  arjun.singh@auspost.com.au          Updated to consume new response for EDD Integration
 *******************************  History ************************************************/
@isTest
private class EDDWidgetController_Test {

    static testMethod void eddIntegrationSuccessResponseTest() {        
        AusPostSettings__c aps = TestDataProvider.createTestAusPostSettingsV2();
        Test.setMock(HttpCalloutMock.class, new EDDMockHttpResponseGenerator());
        Test.startTest();
            EDDWidgetController edd = new EDDWidgetController();        
            Case c = new Case();
            c.DatePosted__c = date.today();
            edd.dummyCase = c;
            edd.senderPostcode = '111';
            edd.receiverPostcode = '222';
            edd.fetchEDD();            
        Test.stopTest();
        system.assert(!edd.services.isEmpty());
    }
    static testMethod void eddIntegrationFailureResponseTest() {        
        AusPostSettings__c aps = TestDataProvider.createTestAusPostSettingsV2();
        TestDataProvider.httpStatus = 400;
        Test.setMock(HttpCalloutMock.class, new EDDMockHttpResponseGenerator());
        Test.startTest();
            EDDWidgetController edd = new EDDWidgetController();        
            Case c = new Case();
            c.DatePosted__c = date.today();
            edd.dummyCase = c;
            edd.senderPostcode = '111';
            edd.receiverPostcode = '222';            
            edd.fetchEDD();            
        Test.stopTest();
        system.assertEquals(edd.servicesFound, false);
    }
}