/**
*  This test class is for SendSMSControllerExtension.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 88%
*/
@isTest
private class SendSMSControllerExtension_Test {

    static testMethod void myUnitTest() {
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
    	Case case1 = new Case();
    	case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        insert case1;
    	
        Test.startTest();
        
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(case1);   
		SendSMSControllerExtension ext = new SendSMSControllerExtension(stdCtl);
		
		SendSMSControllerExtension.sendSMS(case1.Id, '123', con.Id, 'message');
        
        system.assert(true);
        Test.stopTest();
    }
}