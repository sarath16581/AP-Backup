/**************************************************
Description :	This class contains unit tests for validating the behavior of Apex class CompensationGenerateFile_Batchable
History:
2018-09-18 dilshan.egodawela@auspost.com.au created
**************************************************/
 
 
@isTest
public class CompensationGenerateFile_Batchable_Test {

	@testSetup static void setup() {
		//create test data
		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
        insert testCase;
        
        Id recordTypeId = [select Id from RecordType where sobjectType = 'Compensation__c' and DeveloperName = 'EFT'].Id;
        
        Compensation__c comp = new Compensation__c(Case__c = testCase.Id ,Batch_ID__c = 1 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        Insert comp;
        
        Compensation__c comp2 = new Compensation__c(Case__c = testCase.Id , Batch_ID__c = 2 , Compensation_Amount__c = 50, CostCentreCode__c = 'test', BSB__c = '444333', Account_Number__c = '123234345' , RecordTypeId = recordTypeId);
        Insert comp2;
        
	}
	
	/********************************************
	Scenario:
	Test the method used by the scheduler class. Test batch Id assignment and file creation.
	*********************************************/
    static testMethod void testBatchMethod() {

        Test.startTest();
        //run the batch job
        CompensationGenerateFile_Batchable batch = new  CompensationGenerateFile_Batchable();
        Database.executeBatch(batch, 200);
        
		Test.stopTest();
		//get the compensation records after the batch completion
		List<Compensation__c> processedComps = [select id,Batch_ID__c , Name,Status__c from Compensation__c ];
		
		//both compensation values must be updated to batch 3.
		System.assertEquals(3,processedComps[0].Batch_ID__c,'');
		System.assertEquals(3,processedComps[1].Batch_ID__c,'');
		
		String nowDate = Date.today().format();
		System.Debug([SELECT Id,Name FROM Document WHERE Folder.Name = 'Compensation']);
		//get the workspace ID
		Id contectWorkspaceId = [Select Id, Name from ContentWorkspace where Name = 'Compensation' limit 1].Id;
		//use workspace id to get document id
		Id documentID = [select ContentDocumentId, ContentWorkspaceId from ContentWorkspaceDoc where ContentWorkspaceId =:contectWorkspaceId].ContentDocumentId;
		
		//get document title from contectDocument
		System.assertEquals('Compensation Batch(3) '+nowDate,[SELECT Id,Title FROM ContentDocument WHERE Id =:documentID limit 1].Title);
    }
    
    /********************************************
	Scenario:
	test the method used to run compensations by batch Id. verify only specified batches are run.
	*********************************************/
    static testMethod void testBatchbyNumberMethod() {
        
        Test.startTest();
        //run the batch job
        
        CompensationGenerateFile_Batchable batch = new  CompensationGenerateFile_Batchable(2);
        
        Database.executeBatch(batch, 200);
        
		Test.stopTest();
		
		//get the compensation records after the batch completion
		List<Compensation__c> processedComps = [select id,Batch_ID__c , Name,Status__c from Compensation__c Order by Batch_ID__c];
		//only compensation with batch 2 should be processed.
		//record with batch 1 should retain the same value
		System.assertEquals(1,processedComps[0].Batch_ID__c);
		//record with batch 2 should be updated to batch 3
		System.assertEquals(3,processedComps[1].Batch_ID__c);
    }
    
    /********************************************
	Scenario:
	test the method used email errors
	*********************************************/
    static testMethod void testErrorHandling() {
        
        Test.startTest();
        //send the email
        CompensationGenerateFile_Batchable.sendEmail('Compensation File Save Error','dilshan.egodawela@auspost.com.au');
        
        Integer invocations = Limits.getEmailInvocations();
      	System.assertEquals(1,invocations,'email sent');
        
		Test.stopTest();
    }

	/********************************************
   	Scenario:
   	test scheduling funtionality
   	*********************************************/
	static testMethod void testSchedulale() {

		Test.startTest();
		CompensationGenerateFile_Schedulable schedule = new CompensationGenerateFile_Schedulable();
		schedule.execute(null);
		Test.stopTest();

	}
    
}