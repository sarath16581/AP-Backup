/**
 * This apex class is test class for APT_AmendmentRenewalAgreementController
*/
/*********************************
 * @Modified by: Aditya Shetty
 * @Modified On: 18/03/2020
 * @Description: Changes to redirect to details page of Agreement instead of Edit
 * ********************************/
@isTest
private class APT_AmendmentRenwalAgrmntController_Test{

    private static testMethod void testingData(){ 
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
           // System.runAs(testuser) {
 
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,'Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
                /*Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName(); 
                String recordTypeId = recordTypeInfo.get('Amendment Quote').getRecordTypeId();*/
                quote.recordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                
                 
                Test.startTest();
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                amndrenewlagrmntCntrlr.doAmendRenew();
                
                config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
                update config;
                
                amndrenewlagrmntCntrlr.doAmendRenew();
                aptContract.Apttus__Agreement_Number__c = 'APT-012';
                update aptContract;
                
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();   
                
                
                test.stopTest();
                //system.assert(pgRef != null);
            } 
    private static testMethod void testingData0(){
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        //System.runAs(testuser) {   
            Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
 				/*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposalContact(tempacct.id,opp.Id,con.Id,APT_Constants.RECORD_TYPE_RENEWAL_QUOTE,'Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
               /* Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName(); 
                String recordTypeId = recordTypeInfo.get('Amendment Quote').getRecordTypeId();*/
                quote.recordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE).getRecordTypeId();
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                
                
                Test.startTest();
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_RENEWAL_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                amndrenewlagrmntCntrlr.doAmendRenew();
                
                config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
                update config;
                
