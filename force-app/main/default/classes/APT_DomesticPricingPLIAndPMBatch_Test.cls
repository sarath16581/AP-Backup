/**
Description - This apex class is test class for apex class - APT_DomesticPricingPLIAndPMBatch
Created By - Mausam Padhiyar
Created Date - 16th Oct, 20154
Last Modified By -
Last Modified Date - 
**/
@isTest
private with sharing class APT_DomesticPricingPLIAndPMBatch_Test {
    /**
        Creating test data
    **/
    private static testMethod void testMethodDomesticPricingPLIAndPMBatch1() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'Standard');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        Apttus_Config2__ProductAttribute__c productAttribute6 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute6);
        insert listProductAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute6.Id);
        listPriceDimension.add(priceDimension6);
        insert listPriceDimension;
        
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd6);
        insert listDomesticPriceData;
        
        test.startTest();
        set<String> setErrorMessage = new set<String> {'error1', 'error2'};
        APT_DomesticPricingPLIAndPMBatch batchController = new APT_DomesticPricingPLIAndPMBatch();
        batchController.setErrorMessage = setErrorMessage;
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
    /**
        Creating test data
    **/    
    private static testMethod void testMethodDomesticPricingPLIAndPMBatch2() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'Standard');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        Apttus_Config2__ProductAttribute__c productAttribute6 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute6);
        insert listProductAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute6.Id);
        listPriceDimension.add(priceDimension6);
        insert listPriceDimension;
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd6);
        insert listDomesticPriceData;
        
        test.startTest();
        
        APT_DomesticPricingPLIAndPMBatch batchController = new APT_DomesticPricingPLIAndPMBatch();
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
    /**
        Creating test data
    **/    
    private static testMethod void testMethodDomesticPricingPLIAndPMBatch3() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'Standard');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        Apttus_Config2__ProductAttribute__c productAttribute6 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute6);
        insert listProductAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute6.Id);
        listPriceDimension.add(priceDimension6);
        insert listPriceDimension;
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        r2tdomestiPricingProperties.APT_Dimension6_Type__c = 'priceDimension6';
        r2tdomestiPricingProperties.APT_Dimension6_Value__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd6);
        insert listDomesticPriceData;
        
        test.startTest();
        
        APT_DomesticPricingPLIAndPMBatch batchController = new APT_DomesticPricingPLIAndPMBatch();
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
    
    /**
        Creating test data
    **/    
   private static testMethod void testMethodDeleteExistingDomesticPricingBatch1() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'Standard');
        insert product;

        //Startrack Product
        Product2 product1 = APT_TestUtils.createStarTrackProduct('Express Road Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'EXP', 'StarTrack');
        insert product1;
        Product2 product2 = APT_TestUtils.createStarTrackProduct('Special Services RE2 Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'RE2', 'StarTrack');
        insert product2;
        Product2 product3 = APT_TestUtils.createStarTrackProduct('Special Services RET Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'RET', 'StarTrack');
        insert product3;
        Product2 product4 = APT_TestUtils.createStarTrackProduct('Next Flight Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'NXF', 'StarTrack');
        insert product4;
        Product2 product5 = APT_TestUtils.createStarTrackProduct('Security Express Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'SE3', 'StarTrack');
        insert product5;
        Product2 product6 = APT_TestUtils.createStarTrackProduct('Priority Services Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'PRM', 'StarTrack');
        insert product6;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        Apttus_Config2__ProductAttribute__c productAttribute6 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute6);
        insert listProductAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute6.Id);
        listPriceDimension.add(priceDimension6);
        insert listPriceDimension;
        
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd6);
        insert listDomesticPriceData;
        
        Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(testPriceList.Id, product.ID, 'B Mining', 'BAND 1');
        insert pli;
        
        test.startTest();
        set<String> setErrorMessage = new set<String> {'error1', 'error2'};
        APT_DeleteExistingDomesticPricingBatch batchController = new APT_DeleteExistingDomesticPricingBatch();
        batchController.setErrorMessage = setErrorMessage;
        Id jobId = database.executeBatch(batchController, 1);
        
        system.assert(jobId != null);
        test.stopTest();
    }
    
    /**
        Creating test data
    **/    
   private static testMethod void testMethodDeleteExistingDomesticPricingBatch2() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        Product2 product = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'Standard');
        insert product;
        
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        Apttus_Config2__ProductAttribute__c productAttribute6 = APT_TestUtils.createProductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute6);
        insert listProductAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('priceDimension6', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute6.Id);
        listPriceDimension.add(priceDimension6);
        insert listPriceDimension;
        
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        r2tdomestiPricingProperties.APT_Dimension6_Type__c = 'priceDimension6';
        r2tdomestiPricingProperties.APT_Dimension6_Value__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT1', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT1', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
        listDomesticPriceData.add(dpd6);
        insert listDomesticPriceData;
        
        Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(testPriceList.Id, product.ID, 'B Mining', 'BAND 1');
        insert pli;
        
        test.startTest();
        //set<String> setErrorMessage = new set<String> {'error1', 'error2'};
        APT_DeleteExistingDomesticPricingBatch batchController = new APT_DeleteExistingDomesticPricingBatch();
        //batchController.setErrorMessage = setErrorMessage;
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        Creating test data
    **/    
   private static testMethod void testMethodDeleteExistingDomesticPricingBatch3() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //Startrack Product
        Product2 product = APT_TestUtils.createStarTrackProduct('Express Road Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'EXP', 'StarTrack');
        insert product;
        
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'R2T Domestic Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'priceDimension1';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'priceDimension2';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'priceDimension3';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'priceDimension4';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'priceDimension5';
        r2tdomestiPricingProperties.APT_Dimension6_Name__c = 'priceDimension6';
        insert r2tdomestiPricingProperties;
        
        Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(testPriceList.Id, product.ID, 'Express Road Tier 1', 'ExpressRoadTier1');
        insert pli;
        
        test.startTest();
        APT_DeleteExistingDomesticPricingBatch batchController = new APT_DeleteExistingDomesticPricingBatch();
        Id jobId = database.executeBatch(batchController, 1);
        
        system.assert(jobId != null);
        test.stopTest();
    }

    /**
        startrack products pli, pm and pme error test
    **/ 
    private static testMethod void testMethodDomesticPricingPLIAndPMBatchSTProductsError() {
        test.startTest();

        set<String> setErrorMessage = new set<String> {'error1', 'error2'};
        APT_DomesticPricingPMEBatch batchController = new APT_DomesticPricingPMEBatch();
        batchController.setErrorMessage = setErrorMessage;
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatch1() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Express Road Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'EXP', 'StarTrack');
        insert product;
        
        //attributes
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Pickup_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        //dimensions
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        //custom settings
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'ST Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'Inbound - Outbound';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'APT_Outbound_Inbound__c';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'Pickup Zone Code';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'APT_Lodgement_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'Destination Zone Code';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'APT_Destination_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'Price Type';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'Price Type';
        insert r2tdomestiPricingProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);
        
        APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'ADELAIDE', 'ADL', null, null);
        listPostCodeMapping.add(pcm2);
        
        APT_Post_Code_Mapping__c  pcm3 = APT_TestUtils.createPostCodeMapping('5220', 'PARNDANA', null, 'A10', null);
        listPostCodeMapping.add(pcm3);
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'LOC', 'Outbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'EXP', 'Inbound', 'QC3', 'NC3', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd7 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'EXP', 'Outbound', 'QC3', 'D10', 10, 20, 30);
        listDomesticPriceData.add(dpd7);
        
        APT_Domestic_Price_Data__c  dpd8 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'EXP', 'Inbound', 'D10', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd8);
        insert listDomesticPriceData;
        
        test.startTest();

        list<Product2> stProducts = [SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true LIMIT 1];

        System.debug(stProducts);
        
        APT_DetermineSTZoneTypesBatch batchController = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatch2() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Special Services Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'RE2', 'StarTrack');
        insert product;
        
        //attributes
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Pickup_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        //dimensions
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        //custom settings
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'ST Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'Inbound - Outbound';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'APT_Outbound_Inbound__c';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'Pickup Zone Code';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'APT_Lodgement_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'Destination Zone Code';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'APT_Destination_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'Price Type';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'Price Type';
        insert r2tdomestiPricingProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);
        
        APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'ADELAIDE', 'ADL', null, null);
        listPostCodeMapping.add(pcm2);
        
        APT_Post_Code_Mapping__c  pcm3 = APT_TestUtils.createPostCodeMapping('5220', 'PARNDANA', null, 'A10', null);
        listPostCodeMapping.add(pcm3);
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'LO2', 'Outbound', 'ADL', 'BRS', 10, 20, 30);
        listDomesticPriceData.add(dpd3);
        
        APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'RE2', 'Inbound', 'BRS', 'ADL', 10, 20, 30);
        listDomesticPriceData.add(dpd4);
        
        insert listDomesticPriceData;
        
        test.startTest();

        list<Product2> stProducts = [SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true LIMIT 1];

        System.debug(stProducts);
        
        APT_DetermineSTZoneTypesBatch batchController = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatch3() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Special Services Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'Tier 1', 'RET', 'StarTrack');
        insert product;
        
        //attributes
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Pickup_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        //dimensions
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        //custom settings
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'ST Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'Inbound - Outbound';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'APT_Outbound_Inbound__c';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'Pickup Zone Code';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'APT_Lodgement_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'Destination Zone Code';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'APT_Destination_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'Price Type';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'Price Type';
        insert r2tdomestiPricingProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);
        
        APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'ADELAIDE', 'ADL', null, null);
        listPostCodeMapping.add(pcm2);
        
        APT_Post_Code_Mapping__c  pcm3 = APT_TestUtils.createPostCodeMapping('5220', 'PARNDANA', null, 'A10', null);
        listPostCodeMapping.add(pcm3);

        APT_Post_Code_Mapping__c pcm4 = APT_TestUtils.createPostCodeMapping('0200', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', null);
        listPostCodeMapping.add(pcm4);
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'LOT', 'Outbound', 'A10', 'MEL', 10, 20, 30);
        listDomesticPriceData.add(dpd5);
        
        APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceDataForST('Tier 1', 'RET', 'Outbound', 'MEL', 'A10', 10, 20, 30);
        listDomesticPriceData.add(dpd6);

        insert listDomesticPriceData;
        
        test.startTest();

        list<Product2> stProducts = [SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true LIMIT 1];

        System.debug(stProducts);
        
        APT_DetermineSTZoneTypesBatch batchController = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatch4() {
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Security Services Tier 3', 'SecurityServicesTier3', 'Parcel Services', 'Tier 3', 'SE3', 'StarTrack');
        insert product;
        
        //attributes
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Pickup_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5);
        
        //dimensions
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        //custom settings
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'ST Single Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'Inbound - Outbound';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'APT_Outbound_Inbound__c';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'Pickup Zone Code';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'APT_Lodgement_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'Destination Zone Code';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'APT_Destination_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'Price Type';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'Price Type';
        insert r2tdomestiPricingProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('4000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);

        APT_Post_Code_Mapping__c pcm2 = APT_TestUtils.createPostCodeMapping('4500', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'QC3', 'NC3');
        listPostCodeMapping.add(pcm2);
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'SE3', 'Outbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'SE3', 'Inbound', 'QC3', 'NC3', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd7 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'SE3', 'Outbound', 'QC3', 'ADL', 10, 20, 30);
        listDomesticPriceData.add(dpd7);
        
        APT_Domestic_Price_Data__c  dpd8 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'SE3', 'Inbound', 'ADL', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd8);
        insert listDomesticPriceData;
        
        test.startTest();

        list<Product2> stProducts = [SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true LIMIT 1];

        System.debug(stProducts);
        APT_DomesticPricingPLIAndPMBatch batchController = new APT_DomesticPricingPLIAndPMBatch();
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatch5() {
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Next Flight Tier 3', 'NextFlightTier1', 'Parcel Services', 'Tier 3', 'NXF', 'StarTrack');
        insert product;
        
        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('4000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);

        APT_Post_Code_Mapping__c pcm2 = APT_TestUtils.createPostCodeMapping('4500', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'QC3', null);
        listPostCodeMapping.add(pcm2);
        
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Outbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Inbound', 'QC3', 'NC3', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd7 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Outbound', 'QC3', 'ADL', 10, 20, 30);
        listDomesticPriceData.add(dpd7);
        
        APT_Domestic_Price_Data__c  dpd8 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Inbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd8); 
        insert listDomesticPriceData;
        
        test.startTest();
        
        APT_DetermineSTZoneTypesBatch batchController = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
	/** 
	 	New method to cover the APT_DomesticPricingPMEBatch process - Mathew
    **/
    private static testMethod void testMethodDetermineSTZoneTypesBatch6() {

        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 product = APT_TestUtils.createStarTrackProduct('Next Flight Tier 3', 'NextFlightTier1', 'Parcel Services', 'Tier 3', 'NXF', 'StarTrack');
        insert product;

        //attributes
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createProductAttribute('APT_Zone_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createProductAttribute('APT_Inbound_Outbound__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createProductAttribute('APT_Pickup_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        Apttus_Config2__ProductAttribute__c productAttribute4 = APT_TestUtils.createProductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute4);
        
        Apttus_Config2__ProductAttribute__c productAttribute5 = APT_TestUtils.createProductAttribute('APT_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute5); 

        //dimensions
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('priceDimension4', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute4.Id);
        listPriceDimension.add(priceDimension4);
        
        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('priceDimension5', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute5.Id);
        listPriceDimension.add(priceDimension5);
        
        //custom settings
        APT_R2T_Domestic_Pricing_Properties__c r2tdomestiPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
        r2tdomestiPricingProperties.Name = 'ST Single Pricing Properties';
        r2tdomestiPricingProperties.APT_Dimension1_Name__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension1_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension1_Value__c = 'Zone Type';
        r2tdomestiPricingProperties.APT_Dimension2_Name__c = 'Inbound - Outbound';
        r2tdomestiPricingProperties.APT_Dimension2_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension2_Value__c = 'APT_Outbound_Inbound__c';
        r2tdomestiPricingProperties.APT_Dimension3_Name__c = 'Pickup Zone Code';
        r2tdomestiPricingProperties.APT_Dimension3_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension3_Value__c = 'APT_Lodgement_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension4_Name__c = 'Destination Zone Code';
        r2tdomestiPricingProperties.APT_Dimension4_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension4_Value__c = 'APT_Destination_Zone_Code__c';
        r2tdomestiPricingProperties.APT_Dimension5_Name__c = 'Price Type';
        r2tdomestiPricingProperties.APT_Dimension5_Type__c = 'Discrete';
        r2tdomestiPricingProperties.APT_Dimension5_Value__c = 'Price Type';
        insert r2tdomestiPricingProperties;        
                
        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('4000', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'NC3', 'QC3');
        listPostCodeMapping.add(pcm1);

        APT_Post_Code_Mapping__c pcm2 = APT_TestUtils.createPostCodeMapping('4500', 'AUSTRALIAN NATIONAL UNIVERSITY', null, 'QC3', null);
        listPostCodeMapping.add(pcm2);
        
        insert listPostCodeMapping;

        //domestic price data
        list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
        
        APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Outbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd1);
        
        APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Inbound', 'QC3', 'NC3', 10, 20, 30);
        listDomesticPriceData.add(dpd2);
        
        APT_Domestic_Price_Data__c  dpd7 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Outbound', 'QC3', 'ADL', 10, 20, 30);
        listDomesticPriceData.add(dpd7);
        
        APT_Domestic_Price_Data__c  dpd8 = APT_TestUtils.createDomesticPriceDataForST('Tier 3', 'NXF', 'Inbound', 'NC3', 'QC3', 10, 20, 30);
        listDomesticPriceData.add(dpd8); 
        insert listDomesticPriceData;
        
        test.startTest();

        list<Product2> stProducts = [SELECT Id, Name, ProductCode, APT_Category__c, APT_Network_Type__c, APT_Product_type__c FROM Product2 
                                            WHERE APT_Domestic_Pricing__c = true LIMIT 1];

        System.debug(stProducts);
              
        APT_DomesticPricingPLIAndPMBatch batchController = new APT_DomesticPricingPLIAndPMBatch();
        Id jobId = database.executeBatch(batchController, 1);
        
        test.stopTest();

        System.debug('PriceMatrix::'+[SELECT Id,
        							Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c,
        							Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
        							Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
        							Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
        							Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
        							Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c,
        							Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
        							Apttus_Config2__PriceListItemId__r.APT_Zones__c
        							FROM Apttus_Config2__PriceMatrix__c
        							WHERE Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c 
                                    =: stProducts[0].Id LIMIT 1]);               
        system.assert(jobId != null);        

    }    

    
    
    
    /**
        startrack products pli, pm and pme error test
    **/ 
    private static testMethod void testMethodDetermineSTZoneTypesBatchError() {

        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        set<String> setErrorMessage = new set<String> {'error1', 'error2'};

        test.startTest();

        APT_DetermineSTZoneTypesBatch batchController = new APT_DetermineSTZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);

        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :jobId];
        
        batchController.sendEmailNotification(asyncApexJob, setErrorMessage);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }

    /**
        startrack products pli, pm and pme error test
    **/ 
    private static testMethod void testMethodPostCodeZoneTypesBatchError() {

        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;

        //post code mapping
        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        set<String> setErrorMessage = new set<String> {'error1', 'error2'};

        test.startTest();

        APT_PostCodeZoneTypesBatch batchController = new APT_PostCodeZoneTypesBatch(listPostCodeMapping);
        Id jobId = database.executeBatch(batchController, 1);

        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :jobId];
        
        batchController.sendEmailNotification(asyncApexJob, setErrorMessage);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
}