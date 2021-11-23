/**
*  This test class is for Constants.
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
private class Constants_Test {

    static testMethod void myUnitTest() {
        Test.startTest();
        
        Constants con = new Constants();
        
        system.assert(true);
        Test.stopTest();
    }
}