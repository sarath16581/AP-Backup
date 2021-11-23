/***
 * @author Darshan Chauhan
 * @date 2021-03-01
 * @group 
 * @description Test class for APT_UpdatePricingDataBatch.
 * @changelog
*/

@isTest
public with sharing class APT_UpdatePricingDataBatch_Test {
    public static final string TEST_STARTRACK_PRODUCT_TYPE = 'Startrack';

    @isTest
    static void validateUpdatePricingDataBatch(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        Test.startTest();
        System.runAs(testuser){
            set<String> prodId = new set<String>();
            map<String, String> lodgementZonesWithType = new Map<String, String>();
            lodgementZonesWithType.put('CB','');
            lodgementZonesWithType.put('QC4','');
            for(Product2 prod : [Select Id from Product2]){
                prodId.add(prod.Id);
            }
            APT_UpdatePricingDataBatch updb = new APT_UpdatePricingDataBatch(lodgementZonesWithType, prodId, TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(updb);
        }
        Test.stopTest();
        system.assertEquals (1,([Select Id from APT_Pricing_Data__c]).size());
    }

    @TestSetup
    static void createData(){
        Product2 product1 = APT_TestUtils.createStarTrackProduct('Express Road Tier 0', 'ExpressRoadTier1', 'Parcel Services', 'Tier 0', 'SE3', 'Startrack');
        product1.APT_Domestic_Pricing__c = true;
        insert product1;

        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

       List<APT_Pricing_Data__c> pdList = new List<APT_Pricing_Data__c>();

        APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
        pricData1.APT_Product__c = product1.Id;
        pricData1.APT_Pricing_Value_1__c = 'Outbound';
        pricData1.APT_Pricing_Value_2__c = 'QC4';
        pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 4';
        pricData1.APT_Pricing_Value_4__c = 'LC1';
        pricData1.APT_Pricing_Value_5__c = 'LAUNCESTON ZONE 1';
        pricData1.APT_Pricing_Value_6__c = '300';
        pricData1.APT_Pricing_Value_7__c = '65.66';
        pricData1.APT_Pricing_Value_8__c = '300';
        pricData1.APT_Pricing_Value_9__c = 'V8.1';
        pricData1.APT_Pricing_Value_10__c = 'Aug-20';
        pdList.add(pricData1); 

        insert pdList; 
    }
}