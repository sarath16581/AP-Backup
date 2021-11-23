/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class APMSApplicationTest 
{
    // 2014-08-22 Louis Wang (Bluewolf)
    //    This class provides test coverage for Application visualforce page and APMSApplication controller
    //    Note:  Need to use SeeAllData, as there is one account record with legacyId='60000000' used by 
    //           trigger that is not easy to create as test data.

    static user testUser_SiteUser;
    static string httpsRedirect;
    static Account acct;
    static Billing_Account__c bacct;
  
    static
    {
        APMSSetting__c configSetting = APMSSetting__c.getInstance();
        httpsRedirect = configSetting.HttpsRedirection__c;
       
        acct = new Account();
        acct.Name = 'Test Account';
        acct.ACN__c = '123456789';
        insert acct;
        
        bacct = new Billing_Account__c();
        bacct.Legacy_Id__c = '123';
        bacct.Organisation__c = acct.Id;
        insert bacct;               
    }

    @isTest(SeeAllData=true)
    static void startNewApplication_Test() 
    {
        Application__c app = new Application__c();
        
        // run through codes that are relevant to Landing 
        PageReference landingPage = Page.Application;
        Test.setCurrentPage(landingPage); 
        ApexPages.StandardController stdApp = new ApexPages.StandardController(app);
        ApmsApplication apms = new ApmsApplication(stdApp);

        // run through picklist value fetcher
        apms.getOrganisationType();
        apms.getIndustryType();
        apms.getContactPositionTitle();
        apms.getPrincipal1PositionTitle();
        apms.getPrincipal2PositionTitle();
        apms.getShoppingCart();
        apms.getDateBusinessCommencedMonth();
        apms.getLocationState();
        //apms.getSelectedPricePlan();
        apms.getIsGSTRegistered();
        apms.getIsBusinessATrust();
        apms.getPrincipal1Premises();
        apms.getPrincipal2Premises();
        apms.getIsExistingAPMSMerchantID();
        apms.getIsExistingSecurePayMerchantId();
        apms.getOptforMulticurrency();
        apms.getIsMerchantFacilityTerminatedPreviously();
        apms.getIsMerchantFacilityWithAnotherProvider();
        apms.getIsMainBusinessOperatedInAustralia();
        apms.getIsMerchantFacilityToBeUsedByOthers();
        apms.getIsYourSystemsMonitorCCTransactions();
        apms.getIsProcessPaymentsForAnotherBusiness();
        apms.getHowDoYouFindUs();
        
        // get Address strings
        apms.getLocationAddress();
        apms.getPostalAddress();
        apms.getROLocationAddress();
        apms.getROPostalAddress();
        apms.getROPrincipal1Address();
        apms.getROPrincipal2Address();
        
        // Flip states for dynamical rendering
        apms.resetForNewAndOld();
        apms.ShowHideContactPositionOther();
        apms.ShowHidePrincipal1PositionOther();
        apms.ShowHidePrincipal2PositionOther();
        apms.ShowHideShoppingCartOther();
        apms.ShowHideSecurePayMerchant();
        apms.showHideMulticurrencyFields();
        apms.ShowHideTrustee();
        apms.app.IsMailingDiffToLocation__c = true;
        apms.diffToLocationReset();
        apms.app.IsMailingDiffToLocation__c = false;
        apms.diffToLocationReset();
        
        // start a new application
        apms.app.SelectedPricePlan__c = '';
        apms.Start_NewAccount();
        apms.app.SelectedPricePlan__c = 'Launch Price';
        apms.Start_NewAccount();
        
        // navigation between pages
        apms.getHasNextButton();
        apms.getHasPrevButton();
        apms.prevSection();
        apms.nextSection();
        
        // section 1 validaiton
        apms.app.DateBusinessCommencedYear__c = '1';
        apms.app.DateBusinessCommencedMonth__c = '01';
        apms.nextSection();
        apms.app.DateBusinessCommencedYear__c = '1111';
        apms.nextSection();
        apms.app.DateBusinessCommencedYear__c = '2000';
        apms.nextSection();   
        apms.prevSection();   
        
        apms.app.ACN__c = '1';
        apms.nextSection();
        apms.app.ACN__c = '123456789';
        apms.nextSection();
        apms.prevSection();
          
        apms.app.ABN__c = '1';
        apms.nextSection(); 
        apms.app.ABN__c = '12345678901';
        apms.nextSection();
        apms.prevSection();
          
        apms.businessDesc = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        apms.businessDesc +=  '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        apms.businessDesc +=  '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        apms.nextSection();
        apms.businessDesc = 'Test Desc.';
        apms.nextSection();
        apms.prevSection();
        
        apms.app.OrganisationType__c = 'sole trader';
        apms.nextSection();
        apms.prevSection();
        
        apms.fetchedApp = null;
        apms.nextSection();
                
        // section 2 validation
        apms.principal1DOB = '1';
        apms.nextSection();
        apms.principal1DOB = '13/13/2000';
        apms.nextSection();
        apms.principal1DOB = '11/11/1990';
        apms.nextSection();        
        apms.prevSection();

        apms.principal2DOB = '1';
        apms.nextSection();
        apms.principal2DOB = '13/13/2000';
        apms.nextSection();
        apms.principal2DOB = '11/11/1990';
        apms.nextSection();        
        apms.prevSection();

        apms.contactPhone = '@';
        apms.nextSection();
        apms.contactPhone = '@123456789';
        apms.nextSection();
        apms.contactPhone = '1234567890';
        apms.nextSection();
        apms.prevSection();

        apms.contactMobile = '@';
        apms.nextSection();
        apms.contactMobile = '@123456789';
        apms.nextSection();
        apms.contactMobile = '1234567890';
        apms.nextSection();
        apms.prevSection();

        apms.contactFax = '@';
        apms.nextSection();
        apms.contactFax = '@123456789';
        apms.nextSection();
        apms.contactFax = '1234567890';
        apms.nextSection();
        apms.prevSection();
        
        apms.app.isPrincipal2AuthorisedSignatory__c = true;
        apms.nextSection();
        apms.prevSection();
        apms.app.isPrincipal2AuthorisedSignatory__c = false;
        apms.nextSection();
        
        // section 3 validation
        apms.app.isExistingSecurePayMerchantId__c = 'Yes';
        apms.nextSection();
        apms.app.isExistingAPMSMerchantId__c = '123';
        apms.app.CCChargedInAdvancePercentage__c = decimal.valueOf('0');
        apms.app.CCSameDayProcessingPercentage__c = decimal.valueOf('0');
        apms.app.CCChargedInArrearsPercentage__c = decimal.valueOf('100');
        apms.nextSection();
        apms.prevSection();
        
        apms.app.NameOnCCStatement__c ='@';
        apms.nextSection();
        apms.app.NameOnCCStatement__c ='Tester';
        apms.nextSection();
        apms.prevSection();
        
        apms.app.CCChargedInAdvancePercentage__c = decimal.valueOf('10');
        apms.nextSection();
        apms.app.CCChargedInAdvanceDaysInAdvance__c = decimal.valueOf('5');
        apms.nextSection();
        apms.app.CCSameDayProcessingPercentage__c = decimal.valueOf('40');
        apms.app.CCChargedInArrearsPercentage__c = decimal.valueOf('50');
        apms.nextSection();
        apms.prevSection();

        apms.app.isExistingSecurePayMerchantID__c = 'No';
        apms.app.Opt_for_Multicurrency__c = 'Yes';
        apms.app.Avg_Foreign_Currency_Transaction_Value__c = 1000;
        apms.app.Avg_Foreign_Currency_Transactions_Mthly__c = 50000;
        apms.app.Annual_Foreign_Currency_Turnover__c =150000;
        apms.nextSection();
        apms.prevSection();
        
        apms.getHasSubmitButton();
        apms.getHasNextButton();
        apms.nextSection();
        apms.getHasSubmitButton();
        apms.getHasNextButton();
    }

    @isTest(SeeAllData=true)
    static void startExistingApplication_Test() 
    {
        Application__c app = new Application__c();
        
        // run through codes that are relevant to Landing 
        PageReference landingPage = Page.Application;
        Test.setCurrentPage(landingPage); 
        ApexPages.StandardController stdApp = new ApexPages.StandardController(app);
        ApmsApplication apms = new ApmsApplication(stdApp);
    
        apms.app.APCustomerNumber__c = '';
        apms.Start_ExistingAccount();
        apms.app.APCustomerNumber__c = '1';
        apms.Start_ExistingAccount();
        apms.InputAbnOrAcn = '123456789';
        apms.Start_ExistingAccount();
        apms.app.APCustomerNumber__c = '12345678901';
        apms.Start_ExistingAccount();
        apms.app.APCustomerNumber__c = '123';
        apms.Start_ExistingAccount();
        apms.prevSection();
        apms.app.SelectedPricePlan__c = '';
        apms.Start_ExistingAccount();
        apms.app.SelectedPricePlan__c = 'Launch Price';
        apms.Start_ExistingAccount();
        apms.prevSection();
        apms.InputAbnOrAcn = '123';
        apms.Start_ExistingAccount();
        apms.InputAbnOrAcn = '123456789';
        apms.Start_ExistingAccount();

        // section 1
        apms.app.OrganisationType__c = 'sole trader';
        apms.fetchedApp.LocationStreet__c = 'N/A';
        apms.fetchedApp.PostalStreet__c = 'N/A';
        apms.nextSection();
    }

    @isTest(SeeAllData=true)
    static void saveApplication_Test() 
    {
        Application__c app = new Application__c();
        
        // run through codes that are relevant to Landing 
        PageReference landingPage = Page.Application;
        Test.setCurrentPage(landingPage); 
        ApexPages.StandardController stdApp = new ApexPages.StandardController(app);
        ApmsApplication apms = new ApmsApplication(stdApp);
        
        // set minimal mandatory fields to save records
        Test.startTest();
        apms.saveApp();
        // set consent checkbox to true to finish the submit
        apms.app.isConsentReadAndAccept__c = true;
        apms.saveApp();

        apms.app.FullLegalCompanyName__c = 'Test Account';
        apms.saveApp();
        
        apms.app.IsMailingDiffToLocation__c = true;
        apms.saveApp();
        
        apms.app.LocationStreet__c = 'N/A';
        apms.app.PostalStreet__c = 'N/A';
        apms.app.ContactLastName__c = 'Tester';
        apms.saveApp();
        
        apms.SaveAppFeedback();
        Test.stopTest();
    }        
}