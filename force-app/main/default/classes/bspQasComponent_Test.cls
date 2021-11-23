/**
*  Test class for bspQasComponent
*
@author Yuanyuan Zhang
@created 2014-07-15
@version 1.0
@since 29.0
*
@changelog
* 2014-07-15 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* - Created
* - Coverage 100%
* 2021-10-05 seth.heang@auspost.com.au    Uplift SF API Version to 52
*/
@isTest
private class bspQasComponent_Test {
	static testmethod void testAll () {
		AddressExtension add = new AddressExtension('test', 'test', 'test', 'Australia', 'test', 'test', 'test');
		CountryCodes__c countries = new CountryCodes__c(name='Australia', Alpha2__c='AU', Alpha3__c='AUS', Numeric__c=36);
		insert countries;
		test.startTest();
		bspQasComponent bq = new bspQasComponent();
		bq.currentAddress  = add;
		bq.qasTypeString = 'enquiry';
		bq.getCountries();
		AddressExtension add1 = bq.currentAddress;
		test.stopTest();
	}
}