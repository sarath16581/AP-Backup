	/* @author Seth Heang
	* @date 2022-05-30
	* @group Tests
	* @tag Apttus__AgreementLineItem__c
	* @domain Apttus
	* @description A very simple selector class that sits in the Apttus domain
	* @changelog
	* 2022-05-30 - Seth Heang - Created
	* 2022-06-01 - seth.heang@auspost.com.au - Added method selectByContractIdsAndLineType
	* 2022-08-04 - Seth Heang - Added related list WITH_OPTION, WITH_AGREEMENT_ATTRIBUTE_VALUE, ORDER_BY_ITEM_SEQUENCE_ASC and added fields to query
	* 2022-10-17 - Seth Heang - Added WITH_APPLIED_PSR
	* 2022-12-06 - Nasir Jawed - Added method selectByContractIdsLineTypeProduct
	* 2023-04-25 - Yatika Bansal - Added WITH_PRODUCT
	* 2023-05-10 - Yatika Bansal - Added method selectByContractIdLineTypeAndChargeType
	* 2023-06-14 - Yatika Bansal - Added field Apttus__AgreementId__c
	*/
public with sharing class APT_AgreementLineItemsSelector extends ApplicationSelector{
	public enum Options {
		WITH_CONTRACT, WITH_PROPOSAL, WITH_OPTION, WITH_AGREEMENT_ATTRIBUTE_VALUE, ORDER_BY_ITEM_SEQUENCE_ASC, WITH_APPLIED_PSR, WITH_PRODUCT
	}
	public static APT_AgreementLineItemsSelector newInstance() {
		return (APT_AgreementLineItemsSelector)Application.Selectors.newInstance(APT_AgreementLineItemsSelector.class);
	}

	/**
	* @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*                         This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_AgreementLineItemsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		APT_AgreementLineItemsSelector selector = (APT_AgreementLineItemsSelector)Application.Selectors.newInstance(APT_AgreementLineItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus__AgreementLineItem__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus__AgreementLineItem__c.Id, Apttus__AgreementLineItem__c.Name, Apttus__AgreementLineItem__c.APT_Product_Name__c, Apttus__AgreementLineItem__c.Apttus_CMConfig__LineType__c,
			Apttus__AgreementLineItem__c.Apttus_CMConfig__ItemSequence__c, Apttus__AgreementLineItem__c.APT_Price_Structure__c, Apttus__AgreementLineItem__c.APT_Option_Group__c,
			Apttus__AgreementLineItem__c.APT_Option_Product_Name__c, Apttus__AgreementLineItem__c.APT_Lodgement_Zone__c, Apttus__AgreementLineItem__c.APT_Lodgement_Zone_Code__c,
			Apttus__AgreementLineItem__c.SAP_Custom_Reference__c, Apttus__AgreementLineItem__c.APT_Option_Name_Without_Tier__c,Apttus__AgreementLineItem__c.Apttus_CMConfig__EffectiveDate__c,Apttus__AgreementLineItem__c.Apttus_CMConfig__EndDate__c, Apttus__AgreementLineItem__c.Apttus__AgreementId__c
		};
	}

	/**
	* @description Run a simple query to get records based on proposal Id
	* @param Set<Id> contractIds
	* @param Set<String> lineTypes
	* @param Set<Object> selectorOptions
	* @return List<Apttus__AgreementLineItem__c>
	*/
	public virtual List<Apttus__AgreementLineItem__c> selectByContractIdsAndLineType(Set<Id> contractIds, Set<String> lineTypes, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus__AgreementId__c + ' in :contractIds'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus_CMConfig__LineType__c + ' in :lineTypes'))
		.endConditions();
		return (List<Apttus__AgreementLineItem__c>)Database.query(qb.toSoqlString());
	}

	/**
	* @description Run a simple query to get Agreement Line Items based on Contract Id, line type and product name
	* @param Set<Id> contractIds
	* @param Set<String> lineTypes
	* @param Set<String> productName
	* @param Set<Object> selectorOptions
	* @return List<Apttus__AgreementLineItem__c>
	*/

	public virtual List<Apttus__AgreementLineItem__c> selectByContractIdsLineTypeProduct(Set<Id> contractIds, Set<String> lineTypes,Set<String> productName) {
		return selectByContractIdsLineTypeProduct(contractIds, lineTypes,productName, new Set<Object>());
	}

	public virtual List<Apttus__AgreementLineItem__c> selectByContractIdsLineTypeProduct(Set<Id> contractIds, Set<String> lineTypes,Set<String> productName, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus__AgreementId__c + ' in :contractIds'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus_CMConfig__LineType__c + ' in :lineTypes'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.APT_Product_Name__c + '  in :productName'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.APT_New__c + ' = true'))
		.endConditions();
		return (List<Apttus__AgreementLineItem__c>)Database.query(qb.toSoqlString());
	}

	/**
	* @description Run a simple query to get records based on contract, line type and charge type
	* @param Set<Id> contractIds
	* @param Set<String> lineTypes
	* @param Set<String> chargeTypes
	* @param Set<Object> selectorOptions
	* @return List<Apttus__AgreementLineItem__c>
	*/
	public virtual List<Apttus__AgreementLineItem__c> selectByContractIdLineTypeAndChargeType(Set<Id> contractIds, Set<String> lineTypes,Set<String> chargeTypes, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus__AgreementId__c + ' in :contractIds'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus_CMConfig__LineType__c + ' in :lineTypes'))
			.add(new QueryBuilder.SimpleCondition(Apttus__AgreementLineItem__c.Apttus_CMConfig__ChargeType__c + ' in :chargeTypes'))
		.endConditions();
		return (List<Apttus__AgreementLineItem__c>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if(selectorOptions.contains(Options.WITH_CONTRACT)) {
			builder.addRelatedFields(APT_AgreementObjectsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus__AgreementId__r');
		}
		if(selectorOptions.contains(Options.WITH_PROPOSAL)) {
			builder.addRelatedFields(APT_ProposalObjectsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r');
		}
		if(selectorOptions.contains(Options.WITH_OPTION)) {
			builder.addRelatedFields(ProductsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_CMConfig__OptionId__r');
		}
		if(selectorOptions.contains(Options.WITH_AGREEMENT_ATTRIBUTE_VALUE)) {
			builder.addRelatedFields(AgreementProductAttributeValuesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_CMConfig__AttributeValueId__r');
		}
		if(selectorOptions.contains(Options.WITH_APPLIED_PSR)) {
			builder.addRelatedFields(DealSupportRequestsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_CMConfig__AttributeValueId__r.Applied_PSR__r');
		}
		if(selectorOptions.contains(Options.WITH_PRODUCT)) {
			builder.addRelatedFields(ProductsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus__ProductId__r');
		}
		if(selectorOptions.contains(Options.ORDER_BY_ITEM_SEQUENCE_ASC)) {
			builder.addOrder(
				new QueryBuilder.Order(Apttus__AgreementLineItem__c.Apttus_CMConfig__ItemSequence__c)
				.setSortingOrderAsc()
			);
		}

		return builder;
	}
}