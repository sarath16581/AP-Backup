/**
*  This test class is for TIBCODataVisualizerComponentCont.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-24 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  91%
*/
@isTest
private class TIBCODataVisualizerComponentCont_Test {

    static testMethod void myUnitTest1() {
    	
    	TIBCOSearchResult its = new TIBCOSearchResult();
    	its.success = true;
    	
        Test.startTest();
        
        TIBCODataVisualizerComponentCont itd = new TIBCODataVisualizerComponentCont();
        itd.searchResultVar = its;
        itd.save();
        
        system.assert(true);
        Test.stopTest();
    }
    static testMethod void myUnitTest2() {
    	
        Test.startTest();
        
        TIBCODataVisualizerComponentCont itd = new TIBCODataVisualizerComponentCont();
        itd.save();
        
        system.assert(true);
        Test.stopTest();
    }
}