/**
Description: This apex class is test class for apex class - APT_InternationalPricingBatch.
Created By - Mausam Padhiyar
Created Date - 13th Oct, 2015
Last Modified By -
Last Modified Date - 
**/
@isTest
private with sharing class APT_InternationalPricingBatch_Test {
    /**
    Creating test data 
    **/
   private static testMethod void testMethod1() {
        //price list
        Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
        insert testPriceList;
        
        //R2T System Properties
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
        insert r2tSystemProperties;
        
        //product
        Product2 testProduct = APT_TestUtils.createInternationalProduct('Air mail Letters', 'AIRLET', 'Parcel Services');
        insert testProduct;
        
        //pric elist iten
        Apttus_Config2__PriceListItem__c testPLI = APT_TestUtils.createPriceListItem(testPriceList.Id, testProduct.Id, 'B Mining', 'BAND 1');
        insert testPLI;
        
        //product attribute group
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createproductAttributeGroup('Apttus_Config2__productAttribute321Value__c');
        insert productAttributeGroup;
        
        //product attribute
        list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
        Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createproductAttribute('APT_Destination_Zone_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute1);
        
        Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createproductAttribute('APT_Weight_Range_Code__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute2);
        
        Apttus_Config2__ProductAttribute__c productAttribute3 = APT_TestUtils.createproductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
        listProductAttribute.add(productAttribute3);
        
        insert listProductAttribute;
        
        //price dimension
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Destination Zone Code', 'Product Attribute', 'Apttus_Config2__productAttribute321Value__c', 'APT_Destination_Zone_Code__c', productAttribute1.Id);
        listPriceDimension.add(priceDimension1); 
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Weight Range Code', 'Product Attribute', 'Apttus_Config2__productAttribute32Value__c', 'APT_Weight_Range_Code__c', productAttribute2.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__productAttribute3Value__c', 'APT_Domestic_Price_Type__c', productAttribute3.Id);
        listPriceDimension.add(priceDimension3);
        
        insert listPriceDimension;
        
        //price matrix
        Apttus_Config2__PriceMatrix__c priceMatrix = APT_TestUtils.createPriceMatrix(testPLI.Id, priceDimension1.Id, priceDimension2.Id, priceDimension3.Id);
        insert priceMatrix;
        
        set<Id> setPriceMatrixId = new set<Id> {priceMatrix.Id};
        
        //international price data
        list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
        
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone1', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd1);
        
        APT_International_Price_Data__c ipd2 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone2', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd2);
        
        APT_International_Price_Data__c ipd3 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone3', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd3);
        
        APT_International_Price_Data__c ipd4 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone4', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd4);
        
        APT_International_Price_Data__c ipd5 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone5', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd5);
        
        APT_International_Price_Data__c ipd6 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd6);
        
        APT_International_Price_Data__c ipd7 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone7', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd7);
        
        APT_International_Price_Data__c ipd8 = APT_TestUtils.createInternationalPriceData('AIRLET', 'B Mining', 'BAND 1', 'Zone8', 0, 2999, 10, 10, 20, 20);
        listInternationalPriceData.add(ipd8);
        
        insert listInternationalPriceData;
        
        map<String, list<APT_International_Price_Data__c>> mapIPD = new map<String, list<APT_International_Price_Data__c>>();
        for(APT_International_Price_Data__c ipd : listInternationalPriceData){
            list<APT_International_Price_Data__c> listIPD = mapIPD.get(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' +  ipd.APT_Band__c);
            if(listIPD != null && listIPD.size() > 0) {
                listIPD.add(ipd);
                mapIPD.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' +  ipd.APT_Band__c, listIPD);
            } else {
                listIPD = new list<APT_International_Price_Data__c>();
                listIPD.add(ipd);
                mapIPD.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' +  ipd.APT_Band__c, listIPD);
            }
        }
        
        test.startTest();
        
        APT_InternationalPricingBatch controller = new APT_InternationalPricingBatch(setPriceMatrixId, mapIPD);
        Id jobId = database.executeBatch(controller, 1);
        
        test.stopTest();
        
        system.assert(jobId != null);
    }
}