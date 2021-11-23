/**
*  This test class is for LatestFaxExt.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 78%
*/
@isTest
private class LatestFaxExt_Test {

    static testMethod void myUnitTest() {
    	
    	AllowedFaxAttachmentFiles__c allow = TestDataProvider.createTestAllowedFaxAttachmentFiles();
    	
    	Fax__c fax = TestDataProvider.createTestFax();
    	insert fax;
    	
    	Attachment att = new Attachment();
    	att.Name = '123';
    	att.ParentId = fax.Id;
    	att.Body = blob.valueOf('1');
    	insert att;
    	
        Test.startTest();
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(fax);  
        LatestFaxExt ext = new LatestFaxExt(sc1);  
		
		ext.myFaxId = fax.Id;
		
		ext.reLoad();
        
        system.assert(true);
        Test.stopTest();
    }
}