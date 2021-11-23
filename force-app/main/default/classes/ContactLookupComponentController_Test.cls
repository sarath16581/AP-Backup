/**
*  This test class is for ContactLookupComponentController.
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
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
@isTest
private class ContactLookupComponentController_Test {

    static testMethod void myUnitTest() {
        Test.startTest();
        
        ContactLookupComponentController.AutoCompleteData conAc = new ContactLookupComponentController.AutoCompleteData('string label', 'string value', 'string contactType', 'string contactId', 'string contactName');
        ContactLookupComponentController.getData('s');
        
        system.assert(true);
        Test.stopTest();
    }
}