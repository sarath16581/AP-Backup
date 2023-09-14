/**
 * @author Ranjeewa Silva
 * @date 2023-08-08
 * @group Selector
 * @description A very simple selector class for querying Competitor__c records
 * @test CompetitorsSelector_Test
 * @changelog
 * 2023-08-08 - Ranjeewa Silva - Created
 */
public virtual inherited sharing class CompetitorsSelector extends ApplicationSelector {

	public static CompetitorsSelector newInstance() {
		return newInstance(0, new Set<SObjectField>());
	}
	public static CompetitorsSelector newInstance(Integer recordLimit) {
		return newInstance(recordLimit, new Set<SObjectField>());
	}

	public static CompetitorsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return newInstance(recordLimit, new Map<SObjectType, Set<SObjectField>>{Competitor__c.SObjectType => fieldOverrides});
	}

	public static CompetitorsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CompetitorsSelector selector = (CompetitorsSelector)Application.Selectors.newInstance(CompetitorsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected virtual override SObjectType getSObjectType() {
		return Competitor__c.getSObjectType();
	}

	protected virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Competitor__c.Id, Competitor__c.Name, Competitor__c.Primary_Competitor__c, Competitor__c.Incumbents__c,
				Competitor__c.OpportunityId__c, Competitor__c.AccountId__c
		};
	}
}