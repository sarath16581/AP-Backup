/* Created by: Adrian Recio
 * Description: Test class for APT_SAPContractValidationController class
 * Date: 26/07/2017
 */

@IsTest
public class APT_SAPContractValidationController_Test {
    public static testmethod void testSAPContractController(){
        // Create test records
        
        // Product
        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
        productList.add(product);
        
        Product2 product1 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        productList.add(product1);
        
        Product2 product2 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        productList.add(product2);
        
        Product2 product3 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        productList.add(product3);
        insert productList;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        // Pricelist Configuration
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;
        
        
        
        // Account
        List<Account> accList = new List<Account>();
        
        Account legacyacct = APT_TestUtils.createOrganisation();
        legacyacct.Legacy_Id__c = '60000000';
        accList.add(legacyacct);
            
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000'; 
        accList.add(tempacct);
        insert accList;

        legacyacct.Legacy_Id__c = '60000000';
        update legacyacct;

        // Contact
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        // Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        
        // Proposal
        List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal.APT_Contract_Number__c = '012345.1';
        proposalList.add(proposal);
        
        Apttus_Proposal__Proposal__c proposal2 = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal2.APT_Contract_Number__c = '012345.1';
        proposalList.add(proposal2);
        insert proposalList;
        
        //Create Application
        Application__c appli = new Application__c();
        appli.Opportunity__c = opp1.Id;
        appli.Account__c = tempacct.Id;
        insert appli;
        
        // Agreement
        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'In Effect';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract.Apttus__Agreement_Number__c = '012345';
        aptContract.Apttus__Version_Number__c = 1;
        aptContract.APT_Contract_Type__c = 'New Contract';
        aptContract.Is_Document_Signed__c =true;
        agreeList.add(aptContract);
        
        Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
        aptContract2.APT_Product__c= 'eParcel';
        aptContract2.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract2.Apttus__Account__c=tempacct.Id;
        aptContract2.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract2.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract2.APT_New_Rate_Card_Download__c = true;
        aptContract2.APMS_Application__c = appli.ID;
        aptContract2.Apttus__Status_Category__c = 'Request';
        aptContract2.Apttus__Status__c = 'Request';
        aptContract2.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract2.APT_Contract_Type__c = 'Renewal Contract';
        aptContract2.Is_Document_Signed__c =true;
        agreeList.add(aptContract2);
        
        Apttus__APTS_Agreement__c aptContract3 = APT_TestUtils.createAgreement(con.Id);
        aptContract3.APT_Product__c= 'eParcel';
        aptContract3.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract3.Apttus__Account__c=tempacct.Id;
        aptContract3.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract3.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract3.APT_New_Rate_Card_Download__c = true;
        aptContract3.APMS_Application__c = appli.ID;
        aptContract3.Apttus__Status_Category__c = 'Request';
        aptContract3.Apttus__Status__c = 'Request';
        aptContract3.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract3.APT_Contract_Type__c = 'New Contract';
        aptContract3.Is_Document_Signed__c =true;
        agreeList.add(aptContract3);
        
        Apttus__APTS_Agreement__c aptContract4 = APT_TestUtils.createAgreement(con.Id);
        aptContract4.APT_Product__c= 'eParcel';
        aptContract4.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract4.Apttus__Account__c=tempacct.Id;
        aptContract4.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract4.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract4.APT_New_Rate_Card_Download__c = true;
        aptContract4.APMS_Application__c = appli.ID;
        aptContract4.Apttus__Status_Category__c = 'Request';
        aptContract4.Apttus__Status__c = 'Request';
        aptContract4.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract4.APT_Contract_Type__c = 'Migrated Contract';
        aptContract4.Is_Document_Signed__c =true;
        agreeList.add(aptContract4);
        
        insert agreeList;
        
        List<Attachment> attchmntList = new List<Attachment>();
        Attachment atch = APT_TestUtils.createAttachment(agreeList[0].id);
        atch.body=blob.valueOf('Test');
        attchmntList.add(atch);
        Attachment atch1 = APT_TestUtils.createAttachment(agreeList[1].id);
        atch1.body=blob.valueOf('Test1');
        attchmntList.add(atch1);
        Attachment atch2 = APT_TestUtils.createAttachment(agreeList[2].id);
        atch2.body=blob.valueOf('Test2');
        attchmntList.add(atch2);
        Attachment atch3 = APT_TestUtils.createAttachment(agreeList[3].id);
        atch3.body=blob.valueOf('Test3');
        attchmntList.add(atch3);
        
        insert attchmntList;
        // Create SAP Contract 
        List<APT_SAP_Contracts__c>sConList = new List<APT_SAP_Contracts__c>();
        
        APT_SAP_Contracts__c sapConVar =  new APT_SAP_Contracts__c();
        sapConVar.APT_Apttus_Contract__c = aptContract.Id;
        sapConVar.APT_SAP_Contract_Number__c = '012345';
        sapConVar.SAP_Contract_Status__c = 'Active';
        sConList.add(sapConVar);
        
        APT_SAP_Contracts__c sapConVar2 =  new APT_SAP_Contracts__c();
        sapConVar2.APT_Apttus_Contract__c = aptContract3.Id;
        sapConVar2.APT_SAP_Contract_Number__c = '1234568';
        sapConVar2.SAP_Contract_Status__c = 'Active';
        sConList.add(sapConVar2);
        
        insert sConList;
        
        ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
        
        // Generate SAP Contract for original Agreement
        APT_ManageSAPContractController apManageSapCon = new APT_ManageSAPContractController();
        apManageSapCon.textAreaUserInput = '1234567';
        apManageSapCon.saveSAPContracts();     

        test.startTest();
        
            // Constructor Apttus Contract Query error handling
            ApexPages.currentPage().getParameters().put('Id','');
            APT_SAPContractValidationController sapCon = new APT_SAPContractValidationController(); 
        
            // New Contract
            ApexPages.currentPage().getParameters().put('Id',aptContract3.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // Migrated Contract
            ApexPages.currentPage().getParameters().put('Id',aptContract4.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // No Response message
            ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // No with Renewal Contract
            sapCon.replyVal = 'No';
            sapCon.executeSAPContractCheck();
        
            // Validate no response cloning
            List<APT_SAP_Contracts__c>sapConPresentList = [Select Id from APT_SAP_Contracts__c where APT_Apttus_Contract__c = :aptContract2.Id];
            //system.assertEquals(sapConPresentList.size(), 2); 
        	
        
            // Yes with Renewal Contract
            sapCon.replyVal = 'Yes';
            sapCon.executeSAPContractCheck();
        
            // Return to record detail page
            sapCon.returnContract();
        
            // Generate dummy old map
            Map<Id, Apttus__APTS_Agreement__c> dummOldAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c cloneOld = aptContract2.clone(true, true);
            cloneOld.Apttus__Status_Category__c = 'In Signature';
            dummOldAgreementMap.put(cloneOld.Id,cloneOld);
            
            List<Apttus__APTS_Agreement__c> dummyNewAgreementList = new List<Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c cloneNew = aptContract2.clone(true, true);
            cloneNew.Apttus__Status_Category__c = 'In Effect';
            dummyNewAgreementList.add(cloneNew);
            
            // Deactivate Old sap contracts when renewal contract is in effect
            APT_SAPContractValidationController.deactivateOldSapCon(dummyNewAgreementList,dummOldAgreementMap);
        test.stopTest();
    }
    
        public static testmethod void testSAPContractController2(){
        // Create test records
        
        // Product
        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
        productList.add(product);
        
        Product2 product1 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        productList.add(product1);
        
        Product2 product2 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        productList.add(product2);
        
        Product2 product3 = APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        productList.add(product3);
        insert productList;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        // Pricelist Configuration
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;
        
        
        
        // Account
        List<Account> accList = new List<Account>();
        
        Account legacyacct = APT_TestUtils.createOrganisation();
        legacyacct.Legacy_Id__c = '60000000';
        accList.add(legacyacct);
            
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000'; 
        accList.add(tempacct);
        insert accList;

        legacyacct.Legacy_Id__c = '60000000';
        update legacyacct;

        // Contact
        Contact con= APT_TestUtils.createContact();
        insert con;
        
        // Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        
        // Proposal
        List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal.APT_Contract_Number__c = '012345.1';
        proposalList.add(proposal);
        
        Apttus_Proposal__Proposal__c proposal2 = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal2.APT_Contract_Number__c = '012345.1';
        proposalList.add(proposal2);
        insert proposalList;
        
        //Create Application
        Application__c appli = new Application__c();
        appli.Opportunity__c = opp1.Id;
        appli.Account__c = tempacct.Id;
        insert appli;
        
        // Agreement
        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'In Effect';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract.Apttus__Agreement_Number__c = '012345';
        aptContract.Apttus__Version_Number__c = 1;
        aptContract.APT_Contract_Type__c = 'New Contract';
        aptContract.Is_Document_Signed__c =true;
        agreeList.add(aptContract);
        
        Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
        aptContract2.APT_Product__c= 'eParcel';
        aptContract2.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract2.Apttus__Account__c=tempacct.Id;
        aptContract2.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract2.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract2.APT_New_Rate_Card_Download__c = true;
        aptContract2.APMS_Application__c = appli.ID;
        aptContract2.Apttus__Status_Category__c = 'Request';
        aptContract2.Apttus__Status__c = 'Request';
        aptContract2.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract2.APT_Contract_Type__c = 'Renewal Contract';
        aptContract2.Is_Document_Signed__c =true;
        agreeList.add(aptContract2);
        
        Apttus__APTS_Agreement__c aptContract3 = APT_TestUtils.createAgreement(con.Id);
        aptContract3.APT_Product__c= 'eParcel';
        aptContract3.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract3.Apttus__Account__c=tempacct.Id;
        aptContract3.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract3.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract3.APT_New_Rate_Card_Download__c = true;
        aptContract3.APMS_Application__c = appli.ID;
        aptContract3.Apttus__Status_Category__c = 'Request';
        aptContract3.Apttus__Status__c = 'Request';
        aptContract3.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract3.APT_Contract_Type__c = 'New Contract';
        aptContract3.Is_Document_Signed__c =true;
        agreeList.add(aptContract3);
        
        Apttus__APTS_Agreement__c aptContract4 = APT_TestUtils.createAgreement(con.Id);
        aptContract4.APT_Product__c= 'eParcel';
        aptContract4.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract4.Apttus__Account__c=tempacct.Id;
        aptContract4.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract4.Apttus_QPComply__RelatedProposalId__c = proposal2.ID;
        aptContract4.APT_New_Rate_Card_Download__c = true;
        aptContract4.APMS_Application__c = appli.ID;
        aptContract4.Apttus__Status_Category__c = 'Request';
        aptContract4.Apttus__Status__c = 'Request';
        aptContract4.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract4.APT_Contract_Type__c = 'Migrated Contract';
        aptContract4.Is_Document_Signed__c =true;
        agreeList.add(aptContract4);
        
        insert agreeList;
        
        /*List<Attachment> attchmntList = new List<Attachment>();
        Attachment atch = APT_TestUtils.createAttachment(agreeList[0].id);
        atch.body=blob.valueOf('Test');
        attchmntList.add(atch);
        Attachment atch1 = APT_TestUtils.createAttachment(agreeList[1].id);
        atch1.body=blob.valueOf('Test1');
        attchmntList.add(atch1);
        Attachment atch2 = APT_TestUtils.createAttachment(agreeList[2].id);
        atch2.body=blob.valueOf('Test2');
        attchmntList.add(atch2);
        Attachment atch3 = APT_TestUtils.createAttachment(agreeList[3].id);
        atch3.body=blob.valueOf('Test3');
        attchmntList.add(atch3);
        
        insert attchmntList;*/
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = aptContract4.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
            

        test.startTest();

        // Create SAP Contract 
        List<APT_SAP_Contracts__c>sConList = new List<APT_SAP_Contracts__c>();
        
        APT_SAP_Contracts__c sapConVar =  new APT_SAP_Contracts__c();
        sapConVar.APT_Apttus_Contract__c = aptContract.Id;
        sapConVar.APT_SAP_Contract_Number__c = '012345';
        sapConVar.SAP_Contract_Status__c = 'Active';
        sConList.add(sapConVar);
        
        APT_SAP_Contracts__c sapConVar2 =  new APT_SAP_Contracts__c();
        sapConVar2.APT_Apttus_Contract__c = aptContract3.Id;
        sapConVar2.APT_SAP_Contract_Number__c = '1234568';
        sapConVar2.SAP_Contract_Status__c = 'Active';
        sConList.add(sapConVar2);
        
        insert sConList;
        
        ApexPages.currentPage().getParameters().put('Id',aptContract.Id);
        
        // Generate SAP Contract for original Agreement
        APT_ManageSAPContractController apManageSapCon = new APT_ManageSAPContractController();
        apManageSapCon.textAreaUserInput = '1234567';
        apManageSapCon.saveSAPContracts(); 

        
            // Constructor Apttus Contract Query error handling
            ApexPages.currentPage().getParameters().put('Id','');
            APT_SAPContractValidationController sapCon = new APT_SAPContractValidationController(); 
        
            // New Contract
            ApexPages.currentPage().getParameters().put('Id',aptContract3.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // Migrated Contract
            ApexPages.currentPage().getParameters().put('Id',aptContract4.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // No Response message
            ApexPages.currentPage().getParameters().put('Id',aptContract2.Id);
            sapCon = new APT_SAPContractValidationController();
            sapCon.executeSAPContractCheck();
        
            // No with Renewal Contract
            sapCon.replyVal = 'No';
            sapCon.executeSAPContractCheck();
        
            // Validate no response cloning
            List<APT_SAP_Contracts__c>sapConPresentList = [Select Id from APT_SAP_Contracts__c where APT_Apttus_Contract__c = :aptContract2.Id];
            //system.assertEquals(sapConPresentList.size(), 2); 
        
            // Yes with Renewal Contract
            sapCon.replyVal = 'Yes';
            sapCon.executeSAPContractCheck();
        
            // Return to record detail page
            sapCon.returnContract();
        
            // Generate dummy old map
            Map<Id, Apttus__APTS_Agreement__c> dummOldAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c cloneOld = aptContract2.clone(true, true);
            cloneOld.Apttus__Status_Category__c = 'In Signature';
            dummOldAgreementMap.put(cloneOld.Id,cloneOld);
            
            List<Apttus__APTS_Agreement__c> dummyNewAgreementList = new List<Apttus__APTS_Agreement__c>();
            Apttus__APTS_Agreement__c cloneNew = aptContract2.clone(true, true);
            cloneNew.Apttus__Status_Category__c = 'In Effect';
            dummyNewAgreementList.add(cloneNew);
            
            // Deactivate Old sap contracts when renewal contract is in effect
            APT_SAPContractValidationController.deactivateOldSapCon(dummyNewAgreementList,dummOldAgreementMap);
        test.stopTest();
    }
}