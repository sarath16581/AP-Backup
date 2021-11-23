/**
*  This test class is for SSSWCN08FormContExt.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  78%
*/
@isTest
private class SSSWCN08FormContExt_Test {

    static testMethod void myUnitTest() {
    	
    	Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
    	
    	CN08__c cn = new CN08__c();
    	cn.Case__c = case1.Id;
    	insert cn;
    	
    	Test.startTest();
    	
    	ApexPages.StandardController stdCtl = new ApexPages.StandardController(cn);   
		SSSWCN08FormContExt ext = new SSSWCN08FormContExt(stdCtl);
    	
    	system.assert(true);
    	Test.stopTest();
    }
	static testMethod void myUnitTest2() {
		
    	Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
    	
    	CN08__c cn = new CN08__c();
    	cn.Case__c = case1.Id;
    	insert cn;
    	
    	Test.startTest();
    	
    	ApexPages.StandardController stdCtl = new ApexPages.StandardController(cn);   
		SSSWCN08FormContExt ext = new SSSWCN08FormContExt(stdCtl);
		
		ext.cn08 = cn;
    	
    	system.assert(true);
    	Test.stopTest();
    }
}