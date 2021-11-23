/**************************************************
Description:       Test for AccountOrgAddressInformationAccExt
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Created
**************************************************/
@isTest
private class AccountOrgShippingAddressInfoAccExt_Test {

    static testMethod void testLoadingAndSaving() {
    	
    	Account acc = TestDataProvider.createTestAccount();

        acc.ShippingStreet = 'Unit 12';
        acc.ShippingCity = 'SomeOtherCity';
        acc.ShippingPostalCode = '1244';
        acc.Shipping_DPID__c = '3445';
        acc.ShippingState = 'NSW';
        acc.ShippingCountry = 'AU';

    	insert acc;
    	
        Test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc); 
        AccountOrgShippingAddressInfoAccExt ext = new AccountOrgShippingAddressInfoAccExt(ctrl);

        System.assertEquals(ext.shippingAddress.line1, acc.ShippingStreet);
        System.assertEquals(ext.shippingAddress.city, acc.ShippingCity);
        System.assertEquals(ext.shippingAddress.state, acc.ShippingState);
        System.assertEquals(ext.shippingAddress.country, acc.ShippingCountry);
        System.assertEquals(ext.shippingAddress.postcode, acc.ShippingPostalCode);
        System.assertEquals(ext.shippingAddress.dpid, acc.Shipping_DPID__c);

        ext.shippingAddress.line1 = 'Unit 3';
        ext.shippingAddress.line2 = 'Lala St';
        ext.shippingAddress.city = 'Whoas';
        ext.shippingAddress.state = 'WA';
        ext.shippingAddress.country = 'AU';
        ext.shippingAddress.postcode = '5644';
        ext.shippingAddress.dpid = '45466';

        ext.saveAccount();

        acc = [
                SELECT
                        ShippingCountry, ShippingCity, Shipping_DPID__c, ShippingPostalCode, ShippingState, ShippingStreet
                FROM Account
                WHERE Id =:acc.Id
                LIMIT 1
        ];

        System.assertEquals(ext.shippingAddress.line1 + ' ' + ext.shippingAddress.line2, acc.ShippingStreet);
        System.assertEquals(ext.shippingAddress.city, acc.ShippingCity);
        System.assertEquals(ext.shippingAddress.state, acc.ShippingState);
        System.assertEquals(ext.shippingAddress.country, acc.ShippingCountry);
        System.assertEquals(ext.shippingAddress.postcode, acc.ShippingPostalCode);
        System.assertEquals(ext.shippingAddress.dpid, acc.Shipping_DPID__c);

        ext.cancel();
        
        system.assert(true);
        Test.stopTest();
    }
}