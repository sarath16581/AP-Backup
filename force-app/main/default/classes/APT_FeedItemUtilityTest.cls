@isTest
public class APT_FeedItemUtilityTest {

     static testmethod void testmethoddata() {
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        insert proposal;
        
         Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp.Id;
        appli.Account__c = tempacct.Id;
        insert appli;

        List<Apttus__APTS_Agreement__c> agList = new List<Apttus__APTS_Agreement__c>();

        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        aptContract.OwnerId = UserInfo.getUserId();
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'Request';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        agList.add(aptContract);
        
        Apttus__APTS_Agreement__c aptContractAmended = APT_TestUtils.createAgreement(con.Id);
        aptContractAmended.APT_Product__c= 'eParcel';
        //aptContractAmended.Apttus__Related_Opportunity__c=opp.Id;
        aptContractAmended.Apttus__Account__c=tempacct.Id;
        aptContractAmended.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContractAmended.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContractAmended.APT_New_Rate_Card_Download__c = true;
        aptContractAmended.OwnerId = UserInfo.getUserId();
        aptContractAmended.APMS_Application__c = appli.ID;
        aptContractAmended.Apttus__Status_Category__c = 'Amended';
        aptContractAmended.Apttus__Parent_Agreement__c = aptContract.ID;
        aptContractAmended.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        agList.add(aptContractAmended);
        insert agList;

        APT_R2T_System_Properties__c objSystemProperties = new APT_R2T_System_Properties__c();
        objSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'vishah@test.com';
        insert objSystemProperties;
        FeedItem post = TestUtility.createChatterPost('Test Post',aptContract.id);
         insert post;
         
        Test.startTest();
         
         APT_FeedItemUtility.copyFeedItems(aptContract.Id,aptContractAmended.Id);
         
         Test.stopTest();
        
        
        
        
		}
    
    
}