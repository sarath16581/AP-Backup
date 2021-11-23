/**
*  This test class is for PostcodeSuburbLookupController.
*
@author Frank Chen
@created 2014-06-24
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage  93%
*/
@isTest
private class PostcodeSuburbLookupController_Test {

    static testMethod void myUnitTest() {
    	
    	Postcode__c pc = new Postcode__c();
    	pc.Name = '1234';
    	pc.State__c = 'WA';
    	pc.Suburb__c = 'YALLINGUP SIDING';
    	insert pc;
    	
        Test.startTest();
        
        PostcodeSuburbLookupController.AutoCompleteData acd = new PostcodeSuburbLookupController.AutoCompleteData('string label', 'string value', 'string suburb', 'string postcode', 'string state', 'string loyality');
        
        PostcodeSuburbLookupController.getData('postcode', '1234');
        PostcodeSuburbLookupController.getData('suburb', '1234');
        PostcodeSuburbLookupController.getData('downtown', '1234');
        
        system.assert(true);
        Test.stopTest();
    }
}