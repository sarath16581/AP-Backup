/***
 * @author Aakash Khatri
 * @date 2016-04-15
 * @group 
 * @description This class is test class for APT_ProposalApprovalsComponentCntrl.
 * @changelog
 * 2016-04-16 - Aakash Khatri- Created
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
*/
 
@isTest
private class APT_ProposalApprovalsComponentCntrl_Test {
    /**
        Creating Test data
    **/
    private static testmethod void TestMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) { 
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            //Applying the following change as key contact have look up filter introduced on Opportunity on Opportunity(CI-194).  
            Contact con= APT_TestUtils.createContact();
            con.Email = 'temp@temp.com';
            con.AccountId = tempacct.Id;
            insert con;            
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
            bundle1.APT_Sync_with_Opportunity__c=true;
            bundle1.APT_Is_Charge_Account_Product__c = true;
            bundle1.APT_Is_Cash_Account_Product__c = false;
            bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
            insert bundle1;
                 
            //Create Option product
            Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
            option.Apttus_Config2__ConfigurationType__c='Option';
            option.APT_Sync_with_Opportunity__c=true;
            option.APT_International_Pricing__c = false;
            option.APT_Consolidated_Usage_Price_Tiers__c = true;
            insert option;
                 
            //Create PriceBookEntry
            Id pricebookId = Test.getStandardPricebookId();             
            PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
            insert standardPrice;
                 
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
                 
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
            //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
            Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
            Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
            Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
            insert Proposal;
            
            Apttus_Config2__ConfigSystemProperties__c configSystemProperties = new Apttus_Config2__ConfigSystemProperties__c();
            configSystemProperties.Name = 'System Properties';
            configSystemProperties.Apttus_Config2__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
            insert configSystemProperties;
            
            Test.StartTest();
            
            APT_ProposalApprovalsComponentController pacc = new APT_ProposalApprovalsComponentController();
            pacc.proposalSOId = Proposal.ID;
            pacc.proposalSO = Proposal;
            pacc.getProposal();
            pacc.getCartURL();
            
            APT_ProposalApprovalsComponentController pacc2 = new APT_ProposalApprovalsComponentController();
            pacc2.getProposal();
            Test.StopTest();
            system.assert(Proposal!=null);
        }
    }
    
}