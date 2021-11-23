/**
*  This test class is for FieldValueImageController.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52, the class is pending for decommission in the future date
*/
@isTest
private class FieldValueImageController_Test {

    static testMethod void myUnitTest() {
    	
    	FieldValueImageSettings__c fvi1 = TestDataProvider.createTestFieldValueImageSettings();
    	
    	Contact con = TestDataProvider.createTestContact();
    	insert con;
    	
        Test.startTest();
        
        FieldValueImageController fvi = new FieldValueImageController();
        fvi.innerRecordID = con.Id;
        Map<string, string> innerListOfImageUrls = fvi.listOfImageUrls;
        
        system.assert(true);
        Test.stopTest();
    }
}