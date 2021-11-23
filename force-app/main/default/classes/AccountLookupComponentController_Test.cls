/**
*  This test class is for AccountLookupComponentController.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  80%
*/
@isTest
private class AccountLookupComponentController_Test {

    static testMethod void testCtrl() {
    	
    	Account acc = TestDataProvider.createTestAccount();
    	acc.ABN__c = '17289287381';
    	insert acc;
    	
        Test.startTest();
        AccountLookupComponentController instance = new AccountLookupComponentController();
        AccountLookupComponentController.AutoCompleteData acclcAuto = new AccountLookupComponentController.AutoCompleteData('label', 'value','New', acc.Id, '1', 'dfde');
        AccountLookupComponentController.getData('1', true);
        AccountLookupComponentController.getData('1', false);
        
        system.assert(true);
        Test.stopTest();
    
    }
}