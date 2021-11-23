/**
 * Date            Version          Owner               Desription
 * 15-Mar-17        1.0             Adrian A            Test class for documentPreviewController
 */
@isTest
private class DocumentPreviewControllerTest {
	/* Method to build Chatter File */
	public static void buildChatterFile(Id parenId){
		try{
            // Create dummy attachment
            Blob fileTest = Blob.valueof('testblob');
    
            Set<Id> conVerIdSet = new Set<Id>();
            Map<Id, Id> conDocMap = new Map<Id, Id>(); 
    
            // Create content version
            ContentVersion cvVar = new ContentVersion();            
            cvVar.VersionData = fileTest;
            cvVar.pathOnClient = 'test';
            cvVar.title = 'test'; 
            insert cvVar;       
    
            // Pull Generated CD
            ContentDocument cdVar = [Select Id,LatestPublishedVersionId 
                                     from ContentDocument 
                                     where LatestPublishedVersionId = :cvVar.Id LIMIT 1];
               
            // Create content document link
            ContentDocumentLink cdlVar = new ContentDocumentLink();
            cdlVar.LinkedEntityId  = parenId;
            cdlVar.ContentDocumentId = cdVar.Id;
            cdlVar.ShareType = 'V';
            insert cdlVar;
        }catch(Exception e){
        	e.getStackTraceString();    
        }
    }
	
    /* Test Method for document preview */
	public static testmethod void testDocumentPreviewController() {
        try{
            // Create Test Case
            Case cs = I2CTestDataBuilder.createCase();
            insert cs;
    
            // Create Test Disputed Items without existing CA
            List<Disputed_Item__c> diListWithoutCA = I2CTestDataBuilder.createDisputeItem(cs);
    
            insert diListWithoutCA;
    
            // Query generated CA
            List<Credit_Approval__c> caList = [Select Id ,(Select Id from Disputed_Items__r) from Credit_Approval__c];
    
            Test.startTest();
            buildChatterFile(caList[0].Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(caList[0]);
            DocumentPreviewController dpCon = new DocumentPreviewController(sc);			
            Test.stopTest();
            system.assertEquals(1, dpCon.Photos.size());
        }catch(Exception e){
        	e.getStackTraceString();    
        }
	}
	
}