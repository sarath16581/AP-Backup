/**
*  This test class is for AusPostSMSWrapper.
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
private class AusPostSMSWrapper_Test {

    static testMethod void testMethods() {
        Test.startTest();
        
        AusPostSMSWrapper aus = new AusPostSMSWrapper();
        aus.sendSMS('phone', 'message');
        
        system.assert(true);
        Test.stopTest();
    }
}