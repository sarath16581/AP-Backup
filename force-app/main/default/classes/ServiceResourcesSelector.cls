/**
* @author George Nguyen
* @date 2023-04-18
* @group Selector
* @tag Selector
* @tag ServiceResource SObject
* @domain OmniDomain
* @description A very simple selector class that sits in the OmniDomain
* @changelog
* 2023-04-18 - George Nguyen - Created 
* 2023-05-21 - Nathan Franklin - Added new constructors
*/
public inherited sharing class ServiceResourcesSelector extends ApplicationSelector {

	public static ServiceResourcesSelector newInstance() {
		return (ServiceResourcesSelector)Application.Selectors.newInstance(ServiceResourcesSelector.class);
	}

	public static ServiceResourcesSelector newInstance(Integer recordLimit) {
		return (ServiceResourcesSelector)Application.Selectors.newInstance(ServiceResourcesSelector.class).setLimit(recordLimit);
	}

	public static ServiceResourcesSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ServiceResourcesSelector selector = (ServiceResourcesSelector)Application.Selectors.newInstance(ServiceResourcesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return ServiceResource.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			ServiceResource.RelatedRecordId
		};
	}

	public List<ServiceResource> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<ServiceResource> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ServiceResource.Id + ' IN :ids')).endConditions();
		return (List<ServiceResource>)Database.query(qb.toSoqlString());
	}

}