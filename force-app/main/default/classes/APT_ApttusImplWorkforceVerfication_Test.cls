/**
Created By - Seth Heang
Created Date - 08 August, 2019

*/
@isTest
public class APT_ApttusImplWorkforceVerfication_Test {

    /*
        This method will create test data for execution of test class
    */
    @testSetup static void setup() {
        // Create a new test account
        Account acc = APT_TestUtils.createOrganisation();
        acc.name = 'testOrg';
        acc.ABN__c = '12345678912';
        insert acc;

        // Create a new test Opportunity 
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.Amount = 100;
        insert opty;

        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        //create international product
        Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
        insert bundle1;
        
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;

        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
        Proposal.Apttus_Proposal__Account__c = acc.ID;
        insert Proposal;

        //Create Workforce Verification Product
        Product2 workforce_verification_prod = APT_TestUtils.createDomesticProduct(
            'Workforce verification Prod',
            'WVP12345',
            'Other Fees & Services',
            'CAT1',
            'Standard');

        //Input product's metadata to meet mandatory requirement for creating a product
        workforce_verification_prod.APT_Is_Apttus_Product__c = true;
        workforce_verification_prod.IsActive = true;
        workforce_verification_prod.Apttus_Config2__ConfigurationType__c = 'Standalone';
        workforce_verification_prod.APT_Sync_with_Opportunity__c = true;
        workforce_verification_prod.Apttus_Config2__Uom__c = 'Each';
        insert workforce_verification_prod;

        //Create proposal line item 
        Apttus_Proposal__Proposal_Line_Item__c proposal_li = new Apttus_Proposal__Proposal_Line_Item__c(
            Apttus_Proposal__Proposal__c=Proposal.Id,
            Apttus_QPConfig__ItemSequence__c=12,
            Apttus_QPConfig__LineNumber__c=2,
            Apttus_Proposal__Product__c = workforce_verification_prod.Id
        );
        insert proposal_li;

       
        // Query custom meta data setting and filter record type with name 'ACIC_Request'
        Apttus_Proposal_Automation__mdt settings = [SELECT MasterLabel,QualifiedApiName,Product_Type__c, Queue_Name__c,Record_Type__c 
                                                    FROM Apttus_Proposal_Automation__mdt WHERE Record_Type__c = 'ACIC_Request' LIMIT 1];


    }
    
    /*
     * Author: Seth Heang
     * Description: This Method is Used to test that a 'ACIC Request' case is auto-created when the proposal stage reach 'Accepted' status
     * Parameter: N/A
     * Return : Void             
     */ 
    private static TestMethod void APT_ApttusImplWorkforceVerficationAutoCaseCreationPositive() {
        
        //Query proposal 
        Apttus_Proposal__Proposal__c proposal = [SELECT Id from Apttus_Proposal__Proposal__c LIMIT 1];
        
        //Query product and assign the product type to Workforce Verification
        Product2 workforce_prod = [SELECT id from Product2 LIMIT 1];
        workforce_prod.APT_Product_type__c = 'Workforce Verification';
        update workforce_prod;

        //Query Proposal line item and assign the newly updated 'Workforce Verification' type product
        Apttus_Proposal__Proposal_Line_Item__c propsal_li = [SELECT id from Apttus_Proposal__Proposal_Line_Item__c LIMIT 1];
        propsal_li.Apttus_Proposal__Product__c = workforce_prod.Id;
        update propsal_li;

        Test.startTest();
        // Update proposal stage to 'Accepted'
        proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
        update proposal;
        Test.stopTest();

        // Query the Record type name for ACIC Request and obtain the Id
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Id ACIC_ReqRecordTypeID =  caseRecTypeMap.get('ACIC Request').getRecordTypeId();

        // Query Case and filter the record type Id to be from ACIC Request case
        List<Case> newCase = [SELECT id,APT_Approved_Entities__c, Proposal__c,APT_Approved_ABN__c,Subject  FROM CASE WHERE RecordTypeId =: ACIC_ReqRecordTypeID];
        // Query Account data for assertion
        Account acc = [SELECT id, Name, ABN__c FROM Account WHERE ABN__c = '12345678912' LIMIT 1];
        
        // Case should not be null
        System.assertEquals(1, newCase.size());
        // Case's proposal id and the proposal should match
        System.assertEquals(proposal.Id, newCase[0].Proposal__c, 'APT_ApttusImplWorkforceVerficationAutoCaseCreationPositive: Case proposal Id does not match the tested proposal');
        // Case's approved entities should match proposal's parent account name
        System.assertEquals(acc.Name, newCase[0].APT_Approved_Entities__c, 'APT_ApttusImplWorkforceVerficationAutoCaseCreationPositive: Case Approved Entities and Account name does not match');
        // Case's approved ABN should match proposal's parent account ABN
        System.assertEquals(acc.ABN__c, newCase[0].APT_Approved_ABN__c, 'APT_ApttusImplWorkforceVerficationAutoCaseCreationPositive: Case ABN and Proposal ABN does not match ');
        // Case's subject should start with 'ACIC Case:'
        System.assertEquals('ACIC Case: ' + acc.Name, newCase[0].Subject, 'APT_ApttusImplWorkforceVerficationAutoCaseCreationPositive: Case Subject should start with \'ACIC Case: \'');
    }
    
    /*
     * Author: Seth Heang
     * Description: This Method is Used to test that No 'ACIC Request' case is created when the proposal stage reach 'Accepted' status
     * Parameter: N/A
     * Return : Void             
     */ 
    private static TestMethod void APT_ApttusImplWorkforceVerficationAutoCaseCreationNegative() {
        //Query proposal 
        Apttus_Proposal__Proposal__c proposal = [SELECT Id from Apttus_Proposal__Proposal__c LIMIT 1];
        
        //Query product and assign the product type to StarTrack
        Product2 workforce_prod = [SELECT id from Product2 LIMIT 1];
        workforce_prod.APT_Product_type__c = 'StarTrack';
        update workforce_prod;

        //Query Proposal line item and assign the newly updated 'StarTrack' type product
        Apttus_Proposal__Proposal_Line_Item__c propsal_li = [SELECT id from Apttus_Proposal__Proposal_Line_Item__c LIMIT 1];
        propsal_li.Apttus_Proposal__Product__c = workforce_prod.Id;
        update propsal_li;

        Test.startTest();
        //Update proposal stage to 'Accepted'
        proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
        update proposal;
        Test.stopTest();

        // Query the Record type name for ACIC Request and obtain the Id
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Id ACIC_ReqRecordTypeID =  caseRecTypeMap.get('ACIC Request').getRecordTypeId();

        // Query Case and filter the record type Id to be from ACIC Request case
        List<Case> newCase = [SELECT id,APT_Approved_Entities__c, Proposal__c,APT_Approved_ABN__c,Subject  FROM CASE WHERE RecordTypeId =: ACIC_ReqRecordTypeID];
        // Query Account data for assertion
        Account acc = [SELECT id, Name, ABN__c FROM Account WHERE ABN__c = '12345678912' LIMIT 1];

        // Case should be null as the trigger does not fire
        System.assertEquals(0, newCase.size(), 'APT_ApttusImplWorkforceVerficationAutoCaseCreationNegative: Case should be null');
    }
}