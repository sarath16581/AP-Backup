/*
@Description        : Test class for APT_ContractFileShareBatch which links the files under all apttus contract
					  with the related sf contracts. This batch class is one time activity and can be deleted.
================================ Modification Log =============================== 
Developer Name  Date            Comments
Ramtej          15/05/2019      Created
*/
@isTest
public class APT_ContractFileShareBatchTest {
	// Test variable declaration
    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INAUTHOR_STATUS_CATEGORY = 'In Authoring';
    public static final string AUTHORCONTRACT_STATUS = 'Author Contract';
    
    static testMethod void testBatchMethod(){
        // Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        conVar.AccountId = accVar.Id;
        insert conVar;

        // Create test opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);

        // Create test agreement
        Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
                                                                              conVar,
                                                                              oppVar,
                                                                              new Apttus_Proposal__Proposal__c(),
                                                                              AUTHORCONTRACT_STATUS,
                                                                              'In Effect',
                                                                              MSA_RECORTYPE);

        aptContract.APT_Product__c = 'eParcel';
        aptContract.Apttus__Status__C = 'Activated';
        insert aptContract;
        
        //insert a file under apttus contract
        ContentVersion contentVersion0 = APT_TestUtil2.createContentVersion();
        insert contentVersion0;
        id contDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion0.Id].ContentDocumentId;
        insert APT_TestUtil2.createContentDocumentLink (aptContract.id, contDocId);
        
        //when a activated apttus contract is inserted an sf contract is created and hence size 1
        system.assertEquals(1, [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id].size());
        
        //insert custom setting for the batch to pick up the last run date
        Apttus_Contract_File_Share_Schedule_date__c filesShareScheduleDate = new Apttus_Contract_File_Share_Schedule_date__c();
        filesShareScheduleDate.File_Share_From_Date__c = system.Today();
        filesShareScheduleDate.Date_check_required_to_run_batch__c = true;
        insert filesShareScheduleDate;
        
        test.startTest();
        //run the batch
        APT_ContractFileShareBatch fileShareBatch = new APT_ContractFileShareBatch();
		Database.executeBatch(fileShareBatch,1);
        test.stopTest();
        
        //check the number of files for sf contracts
        Id contractId = [SELECT Id FROM Contract WHERE Parent_Agreement__c = :aptContract.Id].Id;
    }
}