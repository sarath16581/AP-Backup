/**************************************************
Description:       Test for AccountOrgAddressInformationAccExt
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Created
**************************************************/
@isTest
private class AccountOrgAddressInformationAccExt_Test {

    static testMethod void testLoadingAndSaving() {
    	
    	Account acc = TestDataProvider.createTestAccount();

        acc.BillingStreet = 'Unit 1';
        acc.BillingStreet2__c = '10 Some Street';
        acc.BillingCity = 'SomeCity';
        acc.BillingPostalCode = '1234';
        acc.BillingState = 'VIC';
        acc.BillingCountry = 'AU';
        acc.Billing_DPID__c = '3456';

        acc.ShippingStreet = 'Unit 12';
        acc.ShippingCity = 'SomeOtherCity';
        acc.ShippingPostalCode = '1244';
        acc.Shipping_DPID__c = '3445';
        acc.ShippingState = 'NSW';
        acc.ShippingCountry = 'AU';

    	insert acc;
    	
        Test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc); 
        AccountOrgAddressInformationAccExt ext = new AccountOrgAddressInformationAccExt(ctrl);

        System.assertEquals(ext.billingAddress.line1, acc.BillingStreet);
        System.assertEquals(ext.billingAddress.line2, acc.BillingStreet2__c);
        System.assertEquals(ext.billingAddress.city, acc.BillingCity);
        System.assertEquals(ext.billingAddress.state, acc.BillingState);
        System.assertEquals(ext.billingAddress.country, acc.BillingCountry);
        System.assertEquals(ext.billingAddress.postcode, acc.BillingPostalCode);
        System.assertEquals(ext.billingAddress.dpid, acc.Billing_DPID__c);

        System.assertEquals(ext.shippingAddress.line1, acc.ShippingStreet);
        System.assertEquals(ext.shippingAddress.city, acc.ShippingCity);
        System.assertEquals(ext.shippingAddress.state, acc.ShippingState);
        System.assertEquals(ext.shippingAddress.country, acc.ShippingCountry);
        System.assertEquals(ext.shippingAddress.postcode, acc.ShippingPostalCode);
        System.assertEquals(ext.shippingAddress.dpid, acc.Shipping_DPID__c);

        ext.billingAddress.line1 = 'Unit 2';
        ext.billingAddress.line2 = 'Lala Ln';
        ext.billingAddress.city = 'Whoa';
        ext.billingAddress.state = 'WA';
        ext.billingAddress.country = 'AU';
        ext.billingAddress.postcode = '5645';
        ext.billingAddress.dpid = '45453';

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
                        BillingCity, Billing_DPID__c, BillingPostalCode, BillingState, BillingStreet, BillingStreet2__c, BillingCountry,
                        ShippingCountry, ShippingCity, Shipping_DPID__c, ShippingPostalCode, ShippingState, ShippingStreet
                FROM Account
                WHERE Id =:acc.Id
                LIMIT 1
        ];

        System.assertEquals(ext.billingAddress.line1, acc.BillingStreet);
        System.assertEquals(ext.billingAddress.line2, acc.BillingStreet2__c);
        System.assertEquals(ext.billingAddress.city, acc.BillingCity);
        System.assertEquals(ext.billingAddress.state, acc.BillingState);
        System.assertEquals(ext.billingAddress.country, acc.BillingCountry);
        System.assertEquals(ext.billingAddress.postcode, acc.BillingPostalCode);
        System.assertEquals(ext.billingAddress.dpid, acc.Billing_DPID__c);

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