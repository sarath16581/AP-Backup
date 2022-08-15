/***
 * @author Darshan Chauhan
 * @date 2021-03-01
 * @group 
 * @description Tests the execution of the batch class APT_PricingDataBatch which creates the Price list items for the respective pricing data.
 * @changelog
 * 2021-04-01 - Darshan Chauhan - Created
 * 2021-05-01 - Mathew Jose - Created test methods to test missing scenarios.
 * 2021-09-23 - Mathew Jose - Added test methods test the simplified parcel products (Appc Speed & FSR)
 * 2022-05-15 - Nasir JAwed Changed Tier
*/

@isTest
public with sharing class APT_PricingDataBatch_Test {
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
        priceListItemList.add(priceListItem5); 
        
        //pli for APPC FSR
        Apttus_Config2__PriceListItem__c priceListItem6 = APT_TestUtils.createPriceListItem(priceList.id,product_APPC_FSR1.id,'','');
        priceListItem6.APT_Pricing_Key__c = product_APPC_FSR1.Id + '~' + 'Parcel Contract-Feature';
        priceListItemList.add(priceListItem6);      

        insert priceListItemList;

        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
        insert productAttributeGroup;
        
        Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
        insert productAttribute;
        
        list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Destination Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute.Id);
        listPriceDimension.add(priceDimension1);
        
        Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension2);
        
        Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('Weight Range Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute.Id);
        listPriceDimension.add(priceDimension3);

        Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('Zone Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension4); 

        Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('Inbound - Outbound', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute.Id);
        listPriceDimension.add(priceDimension5);
        
        Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('Pickup Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute.Id);
        listPriceDimension.add(priceDimension6);
        
        Apttus_Config2__PriceDimension__c priceDimension7 = APT_TestUtils.createPriceDimension('Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension7);
        
        Apttus_Config2__PriceDimension__c priceDimension8 = APT_TestUtils.createPriceDimension('Basic Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Basic_Charge__c', productAttribute.Id);
        listPriceDimension.add(priceDimension8);            

        Apttus_Config2__PriceDimension__c priceDimension9 = APT_TestUtils.createPriceDimension('KG Rate', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_KG_Rate__c', productAttribute.Id);
        listPriceDimension.add(priceDimension9); 
        
        Apttus_Config2__PriceDimension__c priceDimension10 = APT_TestUtils.createPriceDimension('Minimum Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Minimum_Charge__c', productAttribute.Id);
        listPriceDimension.add(priceDimension10);

        Apttus_Config2__PriceDimension__c priceDimension11 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension11);
        
        Apttus_Config2__PriceDimension__c priceDimension12 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
        listPriceDimension.add(priceDimension12);
        
        Apttus_Config2__PriceDimension__c priceDimension13 = APT_TestUtils.createPriceDimension('Weight Range', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Weight_Range__c', productAttribute.Id);
        listPriceDimension.add(priceDimension13);

        Apttus_Config2__PriceDimension__c priceDimension14 = APT_TestUtils.createPriceDimension('Customer Tier', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Customer_Tier__c', productAttribute.Id);
        listPriceDimension.add(priceDimension14); 
        
        Apttus_Config2__PriceDimension__c priceDimension15 = APT_TestUtils.createPriceDimension('Price Point', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Point__c', productAttribute.Id);
        listPriceDimension.add(priceDimension15); 
        
        Apttus_Config2__PriceDimension__c priceDimension16 = APT_TestUtils.createPriceDimension('Lodgment Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Lodgment_Zone__c', productAttribute.Id);
        listPriceDimension.add(priceDimension16);
        
        Apttus_Config2__PriceDimension__c priceDimension17 = APT_TestUtils.createPriceDimension('Weight Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c','APT_Weight_Code__c', productAttribute.Id);
        listPriceDimension.add(priceDimension17);            

        insert listPriceDimension;
        
        // PM for the Pli corresponding to CAT1STD 
        List<Apttus_Config2__PriceMatrix__c> listPM = new List<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c priceMatrix = APT_TestUtils.createPriceMatrix(priceListItem.Id, priceDimension1.Id, priceDimension2.Id, priceDimension3.Id);
        listPM.add(priceMatrix);

        // PM for the Pli corresponding to NXF 
        Apttus_Config2__PriceMatrix__c priceMatrix1 = APT_TestUtils.createPriceMatrix(priceListItem2.Id, priceDimension6.Id, priceDimension1.Id, priceDimension8.Id);
        priceMatrix1.Apttus_Config2__Dimension4Id__c = priceDimension9.Id;
        priceMatrix1.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
        priceMatrix1.Apttus_Config2__Dimension5Id__c = priceDimension10.Id;
        priceMatrix1.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
        listPM.add(priceMatrix1);   
        
        // PM for the Pli corresponding to EXP 1
        Apttus_Config2__PriceMatrix__c priceMatrix2 = APT_TestUtils.createPriceMatrix(priceListItem3.Id,priceDimension4.Id, priceDimension5.Id, priceDimension6.Id);
        priceMatrix2.Apttus_Config2__Dimension4Id__c = priceDimension1.Id;
        priceMatrix2.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
        priceMatrix2.Apttus_Config2__Dimension5Id__c = priceDimension7.Id;
        priceMatrix2.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
        listPM.add(priceMatrix2); 

        // PM for the Pli corresponding to AIRLET
        Apttus_Config2__PriceMatrix__c priceMatrix3 = APT_TestUtils.createPriceMatrix(priceListItem4.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
        listPM.add(priceMatrix3); 
        
        // PM for the Pli corresponding to SPEED1
        Apttus_Config2__PriceMatrix__c priceMatrix4 = APT_TestUtils.createPriceMatrix(priceListItem5.Id,priceDimension16.Id, priceDimension17.Id, priceDimension2.Id);
        priceMatrix4.Apttus_Config2__Dimension4Id__c = priceDimension15.Id;
        priceMatrix4.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
        listPM.add(priceMatrix4);        

        // PM for the Pli corresponding to FSR1
        Apttus_Config2__PriceMatrix__c priceMatrix5 = new Apttus_Config2__PriceMatrix__c();
        priceMatrix5.Apttus_Config2__Sequence__c=1;
        priceMatrix5.Apttus_Config2__PriceListItemId__c=priceListItem6.Id;
        priceMatrix5.Apttus_Config2__Dimension1Id__c = priceDimension14.Id;
        priceMatrix5.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
        listPM.add(priceMatrix5);        

        insert listPM;

        list<APT_Post_Code_Mapping__c > listPostCodeMapping = new list<APT_Post_Code_Mapping__c >();
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
        pcm1.APT_EXP_Zone_Type__c = 'Onforwarding Alternate-VC3~AC3';
        listPostCodeMapping.add(pcm1);
        
        APT_Post_Code_Mapping__c  pcm2 = APT_TestUtils.createPostCodeMapping('5000', 'QUEENSLAND ZONE 3', 'QC3' , null, null);
        pcm2.APT_EXP_Zone_Type__c = 'Direct-QC3';
        listPostCodeMapping.add(pcm2);
        
        APT_Post_Code_Mapping__c  pcm3 = APT_TestUtils.createPostCodeMapping('5220', 'PARNDANA', null, 'A10', null);
        pcm3.APT_EXP_Zone_Type__c='Onforwarding-A10';
        listPostCodeMapping.add(pcm3); 
        
        insert listPostCodeMapping;

        List<APT_Pricing_Data_Mapping__c> pdmList = new List<APT_Pricing_Data_Mapping__c>();
		
        //pdm productCAT1STD
        APT_Pricing_Data_Mapping__c pdMapping = new APT_Pricing_Data_Mapping__c();
        pdMapping.APT_Pricing_Value_Name_1__c = 'Price Structure';
        pdMapping.APT_Pricing_Value_Name_2__c = 'Lodgement Zone Code';
        pdMapping.APT_Pricing_Value_Name_3__c = 'Destination Zone';
        pdMapping.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
        pdMapping.APT_Pricing_Value_Name_5__c = 'Destination Zone List Order';
        pdMapping.APT_Pricing_Value_Name_6__c = 'Weight Range Code';
        pdMapping.APT_Pricing_Value_Name_7__c = 'Weight Range Code Description';
        pdMapping.APT_Pricing_Value_Name_8__c = 'Base Rate';
        pdMapping.APT_Pricing_Value_Name_9__c = 'Subsequent Rate';
        pdMapping.APT_Pricing_Value_Name_10__c = 'Per Kg Rate';
        pdMapping.APT_Product__c = productCAT1STD.Id;
        pdmList.add(pdMapping);

        //pdm productNXF (Startrack)
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
        pdMapping1.APT_Product__c = productNXF.Id;
        pdmList.add(pdMapping1);

        //pdm productAIRLET (International)
        APT_Pricing_Data_Mapping__c pdMapping2 = new APT_Pricing_Data_Mapping__c();
        pdMapping2.APT_Pricing_Value_Name_1__c = 'Band';
        pdMapping2.APT_Pricing_Value_Name_2__c = 'Band Range Max';
        pdMapping2.APT_Pricing_Value_Name_3__c = 'Band Range Min';
        pdMapping2.APT_Pricing_Value_Name_4__c = 'Calc Per Item Rate';
        pdMapping2.APT_Pricing_Value_Name_5__c = 'Calc Per Kg Rate';
        pdMapping2.APT_Pricing_Value_Name_6__c = 'CSP Per Item Rate';
        pdMapping2.APT_Pricing_Value_Name_7__c = 'CSP Per Kg Rate';
        pdMapping2.APT_Pricing_Value_Name_8__c = 'Industry';
        pdMapping2.APT_Pricing_Value_Name_9__c = 'eParcel Per Item Rate';
        pdMapping2.APT_Pricing_Value_Name_10__c = 'eParcel Per Kg Rate';
        pdMapping2.APT_Pricing_Value_Name_11__c = 'Weight Range';
        pdMapping2.APT_Pricing_Value_Name_12__c = 'Zone';
        pdMapping2.APT_Product__c = productAIRLET.Id;
        pdmList.add(pdMapping2);       

        //pdm productEXP (Startrack)
        APT_Pricing_Data_Mapping__c pdMapping3 = new APT_Pricing_Data_Mapping__c();
        pdMapping3.APT_Pricing_Value_Name_1__c = 'Outbound - Inbound';
        pdMapping3.APT_Pricing_Value_Name_2__c = 'Pickup Zone Code';
        pdMapping3.APT_Pricing_Value_Name_3__c = 'Lodgement Zone';
        pdMapping3.APT_Pricing_Value_Name_4__c = 'Destination Zone Code';
        pdMapping3.APT_Pricing_Value_Name_5__c = 'Destination Zone';
        pdMapping3.APT_Pricing_Value_Name_6__c = 'Base Rate';
        pdMapping3.APT_Pricing_Value_Name_7__c = 'Per Kg Rate';
        pdMapping3.APT_Pricing_Value_Name_8__c = 'Subsequent Rate';
        pdMapping3.APT_Pricing_Value_Name_9__c = 'Rate Card Version';
        pdMapping3.APT_Pricing_Value_Name_10__c = 'Rate Card Updated On';
        pdMapping3.APT_Pricing_Value_Name_11__c = '';
        pdMapping3.APT_Pricing_Value_Name_12__c = 'Zone Type';
        pdMapping3.APT_Product__c = productEXP.Id;
        pdmList.add(pdMapping3);

        //PDM SPEED1
        APT_Pricing_Data_Mapping__c pdMapping4 = new APT_Pricing_Data_Mapping__c();
        pdMapping4.APT_Pricing_Value_Name_1__c = 'Price Structure';
        pdMapping4.APT_Pricing_Value_Name_2__c = 'Lodgment Zone';
        pdMapping4.APT_Pricing_Value_Name_3__c = 'Weight Code';
        pdMapping4.APT_Pricing_Value_Name_4__c = 'Weight Range Code Description';
        pdMapping4.APT_Pricing_Value_Name_5__c = 'Base Rate';
        pdMapping4.APT_Pricing_Value_Name_6__c = 'Per Kg Rate';
        pdMapping4.APT_Pricing_Value_Name_7__c = 'Price Point';
        pdMapping4.APT_Product__c = product_APPC_SPEED1.Id;
        pdmList.add(pdMapping4);
        
        //PDM FSR1
        APT_Pricing_Data_Mapping__c pdMapping5 = new APT_Pricing_Data_Mapping__c();
        pdMapping5.APT_Pricing_Value_Name_1__c = 'Product Type';
        pdMapping5.APT_Pricing_Value_Name_2__c = 'Customer Tier';
        pdMapping5.APT_Pricing_Value_Name_3__c = 'Amount';
        pdMapping5.APT_Pricing_Value_Name_4__c = 'Price Point';
        pdMapping5.APT_Product__c = product_APPC_FSR1.Id;
        pdmList.add(pdMapping5);           

        insert pdmList;

        List<APT_Pricing_Data__c> pdList = new List<APT_Pricing_Data__c>();

        //Pricing Data CAT1 STD
        APT_Pricing_Data__c pricData = new APT_Pricing_Data__c();
        pricData.APT_Product__c = productCAT1STD.Id;
        pricData.APT_Pricing_Value_1__c = 'BANDED {Z6}';        
        pricData.APT_Pricing_Value_2__c = 'CB';
        pricData.APT_Pricing_Value_3__c = 'Metro';
        pricData.APT_Pricing_Value_4__c = 'Q5';
        pricData.APT_Pricing_Value_5__c = '';
        pricData.APT_Pricing_Value_6__c = '0.5';
        pricData.APT_Pricing_Value_7__c = 'Up to 500g';
        pricData.APT_Pricing_Value_8__c = '7.37';
        pricData.APT_Pricing_Value_9__c = '6.51';
        pricData.APT_Pricing_Value_10__c = '1.28';
        pricData.APT_Pricing_Data_Mapping__c = pdMapping.Id;
        pdList.add(pricData);

        //Pricing data NXF
        APT_Pricing_Data__c pricData1 = new APT_Pricing_Data__c();
        pricData1.APT_Product__c = productNXF.Id;
        pricData1.APT_Pricing_Value_1__c = 'Outbound';
        pricData1.APT_Pricing_Value_2__c = 'QC3';
        pricData1.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 4';
        pricData1.APT_Pricing_Value_4__c = 'QC3';
        pricData1.APT_Pricing_Value_5__c = 'LAUNCESTON ZONE 1';
        pricData1.APT_Pricing_Value_6__c = '300';
        pricData1.APT_Pricing_Value_7__c = '65.66';
        pricData1.APT_Pricing_Value_8__c = '300';
        pricData1.APT_Pricing_Value_9__c = 'V8.1';
        pricData1.APT_Pricing_Value_10__c = 'Aug-20';
        pricData1.APT_Pricing_Data_Mapping__c = pdMapping1.Id;
        pdList.add(pricData1); 

        //Pricing Data EXP1
        APT_Pricing_Data__c pricData3 = new APT_Pricing_Data__c();
        pricData3.APT_Product__c = productEXP.Id;
        pricData3.APT_Pricing_Value_1__c = 'Outbound';
        pricData3.APT_Pricing_Value_2__c = 'QC3';
        pricData3.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 4';
        pricData3.APT_Pricing_Value_4__c = 'AC3';
        pricData3.APT_Pricing_Value_5__c = 'LAUNCESTON ZONE 1';
        pricData3.APT_Pricing_Value_6__c = '300';
        pricData3.APT_Pricing_Value_7__c = '65.66';
        pricData3.APT_Pricing_Value_8__c = '300';
        pricData3.APT_Pricing_Value_9__c = 'V8.1';
        pricData3.APT_Pricing_Value_10__c = 'Aug-20'; 
        pricData3.APT_Pricing_Value_12__c = '{\"onforwardingZone\":null,\"onforwardingAlternateZone\":null,\"directZone\":\"QC3\"}';         
        pricData3.APT_Pricing_Data_Mapping__c = pdMapping3.Id;
        pdList.add(pricData3);
        
        //Pricing Data EXP2
        APT_Pricing_Data__c pricData4 = new APT_Pricing_Data__c();
        pricData4.APT_Product__c = productEXP.Id;
        pricData4.APT_Pricing_Value_1__c = 'Outbound';
        pricData4.APT_Pricing_Value_2__c = 'A10';
        pricData4.APT_Pricing_Value_3__c = 'QUEENSLAND ZONE 4';
        pricData4.APT_Pricing_Value_4__c = 'AC3';
        pricData4.APT_Pricing_Value_5__c = 'LAUNCESTON ZONE 1';
        pricData4.APT_Pricing_Value_6__c = '300';
        pricData4.APT_Pricing_Value_7__c = '65.66';
        pricData4.APT_Pricing_Value_8__c = '300';
        pricData4.APT_Pricing_Value_9__c = 'V8.1';
        pricData4.APT_Pricing_Value_10__c = 'Aug-20';
        pricData4.APT_Pricing_Value_12__c = '{\"onforwardingZone\":\"A10\",\"onforwardingAlternateZone\":null,\"directZone\":null}'; 
        pricData4.APT_Pricing_Data_Mapping__c = pdMapping3.Id;
        pdList.add(pricData4); 
                 
        
        //Pricing data for AIRLET
        APT_Pricing_Data__c pricData2 = new APT_Pricing_Data__c();
        pricData2.APT_Product__c = productAIRLET.Id;
        pricData2.APT_Pricing_Value_1__c = 'BAND 1';
        pricData2.APT_Pricing_Value_2__c = '2999.99';
        pricData2.APT_Pricing_Value_3__c = '0';
        pricData2.APT_Pricing_Value_4__c = '';
        pricData2.APT_Pricing_Value_5__c = '';
        pricData2.APT_Pricing_Value_6__c = '1.6';
        pricData2.APT_Pricing_Value_7__c = '28.7';
        pricData2.APT_Pricing_Value_8__c = '1.6';
        pricData2.APT_Pricing_Value_9__c = '28.7';
        pricData2.APT_Pricing_Value_10__c = 'Auto Parts';
        pricData2.APT_Pricing_Value_10__c = 'Up to 500g';
        pricData2.APT_Pricing_Value_10__c = 'Zone6';
        pricData2.APT_Pricing_Data_Mapping__c = pdMapping2.Id;
        pdList.add(pricData2);

        //Pricing data for SPEED 1
        APT_Pricing_Data__c pricData5 = new APT_Pricing_Data__c();
        pricData5.APT_Product__c = product_APPC_SPEED1.Id;
        pricData5.APT_Pricing_Value_1__c = 'Z6';
        pricData5.APT_Pricing_Value_2__c = 'Capital_Interstate_Capital';
        pricData5.APT_Pricing_Value_3__c = '3';
        pricData5.APT_Pricing_Value_4__c = '1.001kg to 3kg';
        pricData5.APT_Pricing_Value_5__c = '9.28';
        pricData5.APT_Pricing_Value_6__c = '';
        pricData5.APT_Pricing_Value_7__c = 'CAISCAL_BRSP00S006CA';
        pricData5.APT_Pricing_Data_Mapping__c = pdMapping4.Id;
        pdList.add(pricData5); 
        
        //Pricing data for FSR 1
        APT_Pricing_Data__c pricData6 = new APT_Pricing_Data__c();
        pricData6.APT_Product__c = product_APPC_FSR1.Id;
        pricData6.APT_Pricing_Value_1__c = 'Parcel Contract-Feature';
        pricData6.APT_Pricing_Value_2__c = 'T04';
        pricData6.APT_Pricing_Value_3__c = '100';
        pricData6.APT_Pricing_Value_4__c = 'CAISCAL_BRSP00S006CA';
        pricData6.APT_Pricing_Data_Mapping__c = pdMapping5.Id;
        pdList.add(pricData6);          

        insert pdList;         
		
        //price matrix mapping EXP
        APT_Price_Matrix_Mapping__c prmapping = new APT_Price_Matrix_Mapping__c();
        prmapping.APT_Dimension1__c = 'Zone Type';
        prmapping.APT_Dimension2__c = 'Outbound - Inbound';
        prmapping.APT_Dimension3__c = 'Pickup Zone Code';
        prmapping.APT_Dimension4__c = 'Destination Zone Code';
        prmapping.APT_Dimension5__c = 'Price Type';
        prmapping.APT_Dimension6__c = '';
        prmapping.APT_Dimension1_API__c = 'APT_Zone_Type__c';
        prmapping.APT_Dimension2_API__c = 'APT_Inbound_Outbound__c';
        prmapping.APT_Dimension3_API__c = 'APT_Lodgement_Zone_Code__c';
        prmapping.APT_Dimension4_API__c = 'APT_Destination_Zone_Code__c';
        prmapping.APT_Dimension5_API__c = 'APT_Price_Type__c';
        prmapping.APT_Dimension6_API__c = '';
        prmapping.APT_Dimension1_Type__c = 'Discrete';
        prmapping.APT_Dimension2_Type__c = 'Discrete';
        prmapping.APT_Dimension3_Type__c = 'Discrete';
        prmapping.APT_Dimension4_Type__c = 'Discrete';
        prmapping.APT_Dimension5_Type__c = 'Discrete';
        prmapping.APT_Dimension6_Type__c = '';
        prmapping.APT_Product__c = productEXP.Id;
        insert prmapping;
        
        //price matrix mapping NXF
        APT_Price_Matrix_Mapping__c prmapping1 = new APT_Price_Matrix_Mapping__c();
        prmapping1.APT_Dimension1__c = 'Pickup Zone Code';
        prmapping1.APT_Dimension2__c = 'Destination Zone Code';
        prmapping1.APT_Dimension3__c = 'Base Rate';
        prmapping1.APT_Dimension4__c = 'Per Kg Rate';
        prmapping1.APT_Dimension5__c = 'Subsequent Rate';
        prmapping1.APT_Dimension6__c = '';
        prmapping1.APT_Dimension1_API__c = 'APT_Pickup_Zone_Code__c';
        prmapping1.APT_Dimension2_API__c = 'APT_Destination_Zone_Code__c';
        prmapping1.APT_Dimension3_API__c = 'APT_Basic_Charge__c';
        prmapping1.APT_Dimension4_API__c = 'APT_KG_Rate__c';
        prmapping1.APT_Dimension5_API__c = 'APT_Minimum_Charge__c';
        prmapping1.APT_Dimension6_API__c = '';
        prmapping1.APT_Dimension1_Type__c = 'Discrete';
        prmapping1.APT_Dimension2_Type__c = 'Discrete';
        prmapping1.APT_Dimension3_Type__c = 'Discrete';
        prmapping1.APT_Dimension4_Type__c = 'Discrete';
        prmapping1.APT_Dimension5_Type__c = 'Discrete';
        prmapping1.APT_Dimension6_Type__c = '';
        prmapping1.APT_Product__c = productNXF.Id;
        insert prmapping1;   
        
        //price matrix mapping AIRLET
        APT_Price_Matrix_Mapping__c prmapping2 = new APT_Price_Matrix_Mapping__c();
        prmapping2.APT_Dimension1__c = 'Zone';
        prmapping2.APT_Dimension2__c = 'International Price Type';
        prmapping2.APT_Dimension3__c = 'Weight Range';
        prmapping2.APT_Dimension4__c = '';
        prmapping2.APT_Dimension5__c = '';
        prmapping2.APT_Dimension6__c = '';
        prmapping2.APT_Dimension1_API__c = 'APT_Zone__c';
        prmapping2.APT_Dimension2_API__c = 'APT_International_Price_Type__c';
        prmapping2.APT_Dimension3_API__c = 'Weight_Range__c';
        prmapping2.APT_Dimension4_API__c = '';
        prmapping2.APT_Dimension5_API__c = '';
        prmapping2.APT_Dimension6_API__c = '';
        prmapping2.APT_Dimension1_Type__c = 'Discrete';
        prmapping2.APT_Dimension2_Type__c = 'Discrete';
        prmapping2.APT_Dimension3_Type__c = 'Discrete';
        prmapping2.APT_Dimension4_Type__c = '';
        prmapping2.APT_Dimension5_Type__c = '';
        prmapping2.APT_Dimension6_Type__c = '';
        prmapping2.APT_Product__c = productAIRLET.Id;
        insert prmapping2; 
        
        //price matrix mapping CAT1 STD
        APT_Price_Matrix_Mapping__c prmapping4 = new APT_Price_Matrix_Mapping__c();
        prmapping4.APT_Dimension1__c = 'Destination Zone Code';
        prmapping4.APT_Dimension2__c = 'Weight Range Code';
        prmapping4.APT_Dimension3__c = 'Domestic Price Type';
        prmapping4.APT_Dimension4__c = '';
        prmapping4.APT_Dimension5__c = '';
        prmapping4.APT_Dimension6__c = '';
        prmapping4.APT_Dimension1_API__c = 'APT_Destination_Zone_Code__c';
        prmapping4.APT_Dimension2_API__c = 'APT_Weight_Range_Code__c';
        prmapping4.APT_Dimension3_API__c = 'APT_Domestic_Price_Type__c';
        prmapping4.APT_Dimension4_API__c = '';
        prmapping4.APT_Dimension5_API__c = '';
        prmapping4.APT_Dimension6_API__c = '';
        prmapping4.APT_Dimension1_Type__c = 'Discrete';
        prmapping4.APT_Dimension2_Type__c = 'Range';
        prmapping4.APT_Dimension3_Type__c = 'Discrete';
        prmapping4.APT_Dimension4_Type__c = '';
        prmapping4.APT_Dimension5_Type__c = '';
        prmapping4.APT_Dimension6_Type__c = '';
        prmapping4.APT_Product__c = productCAT1STD.Id;
        insert prmapping4; 

         //price matrix mapping SPEED
         APT_Price_Matrix_Mapping__c prmapping5 = new APT_Price_Matrix_Mapping__c();
         prmapping5.APT_Dimension1__c = 'Lodgment Zone';
         prmapping5.APT_Dimension2__c = 'Weight Code';
         prmapping5.APT_Dimension3__c = 'Domestic Price Type';
         prmapping5.APT_Dimension4__c = 'Price Point';
         prmapping5.APT_Dimension5__c = '';
         prmapping5.APT_Dimension6__c = '';
         prmapping5.APT_Dimension1_API__c = 'APT_Lodgment_Zone__c';
         prmapping5.APT_Dimension2_API__c = 'APT_Weight_Code__c';
         prmapping5.APT_Dimension3_API__c = 'APT_Domestic_Price_Type__c';
         prmapping5.APT_Dimension4_API__c = 'APT_Price_Point__c';
         prmapping5.APT_Dimension5_API__c = '';
         prmapping5.APT_Dimension6_API__c = '';
         prmapping5.APT_Dimension1_Type__c = 'Discrete';
         prmapping5.APT_Dimension2_Type__c = 'Range';
         prmapping5.APT_Dimension3_Type__c = 'Discrete';
         prmapping5.APT_Dimension4_Type__c = 'Discrete';
         prmapping5.APT_Dimension5_Type__c = '';
         prmapping5.APT_Dimension6_Type__c = '';
         prmapping5.APT_Product__c = product_APPC_SPEED1.Id;
         insert prmapping5; 
         
         //price matrix mapping FSR
         APT_Price_Matrix_Mapping__c prmapping6 = new APT_Price_Matrix_Mapping__c();
         prmapping6.APT_Dimension1__c = 'Customer Tier';
         prmapping6.APT_Dimension1_API__c = 'APT_Customer_Tier__c';
         prmapping6.APT_Dimension1_Type__c = 'Discrete';
         prmapping6.APT_Product__c = product_APPC_FSR1.Id;
         insert prmapping6;          
        

    }      
    static testMethod void validatePricingDataBatchTestStartTrack() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            APT_PricingDataBatch pliBatch = new APT_PricingDataBatch(TEST_STARTRACK_PRODUCT_TYPE,'');
            Database.executeBatch(pliBatch);
        }
        test.stopTest();
        system.assertEquals (3,([Select Id from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.Productcode in ('NextFlightTier1','RoadExpress')]).size());
    }

    static testMethod void validatePricingDataBatchTestDomestic() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            APT_PricingDataBatch pliBatch = new APT_PricingDataBatch(TEST_DOMESTIC_PRODUCT_TYPE,'BANDED {Z6}');
            Database.executeBatch(pliBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.Productcode in ('CAT1Standard')]).size());
    }

    static testMethod void validatePricingDataBatchTestInternational() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            APT_PricingDataBatch pliBatch = new APT_PricingDataBatch(TEST_International_PRODUCT_TYPE,'');
            Database.executeBatch(pliBatch);
        }
        test.stopTest();
        system.assertEquals (1,([Select Id from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.Productcode in ('AIRLET')]).size());
    }

    static testMethod void validatePricingDataBatchAppcSpeedTest() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            APT_PricingDataBatch pliBatch = new APT_PricingDataBatch(TEST_DOMESTIC_PARCEL_CONTRACT_PRODUCT_TYPE,'Z6');
            Database.executeBatch(pliBatch);
        }
        test.stopTest();
        List<Apttus_Config2__PriceListItem__c>pliList = new List<Apttus_Config2__PriceListItem__c>([Select Id from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.Productcode in ('PDSP00_Capital')]);
        system.assertEquals (1,pliList.size());        

    } 
    
    static testMethod void validatePricingDataBatchAppcFSRTest() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        test.startTest();
        System.runAs(testuser) {
            APT_PricingDataBatch pliBatch = new APT_PricingDataBatch(TEST_DOMESTIC_FSR_PRODUCT_TYPE,'');
            Database.executeBatch(pliBatch);
        }
        test.stopTest();
        List<Apttus_Config2__PriceListItem__c>pliList = new List<Apttus_Config2__PriceListItem__c>([Select Id,APT_Price_Point__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.Productcode in ('FSR1')]);
        system.assertEquals (1,pliList.size());
        system.assertEquals ('CAISCAL_BRSP00S006CA',pliList[0].APT_Price_Point__c);
    }       

}