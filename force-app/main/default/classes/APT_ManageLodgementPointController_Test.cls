/**
Description - This class is test class for APT_ManageLodgementPointController.
Created By - Raviteja Epuri
Created Date - 18th Dec, 2015
Last Modified By -
Last Modified Date - 
 */

@isTest //(seeAllData = true)
public class APT_ManageLodgementPointController_Test {
    private static Apttus_Config2__ProductConfiguration__c prodcon;
    private static Apttus_Config2__LineItem__c lineItem;
    private static APT_Agreement_Lodgement_Point__c aptlodg;
    private static Network__c ntwk;
    private  static Network__c ntwk1;
    private static String source ='lineItembtn';
    private static APT_Default_Billing_Account_Products__c billingAccountCustomSetting;
    private static Product2 bundle1;
    private static Apttus_Proposal__Proposal__c Proposal;
       
            
    //Creating test data
    private static void createTestData(){
            
            //Create NetworkInterface
            List<Network__c> lstNw = new List<Network__c>();
                Network__c aptNw = APT_TestUtils.createNetwork();
                aptnw.Post_Code__c = '2586';
                aptnw.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Delivery').getRecordTypeId();
                aptnw.Status__c = 'Open';
                aptnw.APT_Apttus_LP__c = true;
                lstNw.add(aptNw);
                
                Network__c aptNw1 = APT_TestUtils.createNetwork();
                aptnw1.Name = 'Lodgement point 2';
                aptnw1.Post_Code__c = '2486';
                aptnw1.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Retail').getRecordTypeId();
                aptnw1.Status__c = 'Open';
                aptnw1.APT_Apttus_LP__c = true;
                aptnw1.Org_ID__c = 'A1pOMJJ0QXeb';
                aptnw1.APT_DWS_ID__c = 'A1pOMJJ0QXeb';
                lstNw.add(aptNw1);
                
                Network__c aptNw2 = APT_TestUtils.createNetwork();
                aptNw2.Name = 'Lodgement point 2';
                aptNw2.Post_Code__c = '2486';
                aptNw2.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Business Hub').getRecordTypeId();
                aptNw2.Status__c = 'Open';
                aptNw2.APT_Apttus_LP__c = true;
                aptNw2.Org_ID__c = 'A1pOMJJ0QXec';
                aptNw2.APT_DWS_ID__c = 'A1pOMJJ0QXec';
                lstNw.add(aptNw2);
              
                Network__c aptNw3 = APT_TestUtils.createNetwork();
                aptNw3.Name = 'Lodgement point 2';
                aptNw3.Post_Code__c = '2486';
                aptNw3.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Business Hub').getRecordTypeId();
                aptNw3.Status__c = 'Open';
                aptNw3.APT_Apttus_LP__c = true;
                aptNw3.Org_ID__c = '272786';
                aptNw3.State__c = 'ACT';
                aptNw3.APT_Business_Unit__c = 'Postal Delivery';
                lstNw.add(aptNw3);

            insert lstNw;
            
            System.Debug(logginglevel.error,'$$$$$$$'+[Select id from RecordType where DeveloperName in ('Delivery_1','Retail_2','Business_Hub_3')]);
            ntwk = aptNw;
            ntwk1= aptNw1;
            //Create contact
            Contact con = APT_TestUtils.createContact();     
            insert con; 

            //Create Account
             RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
            Account acc = APT_TestUtils.createOrganisation();
            acc.Name = 'Temporary Customer';
            acc.AccountNumber = 'Cus 60000000';
            acc.RecordTypeId = rectype.ID;
            acc.Legacy_Id__c = '60000000';
            insert acc;
            System.Debug('******************'+[SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1]);

            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            
            insert opty;

            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;

            //create international product
            bundle1 = APT_TestUtils.createInternationalProduct('eParcel','APOST001','Postal Services');
            insert bundle1;
            
            
            //APT_Default_Billing_Account_Products__c
            billingAccountCustomSetting = new APT_Default_Billing_Account_Products__c();
            billingAccountCustomSetting.Name = bundle1.Name;
            insert billingAccountCustomSetting;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Billing Account
            //List<Billing_Account__c> billacclist = [Select Id, name from Billing_Account__c limit 1];
            Billing_Account__c billacc = APT_TestUtils.createBillingAccount(acc.id);
            //insert billacc;
            
            //Create Agreement
            Apttus__APTS_Agreement__c agID = APT_TestUtils.createAgreement(con.id);
            agID.Name = 'agId';
            //agID.Billing_Account__c = billacc.ID;
            agID.Apttus__Account__c = acc.id;
            insert agID;
            
            
            
            //Create Lodgement Zone
            APT_Lodgement_Zone__c lodZone= APT_TestUtils.getLodgementZone('Lodgement','Test');
            lodZone.APT_Post_Code_End__c = 3000;
            lodZone.APT_Post_Code_Start__c = 2158;
            insert lodZone;
            
            //Create Lodgement Point
            APT_Agreement_Lodgement_Point__c  objLp = new APT_Agreement_Lodgement_Point__c();
            objLp.APT_Status__c = 'Active';
            objLp.APT_Agreement__c = agID.id;
            objLp.APT_Address__c = 'australia';
            objLp.APT_eParcel_Enabled__c = 'Yes';
            objLp.APT_Transport_Capability__c = 'VAN Only';
            objLp.APT_Organisation_ID__c = 'ORG123';
            objLp.APT_Lodgement_Point_Lookup__c= aptNw.id;
            objLp.APT_Organisation__c = acc.id;
            objLp.APT_Lodgement_Zone_Lookup__c= lodZone.id;
            objLp.APT_DWS_ID__c = 'DwS12';
            objLp.APT_Selected_Lodgement_Point__c = objLp.Name;
            objLp.APT_LP_Post_Code__c = 'Pcode';
            objLp.APT_Lodgement_Zone__c = 'LZoone';
            objLp.APT_Product__c = 'Promo Post';
            //objLp.APT_Billing_Account__c = billacc.ID;
            objLp.APT_Outlet_Type__c = 'OType';
            insert objLp; 
            
            aptlodg = objLp;
            
            //Create Proposal
            Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            Proposal.APT_Selected_LP__c = aptNw2.ID + ',' + aptNw1.ID + '~' ;//+ billacc.ID;
            //Proposal.APT_Selected_LP__c = aptNw1.ID + '~' + 'a0FO000000858lD';
            
            insert Proposal;

            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            insert prodconfig;
            
            prodcon = prodconfig;
            
            //Create Temp Obj
            Apttus_Config2__TempObject__c tmp = new Apttus_Config2__TempObject__c();
            tmp.Apttus_Config2__ConfigurationId__c  = prodconfig.id;
            insert tmp;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,1, 'Product/Service',
            bundle1.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, pli.Id,'One Time','Per Unit','Standard Price','One Time',
            true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.APT_Selected_LP__c = aptNw2.ID + ',' + aptNw1.ID + '~'; //+ billacc.ID;
            //bundleLine.APT_Selected_LP__c = aptNw1.ID + '~' + 'a0FO000000858lD';
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            //bundleLine.APT_Billing_Account__c = billacc.ID;
            insert bundleLine;
            
            Set<ID> setLineItem = new Set<ID>();
            setLineItem.add(bundleLine.id);
            lineItem = bundleLine;
            
            //List of LI
            List<Apttus_Config2__LineItem__c> lstLI = new List<Apttus_Config2__LineItem__c>();
                Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,1, 'Product/Service',
                bundle1.Id, true, null,null,null,null, 1, true,'Each',1, priceList.Id, pli.Id,'One Time','Per Unit','Standard Price','One Time',
                true, true, 5500, 5500, 'Per Unit',5225, 0, 5225, 'TestaPTTUS');
                bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
                bundleLine1.Apttus_Config2__NetPrice__c = 5225;
                bundleLine1.Apttus_Config2__IsPrimaryLine__c = True;
               // bundleLine1.APT_Selected_LP__c = billacc.ID + ',' + billacc.ID + '~' + billacc.ID;
                bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
                bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
                //bundleLine.APT_Billing_Account__c = billacc.ID;
            lstLI.add(bundleLine1);
            insert lstLI;
            
