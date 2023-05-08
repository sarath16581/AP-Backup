/**
This apex class will provide methods to create sample test data for test class.
Created By - Mausam Padhiyar
Created Date - 9th Oct, 2015

Last Modified By - Aditya Shetty
Last Modified Date - 18/03/2020

Last Modified By - Seth Heang
Last Modified Date - 30/11/2020 | add createASICReport_element method to mock ASIC returned result
*/
@IsTest
public with sharing class APT_TestUtils {

/**
 create R2T System Properties custom setting record
**/
@TestVisible private static APT_R2T_System_Properties__c createR2TSystemProperties(String defaultPriceListId) {
	Apttus_Config2__ClassificationName__c classification = new Apttus_Config2__ClassificationName__c();
	classification.Apttus_Config2__Active__c = true;
	classification.Apttus_Config2__HierarchyLabel__c = APT_Constants.Australia_Post_All_Categories;
	classification.Apttus_Config2__Type__c = APT_Constants.CAT_OFFERING;
	classification.Apttus_Config2__GuidePage__c = APT_Constants.URL_GUIDED_SELLING_FLOW;
	insert classification;
	
	APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
	
	r2tSystemProperties.APT_Default_Price_List_ID__c = defaultPriceListId;
	r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = APT_Constants.TEST_EMAIL;
	r2tSystemProperties.APT_Classification_ID__c = classification.Id;
	r2tSystemProperties.APT_Interview_Name__c = APT_Constants.STRING_AUSTRALIAPOST;
	
	return r2tSystemProperties;
}

/**
 create account
**/
@TestVisible private static Account createOrganisation() {
	Account organisation = new Account();
	organisation.Name = APT_Constants.STRING_TEST_ORGANIZATION;
	organisation.Type = APT_Constants.STRING_ENTERPRISE;
	
	return organisation;
}

/**
create opportunity
**/
@TestVisible private static Opportunity createOpportunity(Id accountId) {
	Opportunity oppty = new Opportunity();
	oppty.Name = APT_Constants.STRING_TEST_OPPORTUNITY;
	oppty.Type = APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER;
	oppty.AccountId = accountId;
	oppty.Offering_Type__c = APT_Constants.OPPORTUNITY_OFFERING_TYPE_PRODUCT;
	//oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_PROPOSE;
	oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_IDENTIFY;
	oppty.CloseDate = date.Today().addDays(365);
	
	return oppty;
}

	/**
create opportunity
**/
/* Start Aditya Shetty:  Create Opportunity of Opportunity State IdentityStage*/
@TestVisible private static Opportunity createOpportunityofIdentifyStage(Id accountId) {
	Opportunity oppty = new Opportunity();
	oppty.Name = APT_Constants.STRING_TEST_OPPORTUNITY;
	oppty.Type = APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER;
	oppty.AccountId = accountId;
	oppty.Offering_Type__c = APT_Constants.OPPORTUNITY_OFFERING_TYPE_PRODUCT;
	oppty.StageName = APT_Constants.OPPORTUNITY_STAGE_IDENTIFY;
	oppty.CloseDate = date.Today().addDays(365);
	
	return oppty;
}
/*End  Aditya Shetty:  Create Opportunity of Opportunity State IdentityStage */
/**
create price list
**/
@TestVisible private static Apttus_Config2__PriceList__c createPriceList() {
	Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
	priceList.Name = APT_Constants.STRING_AUSTRALIA_POST_PRICE_LIST;
	priceList.Apttus_Config2__Active__c = true;
	
	return priceList;
}    

/**
create price list item
**/
@TestVisible private static Apttus_Config2__PriceListItem__c createPriceListItem(Id priceListId, Id productId, String industry, String band) {
	Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
	pli.Apttus_Config2__PriceListId__c = priceListId;
	pli.Apttus_Config2__ProductId__c = productId;
	pli.Apttus_Config2__ListPrice__c = 0;
	pli.Apttus_Config2__ChargeType__c = APT_Constants.CHARGE_TYPE_STANDARD_PRICE;
	pli.Apttus_Config2__PriceType__c = APT_Constants.PRICE_TYPE_USAGE;
	pli.Apttus_Config2__PriceMethod__c = APT_Constants.PRICE_METHOD_PER_UNIT;
	pli.Apttus_Config2__PriceUom__c = APT_Constants.PRICE_UOM_EACH;
	pli.Apttus_Config2__Active__c = true;
	pli.APT_Industry__c = industry;
	pli.APT_Band__c = band;
	pli.APT_Lodgement_Zone_Code__c=APT_Constants.SRRING_AAT;
	pli.APT_Price_Structure__c=APT_Constants.STRING_BANDED;
			
	return pli;
}

/**
create price matrix
**/
@TestVisible private static Apttus_Config2__PriceMatrix__c createPriceMatrix(Id priceListItemId, Id dimension1Id, Id dimension2Id, Id dimension3Id) {
	Apttus_Config2__PriceMatrix__c pm = new Apttus_Config2__PriceMatrix__c();
	pm.Apttus_Config2__Sequence__c = 1;
	pm.Apttus_Config2__PriceListItemId__c = priceListItemId;
	pm.Apttus_Config2__Dimension1Id__c = dimension1Id;
	pm.Apttus_Config2__Dimension1ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_DISCRETE;
	pm.Apttus_Config2__Dimension2Id__c = dimension2Id;
	pm.Apttus_Config2__Dimension2ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_RANGE;
	pm.Apttus_Config2__Dimension3Id__c = dimension3Id;
	pm.Apttus_Config2__Dimension3ValueType__c = APT_Constants.DIMENSION_VALUE_TYPE_DISCRETE;
	
	return pm;
}


/**
create international price data
**/
@TestVisible private static APT_International_Price_Data__c createInternationalPriceData(String product, String industry, String band, String zone,
																		decimal dBandRangeMin, decimal dBandRangeMax,  
																		double dbCSPPerItemRate, double dbCSPPerKgRate,
																		double dbEParcelPerItemRate, double dbEParcelPerKgRate) {
	APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
	ipd.APT_Product__c = product;
	ipd.APT_Industry__c = industry;
	ipd.APT_Band__c = band;
	ipd.APT_Zone__c = zone;
	ipd.APT_Band_Range_Min__c = dBandRangeMin;
	ipd.APT_Band_Range_Max__c = dBandRangeMax;
	ipd.APT_CSP_Per_Item_Rate__c = dbCSPPerItemRate;
	ipd.APT_CSP_Per_Kg_Rate__c = dbCSPPerKgRate;
	ipd.APT_eParcel_Per_Item_Rate__c = dbEParcelPerItemRate;
	ipd.APT_eParcel_Per_Kg_Rate__c = dbEParcelPerKgRate;
	
	return ipd;
}

/**
create international product
**/
@TestVisible private static Product2 createInternationalProduct(String productName, String productCode, String productFamily) {
	Product2 product = new Product2();
	product.Name = productName;
	product.ProductCode = productCode;
	product.Family = productFamily;
	product.APT_Apttus_Product_Classification__c = productFamily;
	product.IsActive = true;
	product.APT_International_Pricing__c = true;
	
	return product; 
}
/**
create APPC product
**/
//US-126
@TestVisible private static Product2 createAPPCProduct( String productName, String productCode, String productFamily) {
	Product2 product = new Product2();
	product.Name = productName;
	product.ProductCode = productCode;
	product.Family = productFamily;
	product.APT_Apttus_Product_Classification__c = productFamily;
	product.IsActive = true;     
	return product; 
}

/**
create Post Billpay product
**/
//Minor works Post Billpay product build
@TestVisible private static Product2 createPBPProduct( String productName, String productCode, String productFamily) {
	Product2 product = new Product2();
	product.Name = productName;
	product.ProductCode = productCode;
	product.Family = productFamily;
	product.APT_Apttus_Product_Classification__c = productFamily;
	product.IsActive = true;     
	return product; 
}

/**
create Domestic product
**/
@TestVisible private static Product2 createDomesticProduct(String productName, String productCode, String productFamily, String strCategory, String networkType) {
	Product2 product = new Product2();
	product.Name = productName;
	product.ProductCode = productCode;
	product.Family = productFamily;
	product.APT_Apttus_Product_Classification__c = productFamily;
	product.APT_Category__c = strCategory;
	product.APT_Network_Type__c = networkType;
	product.IsActive = true;
	product.APT_Domestic_Pricing__c = true;
	
	return product; 
}

/**
create product attribute group
**/
@TestVisible private static Apttus_Config2__ProductAttributeGroup__c createProductAttributeGroup(String businessObject) {
	Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = new Apttus_Config2__ProductAttributeGroup__c();
	productAttributeGroup.Name = APT_Constants.STRING_TEST_PRODUCT_ATTRIBUTE_GROUP;
	productAttributeGroup.Apttus_Config2__BusinessObject__c = businessObject;
	productAttributeGroup.Apttus_Config2__Description__c = APT_Constants.STRING_TEST_PRODUCT_ATTRIBUTE_GROUP;
	productAttributeGroup.Apttus_Config2__TwoColumnAttributeDisplay__c = true;
	
	return productAttributeGroup;
}    

/**
	create product attribute
**/
@TestVisible private static Apttus_Config2__ProductAttribute__c createProductAttribute(String field, Id attributeGroupId) {
	Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
	productAttribute.Apttus_Config2__Sequence__c = 1;
	productAttribute.Apttus_Config2__Field__c = field;
	productAttribute.Apttus_Config2__AttributeGroupId__c = attributeGroupId;
	
	return productAttribute;
}

/**
 create price dimension
**/
@TestVisible private static Apttus_Config2__PriceDimension__c createPriceDimension(String dimensionName, String contextType, String businessObject,
																	String field, Id productAttributeId) {
	Apttus_Config2__PriceDimension__c priceDimension = new Apttus_Config2__PriceDimension__c();
	priceDimension.Name = dimensionName;
	priceDimension.Apttus_Config2__ContextType__c = contextType;
	priceDimension.Apttus_Config2__BusinessObject__c = businessObject;
	priceDimension.Apttus_Config2__Datasource__c = field;
	priceDimension.Apttus_Config2__AttributeId__c = productAttributeId;
	
	return priceDimension;
}

/**
 domestic price data
**/
@TestVisible private static APT_Domestic_Price_Data__c createDomesticPriceData(String strCategory, String networkType, String lodgementZoneCode,
																String destinationZoneCode, String destinationationZone, 
																String priceStructure, decimal dWeightRangeCode, 
																String weightRangeCodeDescription, Integer iBaseRate,
																Integer iPerKgRate, Integer iSubSequentRate) {

	//Get record type id of AusPost
	Id ausPostRecordTypeId = Schema.SObjectType.APT_Domestic_Price_Data__c.getRecordTypeInfosByName().get(APT_Constants.RECORDTYPE_AUSPOST).getRecordTypeId();

	APT_Domestic_Price_Data__c dpd = new APT_Domestic_Price_Data__c();
	dpd.APT_Category__c = strCategory;
	dpd.APT_Network_Type__c = networkType;
	dpd.APT_Lodgement_Zone_Code__c = lodgementZoneCode;
	dpd.APT_Destination_Zone_Code__c = destinationZoneCode;
	dpd.APT_Destination_Zone__c = destinationationZone;
	dpd.APT_Price_Structure__c = priceStructure;
	dpd.APT_Weight_Range_Code__c = dWeightRangeCode;
	dpd.APT_Weight_Range_Code_Description__c = weightRangeCodeDescription;
	dpd.APT_Base_Rate__c = iBaseRate;
	dpd.APT_Per_Kg_Rate__c = iPerKgRate;
	dpd.APT_Subsequent_Rate__c = iSubSequentRate;
	dpd.RecordTypeId = ausPostRecordTypeId;

	return dpd;
}


/**
Create Proposal
**/
@TestVisible private static Apttus_Proposal__Proposal__c getQuoteProposal(ID accId, ID optyId, String recordTypeName,String quoteName, ID priceList){
	
	Apttus_Proposal__Proposal__c quote = new Apttus_Proposal__Proposal__c(Apttus_Proposal__Proposal_Name__c = quoteName,
	Apttus_Proposal__Opportunity__c = optyId,
	Apttus_Proposal__Account__c = accId,
	RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
	Apttus_QPConfig__PriceListId__c = priceList);
	
	return quote;
}

	/**
Create Proposal with Contact
**/
@TestVisible private static Apttus_Proposal__Proposal__c getQuoteProposalContact(ID accId, ID optyId, ID contactId,String recordTypeName,String quoteName, ID priceList){
	
	Apttus_Proposal__Proposal__c quote = new Apttus_Proposal__Proposal__c(Apttus_Proposal__Proposal_Name__c = quoteName,
	Apttus_Proposal__Opportunity__c = optyId,
	Apttus_Proposal__Account__c = accId,
	Apttus_Proposal__Primary_Contact__c = contactId,                               
	RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
	Apttus_QPConfig__PriceListId__c = priceList);
	
	return quote;
}
/**
 Product Configuration 
**/
@TestVisible private static Apttus_Config2__ProductConfiguration__c getProductConfiguration(String configName,
																				Integer versionNbr,
																				ID bObjectId,
																				String bObjectType,
																				String groupType,
																				ID priceListId, 
																				ID ancestorId, 
																				String status, 
																				Datetime finalizedDate, 
																				Datetime effectiveDate, 
																				Boolean isTransient){
	
	Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
	configSO.Apttus_Config2__VersionNumber__c = versionNbr;
	configSO.Apttus_Config2__SummaryGroupType__c = groupType;
	configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
	configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
	configSO.Apttus_QPConfig__Proposald__c = bObjectId;
	configSO.Apttus_Config2__PriceListId__c = priceListId;
	configSO.Apttus_Config2__AncestorId__c = ancestorId;
	configSO.Apttus_Config2__Status__c = status;
	configSO.Apttus_Config2__IsTransient__c = isTransient;
	configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
	configSO.Apttus_Config2__EffectiveDate__c = effectiveDate; 
	return configSO;
}
/**
 Product Configuration 
**/
@TestVisible private static Apttus_Config2__ProductConfiguration__c getProductConfiguration2(String configName,
																				Integer versionNbr,
																				ID bObjectId,
																				String bObjectType,
																				String groupType,
																				ID priceListId,
																				String status, 
																				Datetime finalizedDate, 
																				Datetime effectiveDate, 
																				Boolean isTransient){
	
	Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
	configSO.Apttus_Config2__VersionNumber__c = versionNbr;
	configSO.Apttus_Config2__SummaryGroupType__c = groupType;
	configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
	configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
	configSO.Apttus_QPConfig__Proposald__c = bObjectId;
	configSO.Apttus_Config2__PriceListId__c = priceListId;
	configSO.Apttus_Config2__Status__c = status;
	configSO.Apttus_Config2__IsTransient__c = isTransient;
	configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
	configSO.Apttus_Config2__EffectiveDate__c = effectiveDate; 
	return configSO;
}

/**
Create Line Item
**/
@TestVisible private static Apttus_Config2__LineItem__c getConfigLineItem(ID configId,
																ID groupId,
																Integer lineNumber,
																Boolean isPrimaryLine,
																Integer itemSeq,
																String lineType,
																ID productId,
																Boolean customizable,
																ID productOptionId,
																ID optionId,
																ID classId,
																String classHierarchy,
																Decimal quantity,
																Boolean isQtyModifiable,
																String uom,
																Integer term,
																ID priceListId,
																ID plItemId,
																String priceType,
																String priceMethod,
																String chargeType,
																String frequency,
																Boolean allowManualAdj,
																Boolean allocateGroupAdj,
																Decimal listPrice,
																Decimal basePrice,
																String basePriceMethod,
																Decimal baseExtPrice,
																Decimal optionPrice,
																Decimal extPrice,
																String lineDesc){
	
	Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(Apttus_Config2__ConfigurationId__c = configId);
	lineItem.Apttus_Config2__LineNumber__c = lineNumber;
	lineItem.Apttus_Config2__IsPrimaryLine__c = isPrimaryLine;
	lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
	lineItem.Apttus_Config2__ItemSequence__c = itemSeq;
	lineItem.Apttus_Config2__SummaryGroupId__c = groupId;
	lineItem.Apttus_Config2__LineType__c = lineType;
	lineItem.Apttus_Config2__ProductId__c = productId;
	lineItem.Apttus_Config2__Customizable__c = customizable;
	lineItem.Apttus_Config2__ProductOptionId__c = productOptionId;
	lineItem.Apttus_Config2__OptionId__c = optionId;
	lineItem.Apttus_Config2__ClassificationId__c = classId;
	lineItem.Apttus_Config2__ClassificationHierarchy__c = classHierarchy;
	lineItem.Apttus_Config2__Quantity__c = quantity;
	lineItem.Apttus_Config2__IsQuantityModifiable__c = isQtyModifiable;
	lineItem.Apttus_Config2__Uom__c = uom;
	lineItem.Apttus_Config2__Term__c = term;
	lineItem.Apttus_Config2__PriceListId__c = priceListId;
	lineItem.Apttus_Config2__PriceListItemId__c = plItemId;
	lineItem.Apttus_Config2__PriceType__c = priceType;
	lineItem.Apttus_Config2__PriceMethod__c = priceMethod;
	lineItem.Apttus_Config2__ChargeType__c = chargeType;
	lineItem.Apttus_Config2__Frequency__c = frequency;
	lineItem.Apttus_Config2__AllowManualAdjustment__c = allowManualAdj;
	lineItem.Apttus_Config2__AllocateGroupAdjustment__c = allocateGroupAdj;
	lineItem.Apttus_Config2__ListPrice__c = listPrice;
	lineItem.Apttus_Config2__BasePrice__c = basePrice;
	lineItem.Apttus_Config2__BasePriceMethod__c = basePriceMethod;
	lineItem.Apttus_Config2__BaseExtendedPrice__c = baseExtPrice;
	lineItem.Apttus_Config2__OptionPrice__c = optionPrice;
	lineItem.Apttus_Config2__ExtendedPrice__c = extPrice;
	lineItem.Apttus_Config2__Description__c = lineDesc;
	lineItem.Apttus_Config2__AdjustedPrice__c = 0;
	
	return lineItem;
}

/**
create product attribute value
**/
@TestVisible private static Apttus_Config2__ProductAttributeValue__c GetAttributeValue(Id lineItemId,string maintenanceLevel,
									boolean isNeoship,boolean isOnlinePostalExpenseManager,boolean isPostalRate,
									String volumeData,String industry, Boolean eParcelLodg, Boolean internationalLetters)
{
	Apttus_Config2__ProductAttributeValue__c pav= new Apttus_Config2__ProductAttributeValue__c();
	pav.Apttus_Config2__LineItemId__c = lineItemId;        
	pav.APT_Volume_Data__c = volumeData;
	pav.APT_Industry__c = industry;
	pav.APT_eParcel_Lodgment__c = eParcelLodg;
	pav.APT_International_Letters__c = internationalLetters;
	return pav;
}

/**
 Update line item with Attribute Value
**/
@TestVisible private static void UpdateLineItem(Id prodAttValID)

{
	Apttus_Config2__LineItem__c lineItem = [select ID,Apttus_Config2__AttributeValueId__c from Apttus_Config2__LineItem__c limit 1];
	lineItem.Apttus_Config2__AttributeValueId__c= prodAttValID;
	
}

/**
 create Logdement Zone
**/
@TestVisible private static APT_Lodgement_Zone__c getLodgementZone(String name,String code)

{
	APT_Lodgement_Zone__c lodZone= new APT_Lodgement_Zone__c();
	lodZone.Name=name;
	lodZone.APT_Lodgement_Zone_Code__c =code;

	return lodZone;
}

/**
Create Feature Pricing  
**/
@TestVisible private static APT_Feature_Pricing__c getFeaturePricing(String name,String category,String lodgementZone,String networkType,String productType,Double flagFallRate,Double perKgRate)

{
	APT_Feature_Pricing__c fp=new APT_Feature_Pricing__c();
	fp.name=name;
	fp.APT_Category__c=category;
	fp.APT_Lodgement_Zone__c=lodgementZone;
	fp.APT_Network_Type__c=networkType;
	fp.APT_Product_Type__c=productType;
	fp.APT_Flag_Fall_Rate__c=flagFallRate;
	fp.APT_Per_Kg_Rate__c =perKgRate;
	
	return fp; 
}
	
/**
create Proposal line Item                                        
**/
@TestVisible private static Apttus_Proposal__Proposal_Line_Item__c getProposalLineItem(String quoteId, String lineId, String pliId, String prodId,String optionId){
	
	Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c(
	Apttus_Proposal__Proposal__c = quoteId,
	Apttus_QPConfig__DerivedFromId__c = lineId,
	Apttus_QPConfig__PriceListItemId__c = pliId,Apttus_QPConfig__OptionId__c = optionId,Apttus_Proposal__Product__c = prodId);        
	return propLineItem;
}                                        
/** 
	Get Product Attribute value                                        
**/
@TestVisible private static Apttus_QPConfig__ProposalProductAttributeValue__c getProposalProductAttributeValue(String propLineItemID){
	
	Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue = new Apttus_QPConfig__ProposalProductAttributeValue__c (
	Apttus_QPConfig__LineItemId__c= propLineItemID,APT_Minimum_Quantity__c=10,APT_Classification__c=APT_Constants.CLASSIFICATION_GROWTH,APT_Sub_Classification__c=APT_Constants.STRING_UP_SELL,APT_Sales_Unit_Price__c=10);
			
	return ProposalProductAttributeValue;
}                                        

/**
	Create PricebookEntry 
**/
@TestVisible private static PricebookEntry getPricebookEntry(String pricebookId,String productID){                                        
	PricebookEntry standardPrice = new PricebookEntry(
			Pricebook2Id = pricebookId, Product2Id = productID,
			UnitPrice = 10000, IsActive = true);
		return standardPrice;                                        
										
	}  
	
	/**
	 Create Contact
	**/
	@TestVisible private static Contact createContact(){
		Contact con = new Contact(FirstName=APT_Constants.STRING_TEST1, LastName=APT_Constants.STRING_SAMPLE,Email =APT_Constants.SAMPLE_EMAIL);
		return con;
	}
	
	/**
 Create Agreement
	**/
	@TestVisible private static Apttus__APTS_Agreement__c createAgreement(Id conId){
		Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId(),Name = APT_Constants.STRING_AGREEMENT,Apttus__Primary_Contact__c=conId,Apttus__Agreement_Category__c=APT_Constants.NETWORK_TYPE_STANDARD
												/*,Billing_Account__c=billingAcc.id*/);
		return aptContract;
	}
										
	/**
	 Create Case
	**/
	@TestVisible private static Case  createCase(Id conId,Id aptContractId ){
		Case cse = new Case(Product_Type__c = APT_Constants.STRING_LETTERS , APT_Contract__c = aptContractId ,
					Billing_Number__c = APT_Constants.STRING_BI1234 , ContactId = conId , Priority =APT_Constants.STRING_MEDIUM ,
					Work_Type__c =APT_Constants.STRING_PRODUCTS , Subject = APT_Constants.STRING_THIS_IS_A_CASE ,Description = APT_Constants.STRING_DESCRIBE);
		return cse;
		}
	
	/** 
	 Create network    
	**/
	@TestVisible private static Network__c createNetwork() {
	Network__c nw = new Network__c();
	nw.Name = APT_Constants.STRING_LODGEMENT_POINT;
	nw.Post_Code__c = APT_Constants.STRING_RANDOM_STRING;
	nw.State__c = APT_Constants.STRING_ACT;

	// Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
	nw.APT_Business_Unit__c = APT_Constants.STRING_BUSINESS;
	nw.Business_Unit__c = APT_Constants.STRING_BUSINESS;
	nw.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
	nw.Org_ID__c = APT_Constants.STRING_ID_A1POM;
	nw.APT_DWS_ID__c = APT_Constants.STRING_ID_A1POM;
	nw.APT_Transport_Capability__c = APT_Constants.STRING_VAN_ONLY;
	nw.APT_MCAT__c = true;
	nw.APT_Threshold_Categories__c = APT_Constants.STRING_CATEGORY;
	nw.APT_Comments__c = APT_Constants.STRING_NO_COMMENTS;
	
	return nw;
	}
	
	/**
	 Create Billing Account
	**/
	@TestVisible private static Billing_Account__c createBillingAccount(Id AccId) {
	Billing_Account__c bAcc = new Billing_Account__c();
	bAcc.Legacy_Id__c =  APT_Constants.STRING_60000000;
	bAcc.Organisation__c = AccId;
	return bAcc;
	}
	/**
	 Create Custom Setting
	**/
	@TestVisible private static SystemSettings__c createSystemSettings(){
	
	SystemSettings__c systemSettings = new SystemSettings__c (Loglevel_Debug__c = true,
																		Loglevel_Error__c = true,
																		Loglevel_Warning__c = true, 
																		Loglevel_Info__c = true,
																		Disable_Billing_Account_Trigger__c=true);
																		
	return systemSettings;                                                                           
}
	/*
	This method will return Agreement Lodgement Point.
	@params -
	acc- id of account
	agr - Id of agreement   
	nwk - id of lodgement point.
	zone - id of lodgement zone
	bcc - id of billing account     
	*/
