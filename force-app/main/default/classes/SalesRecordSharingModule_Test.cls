@isTest
private class SalesRecordSharingModule_Test {
    @isTest
    private static void testAfterInsert() {
        // =====================================
        // Data Preparation
        // =====================================
        
        List<SObject> testInsertData = ApplicationTestDataFactory.getLeads(1, true);
		ApplicationUnitOfWork uow = new ApplicationUnitOfWork();       
        
        // =====================================
        // Stubbing
        // =====================================s
		MockUtility.Mocks.startStubbing();
    	SalesRecordSharingService mockService = (SalesRecordSharingService)MockUtility.mockUtility(SalesRecordSharingService.class);
        MockUtility.Mocks.stopStubbing();
        
        SalesRecordSharingModule testModule = SalesRecordSharingModule.newInstance();
        
        testModule.onAfterInsert(testInsertData, uow);
        
        fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
        
        ((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.anyObject(),(Map<Id, SObject>) shareRecordsCapture.capture(),fflib_Match.anyBoolean(),(ApplicationUnitOfWork)fflib_Match.anyObject());
        Map<Id, SObject> shareRecordsCaptureParams = (Map<Id, SObject>)shareRecordsCapture.getValue();
        
        system.assertEquals(1, shareRecordsCaptureParams.size(),'A record should be submitted for sharing');
    }
    
 	@isTest
    private static void testAfterUpdate() {
        // =====================================
        // Data Preparation
        // =====================================
        
        List<Lead> testUpdateData = ApplicationTestDataFactory.getLeads(2, true);
        testUpdateData[0].id = testUpdateData[1].id;
    	testUpdateData[0].firstName = 'changedValue';
        

        Map<Id,SObject> existingRecords = new Map<Id, SObject>{testUpdateData[1].id => testUpdateData[1]};
        Boolean recalculate = false;
		ApplicationUnitOfWork uow = new ApplicationUnitOfWork();       
        
        SalesRecordSharingService.SalesSharingObjectMapping objectMapping = 
        new SalesRecordSharingService.SalesSharingObjectMapping(
        	Lead.getSObjectType(),
        	Lead.FirstName.getDescribe().getSObjectField(),
            'Name',
            'Reason');
        
        // =====================================
        // Stubbing
        // =====================================s
		MockUtility.Mocks.startStubbing();
    	SalesRecordSharingService mockService = (SalesRecordSharingService)MockUtility.mockUtility(SalesRecordSharingService.class);
        MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eq(objectMapping.objectType))).thenReturn(objectMapping);
        MockUtility.Mocks.stopStubbing();
        
        SalesRecordSharingModule testModule = SalesRecordSharingModule.newInstance();
        
        testModule.onAfterUpdate(testUpdateData,existingRecords, uow);
        
        fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
       
        ((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.anyObject(),(Map<Id, SObject>) shareRecordsCapture.capture(),fflib_Match.anyBoolean(),(ApplicationUnitOfWork)fflib_Match.anyObject());
        Map<Id, SObject> shareRecordsCaptureParams = (Map<Id, SObject>)shareRecordsCapture.getValue();
        
        system.assertEquals(1, shareRecordsCaptureParams.size(),'A record should be submitted for sharing');
        
    }
}