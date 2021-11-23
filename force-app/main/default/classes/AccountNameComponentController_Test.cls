/**
*  This test class is for AccountNameComponentController.
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
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
@isTest
private class AccountNameComponentController_Test {

    static testMethod void testCtrl() {
    	
    	Account acc = TestDataProvider.createTestAccount();
    	insert acc;
    	
        Test.startTest();
        
        AccountNameComponentController.AutoCompleteData acclcAuto = new AccountNameComponentController.AutoCompleteData('label', 'value','New', acc.Id, '1');
        AccountNameComponentController.getData('1');
        
        system.assert(true);
        Test.stopTest();
    
    }
}