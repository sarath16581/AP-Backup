/***
 * @author Mausam Padhiyar
 * @date 2015-12-14
 * @group 
 * @description Test class for APT_CashAccountAssessmentController controller.
 * @changelog
 * 2015-12-14 - Mausam Padhiyar- Created
 * 2021-11-17 - Mathew Jose - Fixing the test class failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * Last Modified By -madhuri.awasthi@auspost.com.au REQ2723568: Text Class changes
 * Last Modified Date -11th Feb 2022 
 * 2022-02-11  REQ2723568: API version 52 upgrade
*/
@isTest
private class APT_CashAccountAssessmentController_Test{
    //Creating test data
    private static testMethod void testMethod1() {
       // Boolean showCompanyBusiness;
       // Boolean showSoleTrader;
       // APT_ABRreport__c selectedABRReport = new APT_ABRreport__c();
       // APT_ASIC_Report__c selectedASICReport = new APT_ASIC_Report__c();
       // Boolean displayPopUp;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            APT_R2T_System_Properties__c r2tSystemProperty = new APT_R2T_System_Properties__c();
            
            //r2tSystemProperty.APT_CompanyCreditAssessmentEndPointURL__c='';
            r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c ='https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';   
            r2tSystemProperty.name='test123';
            //r2tSystemProperty.profileid=thisuser.profile;
            
            insert r2tSystemProperty ;
            
            
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgIdResultList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            Account acc = APT_TestUtils.createOrganisation();
            acc.ShippingState='test';
            acc.ShippingPostalCode='12345';
            acc.ShippingStreet='test';
            acc.Website='www.abc.com';
            acc.phone='123456789';
            acc.BillingStreet='test';
            acc.BillingState='test';
            acc.BillingPostalCode='12345';
            acc.ABN__c='31061621832';
            acc.ACN__c='222222222';
            insert acc; 
            Contact con = APT_TestUtils.createContact();
            con.MobilePhone='123456789';
            con.Phone='123456789';
            con.Fax='123456789'; 
            con.Salutation='mr';
            con.Title='test';
            //Applying the following change as key contact have look up filter introduced on Opportunity.  
            con.AccountId = acc.Id;  
            insert con; 
            
            Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
            opty.AccountId = acc.Id;
            opty.KeyContact__c=con.id;
            insert opty;
            Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList(); 
            insert priceList ;
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote',priceList.id);
            Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
            insert Proposal;
             
              
                        
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            
            
            system.debug('@@cssetting'+r2tSystemProperty);
            
            system.debug('@@endpoint'+r2tSystemProperty.APT_Org_Id_Service_End_Point_URL__c);
             
            PageReference pageRef = Page.APT_CashAccountAssessment;
            Test.setCurrentPage(pageRef);
             
            ApexPages.StandardController sc = new ApexPages.standardController(acc);
            ApexPages.currentPage().getParameters().put('proposalID',Proposal.Id);
            APT_CashAccountAssessmentController Testing = new APT_CashAccountAssessmentController(sc);
         
            Test.StartTest();
            Testing.accounDetails();
            Testing.requestOrgIDDetails();
            
            //Testing.selectReport();
            Testing.doNextForChargeAccount();
            Testing.getCompanyBusinessType();
            pageReference pgRef = Testing.backToProposal();
            
            
            Test.StopTest();
            system.assert(pgRef != null);
        }
    }


    //Creating test data   
    private static TestMethod void APT_CashAccountAssessmentControllerProposal() {
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
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
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
            
            PageReference pageRef = Page.APT_CashAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            
            
            Test.StartTest();
            if (test.isRunningTest()) {
                Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            }
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_CashAccountAssessmentController cac = new APT_CashAccountAssessmentController(sc);
            cac.selectedABRReport = null;
            cac.selectedASICReport = null;
            cac.showCompanyBusiness = null;
            cac.showSoleTrader = null;
            cac.displayPopUp = null;
            cac.selectedOrgIdUniqueNumber = 1;
            cac.accounDetails();
            cac.backToProposal();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            cac.createCashAccount();
            PageReference pgRef = cac.doNextForChargeAccount();
            
            
            Test.StopTest();
            system.assert(pgRef == null);
        }
    }
    //Creating test data    
    private static TestMethod void APT_CashAccountAssessmentControllerProposal2ABN() {
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
            acc.ABN__c = '12345678911';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
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
            
            PageReference pageRef = Page.APT_CashAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_CashAccountAssessmentController cac = new APT_CashAccountAssessmentController(sc);
            cac.selectedOrgIdUniqueNumber = 1;
            cac.accounDetails();
            cac.backToProposal();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
           //cac.selectReport();
            PageReference pgRef = cac.doNextForChargeAccount();
            
            Test.StopTest();
            system.assert(pgRef == null);
        }
    }
    //Creating test data    
    private static TestMethod void APT_CashAccountAssessmentControllerProposal3() {
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
            acc.ABN__c = '12345678911';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
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
            
            PageReference pageRef = Page.APT_CashAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_CashAccountAssessmentController cac = new APT_CashAccountAssessmentController(sc);
            cac.selectedOrgIdUniqueNumber = 1;
            cac.accounDetails();
            cac.backToProposal();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            //cac.selectReport();
            PageReference pgRef = cac.doNextForChargeAccount();
            
            Test.StopTest();
            system.assert(pgRef == null);
        }   
    }
    
    //Creating test data    
    private static TestMethod void APT_CashAccountAssessmentControllerProposal4() {
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
            acc.ABN__c = '12345678911';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
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
            
            PageReference pageRef = Page.APT_CashAccountAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServiceContHelper());        
            
            
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_CashAccountAssessmentController cac = new APT_CashAccountAssessmentController(sc);
            cac.selectedOrgIdUniqueNumber = 1;
            cac.accounDetails();
            cac.backToProposal();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            //cac.selectReport();
            PageReference pgRef = cac.doNextForChargeAccount();
            
            Test.StopTest();
            system.assert(pgRef == null);
        }   
    }





}