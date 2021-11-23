/**************************************************
Type:       Test class for the QuickLinksFooterPanelCont class
Purpose:    Tests if the attachments for the quick links are loaded correctly and the links are sorted 
			according to the definition on the QuickReference__c records
       
History:
--------------------------------------------------
18.12.2013  Mohamed.Atheek@bluewolf.com  Created
26.04.2021  S Judd Added Test.SetCurrentPage
**************************************************/

@isTest
private class TestQuickLinksFooterPanelCont {

    static testMethod void testQuickLinks() {
    	//create test data here
        QuickReference__c qr1 = TestDataProvider.createAndSaveQuickReference('qr1', 'http://www.someurl1.com', 3, Constants.RECORDTYPE_NAME_QUICKREFERENCE_QUICKLINKS);
        TestDataProvider.createAndSaveAttachment('att1', qr1.Id, Blob.valueOf('body1'));
        
        QuickReference__c qr2 = TestDataProvider.createAndSaveQuickReference('qr2', 'http://www.someurl2.com', 2, Constants.RECORDTYPE_NAME_QUICKREFERENCE_QUICKLINKS);
        TestDataProvider.createAndSaveAttachment('att2', qr2.Id, Blob.valueOf('body2'));
        
        QuickReference__c qr3 = TestDataProvider.createAndSaveQuickReference('qr3', 'http://www.someurl3.com', 1, Constants.RECORDTYPE_NAME_QUICKREFERENCE_QUICKLINKS);
        TestDataProvider.createAndSaveAttachment('att3', qr3.Id, Blob.valueOf('body3'));

        PageReference pageRef = Page.QuickLinksFooterPanel;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        
        //create the class in test and call the appropriate method(s) to execute
        QuickLinksFooterPanelCont contr = new QuickLinksFooterPanelCont();
        
        Test.stopTest();
        
        //assert the results
        System.assertEquals(1, contr.quickLinkWrappers.size());//number of rows that the above 3 quick links will create on a large screen
        System.assertEquals(3, contr.quickLinkWrappers[0].size());//number of quick links in the first row on a large screen
        
        System.assertEquals('qr3', contr.quickLinkWrappers[0][0].ql.Name);//asserting if the sort order was respected
        System.assertEquals(qr3.Id, contr.quickLinkWrappers[0][0].a.ParentId);//asserting if the attachment (thumbnail image of the link) was loaded correctly
        
        System.assertEquals('qr2', contr.quickLinkWrappers[0][1].ql.Name);
        System.assertEquals(qr2.Id, contr.quickLinkWrappers[0][1].a.ParentId);
        
        
        System.assertEquals('qr1', contr.quickLinkWrappers[0][2].ql.Name);
        System.assertEquals(qr1.Id, contr.quickLinkWrappers[0][2].a.ParentId);
    }
}