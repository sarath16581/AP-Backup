/**************************************************
Description:       Test for AccountOrgAddressInformationAccExt
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Created
**************************************************/
@isTest
private class AccountOrgBillingAddressInfoAccExt_Test {

    static testMethod void testLoadingAndSaving() {
    	
    	Account acc = TestDataProvider.createTestAccount();

        acc.BillingStreet = 'Unit 1';
        acc.BillingStreet2__c = '10 Some Street';
        acc.BillingCity = 'SomeCity';
        acc.BillingPostalCode = '1234';
        acc.BillingState = 'VIC';
        acc.BillingCountry = 'AU';
        acc.Billing_DPID__c = '3456';

    	insert acc;
    	
        Test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc); 
        AccountOrgBillingAddressInfoAccExt ext = new AccountOrgBillingAddressInfoAccExt(ctrl);

        System.assertEquals(ext.billingAddress.line1, acc.BillingStreet);
        System.assertEquals(ext.billingAddress.line2, acc.BillingStreet2__c);
        System.assertEquals(ext.billingAddress.city, acc.BillingCity);
        System.assertEquals(ext.billingAddress.state, acc.BillingState);
        System.assertEquals(ext.billingAddress.country, acc.BillingCountry);
        System.assertEquals(ext.billingAddress.postcode, acc.BillingPostalCode);
        System.assertEquals(ext.billingAddress.dpid, acc.Billing_DPID__c);

        ext.billingAddress.line1 = 'Unit 2';
        ext.billingAddress.line2 = 'Lala Ln';
        ext.billingAddress.city = 'Whoa';
        ext.billingAddress.state = 'WA';
        ext.billingAddress.country = 'AU';
        ext.billingAddress.postcode = '5645';
        ext.billingAddress.dpid = '45453';

        ext.saveAccount();

        acc = [
                SELECT
                        BillingCity, Billing_DPID__c, BillingPostalCode, BillingState, BillingStreet, BillingStreet2__c, BillingCountry
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

        ext.cancel();
        
        system.assert(true);
        Test.stopTest();
    }
}