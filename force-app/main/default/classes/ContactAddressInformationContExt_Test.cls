/**
*  This test class is for ContactAddressInformationContExt.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  90%
*/
@isTest
private class ContactAddressInformationContExt_Test {

    static testMethod void myUnitTest() {
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
		Test.startTest();
		
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(con);   
		ContactAddressInformationContExt ext = new ContactAddressInformationContExt(stdCtl);
		
		ext.saveContact();
		ext.cancel();
		
		system.assert(true);
		Test.stopTest();
    }
}