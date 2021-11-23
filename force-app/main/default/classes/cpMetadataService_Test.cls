/**
 * Test class to cover the generated WSDL2Apex code, it is not a functional test class
 **/
@isTest
private class cpMetadataService_Test{
    private static User adminUser = new User();
    
    /* Prepare Test data*/
    private static void loadTestData(){
        cpTestDataFactory dataFactory = new cpTestDataFactory();
        
        Profile adminProf = [select Id, Name from Profile where name = 'System Administrator' limit 1];

        String adminemail = 'sysadmin@mailinator.com';
        adminUser = dataFactory.getUser(adminProf.Id,adminemail);
        Database.insert(adminUser);
    }
    
	@isTest
    private static void coverGeneratedCodeTypes() {
        loadTestData();
        System.runAs(adminUser){
            Test.startTest();
            Test.setMock(WebServiceMock.class, new cpWebServiceMockImpl());
        	cpMetadataService.MetadataPort service = new cpMetadataService.MetadataPort();
        	cpMetadataService.IReadResult res = service.readMetadata('KeywordList', new String[] {'Australia Post Community - OLD.Banned'});
        	cpMetadataService.Metadata[] records = res.getRecords();
    		system.debug('----RESULT---' + records);
            Test.stopTest();
        }
        
    }
}