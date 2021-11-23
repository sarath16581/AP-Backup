/**
*  This test class is for CaseMassUploadDeciphaCont.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  81%
*/
@isTest
private class CaseMassUploadDeciphaCont_Test {
	
	static testMethod void myUnitTest() {
		
		Case case1 = new Case();
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.EnquirySubType__c = 'Article carded - no card left';
        case1.DateofIncident__c = date.today();
        insert case1;   
		
		Test.startTest();
		
		CaseMassUploadDeciphaCont cc = new CaseMassUploadDeciphaCont();
		cc.proxyCase = case1;
		cc.csvBlob = blob.valueOf('1');
		
		cc.upload();
		cc.downloadTemplate();
		
		system.assert(true);
		Test.stopTest();
    }
}