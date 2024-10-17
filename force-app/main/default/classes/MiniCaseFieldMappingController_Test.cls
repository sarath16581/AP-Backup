/**
*  This test class is for MiniCaseFieldMappingController.
*
@author Frank Chen
@created 2014-06-20
@version 1.0
@since 20.0
*
@changelog
* 2014-06-20 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 88%
*/
@isTest
private class MiniCaseFieldMappingController_Test {

    static testMethod void testStdCtrl() {
    	
    	MiniCaseFieldMapping__c mcfm = TestDataProvider.createTestMiniCaseFieldMapping();
    	insert mcfm;
    	
        Case testCase = ApplicationTestDataFactoryCase.getCases(1, false).get(0);
        testCase.referenceId__c = 'SSSWCase';
        insert testCase;
        
        Test.startTest();
        
        ApexPages.StandardController stdCtl = new ApexPages.StandardController(mcfm);
       	MiniCaseFieldMappingController ext = new MiniCaseFieldMappingController(stdCtl);
        
        ext.save();
        
        system.assert(mcfm.Id != null);
        
        String recordTypeId = MiniCaseFieldMappingController.getRecordTypeId('General Enquiry', 'Domestic Parcels', 'Express');
        System.assert(recordTypeId != null, 'RecordTypeId expected');
        
        Test.stopTest();
    }
}