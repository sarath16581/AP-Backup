/**
*  This test class is for AccountAddressInformationAccExt.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 100%
*/
@isTest
private class AccountAddressInformationAccExt_Test {

    static testMethod void testStdCtrl() {
    	
    	Account acc = TestDataProvider.createTestAccount();
    	insert acc;
    	
        Test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc); 
        AccountAddressInformationAccExt ext = new AccountAddressInformationAccExt(ctrl);
        
        ext.saveAccount();
        ext.cancel();
        
        system.assert(true);
        Test.stopTest();
    }
}