/**
* @author George Nguyen
* @date 2022-11-02
* @group Selector
* @tag Selector
* @tag QueueRoutingConfig SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2022-11-02 - George Nguyen - Created
*/
public inherited sharing class QueueRoutingConfigSelector extends ApplicationSelector {

	public static QueueRoutingConfigSelector newInstance() {
		return (QueueRoutingConfigSelector)Application.Selectors.newInstance(QueueRoutingConfigSelector.class);
	}

	public static QueueRoutingConfigSelector newInstance(Integer recordLimit) {
		return (QueueRoutingConfigSelector)Application.Selectors.newInstance(QueueRoutingConfigSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return QueueRoutingConfig.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            QueueRoutingConfig.CapacityPercentage, 
            QueueRoutingConfig.CapacityWeight, 
            QueueRoutingConfig.DropAdditionalSkillsTimeout, 
            QueueRoutingConfig.IsAttributeBased, 
            QueueRoutingConfig.OverflowAssigneeId, 
            QueueRoutingConfig.PushTimeout, 
            QueueRoutingConfig.RoutingModel, 
            QueueRoutingConfig.RoutingPriority,
            QueueRoutingConfig.DeveloperName
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<QueueRoutingConfig> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

    /**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<QueueRoutingConfig> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(QueueRoutingConfig.Id + ' in :ids')).endConditions();
		return (List<QueueRoutingConfig>)Database.query(qb.toSoqlString());
	}

    /**
	 * @description Run a simple query to get Group records based on DeveloperName
	 * @param developerNames Set of developer names in the Groups retrieved
	 * @param selectorOptions Additional selector options
	 * @return Group records with developer names passed in.
	 */
	public List<QueueRoutingConfig> selectSkillBasedByDeveloperName(List<String> developerNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
            .add(new QueryBuilder.SimpleCondition(QueueRoutingConfig.DeveloperName + ' in :developerNames'))
            .add(new QueryBuilder.SimpleCondition(QueueRoutingConfig.IsAttributeBased + ' = TRUE')) // NOTE: IsAttributeBased denotes skills based routing
        .endConditions();
		return (List<QueueRoutingConfig>)Database.query(qb.toSoqlString());
	}
}
