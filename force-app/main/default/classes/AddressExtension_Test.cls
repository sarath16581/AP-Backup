/**
*  This test class is for AddressExtension.
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
private class AddressExtension_Test {

    static testMethod void testCtrl() {
        Test.startTest();
        
        AddressExtension add = new AddressExtension('line1', 'line2','city', 'state', 'postcode', 'dpid','country');
        
        system.assert(true);
        Test.stopTest();
    }
    @isTest
    public static void testEmptyConstructor() {
        Test.startTest();
            AddressExtension add = new AddressExtension();
            System.assert(add.line1 == '');
            System.assert(add.line2 == '');
            System.assert(add.city == '');
            System.assert(add.state == '');
            System.assert(add.postcode == '');
            System.assert(add.dpid == '');
            System.assert(add.country == '');
        Test.stopTest();
    }

    @isTest
    public static void testConstructor() {
        Test.startTest();
            AddressExtension add = new AddressExtension('line1', 'line2','city', 'state', 'postcode', 'dpid','australia');
            System.assert(add.line1 == 'line1');
            System.assert(add.line2 == 'line2');
            System.assert(add.city == 'city');
            System.assert(add.state == 'state');
            System.assert(add.postcode == 'postcode');
            System.assert(add.dpid == 'dpid');
            System.assert(add.country == 'AU');
        Test.stopTest();
    }

    @isTest
    public static void testConstructorForCountry() {
        Test.startTest();
            AddressExtension add = new AddressExtension('line1', 'line2','city', 'state', 'postcode', 'dpid','');
            System.assert(add.line1 == 'line1');
            System.assert(add.line2 == 'line2');
            System.assert(add.city == 'city');
            System.assert(add.state == 'state');
            System.assert(add.postcode == 'postcode');
            System.assert(add.dpid == 'dpid');
            System.assert(add.country == 'AU');
        Test.stopTest();
    }    
}