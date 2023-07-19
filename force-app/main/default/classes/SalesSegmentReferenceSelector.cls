/**
 * @author Pratyush Chalasani
 * @date 2023-07-12
 * @group Selector
 * @domain Core
 * @description Selector class to provide a query interface to the Sales_Segment_Reference__c SObject.
 * @changelog
 * 2023-07-12 - Pratyush Chalasani - Created
 */
public inherited sharing class SalesSegmentReferenceSelector extends ApplicationSelector {
	public static SalesSegmentReferenceSelector newInstance() {
		return (SalesSegmentReferenceSelector)Application.Selectors.newInstance(SalesSegmentReferenceSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return Sales_Segment_Reference__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Sales_Segment_Reference__c.Sales_Segment__c, Sales_Segment_Reference__c.SalesDirectorApprover__c, Sales_Segment_Reference__c.GeneralManager__c
		};
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public List<Sales_Segment_Reference__c> selectByName(Set<String> names) {
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(Sales_Segment_Reference__c.Sales_Segment__c + ' in :names')).endConditions();
		return (List<Sales_Segment_Reference__c>)Database.query(qb.toSoqlString());
	}
}