            //Map of LI
            Map<Id,Apttus_Config2__LineItem__c > mapLI = new Map<Id,Apttus_Config2__LineItem__c >();
            mapLI.put(bundleLine.id,bundleLine);
            
            //Create AgreementLineitem
            Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
            ali.Apttus_CMConfig__ItemSequence__c = 1;
            ali.Apttus_CMConfig__LineNumber__c = 1;
            ali.Apttus_CMConfig__BillToAccountId__c= acc.id;
            ali.Apttus__AgreementId__c = agID.ID;
            ali.Apttus__ProductId__c = bundle1.ID;
            ali.Apttus_CMConfig__IsPrimaryLine__c = True;
            ali.Apttus_CMConfig__LineType__c = 'Product/Service';
            ali.Apttus_CMConfig__DerivedFromId__c = bundleLine.id;
            insert ali;
                    
            //Create PromoPost Lodgement
            list<APT_Promo_Post_allowed_Lodgements__c> lstpromo = new List<APT_Promo_Post_allowed_Lodgements__c>();
            APT_Promo_Post_allowed_Lodgements__c objPromo = new  APT_Promo_Post_allowed_Lodgements__c();
            objPromo.Name = 'Promo';
            objPromo.APT_Post_code__c = '2586';
            lstpromo.add(objPromo);
            //insert objPromo;
            
