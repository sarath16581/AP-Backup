/**
* Author: 		Angelo Rivera
* Name: 		BatchDeleteI2CTemporaryDocumentsTest
* Description: 	Test Class for BatchDeleteWebFormTemporaryDocuments
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/
@isTest
private class BatchDeleteI2CTemporaryDocumentsTest {
	
	private static final String ECCF_PROFILE = 'Enterprise Credit Claim Form Profile';

	@isTest static void testBatchClass() {

		I2C_Web_Form_Profiles__c wbProfile = new I2C_Web_Form_Profiles__c(Name = ECCF_PROFILE, Profile_Name__c = ECCF_PROFILE);
		insert wbProfile;

		integer ctr;
		List<Document> lstTempDocument = new List<Document>();

		Profile prof = [SELECT Id,Name FROM profile where Name =: ECCF_PROFILE LIMIT 1];

		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
	       
	        for(ctr = 0; ctr < 10; ctr++){
	        	Document tempDocument = new Document();
		        tempDocument.AuthorId = UserInfo.getUserId();
		        tempDocument.FolderId = UserInfo.getUserId(); // put it in running user's folder
		        tempDocument.Body = Blob.valueOf('Test Document');       
		        tempDocument.Name = 'TemporaryDocument_TestDocument'+ctr+'.txt';  
		        tempDocument.Description = 'TemporaryDocument_TestDescription'+ctr;
		        tempdocument.IsInternalUseOnly = true;
		        lstTempDocument.add(tempdocument);
	        }
	        insert lstTempDocument;

	        Test.startTest();
			    BatchDeleteWebFormTemporaryDocuments batchClass= new BatchDeleteWebFormTemporaryDocuments();
			    Database.executeBatch(batchClass);
	        
	        Test.stopTest();
	    }
	        List<Document> lstDoc = new List<Document>([Select Id from Document 
	        												where name like 'TemporaryDocument_%' 
	        													and Description like 'TemporaryDocument_%'  ]);
        	system.assertEquals(lstDoc.size(), 0);
	}
	
}