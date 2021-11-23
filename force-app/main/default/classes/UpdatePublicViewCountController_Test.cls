/**
*  This test class is for UpdatePublicViewCountController.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 87%
*/
@isTest
private class UpdatePublicViewCountController_Test {

    static testMethod void testUpdate() {
        FAQ__kav faq = new FAQ__kav();
        faq.Language='en_US'; 
        faq.Title = 'New FAQ';
        faq.UrlName = 'a';
        insert faq;
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('Id',faq.Id);
        UpdatePublicViewCountController upv = new UpdatePublicViewCountController();
        FAQ__kav faq2 = [select Id,Language,Title,UrlName from FAQ__kav where Id =: faq.Id];
        system.assertEquals(faq2.Title,'New FAQ');
        Test.stopTest();
    }
}