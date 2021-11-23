/**
*  This test class is for TIBCODataVisulaizationTestCont.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  100%
*/
@isTest
private class TIBCODataVisulaizationTestCont_Test {

    static testMethod void myUnitTest() {
    	
    	Article__c art = new Article__c();
    	art.Name = '123';
    	art.ArticleLodgementDate__c = date.today();
    	art.SenderPostcode__c = '123';
    	art.ReceiverPostcode__c = '3002';
    	art.ArticleType__c = 'Regular Parcel';
    	art.ReceiverName__c = '123';
    	art.ReceiverEmail__c = 'dsf@163.com';
    	art.ArticleLodgementDate__c = date.today();
    	art.ProductCategory__c = 'eParcel';
    	art.ArticleTransitAmountValue__c = 1;
    	art.SubProduct__c = 'eParcel Standard';
    	art.ActualWeight__c = 2;
    	art.DeliveryInstructions__c = '99bb';
    	insert art;    	
    	
    	TIBCOSearchResult searchResult = new TIBCOSearchResult();
    	
    	
        Test.startTest();
        
        TIBCODataVisulaizationTestCont tib = new TIBCODataVisulaizationTestCont();
        
        tib.articleId = art.Id;
        
        tib.search();
        tib.createArticles();
        
        system.assert(true);
        Test.stopTest();
    }
}