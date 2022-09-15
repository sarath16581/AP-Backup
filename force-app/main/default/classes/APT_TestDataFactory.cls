/**
* @description Contains all the test data methods for Apttus object related test classes
* @author Seth Heang
* @date 2022-04-08
* @group Tests
* @tags mocking, apex mocks, tests, data factory, test data, apttus
* @domain Apttus
* @changelog
* 2022-04-08 - Seth Heang - Created
* 2022-05-30 - nasir.jawed@auspost.com.au - added the method to get proposal, contact  for test class
* 2022-06-01 - Seth Heang - Added getAPTAgreementLineItem
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
			Apttus_Config2__ProductAttributeValue__c.APT_Tier_Approved__c => false,
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
			Apttus_Proposal__Proposal__c.Is_Startrack_Proposal__c => 'NO',			
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c => AccID,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c => conID,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c => oppId
		}, count), generateIds);
	}
	// creating a test data for Contact object
	public static List<Contact> getAPTContactRecord(integer count, Id AccID, Boolean generateIds){
		return (List<Contact>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Contact.SObjectType, new Map<SObjectField, Object> {			
			Contact.lastname => 'Jawed',
			Contact.status__c => 'Active',			
			Contact.AccountID => AccID,
			Contact.email => 'njawed@conga.com',
			Contact.phone => '9886340071'
		}, count), generateIds);
	}
}