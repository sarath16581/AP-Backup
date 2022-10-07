/*
* @author Seth Heang
* @date 2022-09-15
* @group Selector
* @tag Selector
* @tag Apttus_Config2__ProductOptionComponent__c
* @domain Apttus
* @description A very simple selector class for Apttus_Config2__ProductOptionComponent__c
* @changelog
* 2022-09-15 - Seth Heang - Created
*/
public virtual inherited sharing class APT_ProductOptionCompsSelector extends ApplicationSelector {
	public enum Options {
		WITH_COMPONENT_PRODUCT
	}

	public static APT_ProductOptionCompsSelector newInstance() {
		return (APT_ProductOptionCompsSelector)Application.Selectors.newInstance(APT_ProductOptionCompsSelector.class);
	}

	public static APT_ProductOptionCompsSelector newInstance(Integer recordLimit) {
		return (APT_ProductOptionCompsSelector)Application.Selectors.newInstance(APT_ProductOptionCompsSelector.class).setLimit(recordLimit);
	}
    
	public virtual override SObjectType getSObjectType() {
		return Apttus_Config2__ProductOptionComponent__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {				
				Apttus_Config2__ProductOptionComponent__c.Id,Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ParentProductId__c,Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ComponentProductId__c
			};
		}

	/**
	 * @description Run a simple query to get records based on parent product Id's
	 */
	public List<Apttus_Config2__ProductOptionComponent__c> selectByParentProductId(Set<Id> ids) {
		return selectByParentProductId(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on parent product Id's
	 */
	public List<Apttus_Config2__ProductOptionComponent__c> selectByParentProductId(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ParentProductId__c + ' in :ids')).endConditions();
		return (List<Apttus_Config2__ProductOptionComponent__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_COMPONENT_PRODUCT)) {
			builder.addRelatedFields(ProductsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_Config2__ComponentProductId__r');
		}

		return builder;
	}
}