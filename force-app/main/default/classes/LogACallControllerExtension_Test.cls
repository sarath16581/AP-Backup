/**
*  This test class is for LogACallControllerExtension.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
@isTest
private class LogACallControllerExtension_Test {

    static testMethod void myUnitTest() {
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
 		Case case1 = new Case();
 		case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
        
        Test.startTest();
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(case1);  
        LogACallControllerExtension ext = new LogACallControllerExtension(sc1);   
        
        LogACallControllerExtension.createLog(case1.Id, con.Id, 'dsf', 'subject', 'description');  
        
        system.assert(true);
        Test.stopTest();
    }
	static testMethod void myUnitTest2() {
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
 		Case case1 = new Case();
 		case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
        
        Test.startTest();
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(case1);  
        LogACallControllerExtension ext = new LogACallControllerExtension(sc1);   
        
        LogACallControllerExtension.createLog(case1.Id, null, 'dsf', 'subject', 'description');  
        
        system.assert(true);
        Test.stopTest();
    }
}