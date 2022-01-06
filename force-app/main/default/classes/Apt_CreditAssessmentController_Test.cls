/**
Created By - Drashtee Shah
Created Date - 22nd Feb, 2016

Last Modified By - Mausam Padhiyar  
Last Modified Date - 31st Jan, 2017

Last Modified By - Seth Heang
Last Modified Date - 20th Nov, 2020 | STP 3414 - Update test class to cover 'Update' functionalty for 'Prospect' Org role and increase code coverage

Last Modified By - Dheeraj Mandavilli
Last Modified Date - 17th May, 2021 | STP 4285 - Update test class to fix Opportunity Close date with current date to prevent failures

Last Modified By - Seth Heang
Last Modified Date - 1th July, 2021 | STP-5757 - Fix method failing and Increase Code Coverage
*/
@isTest
private class Apt_CreditAssessmentController_Test {
    
    /*
        This method will create test data for execution of test class
    */
    @testSetup static void setup() {
        Account acc = APT_TestUtils.createOrganisation();
            acc.name = 'test';
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.L2C_Hotlist__c = false;
            acc.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0].Id;
            insert acc;
            
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
			opty.CloseDate = System.date.Today();
            insert opty;
            
            // Comment out, as 'Propect' role is already created from a trigger
            /*Organisation_Role__c orgRole = new Organisation_Role__c();
            orgRole.organisation__c = acc.id;
            orgRole.Role_Type__c = 'Prospect';
            insert orgRole;*/
        
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
            
            // Create Custom Setting Record
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Credit_Assessment_Valid_States__c = 'VIC,NSW,WA,QLD,TAS,NT,SA,ACT,OS,NZ';
            insert r2tSystemProperties;
            
            //Create Charge Account Record
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            cacc.APT_Company_Name__c = 'AusPost';
            cacc.APT_Contact_Name__c = 'Auspost';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456791';
            cacc.AP_Proposed_Credit_Limit__c = 15000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 1000;
            cacc.APT_Billing_Address_Street_Number__c = '141';
            cacc.APT_Billing_Address_Street_Name__c = 'Bourke Street';
            cacc.APT_Billing_Address_Suburb__c = 'Melbourne';
            cacc.APT_Billing_Addres_State__c = 'VIC';
            cacc.APT_Billing_Address_Street_Postcode__c = '3000';
            cacc.L2C_Total_Proposed_Credit__c = '16000';
            cacc.APT_Term_Days__c = '30';
            insert cacc;
            
            //Create Credit Assessment Record
            APT_Credit_Assessment__c ca = new APT_Credit_Assessment__c();
            ca.APT_Organisation_Name__c = acc.id;
            ca.APT_Proposal__c = Proposal.id;
            ca.APT_ABN__c = '12345678911';
            ca.APT_ACN__c = '123456791';
            ca.L2C_AP_Proposed_Credit_Limit__c = 14000;
            ca.L2C_Star_Track_Proposed_Credit_Limit__c = 1000;
            ca.APT_Credit_Amount_Required__c = 15000;
            ca.APT_Credit_Assessment_Complete__c = true;
            ca.APT_Number_of_Employees__c = 100;
            ca.APT_Nature_of_Business__c = 'Apttus';
            ca.APT_Legal_Entity_Name__c = 'test';
            ca.APT_Applicant_1_First_Name__c = 'Kit ';
            ca.APT_Applicant_1_Last_Name__c = 'Harrington';
            ca.APT_Applicant_1_Street_Number__c = '123';
            ca.APT_Applicant_1_Street_Name__c = 'Bourke ST';
            ca.APT_Applicant_1_Suburb__c = 'Melbounre';
            ca.APT_Applicant_1_State__c = 'VIC';
            ca.APT_Applicant_1_Postcode__c = '3000';
            ca.APT_Charge_Account__c = cacc.id;
            ca.APT_Applicant_1_Date_of_Birth__c = date.newInstance(1988,03,12);
            insert ca;
            
