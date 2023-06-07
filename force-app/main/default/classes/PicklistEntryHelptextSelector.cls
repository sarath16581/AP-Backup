/* @author Pratyush Chalasani
 * @date 2023-06-02
 * @group Tests
 * @tag Selector
 * @tag Picklist Entry Helptext Selector
 * @domain Core
 * @description A selector for querying picklist entry helptext records
 * @changelog
 * 2023-06-02 - Pratyush Chalasani - Created
 */
public without sharing class PicklistEntryHelptextSelector  extends ApplicationSelector {
    public static PicklistEntryHelptextSelector newInstance() {
		return (PicklistEntryHelptextSelector)Application.Selectors.newInstance(PicklistEntryHelptextSelector.class);
	}
	
	public virtual override SObjectType getSObjectType() {
		return Picklist_Entry_Helptext__mdt.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Picklist_Entry_Helptext__mdt.Label, Picklist_Entry_Helptext__mdt.DeveloperName
		};
	}

	// Return a list of entries for picklist entry label and custom label name
	public virtual List<Picklist_Entry_Helptext__mdt> selectByObjectAndField(SObjectType objectType, SObjectField field) {
		String key = objectType.getDescribe().getName() + '.' + field.getDescribe().getName();

		QueryBuilder qb = newQueryBuilder(new Set<Object>{Options.WITHOUT_DEFAULT_ORDER})
							.addConditions()
							.add(new QueryBuilder.SimpleCondition(Picklist_Entry_Helptext__mdt.Object_Field_Name__c + ' = \'' + String.escapeSingleQuotes(key) + '\''))
							.endConditions();

		System.debug('[PLEHTS] ' + qb.toSoqlString());

        return (List<Picklist_Entry_Helptext__mdt>)Database.query(qb.toSoqlString());
	}
}