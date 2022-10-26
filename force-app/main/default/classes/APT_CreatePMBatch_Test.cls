/***
 * @author Darshan Chauhan
 * @date 2021-03-01
 * @group 
 * @description Tests the execution of the batch class APT_CreatePMBatch which creates the Price Matrixes for the relevant PLI's
 * @changelog
 * 2021-04-01 - Darshan Chauhan - Created
 * 2021-05-01 - Mathew Jose - Created test methods to test missing scenarios.
 * 2021-09-23 - Mathew Jose - Added test methods test the simplified parcel products (Appc Speed & FSR)

*/
@isTest
public with sharing class APT_CreatePMBatch_Test {
    public static final string TEST_STARTRACK_PRODUCT_TYPE = 'Startrack';
    public static final string TEST_DOMESTIC_PRODUCT_TYPE = 'Domestic_Non_Startrack';
    public static final string TEST_International_PRODUCT_TYPE = 'International';
    public static final string TEST_DOMESTIC_PARCEL_CONTRACT_PRODUCT_TYPE = 'Domestic_Simplified_Parcel_Contract';
    public static final string TEST_DOMESTIC_FSR_PRODUCT_TYPE = 'Domestic_Simplified_Features_Surcharges';      

    @TestSetup
    static void createData(){
        
        //Domestic (non startrack) product
        Product2 productCAT1STD = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'STANDARD');
        productCAT1STD.APT_Domestic_Pricing__c = true;
        insert productCAT1STD;
        //Startrack Product
        Product2 productNXF = APT_TestUtils.createStarTrackProduct('Next Flight Tier 1', 'NextFlightTier1', 'Parcel Services', 'T01', 'NXF', 'Startrack');
        productNXF.APT_Domestic_Pricing__c = true;
        insert productNXF;
        Product2 productEXP = APT_TestUtils.createStarTrackProduct('Road Express', 'RoadExpress', 'Parcel Services', 'T01', 'EXP', 'Startrack');
        productEXP.APT_Domestic_Pricing__c = true;
        insert productEXP;
        //International product 1
        Product2 productAIRLET = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        productAIRLET.APT_International_Pricing__c = true;
        insert productAIRLET;
        //APPC Speed Product 
        Product2 product_APPC_SPEED1 = APT_TestUtils.createDomesticProduct('Tier4 Standard Capital', 'PDSP00_Capital', 'Parcel Services', 'T04','Standard');
        product_APPC_SPEED1.APT_Domestic_Pricing__c = true;
        product_APPC_SPEED1.APT_Product_type__c = 'Parcel Contract';
        insert product_APPC_SPEED1;                      
        //APPC FSR Product 
        Product2 product_APPC_FSR1 = APT_TestUtils.createDomesticProduct('Premium Express Parcel Transit Cover', 'FSR1', 'Parcel Services', 'T04','Standard');
        product_APPC_FSR1.APT_Product_type__c = 'Parcel Contract-Feature';
        insert product_APPC_FSR1;  

        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
        //pli for productCAT1STD
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,productCAT1STD.id,'','');
        priceListItem.APT_Pricing_Key__c = productCAT1STD.Id + '~' + 'BANDED {Z6}' + '~' + 'CB';
        priceListItem.APT_Price_Structure__c = 'BANDED {Z6}';
        priceListItemList.add(priceListItem);
        //pli for product NXF
        Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id,productNXF.id,'','');
        priceListItem2.APT_Pricing_Key__c = productNXF.Id;
        priceListItem2.APT_Zone_Combination__c = productNXF.Id;
        priceListItemList.add(priceListItem2);
        //pli for EXP 1
        Apttus_Config2__PriceListItem__c priceListItem3 = APT_TestUtils.createPriceListItem(priceList.id,productEXP.id,'','');
        priceListItem3.APT_Pricing_Key__c = productEXP.Id+'~'+'QC3';
        priceListItem3.APT_Zone_Combination__c = productEXP.Id +'~QC3~Direct-QC3';
        priceListItemList.add(priceListItem3);             
        //pli for AIRLET
        Apttus_Config2__PriceListItem__c priceListItem4 = APT_TestUtils.createPriceListItem(priceList.id,productAIRLET.id,'','');
        priceListItem4.APT_Pricing_Key__c = productAIRLET.Id + '~' + productAIRLET.Productcode+'~'+'BAND 1';
        priceListItemList.add(priceListItem4);
        //pli for APPC SPEED
        Apttus_Config2__PriceListItem__c priceListItem5 = APT_TestUtils.createPriceListItem(priceList.id,product_APPC_SPEED1.id,'','');
        priceListItem5.APT_Pricing_Key__c = product_APPC_SPEED1.Id + '~' + 'Z6';
        priceListItem5.APT_Price_Structure__c = 'Z6';
        priceListItemList.add(priceListItem5); 
        
        //pli for APPC FSR
        Apttus_Config2__PriceListItem__c priceListItem6 = APT_TestUtils.createPriceListItem(priceList.id,product_APPC_FSR1.id,'','');
        priceListItem6.APT_Pricing_Key__c = product_APPC_FSR1.Id + '~' + 'Parcel Contract-Feature';
        priceListItemList.add(priceListItem6);          

        insert priceListItemList;     
    }    



    @isTest
    static void validateCreatePMTestStartTrack() {
       
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
            
        test.startTest();
        System.runAs(testuser) {
            
            APT_CreatePMBatch pmBatch = new APT_CreatePMBatch(TEST_STARTRACK_PRODUCT_TYPE,'');
            Database.executeBatch(pmBatch);
        }
        test.stopTest();
        system.assertEquals (2,([Select Id from Apttus_Config2__PriceMatrix__c]).size());
    }

    @isTest
    static void validateCreatePMTestDomestic() {        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            
            APT_CreatePMBatch pmBatch = new APT_CreatePMBatch(TEST_DOMESTIC_PRODUCT_TYPE,'BANDED {Z6}');
            Database.executeBatch(pmBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceMatrix__c where Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c='BANDED {Z6}']).size());
    }

    @isTest
    static void validateCreatePMTestInternational() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();  
        System.runAs(testuser) {
            
            APT_CreatePMBatch pmBatch = new APT_CreatePMBatch(TEST_International_PRODUCT_TYPE,'');
            Database.executeBatch(pmBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceMatrix__c]).size());
    }

    @isTest
    static void validateCreatePMTestAPPCSpeed() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();  
        System.runAs(testuser) {
            
            APT_CreatePMBatch pmBatch = new APT_CreatePMBatch(TEST_DOMESTIC_PARCEL_CONTRACT_PRODUCT_TYPE,'Z6');
            Database.executeBatch(pmBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceMatrix__c where Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c='Z6']).size());
    } 
    
    @isTest
    static void validateCreatePMTestAPPCFSR() {
              
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();  
        System.runAs(testuser) {
            
            APT_CreatePMBatch pmBatch = new APT_CreatePMBatch(TEST_DOMESTIC_FSR_PRODUCT_TYPE,'');
            Database.executeBatch(pmBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceMatrix__c]).size());
    }        

}