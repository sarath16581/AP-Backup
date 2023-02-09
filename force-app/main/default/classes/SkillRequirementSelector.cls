/**
* @author George Nguyen
* @date 2020-10-18
* @group Selector
* @tag Selector
* @tag SkillRequirement SObject
* @domain OmniDomain
* @description A very simple selector class that sits in the OmniDomain
* @changelog
* 2020-11-18 - George Nguyen - Created 
* 2023-02-06 - Nathan Franklin - Added some more fields and skill related object
*/
public inherited sharing class SkillRequirementSelector extends ApplicationSelector {

	public enum Options {
		WITH_SKILLS
	}

	public static SkillRequirementSelector newInstance() {
		return (SkillRequirementSelector)Application.Selectors.newInstance(SkillRequirementSelector.class);
	}

	public static SkillRequirementSelector newInstance(Integer recordLimit) {
		return (SkillRequirementSelector)Application.Selectors.newInstance(SkillRequirementSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SkillRequirementSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		SkillRequirementSelector selector = (SkillRequirementSelector) Application.Selectors.newInstance(SkillRequirementSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static SkillRequirementSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SkillRequirementSelector selector = (SkillRequirementSelector) Application.Selectors.newInstance(SkillRequirementSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return SkillRequirement.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			SkillRequirement.SkillId,
			SkillRequirement.SkillLevel,
			SkillRequirement.RelatedRecordId
		};
	}

	public List<SkillRequirement> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<SkillRequirement> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(SkillRequirement.Id + ' in :ids')).endConditions();
		return (List<SkillRequirement>)Database.query(qb.toSoqlString());
	}

	public List<SkillRequirement> selectByRelatedRecordIds(Set<Id> relatedRecordIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(SkillRequirement.RelatedRecordId + ' in :relatedRecordIds')).endConditions();
		return (List<SkillRequirement>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_SKILLS)) {
			builder.addRelatedFields(SkillsSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Skill');
		}

		return builder;
	}

}