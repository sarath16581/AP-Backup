/**
* @description Contains all the test data methods for Apttus object related test classes
* @author Seth Heang
* @date 2022-04-08
* @group Tests
* @tags mocking, apex mocks, tests, data factory, test data, apttus
* @domain Apttus
* @changelog
* 2022-04-08 - Seth Heang - Created
* 2022-06-01 - Seth Heang - Added getAPTAgreementLineItem
* 2022-05-30 - nasir.jawed@auspost.com.au - added the method to get proposal, contact  for test class
* 2022-08-24 - Bharat Patel - added the method to get SummaryGroup, ProductOptionComponent, ClassificationName, ClassificationHierarchy, ConfigLineItem and update getAPTContactRecord() method   for test class
* 2022-09-19 - Seth Heang - Added getAPTProductOptionComponentRecord
* 2022-11-24 - nasir.jawed@auspost.com.au - added the method to get getTemplateRecord, getAgreementRecord,getRelatedAgreementRecord,getApprovalRecord
* 2023-04-06 - Nasir Jawed - Added getOpportunityLineItemRecord, getDocuSignRecipientsRecord
Ken McGuire 2023.04.19 Proposal field migration to opportunity
* 2023-04-27 - Yatika bansal - Added getOperationalSchedule
*2023-05-31 - Yatika bansal - Added getOrganisationRole, getApttusCreditAssessment
* 2023-09-14 - Paul Perry - Decommissioned StarTrek Pricing Matrix logic MW0005472
*/
@isTest
public class APT_TestDataFactory {

