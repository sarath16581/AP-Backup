/**
* @author Nathan Franklin
* @date 2023-02-06
* @description A very simple selector class that sits in the Omni Domain
* @changelog
*/
public inherited sharing class SkillsSelector extends ApplicationSelector {

	public static SkillsSelector newInstance() {
		return (SkillsSelector)Application.Selectors.newInstance(SkillsSelector.class);
	}

	public static SkillsSelector newInstance(Integer recordLimit) {
		return (SkillsSelector)Application.Selectors.newInstance(SkillsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SkillsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		SkillsSelector selector = (SkillsSelector) Application.Selectors.newInstance(SkillsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static SkillsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SkillsSelector selector = (SkillsSelector) Application.Selectors.newInstance(SkillsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Skill.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Skill.Id,
			Skill.DeveloperName,
			Skill.MasterLabel
		};
	}

	public List<Skill> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<Skill> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Skill.Id + ' IN :ids')).endConditions();
		return (List<Skill>)Database.query(qb.toSoqlString());
	}

}
