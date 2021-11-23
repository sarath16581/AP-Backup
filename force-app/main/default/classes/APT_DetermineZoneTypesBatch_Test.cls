/***
 * @author Darshan Chauhan, Mathew Jose
 * @date 2021-03-01
 * @group 
 * @description Test class for APT_DetermineZoneTypesBatch.
 * @changelog
*/

@isTest
public with sharing class APT_DetermineZoneTypesBatch_Test {
    public static final string TEST_STARTRACK_PRODUCT_TYPE = 'Startrack';
    public static final string TEST_DOMESTIC_PRODUCT_TYPE = 'Domestic_Non_Startrack';

    
    //Setting up test data
    @TestSetup
    static void createData(){
        
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', null);
        listPostCodeMapping.add(pcm1);
        
        APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'QUEENSLAND ZONE 3', 'QC3' , null, null);
        listPostCodeMapping.add(pcm2);
        
        APT_Post_Code_Mapping__c  pcm3 = APT_TestUtils.createPostCodeMapping('5220', 'PARNDANA', null, 'A10', null);
        listPostCodeMapping.add(pcm3);

        APT_Post_Code_Mapping__c pcm4 = APT_TestUtils.createPostCodeMapping('4000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm4);

        APT_Post_Code_Mapping__c pcm5 = APT_TestUtils.createPostCodeMapping('4500', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'QC3', 'NC3');
        listPostCodeMapping.add(pcm5);

        APT_Post_Code_Mapping__c pcm6 = APT_TestUtils.createPostCodeMapping('4500', 'KATHERINE EAST', 'KAT', 'AC9', 'AC9');
        listPostCodeMapping.add(pcm6);
        
        APT_Post_Code_Mapping__c pcm7 = APT_TestUtils.createPostCodeMapping('4000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC4');
        listPostCodeMapping.add(pcm7);        
        
        insert listPostCodeMapping;

    }    
    
    
    static testMethod void validateDetermineZonetypeTestForExp() {
        
            
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            
            //Insert EXP product.
            List<Product2> prodList = new List<Product2>();	
            Product2 product1 = APT_TestUtils.createStarTrackProduct('Express Road Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'EXP', 'StarTrack');
            product1.APT_Domestic_Pricing__c = true;
            insert product1;
            
            //Insert Price data mapping for EXP.                
            APT_Pricing_Data_Mapping__c pdMapping1 = new APT_Pricing_Data_Mapping__c();
            pdMapping1.APT_Pricing_Value_Name_1__c = 'Outbound - Inbound';
            pdMapping1.APT_Pricing_Value_Name_2__c = 'Pickup Zone Code';
            pdMapping1.APT_Pricing_Value_Name_3__c = 'Lodgement Zone';
            pdMapping1.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
            pdMapping1.APT_Pricing_Value_Name_5__c = 'Destination Zone';
            pdMapping1.APT_Pricing_Value_Name_6__c = 'Base Rate';
            pdMapping1.APT_Pricing_Value_Name_7__c = 'Per Kg Rate';
            pdMapping1.APT_Pricing_Value_Name_8__c = 'Subsequent Rate';
            pdMapping1.APT_Pricing_Value_Name_9__c = 'Rate Card Version';
            pdMapping1.APT_Pricing_Value_Name_10__c = 'Rate Card Updated On';
            pdMapping1.APT_Pricing_Value_Name_11__c = '';
            pdMapping1.APT_Pricing_Value_Name_12__c = 'Zone Type';
            pdMapping1.APT_Product__c = product1.Id;
            insert pdMapping1;

            APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
            pricData1.APT_Product__c = product1.Id;
            pricData1.APT_Pricing_Value_1__c = 'Outbound';
            pricData1.APT_Pricing_Value_2__c = 'QC3';
            pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 3';
            pricData1.APT_Pricing_Value_4__c = 'ADL';
            pricData1.APT_Pricing_Value_5__c = 'ADELAIDE';
            pricData1.APT_Pricing_Value_6__c = '175';
            pricData1.APT_Pricing_Value_7__c = '23.06';
            pricData1.APT_Pricing_Value_8__c = '175';
            pricData1.APT_Pricing_Value_9__c = 'V8.1';
            pricData1.APT_Pricing_Value_10__c = 'Aug-20';
            pricData1.APT_Pricing_Data_Mapping__c = pdMapping1.Id;
            insert pricData1;        
            
            List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                        APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                        APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                        FROM APT_Post_Code_Mapping__c];

            system.debug('<<<<<<listPostCodeMapping>>>>>'+listPostCodeMapping);
            test.startTest();
            APT_DetermineZoneTypesBatch dztb = new APT_DetermineZoneTypesBatch(listPostCodeMapping,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(dztb);
            test.stopTest();
            System.assertEquals(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.size(), 1);
            System.assert(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('QC3').contains('\"directZone\":\"QC3\"'));
        }
        
    
    }

    static testMethod void validateDetermineZonetypeTestForPRM() {
        
            
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            
            //Insert EXP product.
         	Product2 product_prm = APT_TestUtils.createStarTrackProduct('Premium PRM Tier 1', 'PremiumPRMTier1', 'Parcel Services', 'Tier 1', 'PRM', 'StarTrack');
        	product_prm.APT_Domestic_Pricing__c = true;
			insert product_prm;             
            //Insert Price data mapping for EXP.                
            APT_Pricing_Data_Mapping__c pdMapping1 = new APT_Pricing_Data_Mapping__c();
            pdMapping1.APT_Pricing_Value_Name_1__c = 'Outbound - Inbound';
            pdMapping1.APT_Pricing_Value_Name_2__c = 'Pickup Zone Code';
            pdMapping1.APT_Pricing_Value_Name_3__c = 'Lodgement Zone';
            pdMapping1.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
            pdMapping1.APT_Pricing_Value_Name_5__c = 'Destination Zone';
            pdMapping1.APT_Pricing_Value_Name_6__c = 'Base Rate';
            pdMapping1.APT_Pricing_Value_Name_7__c = 'Per Kg Rate';
            pdMapping1.APT_Pricing_Value_Name_8__c = 'Subsequent Rate';
            pdMapping1.APT_Pricing_Value_Name_9__c = 'Rate Card Version';
            pdMapping1.APT_Pricing_Value_Name_10__c = 'Rate Card Updated On';
            pdMapping1.APT_Pricing_Value_Name_11__c = '';
            pdMapping1.APT_Pricing_Value_Name_12__c = 'Zone Type';
            pdMapping1.APT_Product__c = product_prm.Id;
            insert pdMapping1;

            APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
            pricData1.APT_Product__c = product_prm.Id;
            pricData1.APT_Pricing_Value_1__c = 'Outbound';
            pricData1.APT_Pricing_Value_2__c = 'QC3';
            pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 3';
            pricData1.APT_Pricing_Value_4__c = 'ADL';
            pricData1.APT_Pricing_Value_5__c = 'ADELAIDE';
            pricData1.APT_Pricing_Value_6__c = '175';
            pricData1.APT_Pricing_Value_7__c = '23.06';
            pricData1.APT_Pricing_Value_8__c = '175';
            pricData1.APT_Pricing_Value_9__c = 'V8.1';
            pricData1.APT_Pricing_Value_10__c = 'Aug-20';
            pricData1.APT_Pricing_Data_Mapping__c = pdMapping1.Id;
            insert pricData1;        
            
            List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                        APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                        APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                        FROM APT_Post_Code_Mapping__c];

            system.debug('<<<<<<listPostCodeMapping>>>>>'+listPostCodeMapping);
            test.startTest();
            APT_DetermineZoneTypesBatch dztb = new APT_DetermineZoneTypesBatch(listPostCodeMapping,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(dztb);
            test.stopTest();
            System.assertEquals(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.size(), 1);
            System.assert(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('QC3').contains('\"directZone\":\"QC3\"'));     
        }   
    
    }    

    static testMethod void validateDetermineZonetypeTestForRET() {
        
            
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            
            //Insert EXP product.
        	Product2 product_ret = APT_TestUtils.createStarTrackProduct('Special Services RET Tier 1', 'SpecialServicesRETTier1', 'Parcel Services', 'Tier 1', 'RET', 'StarTrack');
        	product_ret.APT_Domestic_Pricing__c = true;
			insert product_ret;             
            //Insert Price data mapping for EXP.                
            APT_Pricing_Data_Mapping__c pdMapping1 = new APT_Pricing_Data_Mapping__c();
            pdMapping1.APT_Pricing_Value_Name_1__c = 'Outbound - Inbound';
            pdMapping1.APT_Pricing_Value_Name_2__c = 'Pickup Zone Code';
            pdMapping1.APT_Pricing_Value_Name_3__c = 'Lodgement Zone';
            pdMapping1.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
            pdMapping1.APT_Pricing_Value_Name_5__c = 'Destination Zone';
            pdMapping1.APT_Pricing_Value_Name_6__c = 'Base Rate';
            pdMapping1.APT_Pricing_Value_Name_7__c = 'Per Kg Rate';
            pdMapping1.APT_Pricing_Value_Name_8__c = 'Subsequent Rate';
            pdMapping1.APT_Pricing_Value_Name_9__c = 'Rate Card Version';
            pdMapping1.APT_Pricing_Value_Name_10__c = 'Rate Card Updated On';
            pdMapping1.APT_Pricing_Value_Name_11__c = '';
            pdMapping1.APT_Pricing_Value_Name_12__c = 'Zone Type';
            pdMapping1.APT_Product__c = product_ret.Id;
            insert pdMapping1;

            APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
            pricData1.APT_Product__c = product_ret.Id;
            pricData1.APT_Pricing_Value_1__c = 'Outbound';
            pricData1.APT_Pricing_Value_2__c = 'NC3';
            pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 3';
            pricData1.APT_Pricing_Value_4__c = 'ADL';
            pricData1.APT_Pricing_Value_5__c = 'ADELAIDE';
            pricData1.APT_Pricing_Value_6__c = '175';
            pricData1.APT_Pricing_Value_7__c = '23.06';
            pricData1.APT_Pricing_Value_8__c = '175';
            pricData1.APT_Pricing_Value_9__c = 'V8.1';
            pricData1.APT_Pricing_Value_10__c = 'Aug-20';
            pricData1.APT_Pricing_Data_Mapping__c = pdMapping1.Id;
            insert pricData1;        
            
            List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                        APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                        APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                        FROM APT_Post_Code_Mapping__c];

            system.debug('<<<<<<listPostCodeMapping>>>>>'+listPostCodeMapping);
            test.startTest();
            APT_DetermineZoneTypesBatch dztb = new APT_DetermineZoneTypesBatch(listPostCodeMapping,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(dztb);
            test.stopTest();
            System.debug('lodgementZonesWithType::'+APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('NC3'));
            System.assertEquals(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.size(), 1);
            System.assert(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('NC3').contains('\"onforwardingZone\":\"NC3\"'));
            System.assert(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('NC3').contains('\"onforwardingAlternateZone\":\"NC3~QC3,NC3~QC4\"')); 
        }
        
    
    }      

	static testMethod void validateDetermineZonetypeTestForRE2() {
        
            
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            
            //Insert EXP product.
        	Product2 product_re2 = APT_TestUtils.createStarTrackProduct('Special Services RE2 Tier 1', 'SpecialServicesRE2Tier1', 'Parcel Services', 'Tier 1', 'RE2', 'StarTrack');
        	product_re2.APT_Domestic_Pricing__c = true;
			insert product_re2;             
            //Insert Price data mapping for EXP.                
            APT_Pricing_Data_Mapping__c pdMapping1 = new APT_Pricing_Data_Mapping__c();
            pdMapping1.APT_Pricing_Value_Name_1__c = 'Outbound - Inbound';
            pdMapping1.APT_Pricing_Value_Name_2__c = 'Pickup Zone Code';
            pdMapping1.APT_Pricing_Value_Name_3__c = 'Lodgement Zone';
            pdMapping1.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
            pdMapping1.APT_Pricing_Value_Name_5__c = 'Destination Zone';
            pdMapping1.APT_Pricing_Value_Name_6__c = 'Base Rate';
            pdMapping1.APT_Pricing_Value_Name_7__c = 'Per Kg Rate';
            pdMapping1.APT_Pricing_Value_Name_8__c = 'Subsequent Rate';
            pdMapping1.APT_Pricing_Value_Name_9__c = 'Rate Card Version';
            pdMapping1.APT_Pricing_Value_Name_10__c = 'Rate Card Updated On';
            pdMapping1.APT_Pricing_Value_Name_11__c = '';
            pdMapping1.APT_Pricing_Value_Name_12__c = 'Zone Type';
            pdMapping1.APT_Product__c = product_re2.Id;
            insert pdMapping1;

            APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
            pricData1.APT_Product__c = product_re2.Id;
            pricData1.APT_Pricing_Value_1__c = 'Outbound';
            pricData1.APT_Pricing_Value_2__c = 'A10';
            pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 3';
            pricData1.APT_Pricing_Value_4__c = 'ADL';
            pricData1.APT_Pricing_Value_5__c = 'ADELAIDE';
            pricData1.APT_Pricing_Value_6__c = '175';
            pricData1.APT_Pricing_Value_7__c = '23.06';
            pricData1.APT_Pricing_Value_8__c = '175';
            pricData1.APT_Pricing_Value_9__c = 'V8.1';
            pricData1.APT_Pricing_Value_10__c = 'Aug-20';
            pricData1.APT_Pricing_Data_Mapping__c = pdMapping1.Id;
            insert pricData1;        
            
            List<APT_Post_Code_Mapping__c> listPostCodeMapping = [SELECT Id, APT_Direct_Zone__c, APT_Onforwarding_Zone__c, APT_Onforwarding_Alternate_Zone__c,
                                                                        APT_EXP_Zone_Type__c, APT_PRM_Zone_Type__c, APT_NXF_Zone_Type__c, APT_SE2_Zone_Type__c, 
                                                                        APT_SE3_Zone_Type__c, APT_RET_Zone_Type__c, APT_RE2_Zone_Type__c 
                                                                        FROM APT_Post_Code_Mapping__c];

            system.debug('<<<<<<listPostCodeMapping>>>>>'+listPostCodeMapping);
            test.startTest();
            APT_DetermineZoneTypesBatch dztb = new APT_DetermineZoneTypesBatch(listPostCodeMapping,TEST_STARTRACK_PRODUCT_TYPE);
            Database.executeBatch(dztb);
            test.stopTest();
            System.assertEquals(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.size(), 1);
            System.assert(APT_DetermineZoneTypesBatch.lodgementZonesWithTypeMap.get('A10').contains('\"onforwardingZone\":\"A10\"')); 
        }
        
    
    }

}