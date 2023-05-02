/**
* @author George Nguyen
* @date 2020-10-18
* @group Selector
* @tag Selector
* @tag ServiceResourceSkill SObject
* @domain OmniDomain
* @description A very simple selector class that sits in the OmniDomain
* @changelog
* 2020-11-18 - George Nguyen - Created 
*/
public inherited sharing class ServiceResourceSkillSelector extends ApplicationSelector {

	public enum Options {
		WITH_SERVICE_RESOURCE
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_SERVICE_RESOURCE)) {
			builder.addRelatedFields(ServiceResourcesSelector.newInstance(fieldOverrides).newQueryBuilder(), 'ServiceResource');
		}

		return builder;
	}

	public static ServiceResourceSkillSelector newInstance() {
		return (ServiceResourceSkillSelector)Application.Selectors.newInstance(ServiceResourceSkillSelector.class);
	}

	public static ServiceResourceSkillSelector newInstance(Integer recordLimit) {
		return (ServiceResourceSkillSelector)Application.Selectors.newInstance(ServiceResourceSkillSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return ServiceResourceSkill.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			ServiceResourceSkill.SkillId,
			ServiceResourceSkill.SkillLevel
		};
	}

	public List<ServiceResourceSkill> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<ServiceResourceSkill> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ServiceResourceSkill.Id + ' IN :ids')).endConditions();
		return (List<ServiceResourceSkill>)Database.query(qb.toSoqlString());
	}

	public List<ServiceResourceSkill> selectByActiveServiceResourceRelatedRecordIds(Set<Id> relatedRecordIds, Set<Object> selectorOptions) {
		return selectByActiveServiceResourceRelatedRecordIdsAndSkills(relatedRecordIds, null, selectorOptions);
	}

	public List<ServiceResourceSkill> selectByActiveServiceResourceRelatedRecordIdsAndSkills(Set<Id> relatedRecordIds, Set<String> skillDeveloperNames, Set<Object> selectorOptions) {
		QueryBuilder.ConditionsManager cm = newQueryBuilder(selectorOptions).addConditions()
												.add(new QueryBuilder.SimpleCondition(ServiceResource.getsObjectType() + '.' + ServiceResource.RelatedRecordId + ' IN :relatedRecordIds'))
												.add(new QueryBuilder.SimpleCondition(ServiceResource.getsObjectType() + '.' + ServiceResource.IsActive + ' = TRUE'));
		
		if(skillDeveloperNames != null && skillDeveloperNames.isEmpty() == false) {
			cm.add(new QueryBuilder.SimpleCondition(Skill.getsObjectType() + '.' + Skill.DeveloperName + ' IN :skillDeveloperNames'));
			cm.setConditionOrder('1 AND 2 AND 3');
		} else {
			cm.setConditionOrder('1 AND 2');
		}
							
		QueryBuilder qb = cm.endConditions();

		return (List<ServiceResourceSkill>)Database.query(qb.toSoqlString());
	}

}