            APT_Promo_Post_allowed_Lodgements__c objPromo1 = new  APT_Promo_Post_allowed_Lodgements__c();
            objPromo1.Name = 'Promo 2';
            objPromo1.APT_Post_code__c = '2486';
            lstpromo.add(objPromo1);
            
            insert lstpromo;
            
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            
            //Create custom setting systemSettings 
            //SystemSettings__c systemSettings = APT_TestUtils.createSystemSettings();
           // systemSettings.Loglevel_Info__c = false;
           // insert systemSettings;
                
            
            
            //Create Product Attribute Value
            Apttus_Config2__ProductAttributeValue__c objPAV = APT_TestUtils.GetAttributeValue(bundleLine.id,'',true,true,true,'kg','textile',false,false);
            objPAV.APT_Lodgement_State__c = 'ACT'; 
            objPAV.APT_Lodgement_Zone__c = lodZone.id; 
            objPAV.APT_Postcode__c ='25';
            insert objPAV;
           
    }
    
    
    
    //Creating test data
    static testMethod void testMethod1() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                //Network__c dispNetwork = [Select id,Name,Post_Code__c,State__c,Business_Unit__c,APT_eParcel_Enabled__c,APT_Comments__c,Org_ID__c,APT_DWS_ID__c,Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where Post_Code__c >='21' AND Post_Code__c <='33'];
               // System.Debug(logginglevel.error,'dispNetwork   '+ dispNetwork);
               // System.Debug(logginglevel.error,'ntwk   '+ ntwk);
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.recordsperpage = 10;
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Lodgement';
                
               // manageLPCntrlr.offSetVal = 5;
                manageLPCntrlr.SearchLP();
                //manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.recordsperpage = 2200;
                manageLPCntrlr.offSetVal = 1100;
                manageLPCntrlr.goNext();
                manageLPCntrlr.searchRecCount = 2300;
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                //update manageLPCntrlr.listLodgementPointWrapper;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = '';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                Apexpages.currentPage().getParameters().put('deleteLodgementPointId',ntwk1.Id);
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                manageLPCntrlr.SearchLP();
                
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
                //manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    
        //Creating test data
    static testMethod void testMethod2() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('deleteLodgementPointId',aptlodg.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                PageReference pgRef = manageLPCntrlr.DeleteLP();
                
            Test.stopTest();
            system.assert(pgRef == null);
        }
    }
    //Creating test data
    static testMethod void testMethod3() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                List<APT_Lodgement_Zone__c> lstLZ = [select id,name,APT_Post_Code_Start__c,APT_Post_Code_End__c from APT_Lodgement_Zone__c limit 1000];                  
                System.debug(logginglevel.error,' lstLZ  ' + lstLZ);
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Lodgement';
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                if( manageLPCntrlr.listLodgementPointWrapper.get(0) != null)
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = '';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                Apexpages.currentPage().getParameters().put('deleteLodgementPointId',ntwk1.Id);
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList =manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
               // manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            System.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    static testMethod void testMethod4() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            ntwk.Post_Code__c= null;
            //ntwk.State__c = 'None';

            // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
            ntwk.APT_Business_Unit__c = 'None';
            ntwk.Business_Unit__c = 'None';
            ntwk.APT_eParcel_Enabled__c = Null;
            ntwk.APT_Transport_Capability__c = Null;
            update ntwk;
            
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval = 'None';
                manageLPCntrlr.bussinessUnit = 'None';
                manageLPCntrlr.domesticLodgementZone = 'None';
                manageLPCntrlr.SearchLP();
                 manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
              //  manageLPCntrlr1.Network = ntwk;
        
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    static testMethod void testMethod5() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                lineItem.APT_Billing_Account__c = Null;
                lineItem.APT_Selected_LP__c = null;
                Update lineItem;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                manageLPCntrlr.billingacc = 'Billing';
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.AddLP();
                
                manageLPCntrlr.showallLodgementpoints();
                Apexpages.currentPage().getParameters().put('deleteLodgementPointId',ntwk1.Id);
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                manageLPCntrlr.getBussinessPickval();
                PageReference pgRef = manageLPCntrlr.SearchLP();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
                //manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            System.assert(pgRef == null);
        }
    }
    //Creating test data
    static testMethod void testMethod6() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            ntwk.Post_Code__c= '3523';
            update ntwk;
            
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
               manageLPCntrlr.SearchLP();
                 manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
               // manageLPCntrlr1.Network = ntwk;
        
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    //Creating test data
     static testMethod void testMethod7() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('Promo Post');
            bundle1.Name = 'Promo Post';
            System.debug(logginglevel.error, ' ** Bundle1 name ' + bundle1);
            Test.startTest(); 
           
            update bundle1;
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                //Network__c dispNetwork = [Select id,Name,Post_Code__c,State__c,Business_Unit__c,APT_eParcel_Enabled__c,APT_Comments__c,Org_ID__c,APT_DWS_ID__c,Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where Post_Code__c >='21' AND Post_Code__c <='33'];
                //System.Debug(logginglevel.error,'dispNetwork   '+ dispNetwork);
                //System.Debug(logginglevel.error,'ntwk   '+ ntwk);
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                //manageLPCntrlr.recordsperpage = 10;
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                
               // manageLPCntrlr.offSetVal = 5;
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.recordsperpage = 2200;
                manageLPCntrlr.offSetVal = 1100;
                manageLPCntrlr.goNext();
                manageLPCntrlr.searchRecCount = 2300;
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id);
                
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                Apexpages.currentPage().getParameters().put('deleteLodgementPointId',ntwk1.Id);
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                //APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
                //manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    static testMethod void testMethod8() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();  
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                //Network__c dispNetwork = [Select id,Name,Post_Code__c,State__c,Business_Unit__c,APT_eParcel_Enabled__c,APT_Comments__c,Org_ID__c,APT_DWS_ID__c,Network_Address__c,APT_Transport_Capability__c,APT_MCAT__c,APT_Threshold_Categories__c from Network__c where Post_Code__c >='21' AND Post_Code__c <='33'];
               // System.Debug(logginglevel.error,'dispNetwork   '+ dispNetwork);
               // System.Debug(logginglevel.error,'ntwk   '+ ntwk);
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.recordsperpage = 10;
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                
               // manageLPCntrlr.offSetVal = 5;
                manageLPCntrlr.SearchLP();
                //manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.recordsperpage = 2200;
                manageLPCntrlr.offSetVal = 1100;
                manageLPCntrlr.goNext();
                manageLPCntrlr.searchRecCount = 2300;
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                //update manageLPCntrlr.listLodgementPointWrapper;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = 'Billing';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
                //manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            System.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    static testMethod void testMethod9() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',lineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                lineItem.APT_Billing_Account__c = Null;
                lineItem.APT_Selected_LP__c = null;
                Update lineItem;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                manageLPCntrlr.billingacc = '';
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.AddLP();
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
                //manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    static testMethod void testMethod10() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('Promo Post');
            bundle1.Name = 'Promo Post';
            System.debug(logginglevel.error, ' ** Bundle1 name ' + bundle1);
            Test.startTest();
            update bundle1;
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                if(manageLPCntrlr.listLodgementPointWrapper != null && manageLPCntrlr.listLodgementPointWrapper.size() > 0 && manageLPCntrlr.listLodgementPointWrapper.get(0) != null)
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = '';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
             //   APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
             //   manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            System.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    private static testMethod void testMethod11() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();   
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                if(manageLPCntrlr.listLodgementPointWrapper != null && manageLPCntrlr.listLodgementPointWrapper.size() > 0 && manageLPCntrlr.listLodgementPointWrapper.get(0) != null)
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = 'Billing';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
               // APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
               // manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            System.assert(tempList.size() > 0);
        }
    }
    //Creating test data
    private static testMethod void testMethod12() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                manageLPCntrlr.quote.APT_Selected_LP__c = null;
                if(manageLPCntrlr.listLodgementPointWrapper != null && manageLPCntrlr.listLodgementPointWrapper.size() > 0 && manageLPCntrlr.listLodgementPointWrapper.get(0) != null)
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = 'Billing';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
              //  APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
              //  manageLPCntrlr1.Network = ntwk;
                
               
            Test.stopTest();
             System.assert(tempList.size() > 0);
        }
    }
    //Creating test data
     private static testMethod void testMethod13() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Test';
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.goNext();
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }
                manageLPCntrlr.quote.APT_Selected_LP__c = null;
                if(manageLPCntrlr.listLodgementPointWrapper != null && manageLPCntrlr.listLodgementPointWrapper.size() > 0 && manageLPCntrlr.listLodgementPointWrapper.get(0) != null)
                manageLPCntrlr.listLodgementPointWrapper.get(0).IsSelected = true;
                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.billingacc = '';
                manageLPCntrlr.AddLP();
                manageLPCntrlr.showallLodgementpoints();
                manageLPCntrlr.DeleteLP();
                manageLPCntrlr.backToCart();
                List<SelectOption> tempList = manageLPCntrlr.getBussinessPickval();
                
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
              //  APT_ManageLodgementPointController manageLPCntrlr1 = new APT_ManageLodgementPointController();
               // manageLPCntrlr1.Network = ntwk;
                
                
            Test.stopTest();
            system.assert(tempList.size() > 0);
        }
    }
    
    //Creating test data
    private static TestMethod void testMethod14() {
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {     
            //create pricelist
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            List<APT_R2T_System_Properties__c> sysPropDel = [select ID from APT_R2T_System_Properties__c];
            Delete sysPropDel;
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.ID);
            r2tSystemProperties.APT_Enable_Classic_UI__c = true;
            insert r2tSystemProperties;
            
            //APT_ManageLodgementPointController.backToCart();
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.backToCart();
                
            Test.StopTest();
        }
    }
    //Creating test data
    private static TestMethod void testMethod15() {
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {    
            //create pricelist
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            List<APT_R2T_System_Properties__c> sysPropDel = [select ID from APT_R2T_System_Properties__c];
            Delete sysPropDel;
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.ID);
            //r2tSystemProperties.APT_Enable_Classic_UI__c = true;
            insert r2tSystemProperties;
            
            //APT_ManageLodgementPointController.backToCart();
            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('International Bundle');
            Test.startTest(); 
                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',null);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');
                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.backToCart();
                
            Test.StopTest();
        }    
    }

    //Creating test data
    static testMethod void testMethod16() {       
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);

        System.runAs(testuser) {

            createTestData();
            Set<String> setProductNames = new Set<String>();
            setProductNames.add('Track Mail');

            Apttus_Config2__LineItem__c tmLineItem = [SELECT Id, Apttus_Config2__ProductId__c  from Apttus_Config2__LineItem__c LIMIT 1]; 
            tmLineItem.Apttus_Config2__ProductId__c = '01t90000007BTm0AAG';
            update tmLineItem;

            Test.startTest(); 

                Apexpages.currentpage().getparameters().put('Id',prodcon.Id);
                Apexpages.currentpage().getparameters().put('lineItemId',tmLineItem.Id);
                ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');

                APT_ManageLodgementPointController manageLPCntrlr = new APT_ManageLodgementPointController();
                manageLPCntrlr.Network = ntwk;
                manageLPCntrlr.getdomesticLodgementZoneVal();
                manageLPCntrlr.recordsperpage = 10;
                manageLPCntrlr.stateval= 'ACT';
                manageLPCntrlr.bussinessUnit = 'Bussiness';
                manageLPCntrlr.domesticLodgementZone = 'Lodgement';
                
                manageLPCntrlr.SearchLP();
                manageLPCntrlr.searchLPButton();
                manageLPCntrlr.recordsperpage = 2200;
                manageLPCntrlr.offSetVal = 1100;
                manageLPCntrlr.goNext();
                manageLPCntrlr.searchRecCount = 2300;
                manageLPCntrlr.goLast();
                manageLPCntrlr.getstatePickval();
                
                try {
                    manageLPCntrlr.goPrevious();
                }catch(Exception ex) {
                    System.debug('***ex.getMessage()'+ ex.getMessage());
                }

                Apexpages.currentPage().getParameters().put('selectedLodgementPointId',ntwk.Id); 
                manageLPCntrlr.SearchLP();
                
            Test.stopTest();
            system.assert(manageLPCntrlr.listLodgementPointWrapper != null);
        }
    }
}