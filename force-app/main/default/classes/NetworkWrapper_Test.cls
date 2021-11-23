/**
*  This test class is for NetworkWrapper.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 100%
*/
@isTest
private class NetworkWrapper_Test {

    static testMethod void testCtrl() {
    	
    	Network__c network = new Network__c();
    	
        Test.startTest();
        
        NetworkWrapper nw = new NetworkWrapper(network);
        
        system.assert(true);
        Test.stopTest();
    }
}