@TestVisible private static APT_Agreement_Lodgement_Point__c createLodgementPoint(ID acc, ID agr, ID nwk, ID zone, String product,ID bcc){
	APT_Agreement_Lodgement_Point__c  objLp = new APT_Agreement_Lodgement_Point__c();
		objLp.APT_Status__c = APT_Constants.ACTIVE;
		objLp.APT_Agreement__c = agr;
		objLp.APT_Address__c = APT_Constants.STRING_AUSTRALIA;
		objLp.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
		objLp.APT_Transport_Capability__c = APT_Constants.STRING_VAN_ONLY;
		objLp.APT_Organisation_ID__c = APT_Constants.STIRNG_ORG123;
		objLp.APT_Lodgement_Point_Lookup__c= nwk;
		objLp.APT_Organisation__c = acc;
		objLp.APT_Lodgement_Zone_Lookup__c= zone;
		objLp.APT_DWS_ID__c = APT_Constants.STRING_DWS12;
		objLp.APT_Selected_Lodgement_Point__c = objLp.Name;
		objLp.APT_LP_Post_Code__c = APT_Constants.STRING_PCODE;
		objLp.APT_Lodgement_Zone__c = APT_Constants.STRING_LZOONE;
		objLp.APT_Product__c = product;
		objLp.APT_Billing_Account__c = bcc;
		objLp.APT_Outlet_Type__c = APT_Constants.STRING_OTYPE;
	return objLp;                                                                           
}