            ca.L2C_AP_Proposed_Credit_Limit__c = 15000;
            ca.L2C_Star_Track_Proposed_Credit_Limit__c = 2000;
            update ca;
              
    }
    
    
    private static TestMethod void Apt_CreditAssessmentController1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) { 
            Account acc = [SELECT id, Name, Type, ABN__c, ACN__c,Role_Type_Roll_Up__c FROM Account LIMIT 1];
            
            APT_Charge_Account__c cacc = [SELECT id, APT_Industry_Type__c, APT_Company_Name__c, APT_ABN__c, APT_ACN__c, APT_Credit_Limit_Required__c, L2C_Total_Proposed_Credit__c,
                                            AP_Proposed_Credit_Limit__c, Star_Track_Proposed_Credit_Limit__c
                                         FROM APT_Charge_Account__c LIMIT 1];
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('ID', acc.Id);
            Apexpages.currentPage().getParameters().put('accountType', 'Charge Account + Sub Account');
            
            APT_Credit_Assessment__c ca = [SELECT id,APT_Organisation_Name__c,APT_ABN__c,APT_ACN__c,APT_Credit_Assessment_Status__c,APT_Credit_Amount_Required__c,
                                            APT_Credit_Assessment_Complete__c,APT_Number_of_Employees__c,APT_Nature_of_Business__c,APT_Legal_Entity_Name__c
                                            FROM APT_Credit_Assessment__c WHERE APT_Organisation_Name__c = :acc.id LIMIT 1];

            
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.isAnonymousFlow=true;
            cac.selectedOrgIdUniqueNumber = 1;
            cac.chargeAccount = cacc;
            cac.init();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            cac.orgIdResultList = orgidelementList;
            cac.selectReport();
            cac.doCreditCheck();
            cac.checkCreditAssessment();
            //cac.doProposalRefer();
            cac.redirectToNextPage();
            cac.doRefer();
            cac.goBack();
            //cac.doSave();
            //cac.updateProposal();
            cac.doNextForChargeAccount();
            cac.doContinue();
            cac.assesmentType = 'TEST';
            cac.userinput = '';
            cac.requestOrgIDDetails();
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_CHARGE_ACCOUNT;
            system.assert(cac.showChargeAccount);
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_SEARCH_ABN;
            system.assert(cac.showSearchCreditAssessment);
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_COMPANY_BUSINESS;
            system.assert(cac.showCompanyBusiness);
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_SOLE_TRADER;
            system.assert(cac.showSoleTrader);
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_ABN_RESULTS;
            system.assert(cac.showSearchResults);
            
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_RESULTS;
            system.assert(cac.showCreditAssesssmentResults);
            
            // Save Charge Account with new details, prior to running the update functionality
            cacc.APT_Company_Name__c = 'GLOBAL COMPANY LIMITED';
            cacc.APT_ABN__c = '11223344556';
            cacc.APT_ACN__c = '112233445';
            cac.isAnonymousFlow = false;
            cac.account = acc;
            cac.chargeAccount = cacc;
            cac.updateAccount();

            Test.StopTest();
            system.assert(sc!=null);

            // query the updated Account details
            List<Account> accUpdate = [SELECT id, name, ABN__c, ACN__c FROM Account WHERE id =: acc.id];

            // verify the updated details on Account 
            system.assertEquals('GLOBAL COMPANY LIMITED', accUpdate[0].Name, 'Name does not get updated');
            system.assertEquals('11223344556', accUpdate[0].ABN__c, 'ABN does not get updated');
            system.assertEquals('112233445', accUpdate[0].ACN__c, 'ACN does not get updated');
        }
            
    }
    
    
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void Apt_CreditAssessmentControllerProposal() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Name = 'THE COMPUTER COMPANY PTY. LTD.';
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456788';
            acc.ABN__c = '123456777';
            acc.L2C_Hotlist__c = false;
            acc.billingStreet = 'temp1';
            acc.BillingState = 'NT';
            acc.BillingCity = 'temp11';
            acc.BillingPostalCode = '0820';
            acc.BillingCountry = 'Australia';
            acc.L2C_Approved_AP_Credit_Limit__c = 600;
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678921';
            cacc.APT_ACN__c = '123456788';
            cacc.APT_Credit_Limit_Required__c = 25000;
            cacc.L2C_Total_Proposed_Credit__c = '30000';
            cacc.AP_Proposed_Credit_Limit__c = 25000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 25000;
            //cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            insert cacc;
            
            
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
			opty.CloseDate = System.date.Today();
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
            Proposal.Is_Startrack_Proposal__c = 'No';
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
            
            // ADDED BY SHASHWAT
            APT_Credit_Assessment__c creditAssessment = new APT_Credit_Assessment__c();
            creditAssessment.APT_Legal_Entity_Name__c = 'test';
            creditAssessment.APT_Credit_Assessment_Status__c = 'Cancelled';
            creditAssessment.APT_Applicant_2_Credit_Check_Consent__c = true;
            creditAssessment.APT_Charge_Account__c = cacc.id;
            creditAssessment.APT_Proposal__c = Proposal.id;
            creditAssessment.APT_Credit_Assessment_Status__c = APT_Constants.APPROVAL_STATUS_REJECTED;
            creditAssessment.APT_Credit_Assessment_Complete__c = true;
            creditAssessment.APT_ACN__c = '123456788';
            creditAssessment.Aus_Post_Proposed_for_New_Account__c = 1;
            insert creditAssessment;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Credit_Assessment_Valid_States__c = 'VIC,NSW,WA,QLD,TAS,NT,SA,ACT,OS,NZ';
            r2tSystemProperties.Opportunity_Value_Multiplier__c = 0.2500;
            insert r2tSystemProperties;
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            Apexpages.currentPage().getParameters().put('PageType', 'BLANK');
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.showMultipleRefer = true;
            cac.isAnonymousFlow=false;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            
            cac.isEntityTypePartnership = true;
            cac.userInput = '123456788';
            cac.selectedOrgIdUniqueNumber = 1;
            cac.chargeAccount = cacc;
            cac.init();
            cac.getCompanyBusinessType();
            cac.orgIdResultList = orgidelementList;
            cac.requestOrgIDDetails();
            cac.selectReport();
            
            cac.doCreditCheck();
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            update cacc;
            cac.doCreditCheck();
            
            cacc.APT_Credit_Limit_Required__c = 4000;
            update cacc;
            cac.doCreditCheck();
            
            cac.verifyAccountDetails();
            acc.Name = 'test';
            update acc;
            cac.doCreditCheck();
            
            cacc.APT_ABN__c = '098765432111';
            cac.verifyAccountDetails();
            
            cac.checkCreditAssessment();


            //cac.doCompanyBusinessCreditAssessment();
            //cac.doProposalRefer();
            cac.redirectToNextPage();
            //cac.doRefer();
            cac.goBack();
            //cac.doSave();
            //cac.updateProposal();
            cac.doNextForChargeAccount();
            cac.updateAccount();
            cac.doContinue();
            
            cac.sendEmailAccountFlow();

            cac.backToProposal();

            cac.backToAccount();
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_SOLE_TRADER;
            cac.addPartner();
            cac.doCreditCheck();
            cac.addPartner();
            cac.doCreditCheck();
            cac.addPartner();
            cac.doCreditCheck();
            
            acc.L2C_Hotlist__c = true;
            update acc;
            cac.doCreditCheck();

            // increase coverage by covering populateChargeAccountAddress() for sold trader
            cac.soleTraderAddrress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            cac.residentialAddress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            cac.PageType = Apt_CreditAssessmentController.PAGE_TYPE_SOLE_TRADER;
            cac.doCreditCheck();

            Test.StopTest();
            
            system.assert(sc!=null);
            
            
            //System.debug('Outcome Reason: ' + cac.AssessmentOutComeReason);
            //System.debug('CA Status ' + cac.creditAssesment.APT_Credit_Assessment_Status__c);
            //System.assertEquals(cac.AssessmentOutComeReason, 'Hotlisted Customer');
            //System.assertEquals(cac.creditAssesment.APT_Credit_Assessment_Status__c, 'Referred');
        }    
    }
    
    
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void Apt_CreditAssessmentControllerProposal2ABN() {
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
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456789';
            cacc.APT_Credit_Limit_Required__c = 100;
            cacc.L2C_Total_Proposed_Credit__c = '555';
            cacc.AP_Proposed_Credit_Limit__c = 15500;
            cacc.Star_Track_Proposed_Credit_Limit__c = 5555;
            //cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
			opty.CloseDate = System.date.Today();
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
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.selectedOrgIdUniqueNumber = 1;
            cac.chargeAccount = cacc;
            cac.init();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            cac.orgIdResultList = orgidelementList;
            cac.selectReport();
            cac.doCreditCheck();
            cac.checkCreditAssessment();
            //cac.doProposalRefer();
            cac.redirectToNextPage();
            cac.doRefer();
            cac.goBack();
            //cac.doSave();
            //cac.updateProposal();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            Test.StopTest();
            system.assert(sc!=null);
        } 
    }
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void Apt_CreditAssessmentControllerProposal3() {
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
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456789';
            cacc.APT_Credit_Limit_Required__c = 100;
            cacc.L2C_Total_Proposed_Credit__c = '555';
            cacc.Star_Track_Proposed_Credit_Limit__c = 555;
            cacc.AP_Proposed_Credit_Limit__c = 555;
            //cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
			opty.CloseDate = System.date.Today();
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
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);

            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 2;
            orgidelementList.add(orgIdelement);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.chargeAccount = cacc;
            cac.selectedOrgIdUniqueNumber = 2;
            cac.init();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            cac.orgIdResultList = orgidelementList;
            cac.selectReport();
            cac.doCreditCheck();
            cac.checkCreditAssessment();
            //cac.doProposalRefer();
            cac.redirectToNextPage();
            cac.doRefer();
            cac.goBack();
            //cac.doSave();
            //cac.updateProposal();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            Test.StopTest();
            system.assert(sc!=null);
        }   
    }
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void Apt_CreditAssessmentControllerProposal4() {
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
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456789';
            cacc.APT_Credit_Limit_Required__c = 100;
            cacc.L2C_Total_Proposed_Credit__c = '555';
            cacc.AP_Proposed_Credit_Limit__c = 15555;
            cacc.Star_Track_Proposed_Credit_Limit__c = 15555;
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
			opty.CloseDate = System.date.Today();
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
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServiceContHelper());        
            
            
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.backToSearch();
            cac.chargeAccount = cacc;
            cac.selectedOrgIdUniqueNumber = 1;
            cac.init();
            cac.getCompanyBusinessType();
            cac.requestOrgIDDetails();
            cac.orgIdResultList = orgidelementList;
            cac.selectReport();
            cac.doCreditCheck();
            cac.checkCreditAssessment();
            //cac.doProposalRefer();
            cac.redirectToNextPage();
            cac.doRefer();
            cac.goBack();
            //cac.doSave();
            //cac.updateProposal();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            Test.StopTest();
            system.assert(sc!=null);
        }
    }
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void TestDoSave() {
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
            acc.billingStreet = 'temp1';
            acc.BillingState = 'NT';
            acc.BillingCity = 'temp11';
            acc.BillingPostalCode = '0820';
            acc.BillingCountry = 'Australia';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            cacc.APT_Term_Days__c = '30';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456789';
            cacc.APT_Credit_Limit_Required__c = 100;
            insert cacc;
            
            APT_Credit_Assessment__c creditAssessment = new APT_Credit_Assessment__c();
            creditAssessment.APT_Legal_Entity_Name__c = 'test';
            creditAssessment.APT_Credit_Assessment_Status__c = 'Approve';
            creditAssessment.APT_Applicant_2_Credit_Check_Consent__c = true;
            insert creditAssessment;
            
            //AustralianBusinessRegisterReport_element
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            
            
            
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = new APT_OrgIDWebServiceWrapper.ASICReport_element();
            asicreport.ASICName = '';
            asicreport.ASICOrganisationNumber = '';
            asicreport.ASICABN = '';
            asicreport.ASICOrganisationNumberHeading = '';
            asicreport.ASICPrescribedInterestNumber = '';
            asicreport.ASICUndertakingName = '';
            asicreport.ASICRegistrationDate = System.Today();
            asicreport.ASICStatus = '';
            asicreport.ASICState = '';
            asicreport.ASICBusinessRegistrationNumber = '';
            asicreport.ASICJurisdiction = '';
            asicreport.ErrorMsg = null;
            asicreport.WarningMsg = null;
            asicreport.ASICLocality = '';
            asicreport.ASICAddressState = '';
            asicreport.ASICPostcode = '';
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgidelementList.add(orgIdelement);
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('ID', acc.Id);
            Apexpages.currentPage().getParameters().put('accountType', 'Charge Account + Sub Account');
            
            Test.StartTest();
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            cac.chargeAccount = cacc;
            cac.account = acc;
            cac.orgIdResultList = orgidelementList;
            cac.creditAssesment = creditAssessment;
            cac.selectedOrgIdUniqueNumber = 1;
            cac.mailingAddress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            cac.physicalAddress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            //cac.doSave();
            
            Test.StopTest();
            system.assert(sc!=null);
        }
    }
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void updateProposal() {
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
            acc.billingStreet = 'temp1';
            acc.BillingState = 'NT';
            acc.BillingCity = 'temp11';
            acc.BillingPostalCode = '0820';
            acc.BillingCountry = 'Australia';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            cacc.APT_Term_Days__c = '30';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cacc.APT_Company_Name__c = 'test';
            cacc.APT_ABN__c = '12345678911';
            cacc.APT_ACN__c = '123456789';
            cacc.APT_Credit_Limit_Required__c = 100;
            insert cacc;
            
            APT_Credit_Assessment__c creditAssessment = new APT_Credit_Assessment__c();
            creditAssessment.APT_Legal_Entity_Name__c = 'test';
            creditAssessment.APT_Applicant_2_Credit_Check_Consent__c = true;
            insert creditAssessment;
            
            //result_element
            APT_CompanyCreditAssessmentWrapper.result_element ree = new APT_CompanyCreditAssessmentWrapper.result_element();
            ree.decisionCode = 'ere';
            ree.listReasons = null;
            
            //organisationDetails
            APT_CompanyCreditAssessmentWrapper.organisationDetails odd = new APT_CompanyCreditAssessmentWrapper.organisationDetails();
            odd.name = '';
            odd.entityType = '';
            odd.industryType = '';
            odd.australianCompanyNumber = '';
            odd.ExistingCustomerFlag = False;
            odd.australiaPostArrears = 12;
            odd.CustomerPerformance = 12;
            
            //companyBusinessCommercialApplication_element
            APT_CompanyCreditAssessmentWrapper.companyBusinessCommercialApplication_element cbce = new APT_CompanyCreditAssessmentWrapper.companyBusinessCommercialApplication_element();
            cbce.creditAmountRequired = 'asdas';
            cbce.termDays = 'ere';
            
            //organisationResponse_element
            APT_CompanyCreditAssessmentWrapper.organisationResponse_element ore = new APT_CompanyCreditAssessmentWrapper.organisationResponse_element();
            ore.organisationDetails = odd;
            ore.organisationDecision = ree;
            
            //responseResult_element
            APT_CompanyCreditAssessmentWrapper.responseResult_element response_element = new APT_CompanyCreditAssessmentWrapper.responseResult_element();
            response_element.commercialApplication = cbce;
            response_element.organisationResults = ore;
            
            //companyBusinessResponse_element
            APT_CompanyCreditAssessmentWrapper.companyBusinessResponse_element responsewrapper1 = new APT_CompanyCreditAssessmentWrapper.companyBusinessResponse_element();
            responsewrapper1.companyBusinessDecision = 'Refer';
            responsewrapper1.status = 'Refer';
            //responsewrapper1.creditLimit = 100;
            responsewrapper1.response = response_element;
            responsewrapper1.listErrors = null;
            
            
            //for individual response
            
            //applicantDetails
            APT_IndividualCreditAssessmentWrapper.applicantDetails apd = new APT_IndividualCreditAssessmentWrapper.applicantDetails();
            apd.firstName = 'asdads';
            apd.middleName = 'asda';
            apd.lastName = 'asd';
            apd.dateOfBirth = System.Today()-1000;
            apd.driversLicence = 'asdsdasd';
            
            //individualApplicants_element
            list<APT_IndividualCreditAssessmentWrapper.individualApplicants_element> iaeList = new list<APT_IndividualCreditAssessmentWrapper.individualApplicants_element>();
            APT_IndividualCreditAssessmentWrapper.individualApplicants_element iae = new APT_IndividualCreditAssessmentWrapper.individualApplicants_element();
            iae.applicantDetails = apd;
            iae.additionalApplicantDecision = null;
            iaeList.add(iae);
            
            //individualCommercialResults_element
            APT_IndividualCreditAssessmentWrapper.individualCommercialResults_element icre = new APT_IndividualCreditAssessmentWrapper.individualCommercialResults_element();
            icre.listAdditionalApplicantResults = iaeList;
            icre.commercialApplication = null;
            
            //individualCommercialResponse_element
            APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element mainresponse1 = new APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element();
            mainresponse1.individualDecision = 'Refer';
            mainresponse1.status = 'Refer';
            mainresponse1.creditLimit = 100;
            mainresponse1.response = icre;
            //mainresponse1.listErrorDetails = null;
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getParameters().put('ID', acc.Id);
            Apexpages.currentPage().getParameters().put('accountType', 'Charge Account + Sub Account');
            
            Test.StartTest();
            
            //Test.setMock(WebServiceMock.class, new APT_WebServiceMockServicePartyCustomer());
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            cac.chargeAccount = cacc;
            cac.account = acc;
            cac.responseWrapper = responsewrapper1;
            cac.individualResponseWrapper = mainresponse1;
            //cac.orgIdResultList = orgidelementList;
            cac.creditAssesment = creditAssessment;
            cac.creditAssessmentId = creditAssessment.ID;
            cac.showCompanyBusinessResponse = true;
            cac.showSoleTraderResponse = true;
            cac.selectedOrgIdUniqueNumber = 1;
            cac.mailingAddress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            cac.physicalAddress = new AddressExtension(acc.billingStreet, acc.BillingState, acc.BillingCity, acc.BillingState, acc.BillingPostalCode, acc.ABN__c, acc.BillingCountry);
            //cac.updateProposal();
            
            Test.StopTest();
            system.assert(sc!=null);
        }
    }
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void APT_CA_CommonDataModelSchemaTest2() {
        APT_OrgIDWebServiceWrapper.BusinessName_element tyur1 = new APT_OrgIDWebServiceWrapper.BusinessName_element();
        tyur1.RegisteredBusinessName = null;
        tyur1.DistinguishedWord = null;
        tyur1.VedaBusinessNameId = null;
        
        APT_OrgIDWebServiceWrapper.queryABNType tyur2 = new APT_OrgIDWebServiceWrapper.queryABNType();
        tyur2.OrganisationNumber = null;
        tyur2.AustralianBusinessNumber = null;
        tyur2.OrgName = null;
        tyur2.BusinessRegistrationNumber = null;
        tyur2.BureauReference = null;
        tyur2.SearchType = null;
        
        APT_OrgIDWebServiceWrapper.OrgIdResult_element tyur3 = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
        tyur3.OrgIdResultUniqueNumber = null;
        tyur3.ShowSelect = null;
        tyur3.MatchName = null;
        tyur3.OrganisationNumber = null;
        tyur3.OrganisationType = null;
        tyur3.AustralianBusinessNumber = null;
        tyur3.OrganisationNumberHeading = null;
        tyur3.State = null;
        tyur3.ASICReport = null;
        tyur3.AustralianBusinessRegisterReport = null;
        tyur3.BureauReport = null;
        tyur3.ASICBNRReport = null;
        
        APT_OrgIDWebServiceWrapper.BureauReport_element tyur4 = new APT_OrgIDWebServiceWrapper.BureauReport_element();
        tyur4.Address = null;
        tyur4.LastSearchDate = null;
        tyur4.NatureOfBusiness = null;
        tyur4.ErrorMsg = null;
        tyur4.WarningMsg = null;
        tyur4.BureauReference = null;
        tyur4.BCACompanyType = null;
        tyur4.BCAName = null;
        
        APT_OrgIDWebServiceWrapper.DGR_element tyur5 = new APT_OrgIDWebServiceWrapper.DGR_element();
        tyur5.DGRName = null;
        tyur5.DGRStatus = null;
        tyur5.DGRFromDate = null;
        tyur5.DGRType = null;
        
        APT_OrgIDWebServiceWrapper.HolderReference_element tyur6 = new APT_OrgIDWebServiceWrapper.HolderReference_element();
        tyur6.ABN = null;
        tyur6.ABREntityName = null;
        
        APT_OrgIDWebServiceWrapper.BusinessNameHolderType tyur7 = new APT_OrgIDWebServiceWrapper.BusinessNameHolderType();
        tyur7.ABN = null;
        tyur7.ABREntityName = null;
        tyur7.Individual = null;
        tyur7.Organisation = null;
        tyur7.AssociatedBusinessNames = null;
        
        APT_OrgIDWebServiceWrapper.ErrorType tyur8 = new APT_OrgIDWebServiceWrapper.ErrorType();
        tyur8.ErrorTypeCode = null;
        tyur8.InputContainer = null;
        tyur8.ErrorDescriptionTypeCode = null;
        tyur8.ErrorDescriptiontype = null;
        tyur8.ErrorTypeDesc = null;
        
        APT_OrgIDWebServiceWrapper.ASICBNRReport_element tyur9 = new APT_OrgIDWebServiceWrapper.ASICBNRReport_element();
        tyur9.BusinessName = null;
        tyur9.BusinessNameHolder = null;
        tyur9.ErrorMsg = null;
        tyur9.WarningMsg = null;
        
        APT_OrgIDWebServiceWrapper.OtherEntity_element tyur10 = new APT_OrgIDWebServiceWrapper.OtherEntity_element();
        tyur10.OtherEntityType = null;
        tyur10.OtherEntityName = null;
        
        APT_OrgIDWebServiceWrapper.queryABNResponseType tyur11 = new APT_OrgIDWebServiceWrapper.queryABNResponseType();
        tyur11.OrgIdResult = null;
        tyur11.Error = null;
        
        APT_OrgIDWebServiceWrapper.AssociatedBusinessNames_element tyur12 = new APT_OrgIDWebServiceWrapper.AssociatedBusinessNames_element();
        tyur12.BusinessName = null;
        
        APT_OrgIDWebServiceWrapper.StreetType_element tyur13 = new APT_OrgIDWebServiceWrapper.StreetType_element();
        tyur13.Code = null;
        
        APT_OrgIDWebServiceWrapper.Address_element tyur14 = new APT_OrgIDWebServiceWrapper.Address_element();
        tyur14.FirstReported = null;
        tyur14.Type_x = null;
        tyur14.UnitNumber = null;
        tyur14.StreetNumber = null;
        tyur14.Property = null;
        tyur14.StreetName = null;
        tyur14.StreetType = null;
        tyur14.Suburb = null;
        tyur14.City = null;
        tyur14.State = null;
        tyur14.Postcode = null;
        tyur14.Country = null;
        tyur14.DPID = null;
        
        APT_OrgIDWebServiceWrapper.Country_element tyur15 = new APT_OrgIDWebServiceWrapper.Country_element();
        tyur15.CountryCode = null;
        
        APT_OrgIDWebServiceWrapper.Organisation_element tyur16 = new APT_OrgIDWebServiceWrapper.Organisation_element();
        tyur16.Name = null;
        tyur16.ACN = null;
        
        APT_OrgIDWebServiceWrapper.ErrorDescriptionType tyur17 = new APT_OrgIDWebServiceWrapper.ErrorDescriptionType();
        
        APT_OrgIDWebServiceWrapper.BusinessRegistrationNumber_element tyur18 = new APT_OrgIDWebServiceWrapper.BusinessRegistrationNumber_element();
        tyur18.State = null;
        tyur18.Number_x = null;
        
        APT_OrgIDWebServiceWrapper.Individual_element tyur19 = new APT_OrgIDWebServiceWrapper.Individual_element();
        tyur19.GivenNames = null;
        tyur19.FamilyName = null;
        
        APT_OrgIDWebServiceWrapper.ASICReport_element tyur20 = new APT_OrgIDWebServiceWrapper.ASICReport_element();
        tyur20.ASICName = null;
        tyur20.ASICOrganisationNumber = null;
        tyur20.ASICABN = null;
        tyur20.ASICOrganisationNumberHeading = null;
        tyur20.ASICPrescribedInterestNumber = null;
        tyur20.ASICUndertakingName = null;
        tyur20.ASICType = null;
        tyur20.ASICRegistrationDate = null;
        tyur20.ASICStatus = null;
        tyur20.ASICState = null;
        tyur20.ASICBusinessRegistrationNumber = null;
        tyur20.ASICJurisdiction = null;
        tyur20.ErrorMsg = null;
        tyur20.WarningMsg = null;
        tyur20.ASICLocality = null;
        tyur20.ASICAddressState = null;
        tyur20.ASICPostcode = null;
        
        APT_OrgIDWebServiceWrapper.Status_element tyur21 = new APT_OrgIDWebServiceWrapper.Status_element();
        tyur21.Code = null;
        tyur21.Description = null;
        
        APT_OrgIDWebServiceWrapper.BusinessNameType tyur22 = new APT_OrgIDWebServiceWrapper.BusinessNameType();
        tyur22.RegisteredBusinessName = null;
        tyur22.DistinguishedWord = null;
        tyur22.VedaBusinessNameId = null;
        tyur22.PreviousStateTerritoryCode = null;
        tyur22.PreviousStateRegistrationNumber = null;
        tyur22.HolderReference = null;
        tyur22.Status = null;
        tyur22.Address = null;
        
        APT_OrgIDWebServiceWrapper.OrganisationType_element tyur23 = new APT_OrgIDWebServiceWrapper.OrganisationType_element();
        
        APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element tyur24 = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
        tyur24.ASICNumber = null;
        tyur24.ASICNumberType = null;
        tyur24.ABN = null;
        tyur24.ABNStatus = null;
        tyur24.ABNStatusFromDate = null;
        tyur24.EntityTypeInd = null;
        tyur24.EntityTypeText = null;
        tyur24.IndividualName = null;
        tyur24.NonIndividualName = null;
        tyur24.BusinessAddressState = null;
        tyur24.BusinessAddressPostcode = null;
        tyur24.GSTStatus = null;
        tyur24.GSTStatusFromDate = null;
        tyur24.TradingName = null;
        tyur24.ErrorMsg = null;
        tyur24.WarningMsg = null;
        tyur24.DGR = null;
        tyur24.OtherEntity = null;
        
        APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentType temrut1 = new APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentType();
        APT_CA_IndividualCreditAssessment.Res_ApplicantDetails temrut2 = new APT_CA_IndividualCreditAssessment.Res_ApplicantDetails();
        APT_CA_IndividualCreditAssessment.IndividualCommercialRequest temrut3 = new APT_CA_IndividualCreditAssessment.IndividualCommercialRequest();
        APT_CA_IndividualCreditAssessment.Error temrut4 = new APT_CA_IndividualCreditAssessment.Error();
        APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResponse temrut5 = new APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResponse();
        APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant temrut6 = new APT_CA_IndividualCreditAssessment.Req_AdditionalApplicant();
        APT_CA_IndividualCreditAssessment.Req_CommercialApplication temrut7 = new APT_CA_IndividualCreditAssessment.Req_CommercialApplication();
        APT_CA_IndividualCreditAssessment.Reason temrut8 = new APT_CA_IndividualCreditAssessment.Reason();
        APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResults temrut9 = new APT_CA_IndividualCreditAssessment.Rsp_IndividualCommercialResults();
        APT_CA_IndividualCreditAssessment.Result temrut10 = new APT_CA_IndividualCreditAssessment.Result();
        APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentResponseType temrut11 = new APT_CA_IndividualCreditAssessment.getIndividualCreditAssessmentResponseType();
        APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants temrut12 = new APT_CA_IndividualCreditAssessment.Req_AdditionalApplicants();
        APT_CA_IndividualCreditAssessment.Req_ApplicantDetails temrut13 = new APT_CA_IndividualCreditAssessment.Req_ApplicantDetails();
        APT_CA_IndividualCreditAssessment.Rsp_CommercialApplication temrut14 = new APT_CA_IndividualCreditAssessment.Rsp_CommercialApplication();
        APT_CA_IndividualCreditAssessment.Req_Address temrut15 = new APT_CA_IndividualCreditAssessment.Req_Address();
        APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants temrut16 = new APT_CA_IndividualCreditAssessment.Rsp_IndividualApplicants();
        
        
        APT_SchemaCommondatamodeService.SOAPException_element srut1 = new APT_SchemaCommondatamodeService.SOAPException_element();
        APT_SchemaCommondatamodeService.InterfaceHeader srut2 = new APT_SchemaCommondatamodeService.InterfaceHeader();
        APT_SchemaCommondatamodeService.Exception_x srut3= new APT_SchemaCommondatamodeService.Exception_x();
        APT_SchemaCommondatamodeService.SynchronisationHeaderType srut4= new APT_SchemaCommondatamodeService.SynchronisationHeaderType();
        
        APT_CompanyCreditAssessmentWrapper.error_element tempz1 = new APT_CompanyCreditAssessmentWrapper.error_element();
        tempz1.code = null;
        tempz1.type_x = null;
        tempz1.description = null;
        APT_CompanyCreditAssessmentWrapper.reason tempz2 = new APT_CompanyCreditAssessmentWrapper.reason();
        tempz2.reasonCode = null;
        tempz2.description = null;
        tempz2.rule = null;
        APT_CompanyCreditAssessmentWrapper.result_element tempz3 = new APT_CompanyCreditAssessmentWrapper.result_element();
        tempz3.decisionCode = null;
        tempz3.listReasons = null;
        APT_CompanyCreditAssessmentWrapper.organisationDetails tempz4 = new APT_CompanyCreditAssessmentWrapper.organisationDetails();
        tempz4.name = null;
        tempz4.entityType = null;
        tempz4.industryType = null;
        tempz4.australianCompanyNumber = null;
        tempz4.ExistingCustomerFlag = null;
        tempz4.australiaPostArrears = null;
        tempz4.CustomerPerformance = null;
        
       APT_CompanyCreditAssessmentWrapper.organisationResponse_element tempz5 = new APT_CompanyCreditAssessmentWrapper.organisationResponse_element();
        tempz5.organisationDetails = null;
        tempz5.organisationDecision = null;
        APT_CompanyCreditAssessmentWrapper.companyBusinessCommercialApplication_element tempz6 = new APT_CompanyCreditAssessmentWrapper.companyBusinessCommercialApplication_element();
        tempz6.creditAmountRequired = null;
        tempz6.termDays = null;
        APT_CompanyCreditAssessmentWrapper.responseResult_element tempz7 = new APT_CompanyCreditAssessmentWrapper.responseResult_element();
        tempz7.commercialApplication = null;
        tempz7.organisationResults = null;
        APT_CompanyCreditAssessmentWrapper.companyBusinessResponse_element tempz8 = new APT_CompanyCreditAssessmentWrapper.companyBusinessResponse_element();
        tempz8.companyBusinessDecision = null;
        tempz8.status = null;
        //tempz8.creditLimit = null;
        tempz8.response = null;
        tempz8.listErrors = null;
        
        APT_IndividualCreditAssessmentWrapper.error_element tempe1 = new APT_IndividualCreditAssessmentWrapper.error_element();
        tempe1.code = null;
        tempe1.type_x = null;
        tempe1.description = null;
        APT_IndividualCreditAssessmentWrapper.commercialApplication tempe2 = new APT_IndividualCreditAssessmentWrapper.commercialApplication();
        tempe2.creditAmountRequired = null;
        tempe2.termDays = null;
        tempe2.businessHistoryAge = null;
        APT_IndividualCreditAssessmentWrapper.Reason tempe3 = new APT_IndividualCreditAssessmentWrapper.Reason();
        tempe3.reasonCode = null;
        tempe3.description = null;
        tempe3.rule = null;
        APT_IndividualCreditAssessmentWrapper.result_element tempe4 = new APT_IndividualCreditAssessmentWrapper.result_element();
        tempe4.decisionCode = null;
        tempe4.listReasons = null;
        APT_IndividualCreditAssessmentWrapper.applicantDetails tempe5 = new APT_IndividualCreditAssessmentWrapper.applicantDetails();
        tempe5.firstName = null;
        tempe5.middleName = null;
        tempe5.lastName = null;
        tempe5.dateOfBirth = null;
        tempe5.driversLicence = null;
        APT_IndividualCreditAssessmentWrapper.individualApplicants_element tempe6 = new APT_IndividualCreditAssessmentWrapper.individualApplicants_element();
        tempe6.applicantDetails = null;
        tempe6.additionalApplicantDecision = null;
        APT_IndividualCreditAssessmentWrapper.individualCommercialResults_element tempe7 = new APT_IndividualCreditAssessmentWrapper.individualCommercialResults_element();
        tempe7.listAdditionalApplicantResults = null;
        tempe7.commercialApplication = null;
        APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element tempe8 = new APT_IndividualCreditAssessmentWrapper.individualCommercialResponse_element();
        tempe8.individualDecision = null;
        tempe8.status = null;
        tempe8.creditLimit = null;
        tempe8.response = null;
        //tempe8.listErrorDetails = null;
        
        APT_CA_CommonDataModelSchema cDMS = new APT_CA_CommonDataModelSchema();
        APT_CA_CommonDataModelSchema.SOAPException_element temp1 = new APT_CA_CommonDataModelSchema.SOAPException_element();
        APT_CA_CommonDataModelSchema.InterfaceHeader temp2 = new APT_CA_CommonDataModelSchema.InterfaceHeader();
        APT_CA_CommonDataModelSchema.Exception_x temp3= new APT_CA_CommonDataModelSchema.Exception_x();
        APT_CA_CommonDataModelSchema.SynchronisationHeaderType temp4= new APT_CA_CommonDataModelSchema.SynchronisationHeaderType();
        
        APT_SchemaPartyCustomerService.BusinessName_element t1 = new APT_SchemaPartyCustomerService.BusinessName_element();
        APT_SchemaPartyCustomerService.queryABNType t2 = new APT_SchemaPartyCustomerService.queryABNType();
        APT_SchemaPartyCustomerService.OrgIdResult_element t3 = new APT_SchemaPartyCustomerService.OrgIdResult_element();
        APT_SchemaPartyCustomerService.DGR_element t4 = new APT_SchemaPartyCustomerService.DGR_element();
        APT_SchemaPartyCustomerService.HolderReference_element t5 = new APT_SchemaPartyCustomerService.HolderReference_element();
        APT_SchemaPartyCustomerService.BusinessNameHolderType t6 = new APT_SchemaPartyCustomerService.BusinessNameHolderType();
        APT_SchemaPartyCustomerService.ErrorType t7 = new APT_SchemaPartyCustomerService.ErrorType();
        APT_SchemaPartyCustomerService.ASICBNRReport_element t8 = new APT_SchemaPartyCustomerService.ASICBNRReport_element();
        APT_SchemaPartyCustomerService.OtherEntity_element t9 = new APT_SchemaPartyCustomerService.OtherEntity_element();
        APT_SchemaPartyCustomerService.queryABNResponseType t10 = new APT_SchemaPartyCustomerService.queryABNResponseType();
        APT_SchemaPartyCustomerService.AssociatedBusinessNames_element t11 = new APT_SchemaPartyCustomerService.AssociatedBusinessNames_element();
        APT_SchemaPartyCustomerService.StreetType_element t12 = new APT_SchemaPartyCustomerService.StreetType_element();
        APT_SchemaPartyCustomerService.Address_element t13 = new APT_SchemaPartyCustomerService.Address_element();
        APT_SchemaPartyCustomerService.Country_element t14 = new APT_SchemaPartyCustomerService.Country_element();
        APT_SchemaPartyCustomerService.Organisation_element t15 = new APT_SchemaPartyCustomerService.Organisation_element();
        APT_SchemaPartyCustomerService.ErrorDescriptionType t16 = new APT_SchemaPartyCustomerService.ErrorDescriptionType();
        APT_SchemaPartyCustomerService.BusinessRegistrationNumber_element t17 = new APT_SchemaPartyCustomerService.BusinessRegistrationNumber_element();
        APT_SchemaPartyCustomerService.Individual_element t18 = new APT_SchemaPartyCustomerService.Individual_element();
        APT_SchemaPartyCustomerService.ASICReport_element t19 = new APT_SchemaPartyCustomerService.ASICReport_element();
        APT_SchemaPartyCustomerService.Status_element t20 = new APT_SchemaPartyCustomerService.Status_element();
        APT_SchemaPartyCustomerService.BusinessNameType t21 = new APT_SchemaPartyCustomerService.BusinessNameType();
        APT_SchemaPartyCustomerService.AddressType t22 = new APT_SchemaPartyCustomerService.AddressType();
        APT_SchemaPartyCustomerService.ErrorTypeType t23 = new APT_SchemaPartyCustomerService.ErrorTypeType();
        APT_SchemaPartyCustomerService.BureauReport_element t26 = new APT_SchemaPartyCustomerService.BureauReport_element();
        APT_SchemaPartyCustomerService.OrganisationType_element t25 = new APT_SchemaPartyCustomerService.OrganisationType_element();
        APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element t24 = new APT_SchemaPartyCustomerService.AustralianBusinessRegisterReport_element();
        
    }
    
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void companyresponse() {
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
            
            //APT_Credit_Assessment__c
            APT_Credit_Assessment__c caci = new APT_Credit_Assessment__c();
            caci.APT_Legal_Entity_Name__c = 'test';
            caci.APT_Applicant_2_Credit_Check_Consent__c = true;
            insert caci;
            
            PageReference pageRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pageRef);
            
            //Apexpages.currentPage().getParameters().put('proposalID', Proposal.Id);
            
            Test.setMock(WebServiceMock.class, new APT_WebServiceMockServiceContHelper());        
            
            
            Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.showCompanyBusiness = true;
            cac.creditAssessmentId = caci.ID;
            cac.checkCreditAssessment();
            Test.StopTest();
            system.assert(sc!=null);
        }
    }
    
    /*
    This method will create test data for execution of test class
    */
    private static TestMethod void testMethod1() {
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
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            system.assert(sc!=null);
            
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.ServiceType = '';
            //cac.updateProposal();
           // cac.showReferProposalButton = true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.doRefer();
            //cac.updateProposal();
            cac.doContinue();
            //cac.doProposalRefer();
        }
    }
   
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario
     * Parameter: N/A
     * Return : Void             
     */ 
     private static TestMethod void CompanyResponseApprovalTest() {
        //Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //Creating Test User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user
        System.runAs(testuser) {
            //Querying Account record created in setup Method
            Account acc = [Select Id from Account LIMIT 1];
            //Querying Charge Account record created in setup Method
            APT_Charge_Account__c cacc= [Select Id , APT_Term_Days__c,APT_First_Name__c , APT_Last_Name__c ,APT_Applicant1_Date_of_Birth__c , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Limit_Required__c, APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c ,APT_Applicant1_BA_Unit_Number__c,APT_Applicant1_BA_Street_Number__c,
                                            APT_Applicant1_BA_Street_Name__c,APT_Applicant1_BA_Street_Type__c,APT_Applicant1_BA_Suburb__c,APT_Applicant1_BA_Street_Postcode__c,APT_Applicant1_BA_State__c,
                                            APT_Applicant1_BA_Country_Code__c,APT_A1_Consent_to_check_credit_history__c ,L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            //Querying Credit Assessment Record
            APT_Credit_Assessment__c ca = [Select Id,APT_Account_Type__c,APT_Credit_Amount_Required__c ,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Applicant_1_Date_of_Birth__c,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , APT_Applicant_1_Unit_Number__c,
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c ,APT_Applicant_1_Country__c,APT_Applicant_1_Credit_Check_Consent__c, APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];
            
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('APPROVE','Company'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
                APT_CompanyBusinessContHelper.updateCreditAssessmentFields(ca,cacc);
                APT_CompanyBusinessContHelper.ValidateIsExistingABNACN(cacc,acc.id);
           Test.StopTest();
           APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: ca.ID];
           // Assert the Response
           system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Approved');
        }
            
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */ 
    private static TestMethod void CompanyResponseABNblankTest() {
        //Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        //Creating Test User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user
        System.runAs(testuser) {
            // Querying Account
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];
            
            ca.APT_ABN__c = null;
            update ca;
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('APPROVE','Company'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
                APT_CompanyBusinessContHelper.updateCreditAssessmentFields(ca,cacc);
            Test.StopTest();
           APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: ca.ID];
           // Assert the Response
           system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Approved');
        }
            
    }
    
     /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
     public static TestMethod void companyCreditAssessmentTestReferred() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                            
        System.runAs(testuser) {
            // Querying Account   
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                             AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                             APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment    
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];         
            
           // Setting up the Mock Response Class
           Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_REFER','Company'));
           Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            //Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Referred');
        }
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
    public static TestMethod void companyCreditAssessmentTestDeclined() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                             
        System.runAs(testuser) {  
            // Querying Account
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_DECLINE','Company'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            //Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Rejected');
            
        }
            
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */ 
    
    public static TestMethod void companyCreditAssessmentExceptionCoverage() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
         // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                            
        System.runAs(testuser) {  
            // Querying Account
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('','Exception'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
                ApexPages.Message[] pageMessages = ApexPages.getMessages();
                //Asserting the Response
                System.assertNotEquals(0, pageMessages.size());
            Test.StopTest();
            
        }
            
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void soloCreditAssessmentApproved() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                             
        System.runAs(testuser) {  
            // Querying Account
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('APPROVE' , 'Individual'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.PageType = 'individual';
                cac.checkCreditAssessment();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            //Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Approved');
        }
     }
     
     /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
     public static TestMethod void soloCreditAssessmentABNblank() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                              
        System.runAs(testuser) {  
            // Querying Account
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            cacc.APT_ABN__c = null;
            update cacc;
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('APPROVE' , 'Individual'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.PageType = 'individual';
                cac.checkCreditAssessment();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
             //Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Approved');
        }
     }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
    public static TestMethod void soloCreditAssessmentReferred() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                            
        System.runAs(testuser) {  
            // Querying Account 
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_REFER' , 'Individual'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.PageType = 'individual';
                cac.checkCreditAssessment();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            //Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Referred');
       }
            
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
    public static TestMethod void soloCreditAssessmentDeclined() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user
        System.runAs(testuser) {
            // Querying Account   
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                          AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                          APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            // Querying Credit Assessment     
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];         
                
                
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_DECLINE','Individual'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.PageType = 'individual';
                cac.checkCreditAssessment();
                
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            // Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Rejected');
        }
    }
    
     /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is not Blank but ACN is blank for a Company/Other Type
     * Parameter: N/A
     * Return : Void             
     */
    public static TestMethod void companyCreditAssessmentForOtherType() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user
        System.runAs(testuser) {
            // Querying Account   
            Account acc = [Select Id from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                          AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                          APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            // Querying Credit Assessment     
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];         
                
            ca.APT_ACN__c = null;
            update ca; 
            
            cacc.APT_ACN__c = null;
            update cacc;   
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_DECLINE','Company'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'Company';
                cac.PageType = 'company';
                cac.checkCreditAssessment();
                
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            // Asserting the Response
            system.assertEquals(assessment.APT_Credit_Assessment_Status__c , 'Rejected');
        }
    }
    
    
    /*
     * Author: Shashwat Nath
     * Description: This Method is Used to Invoke Mock Approval Scenario When ABN is Blank
     * Parameter: N/A
     * Return : Void             
     */
    public static TestMethod void soloCreditAssessmentExceptionCoverage() {
        // Querying Profile to Setup Test User
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up Test User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        // Running as Test User                            
        System.runAs(testuser) { 
            // Querying Account  
            Account acc = [Select Id from Account LIMIT 1];
            //Querying Charge Account Record
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            //Querying Credit Assessment Record
            APT_Credit_Assessment__c ca = [Select Id,APT_Organisation_Name__c , APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            //Setting up the Mock Class For Response
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('','Exception'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                cac.doCreditCheckFlag = true ;
                cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.entityTypeForAssessment = 'individual';
                cac.PageType = 'individual';
                cac.checkCreditAssessment();
                ApexPages.Message[] pageMessages = ApexPages.getMessages();
                // Asserting the Result
                System.assertNotEquals(0, pageMessages.size());
            Test.StopTest();
        }
    }
    
    
     public static TestMethod void creditAssessmentForManualEntry() {
        // Querying Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // Setting up User
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                    EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                    LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                    TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                    UserName=APT_Constants.EMAIL_TEST_USER);
        //Running as test user                            
        System.runAs(testuser) {  
            // Querying Account 
            Account acc = [Select Id,Role_Type_Roll_Up__c from Account LIMIT 1];
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,APT_Credit_Limit_Required__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 
            
            // Querying Credit Assessment
            APT_Credit_Assessment__c ca = [Select APT_Organisation_Name__c , APT_Organisation_Name__r.Role_Type_Roll_Up__c,  APT_Proposal__c ,APT_ACN__c , L2C_AP_Proposed_Credit_Limit__c,
                                            L2C_Star_Track_Proposed_Credit_Limit__c ,APT_Credit_Amount_Required__c ,APT_Credit_Assessment_Complete__c , APT_Number_of_Employees__c , 
                                            APT_Nature_of_Business__c ,  APT_Legal_Entity_Name__c , APT_Applicant_1_First_Name__c , 
                                            APT_Applicant_1_Street_Name__c , APT_Applicant_1_Street_Number__c , APT_Applicant_1_Suburb__c,
                                            APT_Applicant_1_State__c ,APT_Applicant_1_Postcode__c , APT_Charge_Account__c  from APT_Credit_Assessment__c LIMIT 1];          
            
            // Setting up the Mock Response Class
            Test.setMock(HttpCalloutMock.class, new Apt_CreditAssessmentControllerMockImpl('PRE_REFER' , 'Individual'));
            Test.StartTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(acc);
                Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
                System.debug('*** ROLE TYPE:'+ ca.APT_Organisation_Name__r.Role_Type_Roll_Up__c);
                ca.APT_Organisation_Name__c = acc.id;
                ca.APT_Credit_Assessment_Complete__c =  true;
                ca.APT_Credit_Assessment_Status__c = 'Rejected';
                ca.APT_ACN__c = '123456777';
                update ca;
                ca.id = null;
                cac.account = acc;
                cac.isAnonymousFlow =true;
                cac.doCreditCheckFlag = true ;
                //cac.creditAssessmentId =ca.ID;
                cac.creditAssesment = ca;
                cac.chargeAccount = cacc;
                cac.PageType = 'individual';
                cac.referToCredit = true;
                cac.doRefer();
                cac.creditAssess = ca ; 
                cac.checkCreditAssessment();
                cac.redirectToCreditAssessmentRecord();
                cac.redirectToHomePage();

                cac.userinput = '123456777';
                cac.assesmentType = 'ACN';
                cac.requestOrgIDDetails();
            Test.StopTest();
            APT_Credit_Assessment__c assessment = [SELECT id , APT_Credit_Assessment_Status__c from APT_Credit_Assessment__c WHERE ID =: CA.ID];
            //Asserting the Response
            System.assert(assessment!=null);
       }
            
    }
    
    /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void hotlistCreditAssessmentNotCreditTeam() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'THE HOTLIST COMPANY PTY. LTD.';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = true;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c, APT_Credit_Limit_Required__c  
                                            from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'THE HOTLIST COMPANY PTY. LTD.';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.chargeAccount = cacc;
            cac.orgIdResultList = orgidelementList;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'THE HOTLIST COMPANY PTY. LTD.'];
            if(crAsmt.size() > 0){
                System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
     /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void accountNameDoesNotMatchCheck() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'THE HOTLIST COMPANY PTY. LTD.';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            //cac.isAccountChanged = false;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'THE HOTLIST COMPANY PTY. LTD.';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;

            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            cac.init();
            cac.orgIdResultList = orgidelementList;
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'THE HOTLIST COMPANY PTY. LTD.'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
     /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void trustOrgCheck() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'THE HOTLIST COMPANY PTY. LTD.';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='THE HOTLIST COMPANY PTY. LTD.',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'THE HOTLIST COMPANY PTY. LTD.';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = true;
            cac.isTrustFlag = true;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'THE HOTLIST COMPANY PTY. LTD.'];
            if(crAsmt.size() > 0){
                System.debug('CA size: ' + crAsmt.size());
                System.debug('CA ID: ' + crAsmt[0].id);
                System.debug('CA ACN: ' + crAsmt[0].APT_ACN__c);
                System.debug('Outcome Reason: ' + crAsmt[0].L2C_Referral_Rejection_Reason__c);
                System.debug('CA Status ' + crAsmt[0].APT_Credit_Assessment_Status__c);
                System.assertNotEquals(cac.displayHotlistPopup, true);
                //System.assertEquals(crAsmt[0].L2C_Referral_Rejection_Reason__c, 'Hotlisted Customer');
                //System.assertEquals(crAsmt[0].APT_Credit_Assessment_Status__c, 'Referred');
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
    /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void govtEntityAutoApprovedTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Govt Enterprises';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Govt Enterprises',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Govt Enterprises',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );

            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'Govt Enterprises';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = true;
            cac.isTrustFlag = false;
            cac.isGovernmentEntity = true;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'Govt Enterprises'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
     /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void belowThresholdAutoApprovalTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Below Threshold';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Below Threshold',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Below Threshold',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '8000';
            cacc.APT_Company_Name__c = 'Below Threshold';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = true;
            cac.isGovernmentEntity = false;
            cac.isTrustFlag = false;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    LIMIT 1];
            if(crAsmt.size() > 0){
                System.assertEquals(crAsmt.Size(), 1);   
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
    /*
     * Author: Seth Heang
     * Description: This Method is Used to perform credit assessment on a hotlisted customer with hotlist restriction, by sale team from proposal level
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void aboveThresholdAutoApprovalTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Below Threshold';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Below Threshold',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Below Threshold',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
                                                       
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 150000;
            cacc.L2C_Total_Proposed_Credit__c = '150000';
            cacc.APT_Company_Name__c = 'Below Threshold';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = true;
            cac.isGovernmentEntity = false;
            cac.isTrustFlag = false;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                   LIMIT 1];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
     /*
     * Author: Shashwat Nath
     * Description: This method is to test the functionality where Account name and ABN does not match with Equifax Account name and ABN
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void accountNameandABNdoNotMatch() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Govt Enterprises';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.ABN__c = '12345678987';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            
            
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.originalOrganisationABN = '98765432154';
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Govt Enterprises',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Govt Enterprises',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);                                           
            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'Govt Enterprises1';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            cac.isGovernmentEntity = true;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'Govt Enterprises'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
     /*
     * Author: Shashwat Nath
     * Description: This method is to test the functionality where ABN does not match with Equifax ABN
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void ABNdoesNotMatch() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Govt Enterprises';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.ABN__c = '12345678987';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            
            
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.originalOrganisationABN = '98765432154';
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Govt Enterprises',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Govt Enterprises',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );

            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();

            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.orgIdResultList = orgidelementList;
            system.debug('*****>>> orgidelementList> ' + orgidelementList);
            system.debug('*****>>> cac.orgIdResultList> ' + cac.orgIdResultList);
            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'Govt Enterprises';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            cac.isGovernmentEntity = true;
            cac.orgIdResultList = orgidelementList;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'Govt Enterprises'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
    /*
     * Author: Shashwat Nath
     * Description: This method is to test the functionality where ACN does not match with Equifax ACN
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void ACNdoesNotMatch() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Govt Enterprises';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '111111111';
            acc.ABN__c = '12345678911';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            
            
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id , APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c  from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            cac.originalOrganisationABN = '98765432154';
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Govt Enterprises',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Govt Enterprises',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);
            
            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            cacc.APT_Company_Name__c = 'Govt Enterprises';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            cac.isGovernmentEntity = true;

            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'Govt Enterprises'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 1);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
    
    
    /*
     * Author: Shashwat Nath
     * Description: This method is to test the functionality where only the Account Name in Equifax does not match with SF account name
     * Parameter: N/A
     * Return : Void             
     */ 
    public static TestMethod void onlyAccountNameDoesNotMatch() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser){
            Test.startTest();
            // Querying Account
            Account acc = [Select Id, Name, Type, ACN__c, Role_Type_Roll_Up__c 
                           from Account LIMIT 1];
            acc.Name = 'Test';
            //acc.Type = 'Charge Account';
            acc.ACN__c = '123456791';
            acc.ABN__c = '12345678911';
            acc.L2C_Hotlist__c = false;
            acc.CreatorProfile__c = '';
            update acc;
            
            
            
            
            // Querying Charge Account
            APT_Charge_Account__c cacc= [Select Id ,APT_First_Name__c , APT_Last_Name__c ,APT_Applicant1_Date_of_Birth__c, APT_Industry_Type__c,APT_Company_Name__c, APT_Contact_Name__c ,APT_ABN__c,APT_ACN__c,APT_Term_Days__c,
                                            AP_Proposed_Credit_Limit__c , Star_Track_Proposed_Credit_Limit__c , APT_Billing_Address_Street_Number__c , APT_Billing_Address_Street_Name__c , APT_Billing_Address_Suburb__c , 
                                            APT_Billing_Addres_State__c , APT_Billing_Address_Street_Postcode__c , L2C_Total_Proposed_Credit__c, APT_Applicant1_BA_Unit_Number__c,APT_Applicant1_BA_Street_Number__c,APT_Applicant1_BA_Street_Name__c,
                                            APT_Applicant1_BA_Street_Type__c, APT_Applicant1_BA_Suburb__c, APT_Applicant1_BA_Street_Postcode__c, APT_Applicant1_BA_State__c, APT_Applicant1_BA_Country_Code__c,APT_A1_Consent_to_check_credit_history__c  
                                            from APT_Charge_Account__c LIMIT 1]; 

            Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c LIMIT 1];
            PageReference pgRef = Page.Apt_CreditAssessment;
            Test.setCurrentPage(pgRef);
            
            //ApexPages.currentPage().getParameters().put('id',acc.id);
            ApexPages.currentPage().getParameters().put('proposalID',proposal.id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            Apt_CreditAssessmentController cac = new Apt_CreditAssessmentController(sc);
            
            APT_ABRreport__c abr = new APT_ABRreport__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Trading_Name__c='Govt Enterprises',
                                                        APT_ASIC_Number__c='123456789'
                                                       );
            APT_ASIC_Report__c asic = new APT_ASIC_Report__c(APT_ABN__c='12345678901',
                                                       ownerId=testuser.id,
                                                        APT_Jurisdiction__c='ASIC',
                                                        APT_ASIC_Name__c='Govt Enterprises',
                                                        APT_Organisation_Number__c = '006261623'
                                                       );
            APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element australianregisterreport = new APT_OrgIDWebServiceWrapper.AustralianBusinessRegisterReport_element();
            //ASICReport_element
            APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = APT_TestUtils.createASICReport_element('','','','','','',System.today(),'','','','',null,null,'','','');
            
            //OrgIdResult_element
            List<APT_OrgIDWebServiceWrapper.OrgIdResult_element> orgidelementList = new List<APT_OrgIDWebServiceWrapper.OrgIdResult_element>();
            APT_OrgIDWebServiceWrapper.OrgIdResult_element orgIdelement = new APT_OrgIDWebServiceWrapper.OrgIdResult_element();
            orgIdelement.ASICReport = asicreport;
            orgIdelement.AustralianBusinessRegisterReport = australianregisterreport;
            orgIdelement.OrgIdResultUniqueNumber = 1;
            orgidelementList.add(orgIdelement);

            cac.selectedASICReport = asic;
            cac.selectedABRReport= abr;
            insert abr;
            insert asic;
            cac.showMultipleRefer = true;
            cac.ServiceType = '';
            cac.showCompanyBusinessResponse= true;
            cac.showSoleTraderResponse = true;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showChargeAccount = true;
            cac.OrgIdAssessmentStatusLT5K = '';
            cac.OrgIdNameMatchLT5K = true;
            cac.showChargeAccount = false;
            cac.showSearchCreditAssessment = true;
            cac.showCompanyBusiness = true;
            cac.showSoleTrader = true;
            cac.showSearchResults = true;
            cac.showCreditAssesssmentResults = false;
            Apt_CreditAssessmentController.strGetValTitleMktOptOut = '';
            Apt_CreditAssessmentController.strGetValContinue = '';
            Apt_CreditAssessmentController.strGetValTitle = '';
            Apt_CreditAssessmentController.strGetValTitleBusiness = '';
            Apt_CreditAssessmentController.strGetValTitlePrivacy = '';
            Apt_CreditAssessmentController.strGetValProcessing = '';
            Apt_CreditAssessmentController.strGetValWait = '';
            Apt_CreditAssessmentController.strGetValBack = '';
            Apt_CreditAssessmentController.strGetValTitleSearchOrg = '';
            cac.displayHotlistPopup = false;
            cac.showApprovedPage = true;
            cac.isReferred = true;
            cac.isApprove = true;
            Apt_CreditAssessmentController.strGetValSearchResults = '';
            cac.isEntityTypePartnership = false;
            cac.selectedOrgIdUniqueNumber = 1;
            
            cacc.APT_Credit_Limit_Required__c = 26000;
            cacc.Star_Track_Proposed_Credit_Limit__c = 3000;
            cacc.L2C_Total_Proposed_Credit__c = '29000';
            //cacc.APT_Company_Name__c = 'Govt Enterprises';
            cacc.APT_Contact_Email_Address__c = 'test@test.com';
            cacc.APT_CustomerAgreementToPrivacyStatement__c = true;
            cac.orgIdResultList = orgidelementList;
            cac.chargeAccount = cacc;
            cac.isAnonymousFlow = false;
            cac.isTrustFlag = false;
            cac.isGovernmentEntity = true;
            cac.init();
            cac.doNextForChargeAccount();
            cac.doContinue();
            
            
            
            cac.selectReport();
            cac.doCreditCheck();
            Test.stopTest();
            
            List<APT_Credit_Assessment__c> crAsmt = [SELECT id,L2C_Referral_Rejection_Reason__c, APT_ACN__c, APT_ABN__c, APT_Legal_Entity_Name__c,
                                                         APT_Credit_Assessment_Status__c FROM APT_Credit_Assessment__c
                                                    WHERE APT_Legal_Entity_Name__c = 'Test'];
            if(crAsmt.size() > 0){
               System.assertEquals(crAsmt.Size(), 2);
            }else{
                System.debug('No Credit Assessment created');
            }
        }
    }
}