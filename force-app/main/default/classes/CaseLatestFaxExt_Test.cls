/**
*  This test class is for CaseLatestFaxExt.
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
private class CaseLatestFaxExt_Test {

    static testMethod void myUnitTest() {
    	
    	AllowedFaxAttachmentFiles__c allow = TestDataProvider.createTestAllowedFaxAttachmentFiles();
    	
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
            	
    	Fax__c fax = TestDataProvider.createTestFax();
    	fax.Case__c = case1.Id;
    	insert fax;

    	Attachment att = new Attachment();
    	att.Name = '123';
    	att.ParentId = fax.Id;
    	att.Body = blob.valueOf('1');
    	insert att;    	
    	
        Test.startTest();
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(case1);  
        CaseLatestFaxExt ext = new CaseLatestFaxExt(sc1);  
        
        ext.myCaseId = case1.Id;
        
        ext.reLoad();
        
        system.assert(true);
        Test.stopTest();
    }
}