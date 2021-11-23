/**************************************************
Type:       Test class for the RecordTypes class
Purpose:    Tests RecordType retrievals 
       
History:
--------------------------------------------------
17.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestRecordTypes {

    private static testMethod void testRecordTypeRetrieval() 
    {
    	RecordType rt = RecordTypes.getRecordTypeByName('Organisation', 'Account');
    	System.assert(rt.Name == 'Organisation' || rt.DeveloperName == 'Business_Account');
    	
    	rt = RecordTypes.getRecordTypeByName('Business_Account', 'Account');
    	System.assert(rt.Name == 'Organisation' || rt.DeveloperName == 'Business_Account');
    	
    	Integer numOfDML = Limits.getDMLStatements();
    	
    	RecordType lcrt = RecordTypes.getRecordTypeByName('Business_Account', 'Account');
    	System.assertEquals(rt.Id, lcrt.Id);
    	System.assertEquals(numOfDML, Limits.getDMLStatements()); //asserting if the internal caching is working correctly
    }
}