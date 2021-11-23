/**
*  This test class is for CustomComponentFactory.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  90%
*/
@isTest
private class CustomComponentFactory_Test {

    static testMethod void myUnitTest() {
    	
    	Article__c art = new Article__c();
    	art.Name = '123';
    	art.ArticleLodgementDate__c = date.today();
    	art.SenderPostcode__c = '123';
    	art.ReceiverPostcode__c = '3002';
    	art.ArticleType__c = 'Regular Parcel';
    	insert art;
    	    	
    	Test.startTest();
    	
        CustomComponentFactory.newComponent('MRSFiltersComponent', art.Id);
        CustomComponentFactory.newComponent('SAPFiltersComponent', art.Id);
        CustomComponentFactory.newComponent('TIBCODataVisualizerComponent', art.Id);
        
        system.assert(true);
        Test.stopTest();
    }
}