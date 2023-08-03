/* @author Yatika Bansal
 * @date 2023-23-04
 * @tag Selector
 * @tag APT_Operational_Schedule__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * 2023.04.19 Ken McGuire  Proposal field migration to opportunity
 */
public virtual inherited sharing class APT_OperationalScheduleSelector extends ApplicationSelector{
 
	public static APT_OperationalScheduleSelector newInstance() {
		return (APT_OperationalScheduleSelector)Application.Selectors.newInstance(APT_OperationalScheduleSelector.class);
	}
	
	public static APT_OperationalScheduleSelector newInstance(Integer recordLimit) {
		return (APT_OperationalScheduleSelector)Application.Selectors.newInstance(APT_OperationalScheduleSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return APT_Operational_Schedule__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			APT_Operational_Schedule__c.Id, APT_Operational_Schedule__c.APT_Contract__c, APT_Operational_Schedule__c.APT_Parcel_Collection_Points__c
		};
	}

	/**
	*@description Run a query to get records based on proposal id and (status or credit assessment status)
	*/
	public List<APT_Operational_Schedule__c> selectByContractId(Set<Id> contractIds) {
		return selectByContractId(contractIds, new Set<Object>());		
	}
	
	/**
	*@description Run a query to get records based on proposal id and (status or credit assessment status)
	*/
	public List<APT_Operational_Schedule__c> selectByContractId(Set<Id> contractIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Operational_Schedule__c.APT_Contract__c + ' = :contractIds')).endConditions();

		return (List<APT_Operational_Schedule__c>)Database.query(qb.toSoqlString());
	}
}