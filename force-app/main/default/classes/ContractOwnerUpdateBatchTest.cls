/**************************************************
Decription: Test class for ContractOwnerUpdateBatch
History:    22/11/2017  adrian.recio@auspost.com.au     Intial test class version

**************************************************/

@IsTest
public class ContractOwnerUpdateBatchTest {
    public static testMethod void ContractOwnerUpdateBatchTest1(){

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // Insert account as current user
        System.runAs (thisUser) {
            // Create test user
            User testUser = new User();
            testUser.UserRoleId = [Select Id From UserRole where DeveloperName='Holding_Sales_Team'].Id;
            testUser.ProfileId = [Select Id From Profile where Name='Standard User'].Id;
            testUser.Alias = APT_Constants.ALIAS_TEST_USER; 
            testUser.Email = APT_Constants.EMAIL_TEST_USER;
            testUser.EmailEncodingKey = APT_Constants.EMAILENCODINGKEY_TEST_USER; 
            testUser.LastName = APT_Constants.LASTNAME_TEST_USER; 
            testUser.LanguageLocaleKey = APT_Constants.LANGUAGELOCALEKEY_TEST_USER;
            testUser.LocaleSidKey = APT_Constants.LOCALESIDKEY_TEST_USER; 
            testUser.TimeZoneSidKey = APT_Constants.TIMEZONESIDKEY_TEST_USER;
            testUser.UserName = APT_Constants.EMAIL_TEST_USER;
            insert testUser;
            
            // Create test contact
            List<Contact>conList = new List<Contact>();
            Contact conVar = APT_TestUtils.createContact();
            conList.add(conVar);
            Contact conVar2 = APT_TestUtils.createContact();
            conList.add(conVar2);
            Contact conVar3 = APT_TestUtils.createContact();
            conList.add(conVar3);
            insert conList;
            
            // Create test account
            List<Account>accList = new List<Account>();
            Account accVar = APT_TestUtils.createOrganisation();
            accList.add(accVar);
            Account accVar2 = APT_TestUtils.createOrganisation();
            accList.add(accVar2);
            Account accVar3 = APT_TestUtils.createOrganisation();
            accList.add(accVar3);
            insert accList;
            
            // Reassign ownership and remove default holding user assignment in account
            accVar.OwnerId = UserInfo.getUserId();
            accVar2.OwnerId = testUser.Id;
            accVar3.OwnerId = UserInfo.getUserId();
            update accList;
                        
            // Create test opportunity
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity oppVar = APT_TestUtils.createOpportunity(accVar.id);
            oppList.add(oppVar);
            Opportunity oppVar2 = APT_TestUtils.createOpportunity(accVar2.id);
            oppList.add(oppVar2);
            Opportunity oppVar3 = APT_TestUtils.createOpportunity(accVar3.id);
            oppList.add(oppVar3);
            insert oppList;
            
            // Create test pricelist
            Apttus_Config2__PriceList__c  priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            // Create test R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
            r2tSystemProperties.APT_HoldingUserID__c = testUser.Id;
            r2tSystemProperties.CRMSupportUserEmail__c = 'testemail@testemail.com';
            r2tSystemProperties.BatchSize_ContractOwnUpdBatch__c = 200;
            insert r2tSystemProperties;
            
            // Pull proposal amendment recordtype Id
            Id proposalRecVar = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
            
            // Create test proposal
            List<Apttus_Proposal__Proposal__c> quoteList = new List<Apttus_Proposal__Proposal__c>();
            Apttus_Proposal__Proposal__c quoteVar = APT_TestUtils.getQuoteProposal(accVar.id,
                                                                                   oppVar.Id,
                                                                                   APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                                                                                   'Test',priceList.id);
            
            quoteVar.APT_Contract_Number__c = 'APT-012.100';
            quoteVar.recordTypeId = proposalRecVar;
            quoteList.add(quoteVar);
            
            Apttus_Proposal__Proposal__c quoteVar2 = APT_TestUtils.getQuoteProposal(accVar.id,
                                                                                   oppVar.Id,
                                                                                   APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                                                                                   'Test',priceList.id);
            quoteVar2.APT_Contract_Number__c = 'APT-012.101';
            quoteVar2.recordTypeId = proposalRecVar;
            quoteList.add(quoteVar2);
            
            Apttus_Proposal__Proposal__c quoteVar3 = APT_TestUtils.getQuoteProposal(accVar.id,
                                                                                   oppVar.Id,
                                                                                   APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                                                                                   'Test',priceList.id);
            quoteVar3.APT_Contract_Number__c = 'APT-012.102';
            quoteVar3.recordTypeId = proposalRecVar;
            quoteList.add(quoteVar3);

            insert quoteList;
            
            // Create test product configuration
            List<Apttus_Config2__ProductConfiguration__c> prodConList = new List<Apttus_Config2__ProductConfiguration__c>();
            Apttus_Config2__ProductConfiguration__c  configVar = new Apttus_Config2__ProductConfiguration__c  ();
            configVar.Name = 'Test1';
            configVar.Apttus_Config2__VersionNumber__c = 1;
            configVar.Apttus_Config2__BusinessObjectId__c = quoteVar.Id;
            configVar.Apttus_QPConfig__Proposald__c = quoteVar.Id;
            configVar.Apttus_Config2__SummaryGroupType__c = 'Test1';
            configVar.Apttus_Config2__BusinessObjectType__c = 'Test1';
            configVar.Apttus_Config2__PriceListId__c = priceList.Id;
            configVar.Apttus_Config2__Status__c = 'Completed';
            configVar.Apttus_Config2__FinalizedDate__c = System.Today();
            configVar.Apttus_Config2__EffectiveDate__c = System.Today();
            configVar.Apttus_Config2__IsTransient__c = true;
            prodConList.add(configVar);
            
            Apttus_Config2__ProductConfiguration__c  configVar2 = new Apttus_Config2__ProductConfiguration__c  ();
            configVar2.Name = 'Test2';
            configVar2.Apttus_Config2__VersionNumber__c = 1;
            configVar2.Apttus_Config2__BusinessObjectId__c = quoteVar2.Id;
            configVar2.Apttus_QPConfig__Proposald__c = quoteVar2.Id;
            configVar2.Apttus_Config2__SummaryGroupType__c = 'Test2';
            configVar2.Apttus_Config2__BusinessObjectType__c = 'Test2';
            configVar2.Apttus_Config2__PriceListId__c = priceList.Id;
            configVar2.Apttus_Config2__Status__c = 'Completed';
            configVar2.Apttus_Config2__FinalizedDate__c = System.Today();
            configVar2.Apttus_Config2__EffectiveDate__c = System.Today();
            configVar2.Apttus_Config2__IsTransient__c = true;
            prodConList.add(configVar2);
            
            Apttus_Config2__ProductConfiguration__c  configVar3 = new Apttus_Config2__ProductConfiguration__c  ();
            configVar3.Name = 'Test3';
            configVar3.Apttus_Config2__VersionNumber__c = 1;
            configVar3.Apttus_Config2__BusinessObjectId__c = quoteVar3.Id;
            configVar3.Apttus_QPConfig__Proposald__c = quoteVar3.Id;
            configVar3.Apttus_Config2__SummaryGroupType__c = 'Test3';
            configVar3.Apttus_Config2__BusinessObjectType__c = 'Test3';
            configVar3.Apttus_Config2__PriceListId__c = priceList.Id;
            configVar3.Apttus_Config2__Status__c = 'Completed';
            configVar3.Apttus_Config2__FinalizedDate__c = System.Today();
            configVar3.Apttus_Config2__EffectiveDate__c = System.Today();
            configVar3.Apttus_Config2__IsTransient__c = true;
            prodConList.add(configVar3);
            
            // Createst test agreement
            List<Apttus__APTS_Agreement__c> agList = new List<Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(conVar.Id);
            aptContract.Apttus__Status_Category__c = 'In Effect';
            aptContract.Apttus__Status__c = 'Activated';
            aptContract.Apttus__Account__c = accVar.Id;
            aptContract.Apttus__Related_Opportunity__c = oppVar.id;
            aptContract.Apttus_QPComply__RelatedProposalId__c = quoteVar.id;
            aptContract.Apttus__Version_Number__c = 123.0;
            aptContract.OwnerId = testUser.Id;
            agList.add(aptContract);
            
            Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(conVar2.Id);
            aptContract2.Apttus__Status_Category__c = 'In Effect';
            aptContract2.Apttus__Status__c = 'Activated';
            aptContract2.Apttus__Account__c = null; //accVar2.Id;
            aptContract2.Apttus__Related_Opportunity__c = oppVar2.id;
            aptContract2.Apttus_QPComply__RelatedProposalId__c = quoteVar2.id;
            aptContract2.Apttus__Version_Number__c = 123.0;
            aptContract2.OwnerId = testUser.Id;
            agList.add(aptContract2);
            
            Apttus__APTS_Agreement__c aptContract3 = APT_TestUtils.createAgreement(conVar3.Id);
            aptContract3.Apttus__Status_Category__c = 'In Effect';
            aptContract3.Apttus__Status__c = 'Activated';
            aptContract3.Apttus__Account__c = null; //accVar3.Id;
            aptContract3.Apttus__Related_Opportunity__c = oppVar3.id;
            aptContract3.Apttus_QPComply__RelatedProposalId__c = quoteVar3.id;
            aptContract3.Apttus__Version_Number__c = 123.0;
            aptContract3.OwnerId = testUser.Id;
            agList.add(aptContract3);
            
            insert agList;
            
        }
        
        
        
        Test.startTest();
        
        	// We now call the batch class to be scheduled
            ContractOwnerUpdateBatch batchContractUpdate = new ContractOwnerUpdateBatch(); 
            
            // Parameters of ExecuteBatch(context,BatchSize)
            database.executebatch(batchContractUpdate);
        
        	ContractOwnerUpdateBatch_Schedule cowSchedClass = new ContractOwnerUpdateBatch_Schedule();      
            String sch = '0 0 23 * * ?'; // Test Sched cron
            system.schedule('Test check', sch, cowSchedClass);
        test.stopTest();
    }          
}