	/***
	 * @author Mathew Jose
	 * @date 2021-03-01
	 * @group
	 * @description Test class consisting of methods to test the helper methods in the APT_PricingBatchUtility class.
	 * @changelog
	 * 2021-03-01 - Darshan Chauhan - Created
	 * 2021-09-23 - Mathew Jose - Added test methods test the simplified parcel products (Appc Speed & FSR)
	 * 2022-05-15 - Nasir Jawed -
	*/

	@isTest
public with sharing class APT_PricingBatchUtility_Test {
	public static final string TEST_STARTRACK_PRODUCT_TYPE = 'Startrack';
	public static final string TEST_DOMESTIC_PRODUCT_TYPE = 'Domestic_Non_Startrack';
	public static final string TEST_International_PRODUCT_TYPE = 'International';
	public static final string TEST_DOMESTIC_PARCEL_CONTRACT_PRODUCT_TYPE = 'Domestic_Simplified_Parcel_Contract';
	public static final string TEST_DOMESTIC_FSR_PRODUCT_TYPE = 'Domestic_Simplified_Features_Surcharges';

	@TestSetup
	static void createData(){
		//Domestic non startrack
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

		//International product 2 (new product)
		Product2 productAIRLET1 = APT_TestUtils.createInternationalProduct('Air Mail Letters1', 'AIRLET1', 'Parcel Services');
		productAIRLET1.APT_International_Pricing__c = true;
		insert productAIRLET1;

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
		//pli for productNXF
		Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id,productNXF.id,'','');
		priceListItem2.APT_Pricing_Key__c = productNXF.Id;
		priceListItem2.APT_Zone_Combination__c = productNXF.Id;
		priceListItemList.add(priceListItem2);
		//pli for EXP 1
		Apttus_Config2__PriceListItem__c priceListItem3 = APT_TestUtils.createPriceListItem(priceList.id,productEXP.id,'','');
		priceListItem3.APT_Pricing_Key__c = productEXP.Id+'~'+'QC3';
		priceListItem3.APT_Zone_Combination__c = productEXP.Id +'~QC3~Direct-QC3';
		priceListItemList.add(priceListItem3);

		//pli for EXP 2
		Apttus_Config2__PriceListItem__c priceListItem4 = APT_TestUtils.createPriceListItem(priceList.id,productEXP.id,'','');
		priceListItem4.APT_Pricing_Key__c = productEXP.Id+'~'+'A10';
		priceListItem4.APT_Zone_Combination__c = productEXP.Id +'~A10~Onforwarding-A10';
		priceListItemList.add(priceListItem4);

		//pli for AIRLET
		Apttus_Config2__PriceListItem__c priceListItem5 = APT_TestUtils.createPriceListItem(priceList.id,productAIRLET.id,'','');
		priceListItem5.APT_Pricing_Key__c = productAIRLET.Id + '~' + productAIRLET.Productcode+'~'+'BAND 1';
		priceListItemList.add(priceListItem5);

		//pli for AIRLET1
		Apttus_Config2__PriceListItem__c priceListItem6 = APT_TestUtils.createPriceListItem(priceList.id,productAIRLET1.id,'','');
		priceListItem6.APT_Pricing_Key__c = productAIRLET1.Id + '~' + productAIRLET1.Productcode+'~'+'BAND 1';
		priceListItemList.add(priceListItem6);

		//pli for APPC SPEED
		Apttus_Config2__PriceListItem__c priceListItem7 = APT_TestUtils.createPriceListItem(priceList.id,product_APPC_SPEED1.id,'','');
		priceListItem7.APT_Pricing_Key__c = product_APPC_SPEED1.Id + '~' + 'Z6';
		priceListItemList.add(priceListItem7);

		//pli for APPC FSR
		Apttus_Config2__PriceListItem__c priceListItem8 = APT_TestUtils.createPriceListItem(priceList.id,product_APPC_FSR1.id,'','');
		priceListItem8.APT_Pricing_Key__c = product_APPC_FSR1.Id + '~' + 'Parcel Contract-Feature';
		priceListItemList.add(priceListItem8);

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

		// PM for the Pli corresponding to EXP 2
		Apttus_Config2__PriceMatrix__c priceMatrix3 = APT_TestUtils.createPriceMatrix(priceListItem4.Id,priceDimension4.Id, priceDimension5.Id, priceDimension6.Id);
		priceMatrix3.Apttus_Config2__Dimension4Id__c = priceDimension1.Id;
		priceMatrix3.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
		priceMatrix3.Apttus_Config2__Dimension5Id__c = priceDimension7.Id;
		priceMatrix3.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
		listPM.add(priceMatrix3);

		// PM for the Pli corresponding to AIRLET
		Apttus_Config2__PriceMatrix__c priceMatrix4 = APT_TestUtils.createPriceMatrix(priceListItem5.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
		listPM.add(priceMatrix4);

		// PM for the Pli corresponding to SPEED1
		Apttus_Config2__PriceMatrix__c priceMatrix5 = APT_TestUtils.createPriceMatrix(priceListItem7.Id,priceDimension16.Id, priceDimension17.Id, priceDimension2.Id);
		priceMatrix5.Apttus_Config2__Dimension4Id__c = priceDimension15.Id;
		priceMatrix5.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
		listPM.add(priceMatrix5);

		// PM for the Pli corresponding to FSR1
		Apttus_Config2__PriceMatrix__c priceMatrix6 = new Apttus_Config2__PriceMatrix__c();
		priceMatrix6.Apttus_Config2__Sequence__c=1;
		priceMatrix6.Apttus_Config2__PriceListItemId__c=priceListItem8.Id;
		priceMatrix6.Apttus_Config2__Dimension1Id__c = priceDimension14.Id;
		priceMatrix6.Apttus_Config2__Dimension1ValueType__c = 'Discrete';
		listPM.add(priceMatrix6);
		insert listPM;

		APT_R2T_System_Properties__c syp = new APT_R2T_System_Properties__c();
		syp.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
		insert syp;

		list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
		Apttus_Config2__PriceMatrixEntry__c pme1 = new Apttus_Config2__PriceMatrixEntry__c();
		pme1.Apttus_Config2__Dimension1Value__c = '1';
		pme1.Apttus_Config2__Dimension2Value__c = '2';
		pme1.Apttus_Config2__Dimension3Value__c = '3';
		pme1.Apttus_Config2__PriceMatrixId__c = priceMatrix.Id;
		pme1.Apttus_Config2__Sequence__c = 1;
		pme1.Apttus_Config2__UsageRate__c = 1;
		pme1.Apttus_Config2__AdjustmentAmount__c = 1;
		pme1.Apttus_Config2__PriceOverride__c = 1;
		listPME.add(pme1);

		insert listPME;

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

		//pdm NXF
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

		//PDM AIRLET
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

		//PDM AIRLET
		APT_Pricing_Data_Mapping__c pdMapping4 = new APT_Pricing_Data_Mapping__c();
		pdMapping4.APT_Pricing_Value_Name_1__c = 'Band';
		pdMapping4.APT_Pricing_Value_Name_2__c = 'Band Range Max';
		pdMapping4.APT_Pricing_Value_Name_3__c = 'Band Range Min';
		pdMapping4.APT_Pricing_Value_Name_4__c = 'Calc Per Item Rate';
		pdMapping4.APT_Pricing_Value_Name_5__c = 'Calc Per Kg Rate';
		pdMapping4.APT_Pricing_Value_Name_6__c = 'CSP Per Item Rate';
		pdMapping4.APT_Pricing_Value_Name_7__c = 'CSP Per Kg Rate';
		pdMapping4.APT_Pricing_Value_Name_8__c = 'Industry';
		pdMapping4.APT_Pricing_Value_Name_9__c = 'eParcel Per Item Rate';
		pdMapping4.APT_Pricing_Value_Name_10__c = 'eParcel Per Kg Rate';
		pdMapping4.APT_Pricing_Value_Name_11__c = 'Weight Range';
		pdMapping4.APT_Pricing_Value_Name_12__c = 'Zone';
		pdMapping4.APT_Product__c = productAIRLET1.Id;
		pdmList.add(pdMapping4);

		//PDM EXP
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
		APT_Pricing_Data_Mapping__c pdMapping5 = new APT_Pricing_Data_Mapping__c();
		pdMapping5.APT_Pricing_Value_Name_1__c = 'Price Structure';
		pdMapping5.APT_Pricing_Value_Name_2__c = 'Lodgment Zone';
		pdMapping5.APT_Pricing_Value_Name_3__c = 'Weight Code';
		pdMapping5.APT_Pricing_Value_Name_4__c = 'Weight Range Code Description';
		pdMapping5.APT_Pricing_Value_Name_5__c = 'Base Rate';
		pdMapping5.APT_Pricing_Value_Name_6__c = 'Per Kg Rate';
		pdMapping5.APT_Pricing_Value_Name_7__c = 'Price Point';
		pdMapping5.APT_Product__c = product_APPC_SPEED1.Id;
		pdmList.add(pdMapping5);

		//PDM FSR1
		APT_Pricing_Data_Mapping__c pdMapping6 = new APT_Pricing_Data_Mapping__c();
		pdMapping6.APT_Pricing_Value_Name_1__c = 'Product Type';
		pdMapping6.APT_Pricing_Value_Name_2__c = 'Customer Tier';
		pdMapping6.APT_Pricing_Value_Name_3__c = 'Amount';
		pdMapping6.APT_Pricing_Value_Name_4__c = 'Price Point';
		pdMapping6.APT_Pricing_Value_Name_5__c = 'Transit Cover Type';
		pdMapping5.APT_Product__c = product_APPC_FSR1.Id;
		pdmList.add(pdMapping6);

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

		//Pricing data for AIRLET (new)
		APT_Pricing_Data__c pricData5 = new APT_Pricing_Data__c();
		pricData5.APT_Product__c = productAIRLET1.Id;
		pricData5.APT_Pricing_Value_1__c = 'BAND 1';
		pricData5.APT_Pricing_Value_2__c = '2999.99';
		pricData5.APT_Pricing_Value_3__c = '0';
		pricData5.APT_Pricing_Value_4__c = '';
		pricData5.APT_Pricing_Value_5__c = '';
		pricData5.APT_Pricing_Value_6__c = '1.6';
		pricData5.APT_Pricing_Value_7__c = '28.7';
		pricData5.APT_Pricing_Value_8__c = '1.6';
		pricData5.APT_Pricing_Value_9__c = '28.7';
		pricData5.APT_Pricing_Value_10__c = 'Auto Parts';
		pricData5.APT_Pricing_Value_10__c = 'Up to 500g';
		pricData5.APT_Pricing_Value_10__c = 'Zone6';
		pricData5.APT_Pricing_Data_Mapping__c = pdMapping4.Id;
		pdList.add(pricData5);

		//Pricing data for SPEED 1
		APT_Pricing_Data__c pricData6 = new APT_Pricing_Data__c();
		pricData6.APT_Product__c = product_APPC_SPEED1.Id;
		pricData6.APT_Pricing_Value_1__c = 'Z6';
		pricData6.APT_Pricing_Value_2__c = 'Capital_Interstate_Capital';
		pricData6.APT_Pricing_Value_3__c = '3';
		pricData6.APT_Pricing_Value_4__c = '1.001kg to 3kg';
		pricData6.APT_Pricing_Value_5__c = '9.28';
		pricData6.APT_Pricing_Value_6__c = '';
		pricData6.APT_Pricing_Value_7__c = 'CAISCAL_BRSP00S006CA';
		pricData6.APT_Pricing_Data_Mapping__c = pdMapping5.Id;
		pdList.add(pricData6);

		//Pricing data for FSR 1
		APT_Pricing_Data__c pricData7 = new APT_Pricing_Data__c();
		pricData7.APT_Product__c = product_APPC_FSR1.Id;
		pricData7.APT_Pricing_Value_1__c = 'Parcel Contract-Feature';
		pricData7.APT_Pricing_Value_2__c = 'T04';
		pricData7.APT_Pricing_Value_3__c = '100';
		pricData7.APT_Pricing_Value_4__c = 'TCOVER-NR_FE002';
		pricData7.APT_Pricing_Value_5__c = 'Always On';
		pricData7.APT_Pricing_Data_Mapping__c = pdMapping6.Id;
		pdList.add(pricData7);

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

		//price matrix mapping AIRLET1
		APT_Price_Matrix_Mapping__c prmapping3 = new APT_Price_Matrix_Mapping__c();
		prmapping3.APT_Dimension1__c = 'Zone';
		prmapping3.APT_Dimension2__c = 'International Price Type';
		prmapping3.APT_Dimension3__c = 'Weight Range';
		prmapping3.APT_Dimension4__c = '';
		prmapping3.APT_Dimension5__c = '';
		prmapping3.APT_Dimension6__c = '';
		prmapping3.APT_Dimension1_API__c = 'APT_Zone__c';
		prmapping3.APT_Dimension2_API__c = 'APT_International_Price_Type__c';
		prmapping3.APT_Dimension3_API__c = 'Weight_Range__c';
		prmapping3.APT_Dimension4_API__c = '';
		prmapping3.APT_Dimension5_API__c = '';
		prmapping3.APT_Dimension6_API__c = '';
		prmapping3.APT_Dimension1_Type__c = 'Discrete';
		prmapping3.APT_Dimension2_Type__c = 'Discrete';
		prmapping3.APT_Dimension3_Type__c = 'Discrete';
		prmapping3.APT_Dimension4_Type__c = '';
		prmapping3.APT_Dimension5_Type__c = '';
		prmapping3.APT_Dimension6_Type__c = '';
		prmapping3.APT_Product__c = productAIRLET1.Id;
		insert prmapping3;

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
	/**
	 * This method will test of arrange the generic pricing data into Map
	 */

	@isTest static void getPricingDataAttributesWithValuesTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			test.stopTest();
			System.assertEquals(pricingDataWithMapping.size(), 8);
		}
	}
	/**
	 * This method will test arrange the generic pricing data into Map for the specific field
	 */

	@isTest static void getPricingDataFieldAPITest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			List<APT_Pricing_Data_Mapping__c> priceDataMappingList = new List<APT_Pricing_Data_Mapping__c>();
			priceDataMappingList = [SELECT Id, APT_Product__c, APT_Pricing_Value_Name_1__c ,
										APT_Pricing_Value_Name_2__c, APT_Pricing_Value_Name_3__c,
										APT_Pricing_Value_Name_4__c,
										APT_Pricing_Value_Name_5__c, APT_Pricing_Value_Name_6__c,
										APT_Pricing_Value_Name_7__c, APT_Pricing_Value_Name_8__c,
										APT_Pricing_Value_Name_9__c, APT_Pricing_Value_Name_10__c,
										APT_Pricing_Value_Name_11__c, APT_Pricing_Value_Name_12__c
									FROM APT_Pricing_Data_Mapping__c where APT_Product__r.Name = 'Next Flight Tier 1' limit 1];
			System.debug('priceDataMappingList'+priceDataMappingList);
			test.startTest();
			String fieldAPIName = APT_PricingBatchUtility.getPricingDataFieldAPI(priceDataMappingList,'Pickup Zone Code');
			test.stopTest();
			System.assertEquals(fieldAPIName,'APT_Pricing_Value_2__c');
		}
	}

	/**
	 * This method will test used to identify and return the pli's to be created or updated for ST products.
	 * */

	@isTest static void createPliForStartrackTestEXP() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			Map<String, set<String>> networkTypeToZoneTypesMap = new map<String, set<String>>();
			Map<String, String> lodgementZoneCodeToDescriptionMap = new Map<String, String>();

			Apttus_Pricing_Data_Config__mdt pricingConfigMdt1 = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_STARTRACK_PRODUCT_TYPE);
			networkTypeToZoneTypesMap = APT_PricingBatchUtility.createNetworkTypeToZoneTypesMap(pricingConfigMdt1);

			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'RoadExpress'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'RoadExpress']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Zone_Combination__c, pli);
			}
			for(APT_Pricing_Data__c pData : priceDataList){
				set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c>();
				pricingDataSet.add(pData);
				String pricingKey = '';
				if(pData.APT_Pricing_Value_2__c == 'QC3'){
					pricingKey += pData.APT_Product__c+ '~' + 'QC3';
				}else if(pData.APT_Pricing_Value_2__c == 'A10'){
					pricingKey += pData.APT_Product__c+ '~' + 'A10';
				}
				pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			}
			for(String dpId : pricingDataWithMapping.keySet()){
				lodgementZoneCodeToDescriptionMap.put(pricingDataWithMapping.get(dpId).get('Pickup Zone Code'), pricingDataWithMapping.get(dpId).get('Lodgement Zone'));
			}
			pliMapToUpsert = APT_PricingBatchUtility.createPliForStartrack(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt1, pricingDataWithMapping,networkTypeToZoneTypesMap,lodgementZoneCodeToDescriptionMap);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),2);
		}
	}

	/**
	 * This method will test used to identify and return the pli's to be created or updated for ST products.
	 * */

	@isTest static void createPliForStartrackTestNXF() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			Map<String, set<String>> networkTypeToZoneTypesMap = new map<String, set<String>>();
			Map<String, String> lodgementZoneCodeToDescriptionMap = new Map<String, String>();

			Apttus_Pricing_Data_Config__mdt pricingConfigMdt1 = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_STARTRACK_PRODUCT_TYPE);
			networkTypeToZoneTypesMap = APT_PricingBatchUtility.createNetworkTypeToZoneTypesMap(pricingConfigMdt1);

			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'NextFlightTier1'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'NextFlightTier1']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem )
			{
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}

			set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c> (priceDataList);
			String pricingKey = priceDataList[0].APT_Product__c;
			pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			for(String dpId : pricingDataWithMapping.keySet()){
				lodgementZoneCodeToDescriptionMap.put(pricingDataWithMapping.get(dpId).get('Pickup Zone Code'), pricingDataWithMapping.get(dpId).get('Lodgement Zone'));
			}
			pliMapToUpsert = APT_PricingBatchUtility.createPliForStartrack(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt1, pricingDataWithMapping,networkTypeToZoneTypesMap,lodgementZoneCodeToDescriptionMap);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),1);
		}
	}

	/**
	 * This method will test and return the pli's to be created or updated for Domestic products.
	 * */

	@isTest static void createPliForDomesticExcludingSTTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'CAT1Standard'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'CAT1Standard']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}

			set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c> (priceDataList);

			//For domestic products (not ST) pricing key is productId~Price Structure~Lodgement zone code
			String pricingKey = priceDataList[0].APT_Product__c+'BANDED {Z6}' + '~' + 'CB';
			pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_DOMESTIC_PRODUCT_TYPE);
			pliMapToUpsert = APT_PricingBatchUtility.createPliForDomesticExcludingST(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),1);
		}
	}


	@isTest static void createPliForDomesticAPPCSpeedTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'PDSP00_Capital'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'PDSP00_Capital']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}

			set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c> (priceDataList);

			//For domestic products (not ST) pricing key is productId~Price Structure~Lodgement zone code
			String pricingKey = priceDataList[0].APT_Product__c+'~'+'Z6';
			pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_DOMESTIC_PARCEL_CONTRACT_PRODUCT_TYPE);
			pliMapToUpsert = APT_PricingBatchUtility.createPliForDomesticExcludingST(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),1);
		}
	}


	@isTest static void createPliForDomesticAPPCFSRTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'FSR1'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'FSR1']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}

			set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c> (priceDataList);

			//For domestic FSR products pricing key is productId~Product type
			String pricingKey = priceDataList[0].APT_Product__c+'~'+'Parcel Contract-Feature';
			pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_DOMESTIC_FSR_PRODUCT_TYPE);
			pliMapToUpsert = APT_PricingBatchUtility.createPliForDomesticFSR(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),1);
		}
	}

	/**
	 * This method will test used to identify and return the pli's to be created or updated for international products.
	 * */

	@isTest static void createPliForInternationalTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.APT_International_Pricing__c = true];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.APT_International_Pricing__c = true]);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}
			for(APT_Pricing_Data__c pData : priceDataList){
				set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c>();
				pricingDataSet.add(pData);
				String pricingKey = '';
				pricingKey += pData.APT_Product__c+ '~' +priceDataList[0].APT_Product__r.ProductCode+'~'+pData.APT_Pricing_Value_1__c;
				pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			}
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_International_PRODUCT_TYPE);
			pliMapToUpsert = APT_PricingBatchUtility.createPliForInternational(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),2);
		}
	}

	@isTest static void createPliForInternationalElseTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Map<string,Apttus_Config2__PriceListItem__c> pliMapToUpsert = new Map<string,Apttus_Config2__PriceListItem__c>();
			Map<String, Apttus_Config2__PriceListItem__c> mapExistingKeyToPli = new map<String, Apttus_Config2__PriceListItem__c>();
			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'AIRLET'];
			test.startTest();
			pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);
			LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																	[SELECT Id, Apttus_Config2__ProductId__c,
																		Apttus_Config2__ProductId__r.ProductCode,
																		APT_Pricing_Key__c, APT_Zone_Type__c,
																		APT_Zone_Combination__c
																	FROM Apttus_Config2__PriceListItem__c
																	Where Apttus_Config2__ProductId__r.ProductCode = 'AIRLET']);

			for(Apttus_Config2__PriceListItem__c pli : listPriceListItem ){
				mapExistingKeyToPli.put(pli.APT_Pricing_Key__c, pli);
			}

			set<APT_Pricing_Data__c> pricingDataSet = new set<APT_Pricing_Data__c> (priceDataList);

			//For domestic products (not ST) pricing key is productId~Price Structure~Lodgement zone code
			String pricingKey = '';//priceDataList[0].APT_Product__c+'~'+priceDataList[0].APT_Product__r.ProductCode+ '~' + 'BAND 1';
			pricingKeyToDataMap.put(pricingKey,pricingDataSet);
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_International_PRODUCT_TYPE);
			pliMapToUpsert = APT_PricingBatchUtility.createPliForInternational(mapExistingKeyToPli, pricingKeyToDataMap, pricingConfigMdt, pricingDataWithMapping);
			test.stopTest();
			System.assertEquals(pliMapToUpsert.size(),0);
		}
	}

	/**
	 * This method will test retrieve a map of network type to zone types for relevant products
	 * */
	@isTest static void createNetworkTypeToZoneTypesMapTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			Apttus_Pricing_Data_Config__mdt pricingConfigMdt1 = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_STARTRACK_PRODUCT_TYPE);
			Map<String, set<String>> networkTypeToZoneTypesMap = APT_PricingBatchUtility.createNetworkTypeToZoneTypesMap(pricingConfigMdt1);
			system.assertEquals(networkTypeToZoneTypesMap.size()>0, true);
		}
	}

	/**
	 * This method will test to retrieve the criteria fields from the custom metadata.
	**/

	@isTest static void getConfigCriteriaFieldsMapTest(){

			List<APT_Pricing_Data__c> priceDataList = new List<APT_Pricing_Data__c>();
			Map<String, Set<APT_Pricing_Data__c>> pricingKeyToDataMap = new Map<String, Set<APT_Pricing_Data__c>>();
			Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
			priceDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'AIRLET'];
		pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(priceDataList);

		Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_International_PRODUCT_TYPE);
		List<Apttus_Charge_Type_Criteria__mdt> chargeTypeCriterias = new List<Apttus_Charge_Type_Criteria__mdt>(
				[Select Field_Expression__c, Field_Label__c,
				Field_Name__c, Field_Type__c, Apttus_Pricing_Data_Config__c
				FROM Apttus_Charge_Type_Criteria__mdt
				WHERE Apttus_Pricing_Data_Config__c = : pricingConfigMdt.Id
				]);
		Map<String, String> pricingDataFieldToValueMap = new Map<String, String>();
		for(String pk: pricingKeyToDataMap.keySet()){
			system.debug('*** new pli ***');
			APT_Pricing_Data__c pd = new List<APT_Pricing_Data__c>(pricingKeyToDataMap.get(pk))[0];
			pricingDataFieldToValueMap = pricingDataWithMapping.get(pd.Id);
		}
		List<Map<String,String>>  plList=APT_PricingBatchUtility.getConfigCriteriaFieldsMap(chargeTypeCriterias, null,pricingDataFieldToValueMap);
		system.assertEquals(plList.size()>0, true);
	}

	@isTest static void createPriceMatrixGenericTest(){
		LisT<Apttus_Config2__PriceListItem__c> listPriceListItem = new List<Apttus_Config2__PriceListItem__c>(
																			[SELECT Id, Apttus_Config2__ProductId__c,
																			Apttus_Config2__ProductId__r.ProductCode,
																			APT_Pricing_Key__c, APT_Zone_Type__c,
																			APT_Zone_Combination__c
																			FROM Apttus_Config2__PriceListItem__c]);
		Set<Id> setPriceListItemId = new Set<Id>();
		for(Apttus_Config2__PriceListItem__c pli: listPriceListItem){
			setPriceListItemId.add(pli.Id);
		}
		Map<String, Apttus_Config2__PriceMatrix__c> mapExistingPriceMatrix = new Map<String, Apttus_Config2__PriceMatrix__c>();
		List<Apttus_Config2__PriceMatrix__c> priceMatrixList = new List<Apttus_Config2__PriceMatrix__c>([SELECT Id, Apttus_Config2__PriceListItemId__c,
																										Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c
																										FROM Apttus_Config2__PriceMatrix__c
																										WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]);
		for(Apttus_Config2__PriceMatrix__c pm : priceMatrixList) {
			mapExistingPriceMatrix.put(pm.Apttus_Config2__PriceListItemId__c, pm);
		}

		List<Product2> products= [SELECT Id, Name FROM Product2];
		Map<Id, Product2> productMap = new Map<Id, Product2>(products);

		List<Apttus_Config2__PriceMatrix__c>pmList = APT_PricingBatchUtility.createPriceMatrixGeneric(listPriceListItem, mapExistingPriceMatrix, productMap);
		System.AssertEquals(pmList.size(),8);
	}

	@isTest static void getSTZoneGroupMappingTest(){
		Apttus_Pricing_Data_Config__mdt pricingConfig_Mdt = [SELECT Id, Pricing_Key_Constituents__c, Order_By_Fields__c, National_Rate_Products__c
																FROM Apttus_Pricing_Data_Config__mdt
																WHERE DeveloperName =: TEST_STARTRACK_PRODUCT_TYPE LIMIT 1];



			String nationalRateNetworkTypes = pricingConfig_Mdt?.National_Rate_Products__c;

			List<String> listNationalRateNetworkTypes = new List<String>(nationalRateNetworkTypes.Split(','));
			Set<String> setNationalRateNetworkTypes = new Set<String>();
			for(String nationalRateNetworkType: listNationalRateNetworkTypes){
				setNationalRateNetworkTypes.add(nationalRateNetworkType.trim());
			}
			Map<String, Map<String, String>> stMap=APT_PricingBatchUtility.getSTZoneGroupMapping(setNationalRateNetworkTypes);
			system.assertEquals(stMap.size()>0, true);
	}

	//Test PME creation for domestic product CAT1 STD
	@isTest static void createPriceMatrixEntryGenericTestCAT1STD(){

		Map<String, Set<Map<String,String>>> pricingKeyToDataMap1 = new Map<String, Set<Map<String,String>>>();

		Set<Map<String,String>> pricingDataSet = new Set<Map<String,String>>();

		List<APT_Pricing_Data__c> pricingDataList = new List<APT_Pricing_Data__c> ();
		pricingDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'CAT1Standard'];
		String pricingKey = pricingDataList[0].APT_Product__c+ '~' +'BANDED {Z6}' + '~' + 'CB';
		Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
		pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(pricingDataList);
		for(String pricingDataId : pricingDataWithMapping.keySet()){
			Map<String,String> pricingMap = pricingDataWithMapping.get(pricingDataId);
			pricingDataSet.add(pricingMap);
			pricingKeyToDataMap1.put(pricingKey, pricingDataSet);
		}
		Map<String, String> priceTypeValues = new Map<String, String>();
		Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_DOMESTIC_PRODUCT_TYPE);
		for(Apttus_Price_Types__mdt priceType : [SELECT MasterLabel, Price_Type__c
													FROM Apttus_Price_Types__mdt
													WHERE Apttus_Pricing_Data_Config__c =: pricingConfigMdt.Id]){
			priceTypeValues.put(priceType.MasterLabel, priceType.Price_Type__c);
		}
		List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>([SELECT Id, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
				Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
				Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
				Apttus_Config2__PriceListItemId__r.APT_Zones__c
				FROM Apttus_Config2__PriceMatrix__c]);
		List<Apttus_Config2__PriceMatrixEntry__c> pmeList = APT_PricingBatchUtility.createPriceMatrixEntryGeneric(listPriceMatrix, pricingKeyToDataMap1, priceTypeValues, TEST_DOMESTIC_PRODUCT_TYPE );
		System.AssertEquals(pmeList.size(),3);
	}

	//Test PME creation for Startrack product
	@isTest static void createPriceMatrixEntryGenericTestEXP(){

		Map<String, Set<Map<String,String>>> pricingKeyToDataMap = new Map<String, Set<Map<String,String>>>();
		List<APT_Pricing_Data__c> pricingDataList = new List<APT_Pricing_Data__c> ();
		pricingDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'RoadExpress'];
		Map<Id,APT_Pricing_Data__c> pricingDataMap = new Map<Id,APT_Pricing_Data__c>(pricingDataList);
		//String pricingKey = pricingDataList[0].APT_Product__c+ '~' +'BANDED {Z6}' + '~' + 'CB';


		Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
		pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(pricingDataList);
		for(String pricingDataId : pricingDataWithMapping.keySet()){
			Map<String,String> pricingMap = pricingDataWithMapping.get(pricingDataId);
			Set<Map<String,String>> pricingDataSet = new Set<Map<String,String>>();
			APT_Pricing_Data__c pData =  pricingDataMap.get(pricingDataId);
			String pricingKey = '';
			if(pData.APT_Pricing_Value_2__c == 'QC3'){
				pricingKey += pData.APT_Product__c+ '~' + 'QC3';
			}else if(pData.APT_Pricing_Value_2__c == 'A10'){
				pricingKey += pData.APT_Product__c+ '~' + 'A10';
			}
			pricingDataSet.add(pricingMap);
			pricingKeyToDataMap.put(pricingKey, pricingDataSet);
		}
		Map<String, String> priceTypeValues = new Map<String, String>();
		Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_STARTRACK_PRODUCT_TYPE);
		for(Apttus_Price_Types__mdt priceType : [SELECT MasterLabel, Price_Type__c
													FROM Apttus_Price_Types__mdt
													WHERE Apttus_Pricing_Data_Config__c =: pricingConfigMdt.Id]){
			priceTypeValues.put(priceType.MasterLabel, priceType.Price_Type__c);
		}
		List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>([SELECT Id, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
				Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
				Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
				Apttus_Config2__PriceListItemId__r.APT_Zones__c
				FROM Apttus_Config2__PriceMatrix__c]);
		List<Apttus_Config2__PriceMatrixEntry__c> pmeList = APT_PricingBatchUtility.createPriceMatrixEntryGeneric(listPriceMatrix, pricingKeyToDataMap, priceTypeValues, TEST_STARTRACK_PRODUCT_TYPE );
		System.AssertEquals(pmeList.size(),6);
	}


	//Test PME creation for Startrack product
	@isTest static void createPriceMatrixEntryGenericTestAIRLET(){

		Map<String, Set<Map<String,String>>> pricingKeyToDataMap = new Map<String, Set<Map<String,String>>>();
		List<APT_Pricing_Data__c> pricingDataList = new List<APT_Pricing_Data__c> ();
		pricingDataList = [SELECT Id, APT_Product__c, APT_Product__r.APT_Network_Type__c,  APT_Product__r.ProductCode,
								APT_Pricing_Value_1__c ,
								APT_Pricing_Value_2__c, APT_Pricing_Value_3__c, APT_Pricing_Value_4__c,
								APT_Pricing_Value_5__c, APT_Pricing_Value_6__c,
								APT_Pricing_Value_7__c, APT_Pricing_Value_8__c,APT_Pricing_Value_9__c, APT_Pricing_Value_10__c,
								APT_Pricing_Value_11__c, APT_Pricing_Value_12__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_1__c , APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_2__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_3__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_4__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_5__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_6__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_7__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_8__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_9__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_10__c,
								APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_11__c, APT_Pricing_Data_Mapping__r.APT_Pricing_Value_Name_12__c
							FROM APT_Pricing_Data__c
							WHERE APT_Product__r.ProductCode = 'AIRLET'];
		Map<Id,APT_Pricing_Data__c> pricingDataMap = new Map<Id,APT_Pricing_Data__c>(pricingDataList);
		Map<String,Map<String,String>> pricingDataWithMapping = new Map<String,Map<String,String>>();
		pricingDataWithMapping = APT_PricingBatchUtility.getPricingDataAttributesWithValues(pricingDataList);
		for(String pricingDataId : pricingDataWithMapping.keySet()){
			Map<String,String> pricingMap = pricingDataWithMapping.get(pricingDataId);
			Set<Map<String,String>> pricingDataSet = new Set<Map<String,String>>();
			APT_Pricing_Data__c pData =  pricingDataMap.get(pricingDataId);
			String pricingKey = '';
			pricingKey += pData.APT_Product__c+ '~' + pData.APT_Product__r.ProductCode+'~'+pData.APT_Pricing_Value_1__c;
			pricingDataSet.add(pricingMap);
			pricingKeyToDataMap.put(pricingKey, pricingDataSet);
		}
		Map<String, String> priceTypeValues = new Map<String, String>();
		Apttus_Pricing_Data_Config__mdt pricingConfigMdt = Apttus_Pricing_Data_Config__mdt.getInstance(TEST_International_PRODUCT_TYPE);
		for(Apttus_Price_Types__mdt priceType : [SELECT MasterLabel, Price_Type__c
													FROM Apttus_Price_Types__mdt
													WHERE Apttus_Pricing_Data_Config__c =: pricingConfigMdt.Id]){
			priceTypeValues.put(priceType.MasterLabel, priceType.Price_Type__c);
		}
		List<Apttus_Config2__PriceMatrix__c> listPriceMatrix = new List<Apttus_Config2__PriceMatrix__c>([SELECT Id, Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Network_Type__c,
				Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_Product_type__c,
				Apttus_Config2__PriceListItemId__r.APT_Pricing_Key__c,
				Apttus_Config2__PriceListItemId__r.APT_Zone_Type__c,
				Apttus_Config2__PriceListItemId__r.APT_Zones__c
				FROM Apttus_Config2__PriceMatrix__c]);
		List<Apttus_Config2__PriceMatrixEntry__c> pmeList = APT_PricingBatchUtility.createPriceMatrixEntryGeneric(listPriceMatrix, pricingKeyToDataMap, priceTypeValues, TEST_International_PRODUCT_TYPE );
		System.AssertEquals(pmeList.size(),2);
	}

	@isTest static void sendEmailNotificationTest(){
		set<String> setErrorMessage = new set<String>();
		setErrorMessage.add('error occured');
		try {
			APT_PricingBatchUtility.sendEmailNotification('CreatePMBatch', null, setErrorMessage, ' Batch Job Completed Successfully');
		} catch (Exception ex) {
			system.debug('error occured');
		}
	}

}