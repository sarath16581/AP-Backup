@isTest
public class CustomerSAPEMArticlesController_Test {
        static testMethod void myUnitTest() {
            
        Account acc = TestDataProvider.createAndSavePersonAccount('DisplayArticles', Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        acc.APCN__pc = '1123456789';
        acc.APCN__c = '1123456789';
        update acc;
 
        insert new AusPostSettings__c(Name = 'SAPEMCustomerArticles', Username__c = 'Username', Password__c = 'Password',URL__c = 'https://ptest.npe.auspost.com.au/mypost/dashboard/#/home',PageSize__c = 10);
            
        test.startTest();           
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(acc);
        CustomerSAPEMArticlesController ext = new CustomerSAPEMArticlesController(stdCtl);    
        Test.setMock(HttpCalloutMock.class, new CustomerArticleSearchHttpCalloutMock());
            
            ext.first();
            System.assertEquals(1,ext.pagenumber);

            ext.next();
            System.assertEquals(2,ext.pagenumber);
            
            ext.previous();
            System.assertEquals(1,ext.pagenumber);
            
            ext.last();
            System.assertEquals(ext.totalpages,ext.pagenumber);
            
            ext.getCustomerArticleList();
           	System.assertEquals('8GY001658901000605005',ext.articleList[0].articleID);
            
            test.stopTest();
        
        }

}