                amndrenewlagrmntCntrlr.doAmendRenew();
                aptContract.Apttus__Agreement_Number__c = 'APT-012';
                update aptContract;
                
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();   
                
                
                test.stopTest();
                //system.assert(pgRef != null);
       }     
    private static testMethod void testingDataWithoutUpdate1(){
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
           // System.runAs(testuser) {
                  
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
        		 /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED,Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Agreement_Number__c = '012';
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
                String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
                
                test.startTest();
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_RENEWAL_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();
                
                
                test.stopTest();
                //system.assert(pgRef != null);
         // }
       
    }
    private static testMethod void testingDataWithoutUpdate2(){
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
           // System.runAs(testuser) {
                    
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
                 /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED,Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Agreement_Number__c = '012';
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
                String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
                
                test.startTest();
                
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();
                
                
                test.stopTest();
                //system.assert(pgRef != null);
           // }      
    }
    private static testMethod void testingData2(){
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
           // System.runAs(testuser) {
                       
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
                 /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
                insert quote;
        
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
                String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
                
                test.startTest();
                
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                amndrenewlagrmntCntrlr.doAmendRenew();
                config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
                update config;
                amndrenewlagrmntCntrlr.doAmendRenew();
                aptContract.Apttus__Agreement_Number__c = 'APT-012';
                update aptContract;
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();
                
        
                test.stopTest();
                //system.assert(pgRef != null);
       // }
       
    }
    private static testMethod void testingData3(){
        Contact con = APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
         /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
        Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
        insert priceList;
        Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        quote.APT_Contract_Number__c='APT-012.123';
        insert quote;
        Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                        Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
        
        insert config;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.Apttus__Related_Opportunity__c =opp.id;
        aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
        aptContract.Apttus__Version_Number__c=123.0;
        insert aptContract;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
        Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
        String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
        test.startTest();
        ApexPages.currentPage().getParameters().put('id',quote.ID);
        ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
        APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
        //amndrenewlagrmntCntrlr.doAmendRenew();
        //config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
        //update config;
        amndrenewlagrmntCntrlr.doAmendRenew();
        aptContract.Apttus__Agreement_Number__c = 'APT-012';
        update aptContract;
        amndrenewlagrmntCntrlr.doAmendRenew();
        test.stopTest();
    } 
    private static testMethod void testingData4(){
        Contact con = APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
        Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
        insert priceList;
        Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        quote.APT_Contract_Number__c='APT-012.123';
        insert quote;
       // Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
          //                                              Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
        
       // insert config;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.Apttus__Related_Opportunity__c =opp.id;
        aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
        aptContract.Apttus__Version_Number__c=123.0;
        insert aptContract;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
        Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
        String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
        test.startTest();
        ApexPages.currentPage().getParameters().put('id',quote.id);
        ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
        APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
        amndrenewlagrmntCntrlr.doAmendRenew();
        //config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
        //update config;
        //amndrenewlagrmntCntrlr.doAmendRenew();
        aptContract.Apttus__Agreement_Number__c = 'APT-012';
        update aptContract;
        amndrenewlagrmntCntrlr.doAmendRenew();
        test.stopTest();
    }
    private static testMethod void testingData5(){
        Contact con = APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
         /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
        Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
        insert priceList;
        Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        quote.APT_Contract_Number__c='APT-012.123';
        insert quote;
       // Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
        //                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
        
       // insert config;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.Apttus__Related_Opportunity__c =opp.id;
        aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
        aptContract.Apttus__Version_Number__c=123.0;
        insert aptContract;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
        Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
        String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
        test.startTest();
        ApexPages.currentPage().getParameters().put('id',quote.id);
        ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_RENEWAL_QUOTE);
        APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
        //amndrenewlagrmntCntrlr.doAmendRenew();
        //config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
        //update config;
        amndrenewlagrmntCntrlr.doAmendRenew();
        aptContract.Apttus__Agreement_Number__c = 'APT-012';
        update aptContract;
        amndrenewlagrmntCntrlr.doAmendRenew();
        test.stopTest();
    } 
    private static testMethod void testingData1(){
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
            //System.runAs(testuser) {
                   
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
                 /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
        
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
                //quote.APT_Contract_Number__c='APT-012.123';
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                test.startTest();
                
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName();
                String recordTypeId = recordTypeInfo.get('Renewal Quote').getRecordTypeId();
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_RENEWAL_QUOTE);
                
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                amndrenewlagrmntCntrlr.doAmendRenew();
                
                config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
                update config;
                
                amndrenewlagrmntCntrlr.doAmendRenew();
                
                aptContract.Apttus__Agreement_Number__c = 'APT-012';
                update aptContract;
                
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();
                
                
                test.stopTest();
                //system.assert(pgRef == null);
          }
    private static testMethod void testingData6(){ 
            // Setup test data
            // This code runs as the system admin test user
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
            User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
            EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
            LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
            TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
            UserName=APT_Constants.EMAIL_TEST_USER);
           // System.runAs(testuser) {
 
                Contact con = APT_TestUtils.createContact();
                insert con;
                
                Account tempacct = APT_TestUtils.createOrganisation();
                insert tempacct;
                
                /*Start:Aditya Shetty Changes to skip validations */
                Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
                insert opp;
                 /*End:Aditya Shetty Changes to skip validations */
                
                Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
                insert priceList;
                
                Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,'Test',priceList.id);
                quote.APT_Contract_Number__c='APT-012.123';
                /*Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                DescribeSObjectResult result = gd.get('Apttus_Proposal__Proposal__c').getDescribe();
                Map<String,Schema.RecordTypeInfo>recordTypeInfo = result.getRecordTypeInfosByName(); 
                String recordTypeId = recordTypeInfo.get('Amendment Quote').getRecordTypeId();*/
                quote.recordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
                insert quote;
                
                Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =quote.Id,Apttus_QPConfig__Proposald__c =quote.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c ='Completed',Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
                
                insert config;
                
                Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
                aptContract.Apttus__Related_Opportunity__c =opp.id;
                aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
                aptContract.Apttus__Version_Number__c=123.0;
                insert aptContract;
                
                
                
                Test.startTest();
                ApexPages.currentPage().getParameters().put('id',quote.Id);
                ApexPages.currentPage().getParameters().put('recordType',APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE);
                APT_AmendmentRenewalAgreementController  amndrenewlagrmntCntrlr = new APT_AmendmentRenewalAgreementController ();
                amndrenewlagrmntCntrlr.doAmendRenew();
                
                config.Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED;
                update config;
                
                amndrenewlagrmntCntrlr.doAmendRenew();
                aptContract.Apttus__Agreement_Number__c = 'APT-012';
                update aptContract;
                FeedItem feed = new FeedItem (ParentId = aptContract.id, Body = 'Hello');
                insert feed;

                
                PageReference pgRef = amndrenewlagrmntCntrlr.doAmendRenew();   
                
                
        		APT_AmendmentRenewalAgreementController.getAgreementReturnURL(string.valueOf(aptContract.Id));
        
        		amndrenewlagrmntCntrlr.testRollBack = true;
        		amndrenewlagrmntCntrlr.doAmendRenew();
        		
                test.stopTest();
                //system.assert(pgRef != null);
            } 
    
}