/* @author Seth Heang
 * @date 2022-04-08
 * @group Selector
 * @tag Selector
 * @tag Apttus_Config2__TempObject__c
 * @domain Apttus
 * @description A very simple selector class for Apttus_Config2__TempObject__c that sits in the Apttus domain
 */
public virtual inherited sharing class APT_ConfigTempObjectsSelector extends ApplicationSelector {
	public enum Options {
	}

	public static APT_ConfigTempObjectsSelector newInstance() {
		return (APT_ConfigTempObjectsSelector)Application.Selectors.newInstance(APT_ConfigTempObjectsSelector.class);
	}
	public static APT_ConfigTempObjectsSelector newInstance(Integer recordLimit) {
		return (APT_ConfigTempObjectsSelector)Application.Selectors.newInstance(APT_ConfigTempObjectsSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus_Config2__TempObject__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus_Config2__TempObject__c.Id,  Apttus_Config2__TempObject__c.Apttus_Config2__ConfigurationId__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Apttus shopping cart config Id's
	 */
	public virtual List<Apttus_Config2__TempObject__c> selectByConfigId(Set<Id> configIds) {
		return selectByConfigId(configIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Apttus shopping cart config Id's
	 */
	public virtual List<Apttus_Config2__TempObject__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__TempObject__c.Apttus_Config2__ConfigurationId__c + ' = :configIds'))
			.endConditions();
		return (List<Apttus_Config2__TempObject__c>)Database.query(qb.toSoqlString());
	}

}