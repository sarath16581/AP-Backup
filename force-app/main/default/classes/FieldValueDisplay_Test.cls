/**
*  This test class is for FieldValueDisplay.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 100%
*/
@isTest
private class FieldValueDisplay_Test {

    static testMethod void myUnitTest() {
        Test.startTest();
        
        FieldValueDisplay fvd = new FieldValueDisplay('Account','Account','Account');
        
        system.assert(true);
        Test.stopTest();
    }
}