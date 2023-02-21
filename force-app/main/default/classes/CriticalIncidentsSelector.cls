/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Mahesh Parvathaneni
 * @date 2022-11-15
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 */

public virtual inherited sharing class CriticalIncidentsSelector extends ApplicationSelector {
    
    public static CriticalIncidentsSelector newInstance() {
		return (CriticalIncidentsSelector)Application.Selectors.newInstance(CriticalIncidentsSelector.class);
	}

    public static CriticalIncidentsSelector newInstance(Integer recordLimit) {
		return (CriticalIncidentsSelector)Application.Selectors.newInstance(CriticalIncidentsSelector.class).setLimit(recordLimit);
	}

    public virtual override SObjectType getSObjectType() {
		return Critical_Incident__kav.getSObjectType();
	}

    public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            Critical_Incident__kav.Id, Critical_Incident__kav.Network_Org_Id__c, Critical_Incident__kav.KnowledgeArticleId, 
            Critical_Incident__kav.Title, Critical_Incident__kav.Summary, Critical_Incident__kav.PublishStatus, Critical_Incident__kav.language,
            Critical_Incident__kav.URLName
		};
	}

    /**
	 * @description Run a simple query to get records based on PublishStatus
	 */
	public virtual Map<Id, Critical_Incident__kav> selectCriticalIncidentsByPublishStatus(String status) {
		return selectCriticalIncidentsByPublishStatus(status, new Set<Object>());
	}

    /**
	 * @description Run a simple query to get records based on PublishStatus
	 */
	public virtual Map<Id, Critical_Incident__kav> selectCriticalIncidentsByPublishStatus(String status, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
                            .addConditions()
                            .add(new QueryBuilder.SimpleCondition(Critical_Incident__kav.PublishStatus + ' =: status'))
                            .add(new QueryBuilder.SimpleCondition(Critical_Incident__kav.language + ' = \'en_US\''))
                            .endConditions();
		return new Map<Id, Critical_Incident__kav>((List<Critical_Incident__kav>)Database.query(qb.toSoqlString()));
	}

}
