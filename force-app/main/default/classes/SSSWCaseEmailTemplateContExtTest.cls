@isTest
public with sharing class SSSWCaseEmailTemplateContExtTest {
	
	static testMethod void SSSWCaseEmailTemplateContExtTest() {
		Contact con = TestDataProvider.createAndSaveContact();
		Case c = TestDataProvider.createCase();
		c.Type = 'General Enquiry';
		c.ContactId = con.Id;
		insert c;
		
		Test.startTest();
		
		ApexPages.CurrentPage().getparameters().put('id', c.id);
        ApexPages.StandardController sc = new ApexPages.standardController(c);
        SSSWCaseEmailTemplateContExt caseExt = new SSSWCaseEmailTemplateContExt(sc);
        caseExt.getBody();
        
        Test.stopTest();
	}
}