/**
 crete charge code
**/
@TestVisible private static APT_Charge_Code__c createChargeCode(String strPriceStructure) {
	APT_Charge_Code__c objChargeCode = new APT_Charge_Code__c();
	objChargeCode.APT_Price_Structure__c = strPriceStructure;
	objChargeCode.APT_Network_Type__c = APT_Constants.NETWORK_TYPE_EXPRESS;
	objChargeCode.APT_Weight_Measure__c = APT_Constants.WEIGHT_MEASURE_CUBIC;
	return objChargeCode;
}
/**
 crete opportunity product line item
**/
@TestVisible private static APT_Opportunity_Product_Line_Item__c createOpProdLI(String clsf,String contPro,ID pro,ID proconf,Integer qty,ID prop,Integer unitSP,Date revStrt,Date revEnd) {
	APT_Opportunity_Product_Line_Item__c OppProLineItem = new APT_Opportunity_Product_Line_Item__c();
	OppProLineItem.APT_Classification__c = clsf;
	OppProLineItem.APT_Contract_Product__c = contPro;
	OppProLineItem.APT_Product__c = pro;
	OppProLineItem.APT_Product_Configuration__c = proconf;
	OppProLineItem.APT_Quantity__c = qty;
	OppProLineItem.APT_Quote_Proposal__c = prop;
	OppProLineItem.APT_Unit_Sales_Price__c = unitSP;
	OppProLineItem.APT_Revenue_Start_Date__c = revStrt;
	OppProLineItem.APT_Revenue_End_Date__c= revEnd;
	return OppProLineItem;
}
/**
 create attachment
**/
@TestVisible private static Attachment createAttachment(ID pid){
	Attachment atc = new Attachment();
	atc.Name = APT_Constants.STRING_SAMPLE_ATTACHMENT;
	atc.ParentID = pid;
	return atc;
}  
/**
create startrack product
**/
@TestVisible private static Product2 createStarTrackProduct(String productName, String productCode, String productFamily, String strCategory, String networkType, String productType) {
	Product2 product = new Product2();
	product.Name = productName;
	product.ProductCode = productCode;
	product.Family = productFamily;
	product.APT_Apttus_Product_Classification__c = productFamily;
	product.APT_Category__c = strCategory;
	product.APT_Network_Type__c = networkType;
	product.IsActive = true;
	product.APT_Domestic_Pricing__c = true;
	product.APT_Product_type__c  = productType;
	
	return product; 
}
/**
 domestic price data for startrack record type
**/
@TestVisible private static APT_Domestic_Price_Data__c createDomesticPriceDataForST(String strCategory, String networkType, String outboundInbound,
																					String lodgementZoneCode, String destinationZoneCode, Integer iBaseRate, 
																					Integer iPerKgRate, Integer iSubSequentRate) {
	//Get record type id of AusPost
	Id starTrackRecordTypeId = Schema.SObjectType.APT_Domestic_Price_Data__c.getRecordTypeInfosByName().get(APT_Constants.RECORDTYPE_STARTRACK).getRecordTypeId();

	APT_Domestic_Price_Data__c dpd = new APT_Domestic_Price_Data__c();
	dpd.APT_Category__c = strCategory;
	dpd.APT_Network_Type__c = networkType;
	dpd.APT_Lodgement_Zone_Code__c = lodgementZoneCode;
	dpd.APT_Destination_Zone_Code__c = destinationZoneCode;
	dpd.APT_Base_Rate__c = iBaseRate;
	dpd.APT_Per_Kg_Rate__c = iPerKgRate;
	dpd.APT_Subsequent_Rate__c = iSubSequentRate;
	dpd.APT_Outbound_Inbound__c = outboundInbound;
	dpd.RecordTypeId = starTrackRecordTypeId;
	
	return dpd;
}
/**
 post code mapping
**/
@TestVisible private static APT_Post_Code_Mapping__c createPostCodeMapping(String postCode, String subUrb, String directZone,
																					String onforwardingZone, String onforwardingAltZone) {
	APT_Post_Code_Mapping__c pcm = new APT_Post_Code_Mapping__c();
	pcm.APT_Post_Code__c = postCode;
	pcm.APT_Suburb__c = subUrb;
	pcm.APT_Direct_Zone__c = directZone;
	pcm.APT_Onforwarding_Zone__c = onforwardingZone;
	pcm.APT_Onforwarding_Alternate_Zone__c = onforwardingAltZone;
	
	return pcm;
}

