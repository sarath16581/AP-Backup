/***
 * @author Darshan Chauhan, Mathew Jose
 * @date 2021-03-01
 * @group 
 * @description Test class for APT_UpdatePostCodeMappingBatch.
 * @changelog
*/

@isTest
public with sharing class APT_UpdatePostCodeMappingBatch_Test {
    public static final string TEST_STARTRACK_PRODUCT_TYPE = 'Startrack';
    public static final string TEST_DOMESTIC_PRODUCT_TYPE = 'Domestic_Non_Startrack';
    public static final string TEST_International_PRODUCT_TYPE = 'International';


    @TestSetup
    static void createData(){
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', '');
        product.APT_Domestic_Pricing__c = true;
        insert product;
        //Startrack Product
        Product2 product1 = APT_TestUtils.createStarTrackProduct('Express Road Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'EXP', 'Startrack');
        product.APT_Domestic_Pricing__c = true;
        insert product1;
        Product2 productInternational = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        productInternational.APT_International_Pricing__c = true;
        insert productInternational;
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;        

    }

    //Positive test case.
    static testMethod void validatePricingDataBatchTestStartTrackSuccess() {
        

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
            
        test.startTest();
        System.runAs(testuser) {
            list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
            APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'QUEENSLAND ZONE 3', 'QC3' , null, null);
            listPostCodeMapping.add(pcm2);
            insert listPostCodeMapping;
            set<String> prodId = new set<String>();
            map<String, String> lodgementZonesWithType = new Map<String, String>();
            for(Product2 prod : [Select Id from Product2]){
                prodId.add(prod.Id);
            }
            APT_UpdatePostCodeMappingBatch aptDel = new APT_UpdatePostCodeMappingBatch(listPostCodeMapping,lodgementZonesWithType,prodId,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(aptDel,1);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from APT_Post_Code_Mapping__c]).size());
    }

    //Negative test case.
    static testMethod void validatePricingDataBatchTestStartTrackFail() {
       
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
            
        test.startTest();
        System.runAs(testuser) {
            list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
            APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5001', 'QUEENSLAND ZONE 4', 'QC4' , null, null);    
            listPostCodeMapping.add(pcm2);
			System.debug('About to insert');            
            insert listPostCodeMapping;
            listPostCodeMapping[0].Name   = 'abcdedfffffffffabcdedfffffffffabcdedfffffffffabcdedfffffffff'+
                							'abcdedfffffffffabcdedfffffffffabcdedfffffffffabcdedfffffffff'+
                							'abcdedfffffffffabcdedfffffffffabcdedfffffffffabcdedfffffffff'+
                							'abcdedfffffffffabcdedfffffffffabcdedfffffffffabcdedfffffffff';
            listPostCodeMapping[0].APTS_Ext_ID__c = 'abcd';                                 
            set<String> prodId = new set<String>();
            map<String, String> lodgementZonesWithType = new Map<String, String>();
            for(Product2 prod : [Select Id from Product2]){
                prodId.add(prod.Id);
            }
            APT_UpdatePostCodeMappingBatch aptDel = new APT_UpdatePostCodeMappingBatch(listPostCodeMapping,lodgementZonesWithType,prodId,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(aptDel);
        }
        test.stopTest();
        List<ExceptionLog__c> elList = new List<ExceptionLog__c>([Select Id, ClassName__C, MethodName__c, ExceptionCode__c,ExceptionDetails__c From ExceptionLog__c limit 1]);
        system.assertEquals (0,([Select Id from APT_Post_Code_Mapping__c where APTS_Ext_ID__c = 'abcd']).size());
    }    
    
}