	public static List<Apttus_Config2__ProductConfiguration__c> getAPTProductConfig(integer count, Id orgId, Id proposalId, Boolean generateIds){
		return (List<Apttus_Config2__ProductConfiguration__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ProductConfiguration__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ProductConfiguration__c.Name => 'test APT_ProductConfig %count%',
			Apttus_Config2__ProductConfiguration__c.APT_Config_Change__c => false,
			Apttus_Config2__ProductConfiguration__c.APT_Customised_Pricing__c => false,
			Apttus_Config2__ProductConfiguration__c.APT_Is_Cloned__c => false,
			Apttus_Config2__ProductConfiguration__c.APT_Validate_Approvals__c => false,
			Apttus_Config2__ProductConfiguration__c.Apttus_Config2__IsPricePending__c => false,
			Apttus_Config2__ProductConfiguration__c.Apttus_Config2__IsTaskPending__c => false,
			Apttus_Config2__ProductConfiguration__c.Apttus_Config2__IsTransient__c => false,
			Apttus_Config2__ProductConfiguration__c.Apttus_Config2__IsValidationPending__c => false,
			Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c => proposalId,
			Apttus_Config2__ProductConfiguration__c.Apttus_Config2__AccountId__c => orgId
		}, count), generateIds);
	}

	public static List<Apttus_Config2__TempObject__c> getAPTConfigTempObj(integer count, Id prodConfigId, Boolean generateIds){
		return (List<Apttus_Config2__TempObject__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__TempObject__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__TempObject__c.Apttus_Config2__ConfigurationId__c => prodConfigId
		}, count), generateIds);
	}

	public static List<Apttus_Config2__ProductAttributeValue__c> getAPTProductAttributeValues(integer count, Id lineItemId, Boolean generateIds){
		return (List<Apttus_Config2__ProductAttributeValue__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ProductAttributeValue__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ProductAttributeValue__c.APT_eParcel_Integrated__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_eParcel_Lodgment__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_Existing_APPC_Customer__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_International_Letters__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_Non_Contracted_Rates_Printpost__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_RK_Code_Applied__c => false,
			Apttus_Config2__ProductAttributeValue__c.APT_Valid_Primary_Postcode__c => true,
			Apttus_Config2__ProductAttributeValue__c.Apttus_Config2__IsTransient__c => false,
			Apttus_Config2__ProductAttributeValue__c.Apttus_Config2__LineItemId__c => lineItemId
		}, count), generateIds);
	}

	public static List<Apttus_Config2__LineItem__c> getAPTLineItem(integer count, Id pavId, Id prodConfigId, Boolean generateIds){
		return (List<Apttus_Config2__LineItem__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__LineItem__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__LineItem__c.Apttus_Config2__AttributeValueId__c => pavId,
			Apttus_Config2__LineItem__c.APT_Added_LP__c => false,
			Apttus_Config2__LineItem__c.APT_Amendment__c => false,
			Apttus_Config2__LineItem__c.APT_Customised_Pricing__c => false,
			Apttus_Config2__LineItem__c.APT_Deep_Clone__c => false,
			Apttus_Config2__LineItem__c.APT_Is_Band_Changed__c => false,
			Apttus_Config2__LineItem__c.APT_Is_Higher_Band_Offered__c => false,
			Apttus_Config2__LineItem__c.APT_Is_OPC_deleted__c => false,
			Apttus_Config2__LineItem__c.APT_New__c => false,
			Apttus_Config2__LineItem__c.APT_New_Amend__c => false,
			Apttus_Config2__LineItem__c.APT_New_Renew__c => false,
			Apttus_Config2__LineItem__c.APT_Rate_Card_Edited__c => false,
			Apttus_Config2__LineItem__c.APTS_Charge_Type_Criteria__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__AllocateGroupAdjustment__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__AllowManualAdjustment__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__AllowProration__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__AllowRemoval__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__AutoRenew__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__Customizable__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasAttributes__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasBaseProduct__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasDefaults__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasIncentives__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasOptions__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HasTieredPrice__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HideCopyAction__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__HideInvoiceDisplay__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsAssetPricing__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsCustomPricing__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsHidden__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsOptional__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsOptionRollupLine__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsPrimaryLine__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsPrimaryRampLine__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsQuantityModifiable__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsReadOnly__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsSellingTermReadOnly__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__IsUsageTierModifiable__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__ItemSequence__c => 1,
			Apttus_Config2__LineItem__c.Apttus_Config2__LineNumber__c => 1,
			Apttus_Config2__LineItem__c.Apttus_Config2__PriceIncludedInBundle__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__RollupPriceToBundle__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__Taxable__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__TaxInclusive__c => false,
			Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c => prodConfigId
		}, count), generateIds);
	}

	public static List<APT_Lodgement_Zone__c> getAPTLodgementZone(integer count, Boolean generateIds){
		return (List<APT_Lodgement_Zone__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(APT_Lodgement_Zone__c.SObjectType, new Map<SObjectField, Object> {
			APT_Lodgement_Zone__c.Name => 'test APT lodgement zone %count%'
		}, count), generateIds);
	}

	public static List<Apttus__AgreementLineItem__c> getAPTAgreementLineItem(integer count, Boolean generateIds){
		return (List<Apttus__AgreementLineItem__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus__AgreementLineItem__c.SObjectType, new Map<SObjectField, Object> {
			Apttus__AgreementLineItem__c.APT_Contracted_Line_Item__c => true,
			Apttus__AgreementLineItem__c.APT_New__c => true,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__HasAttributes__c => true,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__HasOptions__c => true,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsPrimaryLine__c => true,
			Apttus__AgreementLineItem__c.APT_eParcel_Identity_done__c => false,
			Apttus__AgreementLineItem__c.APT_Identical_Line__c => false,
			Apttus__AgreementLineItem__c.APT_WFV_Police_and_Visa_Check__c => false,
			Apttus__AgreementLineItem__c.APT_WFV_Working_with_Children_Check__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__AutoActivateOrder__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__AutoCreateBill__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__AutoCreateRevenue__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__AutoRenew__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__HasIncentives__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__HideInvoiceDisplay__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsAssetPricing__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsCustomPricing__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsOptional__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsOptionRollupLine__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsPrimaryRampLine__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__IsUsageTierModifiable__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__PriceIncludedInBundle__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__Taxable__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__TaxInclusive__c => false,
			Apttus__AgreementLineItem__c.Populate_Operational_Schedule__c => false,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__ItemSequence__c => 1,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__LineNumber__c => 1
		}, count), generateIds);
	}
	// creating a test data for proposal object
	public static List<Apttus_Proposal__Proposal__c> getAPTProposalRecord(integer count, Id oppId, Id AccID,ID conID, Boolean generateIds){
		return (List<Apttus_Proposal__Proposal__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Proposal__Proposal__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary__c => true,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c => AccID,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c => conID,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c => oppId,
			Apttus_Proposal__Proposal__c.RecordTypeId => Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId()
		}, count), generateIds);
	}
	// creating a test data for Contact object
	public static List<Contact> getAPTContactRecord(integer count, Id accId, Boolean generateIds){
		return (List<Contact>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Contact.SObjectType, new Map<SObjectField, Object> {
			Contact.FirstName => APT_Constants.STRING_TEST1,
			Contact.LastName => APT_Constants.STRING_SAMPLE,
			Contact.Status__c => 'Active',
			Contact.AccountId => accId,
			Contact.Email => APT_Constants.SAMPLE_EMAIL,
			Contact.Phone => '9886340071'
		}, count), generateIds);
	}

	// creating a test data for Apttus_Config2__SummaryGroup__c object
	public static List<Apttus_Config2__SummaryGroup__c> getSummaryGroupRecord(integer count, Id configId, integer itemSequence, integer lineNumber, Boolean generateIds){
		return (List<Apttus_Config2__SummaryGroup__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__SummaryGroup__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__SummaryGroup__c.Apttus_Config2__ConfigurationId__c => configId,
			Apttus_Config2__SummaryGroup__c.Apttus_Config2__ItemSequence__c => itemSequence,
			Apttus_Config2__SummaryGroup__c.Apttus_Config2__LineNumber__c => lineNumber
		}, count), generateIds);
	}

	// creating a test data for Apttus_Config2__ProductOptionComponent__c object
	public static List<Apttus_Config2__ProductOptionComponent__c> getAPTProductOptionComponentRecord(integer count, Id parentProductId, Id optionProductId, Boolean generateIds){
		return (List<Apttus_Config2__ProductOptionComponent__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ProductOptionComponent__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Required__c => false,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Sequence__c => 1,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ComponentProductId__c => optionProductId,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ParentProductId__c => parentProductId,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Default__c => false,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Modifiable__c => true,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__AllowCloning__c => false,
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__AutoUpdateQuantity__c => false
		}, count), generateIds);
	}

	// creating a test data for Apttus_Config2__ProductOptionComponent__c object
	public static List<Apttus_Config2__ProductOptionComponent__c> getProductOptionComponentRecord(integer count,  integer itemSequence, Boolean generateIds){
		return (List<Apttus_Config2__ProductOptionComponent__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ProductOptionComponent__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Sequence__c => itemSequence
		}, count), generateIds);
	}

	// creating a test data for Apttus_Config2__ClassificationName__c object
	public static List<Apttus_Config2__ClassificationName__c> getClassificationNameRecord(integer count,  String name, String hierarchyLabel, String type, String guidePage, Boolean generateIds){
		return (List<Apttus_Config2__ClassificationName__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ClassificationName__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ClassificationName__c.Name => name,
			Apttus_Config2__ClassificationName__c.Apttus_Config2__Active__c => true,
			Apttus_Config2__ClassificationName__c.Apttus_Config2__HierarchyLabel__c => hierarchyLabel,
			Apttus_Config2__ClassificationName__c.Apttus_Config2__Type__c => type,
			Apttus_Config2__ClassificationName__c.Apttus_Config2__GuidePage__c => guidePage
		}, count), generateIds);
	}

	// creating a test data for Apttus_Config2__ClassificationHierarchy__c object
	public static List<Apttus_Config2__ClassificationHierarchy__c> getClassificationHierarchyRecord(integer count, Id hierarchyId, String label, Boolean generateIds){
		return (List<Apttus_Config2__ClassificationHierarchy__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ClassificationHierarchy__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ClassificationHierarchy__c.Apttus_Config2__HierarchyId__c => hierarchyId,
			Apttus_Config2__ClassificationHierarchy__c.Apttus_Config2__Label__c => label
		}, count), generateIds);
	}
	//creating a test data for Apttus_Config2__LineItem__c object
	public static List<Apttus_Config2__LineItem__c> getConfigLineItemRecords(integer count, ID configId,ID groupId, Integer itemSeq,
		ID productId, ID productOptionId, ID optionId, ID classId, Decimal quantity,
		Boolean isQtyModifiable, String uom,Integer term,ID priceListId,ID plItemId, String priceType,String priceMethod,String chargeType, String frequency,
		Decimal listPrice, Decimal basePrice,  Decimal baseExtPrice,Decimal optionPrice,
		Decimal extPrice, Boolean generateIds){
			return (List<Apttus_Config2__LineItem__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__LineItem__c.SObjectType, new Map<SObjectField, Object> {
				Apttus_Config2__LineItem__c.Apttus_Config2__LineNumber__c => 1,
				Apttus_Config2__LineItem__c.Apttus_Config2__IsPrimaryLine__c => true,
				Apttus_Config2__LineItem__c.Apttus_Config2__PrimaryLineNumber__c => 1,
				Apttus_Config2__LineItem__c.Apttus_Config2__ItemSequence__c => itemSeq,
				Apttus_Config2__LineItem__c.Apttus_Config2__SummaryGroupId__c => groupId,
				Apttus_Config2__LineItem__c.Apttus_Config2__LineType__c => '',
				Apttus_Config2__LineItem__c.Apttus_Config2__ProductId__c => productId,
				Apttus_Config2__LineItem__c.Apttus_Config2__Customizable__c => false,
				Apttus_Config2__LineItem__c.Apttus_Config2__ProductOptionId__c => productOptionId,
				Apttus_Config2__LineItem__c.Apttus_Config2__OptionId__c => optionId,
				Apttus_Config2__LineItem__c.Apttus_Config2__ClassificationId__c => classId,
				Apttus_Config2__LineItem__c.Apttus_Config2__ClassificationHierarchy__c => '',
				Apttus_Config2__LineItem__c.Apttus_Config2__Quantity__c => quantity,
				Apttus_Config2__LineItem__c.Apttus_Config2__IsQuantityModifiable__c => isQtyModifiable,
				Apttus_Config2__LineItem__c.Apttus_Config2__Uom__c => uom,
				Apttus_Config2__LineItem__c.Apttus_Config2__Term__c => term,
				Apttus_Config2__LineItem__c.Apttus_Config2__PriceListId__c => priceListId,
				Apttus_Config2__LineItem__c.Apttus_Config2__PriceListItemId__c => plItemId,
				Apttus_Config2__LineItem__c.Apttus_Config2__PriceType__c => priceType,
				Apttus_Config2__LineItem__c.Apttus_Config2__PriceMethod__c => priceMethod,
				Apttus_Config2__LineItem__c.Apttus_Config2__ChargeType__c => chargeType,
				Apttus_Config2__LineItem__c.Apttus_Config2__Frequency__c => frequency,
				Apttus_Config2__LineItem__c.Apttus_Config2__AllowManualAdjustment__c => false,
				Apttus_Config2__LineItem__c.Apttus_Config2__AllocateGroupAdjustment__c => false,
				Apttus_Config2__LineItem__c.Apttus_Config2__ListPrice__c => listPrice,
				Apttus_Config2__LineItem__c.Apttus_Config2__BasePrice__c => basePrice,
				Apttus_Config2__LineItem__c.Apttus_Config2__BasePriceMethod__c => '',
				Apttus_Config2__LineItem__c.Apttus_Config2__BaseExtendedPrice__c => baseExtPrice,
				Apttus_Config2__LineItem__c.Apttus_Config2__OptionPrice__c => optionPrice,
				Apttus_Config2__LineItem__c.Apttus_Config2__ExtendedPrice__c => extPrice,
				Apttus_Config2__LineItem__c.Apttus_Config2__Description__c => 'Line Description',
				Apttus_Config2__LineItem__c.Apttus_Config2__AdjustedPrice__c => 0
			}, count), generateIds);
	}
	//creating a test data for Product2 object
	public static List<Product2> getAppcProduct(integer count, Boolean generateIds){
		return (List<Product2>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Product2.SObjectType, new Map<SObjectField, Object> {
			Product2.ProductCode=> 'APPC',
			Product2.name=>'Australia Post Parcel Contract',
			Product2.Family=>'APPC',
			Product2.APT_Contracting_Entity__c=>'Australian Postal Corporation',
			Product2.IsActive=>true,
			Product2.APT_Apttus_Product_Classification__c=>'APPC',
			Product2.APT_Is_Apttus_Product__c=>true
		}, count), generateIds);
	}
	//creating a test data for APT_Agreement_Lodgement_Point__c object
	public static List<APT_Agreement_Lodgement_Point__c> getAgreementLodgementPoints(integer count, Id networkId, Id apttusContractId, Id accountId, Boolean generateIds){
		return (List<APT_Agreement_Lodgement_Point__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(APT_Agreement_Lodgement_Point__c.SObjectType, new Map<SObjectField, Object> {
			APT_Agreement_Lodgement_Point__c.APT_Lodgement_Point_Lookup__c => networkId,
			APT_Agreement_Lodgement_Point__c.APT_Agreement__c => apttusContractId,
			APT_Agreement_Lodgement_Point__c.APT_Organisation__c => accountId
		}, count), generateIds);
	}

	//creating a test data for Apttus_Config2__UsagePriceTier__c object
	public static List<Apttus_Config2__UsagePriceTier__c> getAPTUPTRecord(integer count, Id LineItemId, Boolean generateIds){
		return (List<Apttus_Config2__UsagePriceTier__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__UsagePriceTier__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__UsagePriceTier__c.Apttus_Config2__LineItemId__c => LineItemId,
			Apttus_Config2__UsagePriceTier__c.Apttus_Config2__Dimension4Value__c => 'CASSLOS_KRSP00S006CA',
			Apttus_Config2__UsagePriceTier__c.Apttus_Config2__AdjustmentAmount__c => 2.3,
			Apttus_Config2__UsagePriceTier__c.Apttus_Config2__Sequence__c => 1
		}, count), generateIds);
	}
	//creating a test data for Apttus_Config2__AppliedRuleInfo__c object
	public static List<Apttus_Config2__AppliedRuleInfo__c> getARIRecord(integer count, Id configId, Boolean generateIds){
		return (List<Apttus_Config2__AppliedRuleInfo__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__AppliedRuleInfo__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__Invalid__c => true,
			Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__ConfigurationId__c=> configId,
			Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__PrimaryLineNumber__c => 1

		}, count), generateIds);
	}
	//creating a test data for Apttus_Config2__ConstraintRule__c object
	public static List<Apttus_Config2__ConstraintRule__c> getConstraintRuleRecord(integer count,  Boolean generateIds){
		return (List<Apttus_Config2__ConstraintRule__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Config2__ConstraintRule__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Config2__ConstraintRule__c.Name => 'const',
			Apttus_Config2__ConstraintRule__c.Apttus_Config2__Active__c=> True,
			Apttus_Config2__ConstraintRule__c.Apttus_Config2__MatchInPrimaryLines__c=> True

		}, count), generateIds);
	}
	//creating a test data for APT_Post_Code_Mapping__c object
	public static List<APT_Post_Code_Mapping__c> getPostCodeMappingRecord(integer count,  Boolean generateIds){
	return (List<APT_Post_Code_Mapping__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(APT_Post_Code_Mapping__c.SObjectType, new Map<SObjectField, Object> {
		APT_Post_Code_Mapping__c.Name => 'test record',
		APT_Post_Code_Mapping__c.APT_Suburb__c=> 'Melbourne',
		APT_Post_Code_Mapping__c.APT_Post_Code__c=> '3000'
	}, count), generateIds);
	}
	//creating a test data for OpportunityLineItem object
	public static List<OpportunityLineItem> getOpportunityLineItemRecord(integer count, Id opportunityId,  Boolean generateIds){
	return (List<OpportunityLineItem>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(OpportunityLineItem.SObjectType, new Map<SObjectField, Object> {
		OpportunityLineItem.Classification__c => 'New Business',
		OpportunityLineItem.UnitPrice=> 1.5,
		OpportunityLineItem.Quantity=> 1,
		OpportunityLineItem.opportunityId=> opportunityId,
		OpportunityLineItem.Contract_Product__c=> 'Yes',
		OpportunityLineItem.Change_Classification__c=> 'No'
	}, count), generateIds);
	}
	//creating a test data for Apttus_DocuApi__DocuSignDefaultRecipient2__c object
	public static List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> getDocuSignRecipientsRecord(integer count, Id AgreementId, Id userId,Id contactId,  Boolean generateIds){
	return (List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_DocuApi__DocuSignDefaultRecipient2__c.SObjectType, new Map<SObjectField, Object> {
		Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__UserId__c => userId,
		Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__RecipientType__c=> 'Signer',
		Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__SigningOrder__c=> 1,
		Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_CMDSign__AgreementId__c=> AgreementId ,
		Apttus_DocuApi__DocuSignDefaultRecipient2__c.Apttus_DocuApi__ContactId__c=> contactId
	}, count), generateIds);
	}

	//creating a test data for Account_Plan__c object
	public static List<Account_Plan__c> getAccountPlanRecord(integer count, Id AccountId, Boolean generateIds){
		return (List<Account_Plan__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Account_Plan__c.SObjectType, new Map<SObjectField, Object> {
			Account_Plan__c.Name => 'Test',
			Account_Plan__c.Account__c => AccountId
		}, count), generateIds);
	}

	public static List<Apttus__APTS_Template__c> getTemplateRecord(integer count,  Boolean generateIds){
		return (List<Apttus__APTS_Template__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus__APTS_Template__c.SObjectType, new Map<SObjectField, Object> {
			Apttus__APTS_Template__c.Apttus__Agreement_Types__c => 'APT_MSA_Service_Schedule'
		}, count), generateIds);
	}
	public static List<Apttus__APTS_Agreement__c> getAgreementRecord(integer count,  Boolean generateIds){
		return (List<Apttus__APTS_Agreement__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus__APTS_Agreement__c.SObjectType, new Map<SObjectField, Object> {
			Apttus__APTS_Agreement__c.Name => 'Test',
			Apttus__APTS_Agreement__c.Apttus__Subtype__c => 'TestSubType'
		}, count), generateIds);
	}

	public static List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementRecord(integer count,id Agreement1,id Agreement2,  Boolean generateIds){
		return (List<Apttus__APTS_Related_Agreement__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus__APTS_Related_Agreement__c.SObjectType, new Map<SObjectField, Object> {
			Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_To__c => Agreement1,
			Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_From__c => Agreement2
		}, count), generateIds);
	}

	public static List<Apttus_Approval__Approval_Request__c> getApprovalRecord(integer count,id cartID,  Boolean generateIds){
		return (List<Apttus_Approval__Approval_Request__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Apttus_Approval__Approval_Request__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Approval__Approval_Request__c.Apttus_CQApprov__CartId__c=> cartID
		}, count), generateIds);
	}
	public static List<APT_Operational_Schedule__c> getOperationalSchedule(integer count, Id contractId, Boolean generateIds){
		return (List<APT_Operational_Schedule__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(APT_Operational_Schedule__c.SObjectType, new Map<SObjectField, Object> {
			APT_Operational_Schedule__c.APT_Contract__c => contractId
		}, count), generateIds);
	}

	public static List<Organisation_Role__c> getOrganisationRole(integer count, Id accountId, Boolean generateIds){
		return (List<Organisation_Role__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Organisation_Role__c.SObjectType, new Map<SObjectField, Object> {
			Organisation_Role__c.Role_Type__c => 'Prospect',
			Organisation_Role__c.Organisation__c => accountId
		}, count), generateIds);
	}


	public static List<APT_Credit_Assessment__c> getApttusCreditAssessment(integer count, Id proposalId, Boolean generateIds){
		return (List<APT_Credit_Assessment__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(APT_Credit_Assessment__c.SObjectType, new Map<SObjectField, Object> {
			APT_Credit_Assessment__c.APT_Legal_Entity_Name__c => 'TestLegalEntity',
			APT_Credit_Assessment__c.APT_Proposal__c => proposalId,
			APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c => 'Approved'
		}, count), generateIds);
	}
}