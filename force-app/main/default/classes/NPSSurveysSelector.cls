/**
 * @author SteveL
 * @date 2023-11-16
 * @group Selector
 * @tag Selector
 * @tag NPS Survey
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 */

public virtual inherited sharing class NPSSurveysSelector extends ApplicationSelector{

	public static NPSSurveysSelector newInstance() {
		return (NPSSurveysSelector)Application.Selectors.newInstance(NPSSurveysSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return NPSSurvey__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				NPSSurvey__c.Id, NPSSurvey__c.Name, NPSSurvey__c.Case__c
		};
	}

	public List<NPSSurvey__c> selectByCaseId(Set<Id> ids) {
		return selectByCaseId(ids,new Set<Object>());
	}

	/**
     * @param ids the case ids
     * @param selectorOptions
     *
     * @return
     */
	public List<NPSSurvey__c> selectByCaseId(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(NPSSurvey__c.Case__c + ' in :ids')).endConditions();
		return (List<NPSSurvey__c>)Database.query(qb.toSoqlString());
	}


	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}
}