@TestVisible private static APT_OrgIDWebServiceWrapper.ASICReport_element createASICReport_element(String asicName, String asicOrgNum, String asicABN,
																									String asicOrgNumHeading, String asicPrescribedIntNum, String asicUndertakingName,
																									Date asicRegDate, String asicStatus, String asicState, String asicBusRegNum, String asicJuris,
																									List<String> errorMsg, List<String> warningMsg, String asicLocality, String asicAddrState, String asicPostcode){
	APT_OrgIDWebServiceWrapper.ASICReport_element asicreport = new APT_OrgIDWebServiceWrapper.ASICReport_element();
		asicreport.ASICName = asicName;
		asicreport.ASICOrganisationNumber = asicOrgNum;
		asicreport.ASICABN = asicABN;
		asicreport.ASICOrganisationNumberHeading = asicOrgNumHeading;
		asicreport.ASICPrescribedInterestNumber = asicPrescribedIntNum;
		asicreport.ASICUndertakingName = asicUndertakingName;
		asicreport.ASICRegistrationDate = asicRegDate;
		asicreport.ASICStatus = asicStatus;
		asicreport.ASICState = asicState;
		asicreport.ASICBusinessRegistrationNumber = asicBusRegNum;
		asicreport.ASICJurisdiction = asicJuris;
		asicreport.ErrorMsg = errorMsg;
		asicreport.WarningMsg = warningMsg;
		asicreport.ASICLocality = asicLocality;
		asicreport.ASICAddressState = asicAddrState;
		asicreport.ASICPostcode = asicPostcode;
	return asicreport;
}
}