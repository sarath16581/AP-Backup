/**
*  This test class is for CaseUtility.
*
@author Yuanyuan Zhang
@created 2014-07-16
@version 1.0
@since 30.0
*
@changelog
* 2014-07-16 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* - Created
* - Test coverage  100%
* 2021-08-11 - Seth Heang - Uplift API version to 52
*/
@isTest
private class internalArticlePreview_Test {
    
    static testmethod void test1 () {
        test.startTest();
        
        
        FAQ__kav fk = new FAQ__kav();
        fk.Answer__c = 'testxxx';
        //fk.PublishStatus = 'Draft';
        fk.Title = 'testxxx';
        fk.UrlName = 'testxx';
        insert fk;
        
        try {
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(fk);   
            internalArticlePreview ext = new internalArticlePreview(stdCtl);
            ext.previewRedirect();
        } catch (Exception e) {
            ExternalURL__c ex = new ExternalURL__c(Name = 'ArticlePreview', myURL__c = 'https://test.my.url.com');
            insert ex;
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(fk);   
            internalArticlePreview ext = new internalArticlePreview(stdCtl);
            ext.previewRedirect();
        }
        test.stopTest();
    }
}