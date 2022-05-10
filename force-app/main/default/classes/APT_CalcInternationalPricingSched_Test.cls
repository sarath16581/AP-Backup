/**
Description: This Apex Class is test class for apex class - APT_CalculateInternationalPricingSched.
Created By - Mausam Padhiyar
Created Date - 13th Oct, 2015
Last Modified By -
Last Modified Date - 
@changelog
09/05/2022 - Seth Heang - Fix Test class failure due to system.schedule() set in the past
**/
@isTest
private with sharing class APT_CalcInternationalPricingSched_Test {
    //Creating test data
    private static testMethod void testMethod1() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('AIRPCL', 'B Mining', 'BAND 1', 'Zone1', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd1);
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRSMPCL', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
      //  APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod3() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('AIRPCL', 'B Mining', 'BAND 1', 'Zone1', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd1);
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRSMPCL', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        //ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        // create product
        Product2 prod = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        prod.APT_International_Pricing__c = true;
        insert prod;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod4() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('AIRPCL', 'B Mining', 'BAND 1', 'Zone1', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd1);
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRSMPCL', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        //ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        //ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        // create product
        Product2 prod = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        prod.APT_International_Pricing__c = true;
        insert prod;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
     private static testMethod void testMethod5() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('AIRPCL', 'B Mining', 'BAND 1', 'Zone1', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd1);
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRSMPCL', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        product.APT_International_Pricing__c = true;
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension1_Type__c = 'priceDimension1';
        ipp.APT_Dimension1_Value__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension2_Type__c = 'priceDimension2';
        ipp.APT_Dimension2_Value__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension3_Type__c = 'priceDimension3';
        ipp.APT_Dimension3_Value__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension4_Type__c = 'priceDimension4';
        ipp.APT_Dimension4_Value__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension5_Type__c = 'priceDimension5';
        ipp.APT_Dimension5_Value__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_Dimension6_Type__c = 'priceDimension6';
        ipp.APT_Dimension6_Value__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod6() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRSMPCL', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
       // APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod7() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('EMSDOCT', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
       // APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod8() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('EMSMERCH', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod9() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('EMSMER20', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod10() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        Product2 product = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        insert listPriceDimension;
                
                
        APT_R2T_International_Pricing_Properties__c ipp = new APT_R2T_International_Pricing_Properties__c();
        ipp.name = APT_Constants.R2T_INTERNATIONAL_PRICING_PROPERTIES;
        ipp.APT_Dimension1_Name__c = 'priceDimension1';
        ipp.APT_Dimension2_Name__c = 'priceDimension2';
        ipp.APT_Dimension3_Name__c = 'priceDimension3';
        ipp.APT_Dimension4_Name__c = 'priceDimension4';
        ipp.APT_Dimension5_Name__c = 'priceDimension5';
        ipp.APT_Dimension6_Name__c = 'priceDimension6';
        ipp.APT_AIRLET_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPTI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRRPI_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_AIRSMPCL_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSDOCT_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMERCH_Charge_Type__c = 'Standard Price';
        ipp.APT_EMSMER20_Charge_Type__c = 'Standard Price';
        insert ipp;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        //APT_CalculateInternationalPricingSched cips = new APT_CalculateInternationalPricingSched();
        test.stopTest();
        
        system.assert(jobId != null);
    }
    //Creating test data
    private static testMethod void testMethod2() {        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(null);
        insert r2tSystemProperties;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        Apttus_Config2__PriceDimension__c priceDimension = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        insert priceDimension;
        
        test.startTest();
        
        Id jobId = system.schedule('Calculate International Pricing', '0 0 0 ? * *', new APT_CalculateInternationalPricingSched());
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
}