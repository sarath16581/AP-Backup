/**
 * @author Paul Perry
 * @date 2023-04-24
 * @group Selector
 * @tag Selector
 * @tag HistoryTracking__mdt SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class HistoryTrackingSelector extends ApplicationSelector {
	private static HistoryTrackingSelector instance {
		get {
			if (instance == null) {
				instance = (HistoryTrackingSelector)Application.Selectors.newInstance(HistoryTrackingSelector.class);
			}

			return instance;
		}
		set;
	}

	public static HistoryTrackingSelector newInstance() {
		return instance;
	}

	public static HistoryTrackingSelector newInstance(Integer recordLimit) {
		return (HistoryTrackingSelector)Application.Selectors.newInstance(HistoryTrackingSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return HistoryTracking__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			HistoryTracking__mdt.Id,
			HistoryTracking__mdt.DeveloperName,
			HistoryTracking__mdt.ObjectName__c,
			HistoryTracking__mdt.OverwriteExistingValue__c,
			HistoryTracking__mdt.MatchingValue__c,
			HistoryTracking__mdt.TargetField__c,
			HistoryTracking__mdt.TargetValue__c,
			HistoryTracking__mdt.TrackedFieldName__c
		};
	}

	/**
	 * Select HistoryTrackings based on Object Api Names
	 * @param objectApiNames If supplied, only select HistoryTracking for the ObjectApiNames names passed in. 
	 * @return matching active HistoryTracking records
	 */
	public virtual Map<Id, HistoryTracking__mdt> selectByObjectApiNames(List<String> objectApiNames) {
		QueryBuilder qb = newQueryBuilder(objectApiNames);

		String soql = qb.toSoqlString();
		return new Map<Id, HistoryTracking__mdt>((List<HistoryTracking__mdt>)Database.query(soql));
	}

	public virtual QueryBuilder newQueryBuilder(List<String> objectApiNames) {
        return newQueryBuilder().addConditions()
            .add(new QueryBuilder.CompareCondition(HistoryTracking__mdt.IsActive__c).eq(true))
            .add(new QueryBuilder.SimpleCondition('ObjectName__c IN :objectApiNames'))                        
            .endConditions()
            .setOrder(new QueryBuilder.Order(HistoryTracking__mdt.Id));        
	}
}