/**
Description - This apex class is test class for apex class - APT_PricingUtility
Created By - Mausam Padhiyar
Created Date - 13th Oct, 2015
Last Modified By -
Last Modified Date - 
**/
@isTest
private with sharing class APT_PricingUtility_Test { 
    /**
        Creating test data
    **/
    static testMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            //price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //product
            list<Product2> listProduct = new list<Product2>();
            Product2 product1 = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
            // Product2 product3 = APT_TestUtils.createInternationalProduct('International Pack and Track', 'AIRPTI', 'Parcel Services');
            // Product2 product4 = APT_TestUtils.createInternationalProduct('Registered Post International Parcels', 'AIRRPI', 'Parcel Services');
            // Product2 product5 = APT_TestUtils.createInternationalProduct('Air Mail Parcels', 'AIRPCL', 'Parcel Services');
            // Product2 product6 = APT_TestUtils.createInternationalProduct('International Express - Documents', 'EXPRESS_DOCT', 'Parcel Services');
            // Product2 product7 = APT_TestUtils.createInternationalProduct('International Express - Merchandise', 'EXPRESS_MERCH', 'Parcel Services');
            // Product2 product8 = APT_TestUtils.createInternationalProduct('International Standard', 'STANDARD', 'Parcel Services');
            // Product2 product9 = APT_TestUtils.createInternationalProduct('International Economy', 'ECONOMY', 'Parcel Services');
            // Product2 product10 = APT_TestUtils.createInternationalProduct('Internat Returns - Standard Untracked', 'RETURNS_STANDARD', 'Parcel Services');
            // Product2 product11 = APT_TestUtils.createInternationalProduct('International Airmail Letters', 'AIRMAIL_LETTERS', 'Parcel Services');
            // Product2 product12 = APT_TestUtils.createInternationalProduct('International Returns - Express', 'RETURNS_EXPRESS', 'Parcel Services');
            // Product2 product13 = APT_TestUtils.createInternationalProduct('International Economy with Signature', 'ECONOMY_SIG', 'Parcel Services');
            // Product2 product14 = APT_TestUtils.createInternationalProduct('International Standard with Signature', 'STANDARD_SIG', 'Parcel Services');

            listProduct.add(product1);
            // listProduct.add(product3);
            // listProduct.add(product4);
            // listProduct.add(product5);
            // listProduct.add(product6);
            // listProduct.add(product7);
            // listProduct.add(product8);
            // listProduct.add(product9);
            // listProduct.add(product10);
            // listProduct.add(product11);
            // listProduct.add(product12);
            // listProduct.add(product13);
            // listProduct.add(product14);
            
            //Product2 product2 = APT_TestUtils.createInternationalProduct('Air Mail Parcels', 'AIRPCL', 'Parcel Services');
            //listProduct.add(product2);        
            insert listProduct;
            
            //price list item
            list<Apttus_Config2__PriceListItem__c> listPLI = new list<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c testPLI1 = APT_TestUtils.createPriceListItem(testPriceList.Id, product1.Id, 'B Mining', 'BAND 1');
            listPLI.add(testPLI1);
            
            //Apttus_Config2__PriceListItem__c testPLI2 = APT_TestUtils.createPriceListItem(testPriceList.Id, product1.Id, 'B Mining', 'BAND 1');
            //testPLI2.Apttus_Config2__ChargeType__c = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT;
            //listPLI.add(testPLI2);        
            insert listPLI;        
            
            product1 = [SELECT Id, productCode FROM Product2 WHERE Id =: product1.Id];
            //set<String> setProduct = new set<String>{product1.productCode};
            // set<String> setProduct = new set<String>{listProduct[0].productCode,listProduct[1].productCode,listProduct[2].productCode,listProduct[3].productCode};
            set<String> setProduct = new set<String>{'AIRLET','AIRPTI','AIRRPI','AIRPCL','EXPRESS_DOCT','EXPRESS_MERCH','STANDARD','ECONOMY','RETURNS_STANDARD','AIRMAIL_LETTERS','RETURNS_EXPRESS','ECONOMY_SIG','STANDARD_SIG'};
            
            //set<String> setIndustry = new set<String>{'B Mining'};
            set<String> setBand = new set<String>{'BAND 1'};
            set<String> seteParcelLodgment = new set<String>{'True', 'False'};
            map<String, String> mapProduct = new map<String, String>{product1.productCode => product1.Id};
            map<String, list<String>> mapChargeType = new map<String, list<String>>{'AIRLET' => new list<String>{'Standard Price'},'AIRPTI' => new list<String>{'Standard Price'},'AIRRPI' => new list<String>{'Standard Price'},'AIRPCL' => new list<String>{'Standard Price'},'EXPRESS_DOCT' => new list<String>{'Standard Price'},'EXPRESS_MERCH' => new list<String>{'Standard Price'},'STANDARD' => new list<String>{'Standard Price'},'ECONOMY' => new list<String>{'Standard Price'},'RETURNS_STANDARD' => new list<String>{'Standard Price'},'AIRMAIL_LETTERS' => new list<String>{'Standard Price'},'RETURNS_EXPRESS' => new list<String>{'Standard Price'},'ECONOMY_SIG' => new list<String>{'Standard Price'},'STANDARD_SIG' => new list<String>{'Standard Price'}};
            map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<String, Apttus_Config2__PriceListItem__c>();
            mapExistingPLI.put(product1.productCode + '~BAND 1~True', testPLI1);
            mapExistingPLI.put(product1.productCode + '~BAND 1~False', testPLI1);
            
            list<String> listProductId = new list<String>{product1.Id};
            
            //product attribute group
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createproductAttributeGroup('Apttus_Config2__productAttribute321Value__c');
            insert productAttributeGroup;
            
            //product attribute
            list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
            Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createproductAttribute('APT_Zone__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute1);
            
            Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createproductAttribute('APT_International_Price_Type__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute2);
            
            insert listProductAttribute;
            
            //price dimension
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__productAttribute321Value__c', 'APT_Zone__c', productAttribute1.Id);
            listPriceDimension.add(priceDimension1);        
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__productAttribute3Value__c', 'APT_International_Price_Type__c', productAttribute2.Id);
            listPriceDimension.add(priceDimension2);        
            insert listPriceDimension;
            
            map<String, String> mapDimension = new map<String, String> {priceDimension1.Name => priceDimension1.Id, priceDimension2.Name => priceDimension2.Id};
            
            //price matrix
            list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c pm1 = APT_TestUtils.createPriceMatrix(testPLI1.Id, priceDimension1.Id, priceDimension2.Id, priceDimension1.Id);
            listPriceMatrix.add(pm1);
            
            //Apttus_Config2__PriceMatrix__c pm2 = APT_TestUtils.createPriceMatrix(testPLI2.Id, priceDimension1.Id, priceDimension2.Id, null);
            //listPriceMatrix.add(pm2);
            insert listPriceMatrix;
            
            listPriceMatrix = [SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                               Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                               Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                               Apttus_Config2__PriceListItemId__r.APT_Band__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                               FROM Apttus_Config2__PriceMatrix__c
                               WHERE Id = :pm1.Id];
            
            map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
            //mapExistingPriceMatrix.put(testPLI1.Id, pm1);
            
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
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            r2tInternationalPricingProperties.APT_Dimension1_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension1_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension2_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension2_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension3_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension3_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension4_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension4_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension5_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension5_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension6_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension6_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension1_Value__c = 'International Price Data Name';
            r2tInternationalPricingProperties.APT_Dimension2_Value__c = 'International Price Data Name';
            r2tInternationalPricingProperties.APT_Dimension3_Value__c = 'International Price Data Name';
            r2tInternationalPricingProperties.APT_Dimension4_Value__c = 'International Price Data Name';
            r2tInternationalPricingProperties.APT_Dimension5_Value__c = 'International Price Data Name';
            r2tInternationalPricingProperties.APT_Dimension6_Value__c = 'International Price Data Name';
            
            insert r2tInternationalPricingProperties;
            
            map<String, list<APT_International_Price_Data__c>> mapInternationalPriceData = new map<String, list<APT_International_Price_Data__c>>();
            for(APT_International_Price_Data__c ipd : listInternationalPriceData) {
                list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c);
                if(listIPD != null && listIPD.size() > 0) {
                    listIPD.add(ipd);
                    //mapInternationalPriceData.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c, listIPD);
                    mapInternationalPriceData.put(ipd.APT_Product__c + '~'+ ipd.APT_Band__c, listIPD);
                } else {
                    listIPD = new list<APT_International_Price_Data__c>();
                    listIPD.add(ipd);
                    //mapInternationalPriceData.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c, listIPD);
                    mapInternationalPriceData.put(ipd.APT_Product__c + '~'+ ipd.APT_Band__c, listIPD);
                }           
            }        
            
            test.startTest();
            
            //APT_PricingUtility.deletePriceListItems(listProductId);
            
            //APT_PricingUtility.deletePriceMatrix(listProductId);
            
            //APT_PricingUtility.deletePriceMatrixEntries(listProductId);
            
            //APT_PricingUtility.generateJSONStringForInternational('test','test','test');
            
            APT_PricingUtility.getAllFields('Product2');
            APT_PricingUtility.createPriceListItemForInternational(setProduct/*, setIndustry*/, setBand, seteParcelLodgment, testPriceList.Id, mapProduct,mapChargeType,mapExistingPLI);
            APT_PricingUtility.createPriceMatrixForInternational(listPLI, mapDimension, r2tInternationalPricingProperties,mapExistingPriceMatrix);
            APT_PricingUtility.createPriceMatrixEntryForInternational(listPriceMatrix, mapInternationalPriceData);

            test.stopTest(); 
           system.assert(APT_PricingUtility.createPriceListItemForInternational(setProduct/*, setIndustry*/, setBand, seteParcelLodgment, testPriceList.Id, mapProduct,mapChargeType,mapExistingPLI).size() > 0);        
            
            //system.assert(APT_PricingUtility.generateJSONStringForInternational('B Mining', 'BAND 1', 'True') != null);
            system.assert(APT_PricingUtility.createPriceMatrixForInternational(listPLI, mapDimension, r2tInternationalPricingProperties,mapExistingPriceMatrix).size() > 0);
            
            system.assert(APT_PricingUtility.createPriceMatrixEntryForInternational(listPriceMatrix, mapInternationalPriceData).size() > 0);
            
    
        }    
    }
    /**
        Creating test data
    **/    
    static testMethod void testMethodElseR2TIP() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            //price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //product
            list<Product2> listProduct = new list<Product2>();
            Product2 product1 = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
            listProduct.add(product1);
            
            //Product2 product2 = APT_TestUtils.createInternationalProduct('Air Mail Parcels', 'AIRPCL', 'Parcel Services');
            //listProduct.add(product2);        
            insert listProduct;
            
            //price list item
            list<Apttus_Config2__PriceListItem__c> listPLI = new list<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c testPLI1 = APT_TestUtils.createPriceListItem(testPriceList.Id, product1.Id, 'B Mining', 'BAND 1');
            listPLI.add(testPLI1);
            
            //Apttus_Config2__PriceListItem__c testPLI2 = APT_TestUtils.createPriceListItem(testPriceList.Id, product1.Id, 'B Mining', 'BAND 1');
            //testPLI2.Apttus_Config2__ChargeType__c = APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT;
            //listPLI.add(testPLI2);        
            insert listPLI;        
            
            product1 = [SELECT Id, productCode FROM Product2 WHERE Id =: product1.Id];
            set<String> setProduct = new set<String>{product1.productCode};
          //  set<String> setIndustry = new set<String>{'B Mining'};
            set<String> setBand = new set<String>{'BAND 1'};
            set<String> seteParcelLodgment = new set<String>{'True', 'False'};
            map<String, String> mapProduct = new map<String, String>{product1.productCode => product1.Id};
            map<String, list<String>> mapChargeType = new map<String, list<String>>{'AIRLET' => new list<String>{'Standard Price'}};
            map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<String, Apttus_Config2__PriceListItem__c>();
            mapExistingPLI.put(product1.productCode + '~BAND 1~True', testPLI1);
            mapExistingPLI.put(product1.productCode + '~BAND 1~False', testPLI1);
            
            list<String> listProductId = new list<String>{product1.Id};
            
            //product attribute group
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createproductAttributeGroup('Apttus_Config2__productAttribute321Value__c');
            insert productAttributeGroup;
            
            //product attribute
            list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
            Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createproductAttribute('APT_Zone__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute1);
            
            Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createproductAttribute('APT_International_Price_Type__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute2);
            
            insert listProductAttribute;
            
            //price dimension
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__productAttribute321Value__c', 'APT_Zone__c', productAttribute1.Id);
            listPriceDimension.add(priceDimension1);        
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__productAttribute3Value__c', 'APT_International_Price_Type__c', productAttribute2.Id);
            listPriceDimension.add(priceDimension2);        
            insert listPriceDimension;
            
            map<String, String> mapDimension = new map<String, String> {priceDimension1.Name => priceDimension1.Id, priceDimension2.Name => priceDimension2.Id};
            
            //price matrix
            list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c pm1 = APT_TestUtils.createPriceMatrix(testPLI1.Id, priceDimension1.Id, priceDimension2.Id, priceDimension1.Id);
            listPriceMatrix.add(pm1);
            
            //Apttus_Config2__PriceMatrix__c pm2 = APT_TestUtils.createPriceMatrix(testPLI2.Id, priceDimension1.Id, priceDimension2.Id, null);
            //listPriceMatrix.add(pm2);
            insert listPriceMatrix;
            
            listPriceMatrix = [SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                               Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                               Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                               Apttus_Config2__PriceListItemId__r.APT_Band__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                               FROM Apttus_Config2__PriceMatrix__c
                               WHERE Id = :pm1.Id];
            
            map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
            //mapExistingPriceMatrix.put(testPLI1.Id, pm1);
            
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
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            r2tInternationalPricingProperties.APT_Dimension1_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension1_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension2_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension2_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension3_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension3_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension4_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension4_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension5_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension5_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension6_Name__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension6_Type__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension1_Value__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension2_Value__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension3_Value__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension4_Value__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension5_Value__c = 'International Price Type';
            r2tInternationalPricingProperties.APT_Dimension6_Value__c = 'International Price Type';
            
            insert r2tInternationalPricingProperties;
            
            map<String, list<APT_International_Price_Data__c>> mapInternationalPriceData = new map<String, list<APT_International_Price_Data__c>>();
            for(APT_International_Price_Data__c ipd : listInternationalPriceData) {
                list<APT_International_Price_Data__c> listIPD = mapInternationalPriceData.get(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c);
                if(listIPD != null && listIPD.size() > 0) {
                    listIPD.add(ipd);
                    //mapInternationalPriceData.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c, listIPD);
                    mapInternationalPriceData.put(ipd.APT_Product__c + '~'+ ipd.APT_Band__c, listIPD);
                } else {
                    listIPD = new list<APT_International_Price_Data__c>();
                    listIPD.add(ipd);
                    //mapInternationalPriceData.put(ipd.APT_Product__c + '~' + ipd.APT_Industry__c + '~' + ipd.APT_Band__c, listIPD);
                    mapInternationalPriceData.put(ipd.APT_Product__c + '~'+ ipd.APT_Band__c, listIPD);
                }           
            }        
            
            test.startTest();
            
            //APT_PricingUtility.deletePriceListItems(listProductId);
            
            //APT_PricingUtility.deletePriceMatrix(listProductId);
            
            //APT_PricingUtility.deletePriceMatrixEntries(listProductId);
            
            //APT_PricingUtility.generateJSONStringForInternational('test','test','test');
            APT_PricingUtility.createPriceListItemForInternational(setProduct, setBand, seteParcelLodgment, testPriceList.Id, mapProduct,mapChargeType,mapExistingPLI);
            APT_PricingUtility.createPriceMatrixForInternational(listPLI, mapDimension, r2tInternationalPricingProperties,mapExistingPriceMatrix);
            APT_PricingUtility.createPriceMatrixEntryForInternational(listPriceMatrix, mapInternationalPriceData);
      
            test.stopTest(); 
            system.assert(APT_PricingUtility.createPriceListItemForInternational(setProduct, setBand, seteParcelLodgment, testPriceList.Id, mapProduct,mapChargeType,mapExistingPLI).size() > 0);        
            
            //system.assert(APT_PricingUtility.generateJSONStringForInternational('B Mining', 'BAND 1', 'True') != null);
            system.assert(APT_PricingUtility.createPriceMatrixForInternational(listPLI, mapDimension, r2tInternationalPricingProperties,mapExistingPriceMatrix).size() > 0);
            
            system.assert(APT_PricingUtility.createPriceMatrixEntryForInternational(listPriceMatrix, mapInternationalPriceData).size() > 0);
                  
        }
    }
     /**
        Creating test data
    **/   
    static testMethod void testMethod2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {   
            //price list
            Apttus_Config2__PriceList__c PriceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create Domestic product
            list<Product2> listProduct = new list<Product2>();
            Product2 product1 = APT_TestUtils.createDomesticProduct('Air Mail Letters', 'AIRLET', 'Parcel Services','CAT2','Standard');
            listProduct.add(product1);               
            insert listProduct; 
            
            Set<String> setLodgment = new set<String>{'LodgmentZone1','LodgmentZone2'};
            Set<String> setPricing = new set<String>{'WINE {Z20}','WINE {Z30}'};
            map<String, Set<String>> mapLodgment = new map<String, Set<String>>();
            mapLodgment.put('CAT2~Standard', setLodgment);
            map<String, Set<String>> mapPricing = new map<String, Set<String>>();
            mapPricing.put('CAT2~Standard', setPricing);
            
            //price list item
            list<Apttus_Config2__PriceListItem__c> listPLI = new list<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c testPLI1 = APT_TestUtils.createPriceListItem(priceList.Id, product1.Id, 'B Mining', 'BAND 1');
            listPLI.add(testPLI1);               
            insert listPLI;        
                           
            
            map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<String, Apttus_Config2__PriceListItem__c>();
            mapExistingPLI.put(product1.productCode + '~BAND 1~True', testPLI1);
            mapExistingPLI.put(product1.productCode + '~BAND 1~False', testPLI1);
            
            //product attribute group
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createproductAttributeGroup('Apttus_Config2__productAttribute321Value__c');
            insert productAttributeGroup;
            
            //product attribute
            list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
            Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createproductAttribute('APT_Zone__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute1);
            
            Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createproductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute2);
            
            insert listProductAttribute;
            
            //price dimension
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__productAttribute321Value__c', 'APT_Zone__c', productAttribute1.Id);
            listPriceDimension.add(priceDimension1);        
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__productAttribute3Value__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
            listPriceDimension.add(priceDimension2);        
            insert listPriceDimension;
            
            map<String, String> mapDimension = new map<String, String> {priceDimension1.Name => priceDimension1.Id, priceDimension2.Name => priceDimension2.Id};
            
            
            
            //price matrix
            list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c pm1 = APT_TestUtils.createPriceMatrix(testPLI1.Id, priceDimension1.Id, priceDimension2.Id, priceDimension1.Id);
            listPriceMatrix.add(pm1);        
            insert listPriceMatrix;
            
            listPriceMatrix = [SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
                               Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
                               Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c,
                               Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                               Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                               Apttus_Config2__PriceListItemId__r.APT_Band__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                               FROM Apttus_Config2__PriceMatrix__c
                               WHERE Id = :pm1.Id];
            
            
            map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
            //mapExistingPriceMatrix.put(testPLI1.Id, pm1);
            
            //international price data
             list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
            
            APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd1);
            
            APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd2);
            
            APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd3);
            
            APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd4);
            
            APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd5);
            
            APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd6);
            insert listDomesticPriceData;
            
            //APT_R2T_Domestic_Pricing_Properties__c
            APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
            r2tDomesticPricingProperties.Name = 'R2T Domestic Pricing Properties';
            r2tDomesticPricingProperties.APT_Dimension1_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension1_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension2_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension2_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension3_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension3_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension4_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension4_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension5_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension5_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension6_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension6_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension1_Value__c = 'Domestic Price Data Name';
            r2tDomesticPricingProperties.APT_Dimension2_Value__c = 'Domestic Price Data Name';
            r2tDomesticPricingProperties.APT_Dimension3_Value__c = 'Domestic Price Data Name';
            r2tDomesticPricingProperties.APT_Dimension4_Value__c = 'Domestic Price Data Name';
            r2tDomesticPricingProperties.APT_Dimension5_Value__c = 'Domestic Price Data Name';
            r2tDomesticPricingProperties.APT_Dimension6_Value__c = 'Domestic Price Data Name';
            insert r2tDomesticPricingProperties;
            
            map<String, list<APT_Domestic_Price_Data__c>> mapDomesticPriceData = new map<String, list<APT_Domestic_Price_Data__c>>();
            for(APT_Domestic_Price_Data__c dpd : listDomesticPriceData) {
                list<APT_Domestic_Price_Data__c> listDPD = mapDomesticPriceData.get(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c);
                if(listDPD != null && listDPD.size() > 0) {
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c, listDPD);
                } else {
                    listDPD = new list<APT_Domestic_Price_Data__c>();
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c, listDPD);
                }           
            }        
            
            
          
          Test.starttest();
            APT_PricingUtility.createPriceListItemForDomestic(listProduct,PriceList.ID,mapLodgment,mapPricing,mapExistingPLI);
            APT_PricingUtility.createPriceMatrixForDomestic(listPLI, mapDimension, r2tDomesticPricingProperties,mapExistingPriceMatrix);
            APT_PricingUtility.createPriceMatrixEntryForDomestic(listPriceMatrix, mapDomesticPriceData);

          Test.stoptest();
            system.assert(APT_PricingUtility.createPriceListItemForDomestic(listProduct,PriceList.ID,mapLodgment,mapPricing,mapExistingPLI).size()>0);
            
            system.assert(APT_PricingUtility.createPriceMatrixForDomestic(listPLI, mapDimension, r2tDomesticPricingProperties,mapExistingPriceMatrix).size() > 0);
            
            system.assert(APT_PricingUtility.createPriceMatrixEntryForDomestic(listPriceMatrix, mapDomesticPriceData).size() > 0);
          
        }
    }
     /**
        Creating test data
    **/   
    static testMethod void testMethodElseR2TDP() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //price list
            Apttus_Config2__PriceList__c PriceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create Domestic product
            list<Product2> listProduct = new list<Product2>();
            Product2 product1 = APT_TestUtils.createDomesticProduct('Air Mail Letters', 'AIRLET', 'Parcel Services','CAT2','Standard');
            listProduct.add(product1);               
            insert listProduct; 
            
            Set<String> setLodgment = new set<String>{'LodgmentZone1','LodgmentZone2'};
            Set<String> setPricing = new set<String>{'WINE {Z20}','WINE {Z30}'};
            map<String, Set<String>> mapLodgment = new map<String, Set<String>>();
            mapLodgment.put('CAT2~Standard', setLodgment);
            map<String, Set<String>> mapPricing = new map<String, Set<String>>();
            mapPricing.put('CAT2~Standard', setPricing);
            
            //price list item
            list<Apttus_Config2__PriceListItem__c> listPLI = new list<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c testPLI1 = APT_TestUtils.createPriceListItem(priceList.Id, product1.Id, 'B Mining', 'BAND 1');
            listPLI.add(testPLI1);               
            insert listPLI;        
            
            
            map<String, Apttus_Config2__PriceListItem__c> mapExistingPLI = new map<String, Apttus_Config2__PriceListItem__c>();
            mapExistingPLI.put(product1.productCode + '~BAND 1~True', testPLI1);
            mapExistingPLI.put(product1.productCode + '~BAND 1~False', testPLI1);               
            
            //product attribute group
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createproductAttributeGroup('Apttus_Config2__productAttribute321Value__c');
            insert productAttributeGroup;
            
            //product attribute
            list<Apttus_Config2__ProductAttribute__c> listProductAttribute = new list<Apttus_Config2__ProductAttribute__c>();
            Apttus_Config2__ProductAttribute__c productAttribute1 = APT_TestUtils.createproductAttribute('APT_Zone__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute1);
            
            Apttus_Config2__ProductAttribute__c productAttribute2 = APT_TestUtils.createproductAttribute('APT_Domestic_Price_Type__c', productAttributeGroup.Id);
            listProductAttribute.add(productAttribute2);
            
            insert listProductAttribute;
            
            //price dimension
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__productAttribute321Value__c', 'APT_Zone__c', productAttribute1.Id);
            listPriceDimension.add(priceDimension1);        
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__productAttribute3Value__c', 'APT_Domestic_Price_Type__c', productAttribute2.Id);
            listPriceDimension.add(priceDimension2);        
            insert listPriceDimension;
            
            map<String, String> mapDimension = new map<String, String> {priceDimension1.Name => priceDimension1.Id, priceDimension2.Name => priceDimension2.Id};
            
            
            
            //price matrix
            list<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new list<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c pm1 = APT_TestUtils.createPriceMatrix(testPLI1.Id, priceDimension1.Id, priceDimension2.Id, priceDimension1.Id);
            listPriceMatrix.add(pm1);        
            insert listPriceMatrix;
            
            listPriceMatrix = [SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Category__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
                               Apttus_Config2__PriceListItemId__r.APT_Lodgement_Zone_Code__c,
                               Apttus_Config2__PriceListItemId__r.APT_Price_Structure__c,
                               Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                               Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                               Apttus_Config2__PriceListItemId__r.APT_Band__c,
                               Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                               FROM Apttus_Config2__PriceMatrix__c
                               WHERE Id = :pm1.Id];
            
            
            map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new map<String, Apttus_Config2__PriceMatrix__c>();
            //mapExistingPriceMatrix.put(testPLI1.Id, pm1);
            
            //international price data
             list<APT_Domestic_Price_Data__c > listDomesticPriceData = new list<APT_Domestic_Price_Data__c >();
            
            APT_Domestic_Price_Data__c  dpd1 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd1);
            
            APT_Domestic_Price_Data__c  dpd2 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd2);
            
            APT_Domestic_Price_Data__c  dpd3 = APT_TestUtils.createDomesticPriceData('CAT2', 'Standard', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd3);
            
            APT_Domestic_Price_Data__c  dpd4 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'N1', 'Sydney', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd4);
            
            APT_Domestic_Price_Data__c  dpd5 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'GF', 'Gosford', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd5);
            
            APT_Domestic_Price_Data__c  dpd6 = APT_TestUtils.createDomesticPriceData('CAT2', 'Express', 'AAT', 'WG', 'Wollongong', 'BANDED {Z30}', 0.5, 'Upto 500g', 10, 20, 30);
            listDomesticPriceData.add(dpd6);
            insert listDomesticPriceData;
            
            //APT_R2T_Domestic_Pricing_Properties__c
            APT_R2T_Domestic_Pricing_Properties__c r2tDomesticPricingProperties = new APT_R2T_Domestic_Pricing_Properties__c();
            r2tDomesticPricingProperties.Name = 'R2T Domestic Pricing Properties';
            r2tDomesticPricingProperties.APT_Dimension1_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension1_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension2_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension2_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension3_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension3_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension4_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension4_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension5_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension5_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension6_Name__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension6_Type__c = 'test';
            r2tDomesticPricingProperties.APT_Dimension1_Value__c = 'Domestic Price Type';
            r2tDomesticPricingProperties.APT_Dimension2_Value__c = 'Domestic Price Type';
            r2tDomesticPricingProperties.APT_Dimension3_Value__c = 'Domestic Price Type';
            r2tDomesticPricingProperties.APT_Dimension4_Value__c = 'Domestic Price Type';
            r2tDomesticPricingProperties.APT_Dimension5_Value__c = 'Domestic Price Type';
            r2tDomesticPricingProperties.APT_Dimension6_Value__c = 'Domestic Price Type';
            insert r2tDomesticPricingProperties;
            
            map<String, list<APT_Domestic_Price_Data__c>> mapDomesticPriceData = new map<String, list<APT_Domestic_Price_Data__c>>();
            for(APT_Domestic_Price_Data__c dpd : listDomesticPriceData) {
                list<APT_Domestic_Price_Data__c> listDPD = mapDomesticPriceData.get(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c);
                if(listDPD != null && listDPD.size() > 0) {
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c, listDPD);
                } else {
                    listDPD = new list<APT_Domestic_Price_Data__c>();
                    listDPD.add(dpd);
                    mapDomesticPriceData.put(dpd.APT_Category__c + '~' + dpd.APT_Network_Type__c + '~' + dpd.APT_Lodgement_Zone_Code__c + '~' + dpd.APT_Price_Structure__c, listDPD);
                }           
            }        
            
            
          
          Test.starttest();
            APT_PricingUtility.createPriceListItemForDomestic(listProduct,PriceList.ID,mapLodgment,mapPricing,mapExistingPLI);
            APT_PricingUtility.createPriceMatrixForDomestic(listPLI, mapDimension, r2tDomesticPricingProperties, mapExistingPriceMatrix);
            APT_PricingUtility.createPriceMatrixEntryForDomestic(listPriceMatrix, mapDomesticPriceData);

          
          Test.stoptest();
            system.assert(APT_PricingUtility.createPriceListItemForDomestic(listProduct,PriceList.ID,mapLodgment,mapPricing,mapExistingPLI).size()>0);
            
            system.assert(APT_PricingUtility.createPriceMatrixForDomestic(listPLI, mapDimension, r2tDomesticPricingProperties, mapExistingPriceMatrix).size() > 0);
            
            system.assert(APT_PricingUtility.createPriceMatrixEntryForDomestic(listPriceMatrix, mapDomesticPriceData).size() > 0);
        }
    }
    
}