/**
 * @author Ranjeewa Silva
 * @date 2023-12-14
 * @description A very simple selector for Sales_Team_Segment__c.
 * @group Selector
 * @test SalesTeamSegmentsSelector_Test
 * @changelog
 * 2023-12-14 - Ranjeewa Silva - Created
*/
public virtual inherited sharing class SalesTeamSegmentsSelector extends ApplicationSelector {

	public static SalesTeamSegmentsSelector newInstance() {
		return (SalesTeamSegmentsSelector)Application.Selectors.newInstance(SalesTeamSegmentsSelector.class);
	}

	public static SalesTeamSegmentsSelector newInstance(Integer recordLimit) {
		return (SalesTeamSegmentsSelector)Application.Selectors.newInstance(SalesTeamSegmentsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SalesTeamSegmentsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		SalesTeamSegmentsSelector selector = (SalesTeamSegmentsSelector)Application.Selectors.newInstance(SalesTeamSegmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SalesTeamSegmentsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SalesTeamSegmentsSelector selector = (SalesTeamSegmentsSelector)Application.Selectors.newInstance(SalesTeamSegmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return Sales_Team_Segment__c.getSObjectType();
	}

	protected virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				Sales_Team_Segment__c.Id, Sales_Team_Segment__c.Name, Sales_Team_Segment__c.Segment__c
		};
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<Sales_Team_Segment__c> selectByName(Set<String> salesTeamSegmentNames) {
		return selectByName(salesTeamSegmentNames, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual List<Sales_Team_Segment__c> selectByName(Set<String> salesTeamSegmentNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Sales_Team_Segment__c.Name + ' in :salesTeamSegmentNames')).endConditions();
		return (List<Sales_Team_Segment__c>)Database.query(qb.toSoqlString());
	}
}