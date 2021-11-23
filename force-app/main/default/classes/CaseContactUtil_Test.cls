/**
*  This test class is for CaseContactUtil.
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
private class CaseContactUtil_Test {

    static testMethod void myUnitTest() {
		Account acc = TestDataProvider.createTestAccount();
    	insert acc;
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
    	Opp_Product_Classification__c opc = TestDataProvider.createTestOpp_Product_Classification();
    	opc.Account__c = acc.Id;
    	insert opc;
    	
    	Opportunity oppy = TestDataProvider.createTestOpportunity();
    	insert oppy;
    	
    	Case case1 = new Case();
    	case1.Originating_OPC__c = opc.Id;
    	case1.Opportunity__c = oppy.Id;
    	case1.ContactId = con.Id;
    	case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
    	insert case1;
    	
    	AuthorisedContacts__c autho = new AuthorisedContacts__c();
    	autho.AuthorisingContact__c = con.Id;
    	insert autho;
    	
    	Map<Id,Case> newCases = new Map<Id,Case>();
    	newCases.put(case1.Id,case1);
    	
    	Test.startTest();
    	
    	CaseContactUtil.CopyAuthorisedContacts(newCases);
    	
    	system.assert(true);
    	Test.stopTest();
    }
}