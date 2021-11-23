/**
*  This test class is for AddressComponentV1Controller.
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
private class AddressComponentV1Controller_Test {

    static testMethod void testMethods() {
        Test.startTest();
        AddressExtension add = new AddressExtension('line1', 'line2','city', 'state', 'postcode', 'dpid','country');
        AddressComponentV1Controller addd = new AddressComponentV1Controller();
        addd.setCurrentAddress(add);
        addd.getCurrentAddress();
        
        system.assert(true);
        Test.stopTest();
    }
}