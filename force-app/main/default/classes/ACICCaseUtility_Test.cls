/**************************************************
Description:    Test Class for ACICCaseUtility
History:
--------------------------------------------------
26.03.2019    gnana.muruganantham@auspost.com.au	Created
**************************************************/
@isTest
private with sharing class ACICCaseUtility_Test {
    
    /******************************************************************************************************
    * @description       This method is to test Proposal Update based on Case Status Update
    * @param             NA
    * @return            Void
    * @throws            NA
    ******************************************************************************************************/
    static testmethod void testUpdateProposalBasedOnACICStatus_success() {
        // Get ACIC Case Record Type Id 
        Id acicRecordTypeId = CaseUtility.getRecordIdWithDevName(Constants.RECORDTYPE_NAME_ACIC_REQUEST);
        
        // Create test Account
        Account testAccount = TestDataProvider.createTestAccount();
        Database.Insert(testAccount);
        
		// Create test Contact
        Contact testContact = TestDataProvider.createTestContact();
        Database.Insert(testContact);        
        
        // Create test Proposal
        Apttus_Proposal__Proposal__c testProposal = new Apttus_Proposal__Proposal__c(Apttus_Proposal__Proposal_Name__c='Test Proposal',Apttus_Proposal__Account__c=testAccount.Id,Apttus_Proposal__Primary_Contact__c=testContact.Id,Apttus_Proposal__Proposal_Expiration_Date__c=date.today()+10);
        Database.Insert(testProposal);
        
        // Create test ACIC Request Case
        Case testCase = new Case();
        testCase.Subject = 'Test ACIC Request Case';
        testCase.Description = 'Test ACIC Request Case';
        testCase.RecordTypeId = acicRecordTypeId;
        testCase.Proposal__c = testProposal.Id;
        testCase.Requestor__c= UserInfo.getUserId();
        
        // Inserting Case record
        test.startTest();
        Database.Insert(testCase);
        testCase.Status=Constants.CASE_STATUS_APPROVED;
        Database.Update(testCase);
        test.stopTest();
        
        // Checking whether Proposal record updated accordingly
        Apttus_Proposal__Proposal__c proposalRec = [SELECT Id, ACIC_Request_Approved__c FROM Apttus_Proposal__Proposal__c WHERE Id =: testProposal.Id];
        System.assertEquals(true, proposalRec.ACIC_Request_Approved__c);
    }
}