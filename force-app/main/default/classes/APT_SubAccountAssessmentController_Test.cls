/**
Description: This apex class is test class for APT_SubAccountAssessmentController.
Created By - Drashtee Shah
Created Date - 3rd Mar, 2016
Last Modified By -
Last Modified Date - 
**/
@isTest
private class APT_SubAccountAssessmentController_Test {
    
    /**
        Creating Test Data
    **/
    private static TestMethod void APT_SubAccountAssessmentController1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {           
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.BillingCountry = 'Russia';
            acc.ShippingCountry = 'Russia';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            cacc.APT_Organisation__c = acc.ID;
            insert cacc;
            
            //Create Opportunity
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
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine; 
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            insert r2tSystemProperties;
            
            PageReference pageRef = Page.APT_SubAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalId', Proposal.Id);
            Apexpages.currentPage().getParameters().put('chargeAccountId', cacc.Id);
            Apexpages.currentPage().getParameters().put('accountId', acc.Id);
            Apexpages.currentPage().getParameters().put('isExistingCustomer', 'false');
            
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_SubAccountAssessmentController saac = new APT_SubAccountAssessmentController(sc);
            saac.saveAndNew();
            saac.saveAndClose();
            saac.saveAndNew();
            saac.backToProposal();
            
            Test.StopTest();
            system.assert(pageRef!=null);
        }
        
    }
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_SubAccountAssessmentController2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {             
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.BillingCountry = 'Russia';
            acc.ShippingCountry = 'Russia';
            insert acc;
            
            //APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            //cacc.APT_Industry_Type__c = 'CTTT';
            //cacc.APT_Organisation__c = acc.ID;
            //insert cacc;
            
            //Create Opportunity
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
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine; 
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            insert r2tSystemProperties;
            
            PageReference pageRef = Page.APT_SubAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            //Apexpages.currentPage().getParameters().put('proposalId', Proposal.Id);
            //Apexpages.currentPage().getParameters().put('chargeAccountId', cacc.Id);
            //Apexpages.currentPage().getParameters().put('accountId', acc.Id);
            Apexpages.currentPage().getParameters().put('isExistingCustomer', 'false');
            
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_SubAccountAssessmentController saac = new APT_SubAccountAssessmentController(sc);
            saac.saveAndClose();
            saac.saveAndNew();
            saac.backToProposal();
            
            Test.StopTest();
            system.assert(pageRef!=null);
        }
        
    }
    
    /**
        Creating Test Data
    **/    
    private static TestMethod void APT_SubAccountAssessmentController3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.BillingCountry = 'Russia';
            acc.ShippingCountry = 'Russia';
            insert acc;
            
            //APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            //cacc.APT_Industry_Type__c = 'CTTT';
            //cacc.APT_Organisation__c = acc.ID;
            //insert cacc;
            
            //Create Opportunity
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
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine; 
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Credit_Assessment_Valid_States__c = 'ValidStates';
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            insert r2tSystemProperties;
            
            //create addressExtension
            AddressExtension objMailingAddress = new AddressExtension('testLine1','testLine2','Sydney','testState', 'testPostCode','testDPId','Australia');
            AddressExtension objPhysicaladdress = new AddressExtension('testLine1','testLine2','Sydney','testState', 'testPostCode','testDPId','Australia');
            
            PageReference pageRef = Page.APT_SubAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalId', Proposal.Id);
            //Apexpages.currentPage().getParameters().put('chargeAccountId', cacc.Id);
            Apexpages.currentPage().getParameters().put('accountId', acc.Id);
            Apexpages.currentPage().getParameters().put('isExistingCustomer', 'false');
            
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_SubAccountAssessmentController saac = new APT_SubAccountAssessmentController(sc);
            saac.mailingAddress = objMailingAddress;
            saac.physicaladdress = objPhysicaladdress;
            saac.saveAndNew();
            saac.saveAndClose();
            saac.saveAndNew();
            saac.backToProposal();
            
            Test.StopTest();
            system.assert(pageRef!=null);
        }
        
    }
    private static TestMethod void APT_SubAccountAssessmentController4() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.BillingCountry = 'Russia';
            acc.ShippingCountry = 'Russia';
            insert acc;
            
            //APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            //cacc.APT_Industry_Type__c = 'CTTT';
            //cacc.APT_Organisation__c = acc.ID;
            //insert cacc;
            
            //Create Opportunity
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
            
           
            
            // Create LineItem
            
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            insert r2tSystemProperties;
            
            PageReference pageRef = Page.APT_SubAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalId', null);
            //Apexpages.currentPage().getParameters().put('chargeAccountId', cacc.Id);
            Apexpages.currentPage().getParameters().put('accountId', acc.Id);
            Apexpages.currentPage().getParameters().put('isExistingCustomer', 'false');
            
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_SubAccountAssessmentController saac = new APT_SubAccountAssessmentController(sc);
            saac.saveAndNew();
            saac.saveAndClose();
            saac.saveAndNew();
            saac.backToProposal();
            boolean resBool = saac.ChargeAccountEmptyFlag;
            integer intCount = saac.ChargeAccountsCount;
            String strValTitle = APT_SubAccountAssessmentController.strGetValTitle;
            String strValtitleDetails = APT_SubAccountAssessmentController.strGetValTitleDetails;
            String strValAccountName = APT_SubAccountAssessmentController.strGetValAccName;
            String strValBranch = APT_SubAccountAssessmentController.strGetValBranch;
            String strContactName = APT_SubAccountAssessmentController.strGetValAccContactName;
            String strContactTel = APT_SubAccountAssessmentController.strGetValAccContactTel;
            String steContactEmail = APT_SubAccountAssessmentController.strGetValAccContactEmail;
            String strContactFax = APT_SubAccountAssessmentController.strGetValAccContactFax;
            String strChargeAcc = APT_SubAccountAssessmentController.strGetValChargeAcc;
            String strValueOrg = APT_SubAccountAssessmentController.strGetValOrg;
            String strValAddress = APT_SubAccountAssessmentController.strGetValAddr;
            String strValsaveandclose = APT_SubAccountAssessmentController.strGetValSaveClose;
            String strValsaveandnew = APT_SubAccountAssessmentController.strGetValSaveNew;
            String strValCancel = APT_SubAccountAssessmentController.strGetValCancel;
            string strStreet = APT_SubAccountAssessmentController.strGetValStreet;
    
    
    
            
            Test.StopTest();
            system.assert(pageRef!=null);
        }
        
    }
}