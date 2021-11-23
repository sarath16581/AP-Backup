/**
  * This test class is for QuickLinksFooterPanelCont.
  *
  * @author Frank Chen
  * @created 2014-06-24
  * @version 1.0
  * @since 20.0
  * @changelog
  * 2014-06-23 Frank Chen <di.chen@bluewolf.com>
  * - Created
  * - Test coverage
  * 2021-05-17 S Judd Added new method testSTQuicklinks
*/
@isTest
private class QuickLinksFooterPanelCont_Test {

    static testMethod void myUnitTest() {
    	
    	AusPostSettings__c aps = TestDataProvider.createTestAusPostSettings2();
    	
    	QuickReference__c qr = new QuickReference__c();
    	qr.Hide__c = false;
    	qr.RecordTypeId = [SELECT Id FROM RecordType where DeveloperName = 'QuickLinks' and SobjectType = 'QuickReference__c' limit 1].Id;
    	qr.FullHyperlink__c = 'http://auspost.com.au/apps/postage-calculator.html';
    	insert qr;
    	
    	Attachment att = new Attachment();
    	att.Body = blob.valueOf('1');
    	att.ParentId = qr.Id;
    	att.Name = 'SunNM';
    	insert att;

		PageReference pageRef = Page.QuickLinksFooterPanel;
		Test.setCurrentPage(pageRef);
		Test.startTest();

        QuickLinksFooterPanelCont qlf = new QuickLinksFooterPanelCont();
        
        QuickLinksFooterPanelCont.getToken(true);

		system.assert(qlf.quickLinkWrappers.size() != 0);
        Test.stopTest();
    }
	// Tests for StarTrack console - different page.
	static testMethod void testSTQuicklinks() {

		AusPostSettings__c aps = TestDataProvider.createTestAusPostSettings2();

		QuickReference__c qr = new QuickReference__c();
		qr.Hide_ST__c = false;
		qr.RecordTypeId = [SELECT Id FROM RecordType where DeveloperName = 'QuickLinks' and SobjectType = 'QuickReference__c' limit 1].Id;
		qr.FullHyperlink__c = 'http://auspost.com.au/apps/postage-calculator.html';
		insert qr;

		Attachment att = new Attachment();
		att.Body = blob.valueOf('1');
		att.ParentId = qr.Id;
		att.Name = 'SunNM';
		insert att;

		PageReference pageRef = Page.QuickLinksFooterPanelST;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		//QuickLinksFooterPanelCont.QuickLinkWrapper qw = new QuickLinksFooterPanelCont.QuickLinkWrapper(qr,att);

		QuickLinksFooterPanelCont qlf = new QuickLinksFooterPanelCont();

		QuickLinksFooterPanelCont.getToken(true);

		system.assert(qlf.quickLinkWrappers.size() != 0);
		Test.stopTest();
	}
}