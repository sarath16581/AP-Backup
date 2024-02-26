/**
* @author Victor Cheng
* @date 2021-04-28
* @group Selector
* @tag Selector
* @tag Custom Settings
* @domain Core
* @description A polymorphic Selector Class for custom settings
* @changelog
* 2021-04-28 - Victor Cheng - Created
* 2022-09-05 - Swati Mogadala - Created a new method selectBySetupOwnerId() for hierarchy custom settings
* 2024-02-20 - Naveen Rajanna - REQ3445775
*/
public virtual inherited sharing class CustomsSettingsSelector extends ApplicationSelector{

	public SObjectType settingsType {get; set;}
	public Set<SObjectField> fieldList {get; set;}

	public static CustomsSettingsSelector newInstance(SObjectType sType, Set<SObjectField> fields){

		CustomsSettingsSelector selector = (CustomsSettingsSelector)Application.Selectors.newInstance(CustomsSettingsSelector.class);
		selector.settingsType = sType;
		selector.fieldList = fields;

		return selector;
	}

	protected override SObjectType getSObjectType() {
		return settingsType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return fieldList;
	}

	public virtual Map<String, SObject> selectByNames(Set<String> names)
	{
		// new query string
		QueryBuilder qb = newQueryBuilder();

		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		cm.add(new QueryBuilder.SimpleCondition('Name IN:  names'));
				cm.endConditions();
		List<SObject> queryResults = Database.query((qb.toSoqlString()));

		Map<String, SObject> mapReturn = new Map<String, SObject>();
		for(SObject obj: queryResults)
		{
			mapReturn.put((String) obj.get('Name'), obj);
		}
		return mapReturn;
	}

	/**
	 * Get the Hierarchial Custom Settings rows filtered by the setupOwnerIds
	 * @param targetIds contains setupOwnerIds
	 * @return  `List<SObject>`
	 */
	public virtual List<SObject> selectBySetupOwnerId(Set<Id> targetIds) {
		// new query string
		QueryBuilder qb = newQueryBuilder();

		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		cm.add(new QueryBuilder.SimpleCondition('SetupOwnerId IN:  targetIds'));
		cm.endConditions();
		List<SObject> queryResults = Database.query((qb.toSoqlString()));
		return queryResults;
	}
	
}