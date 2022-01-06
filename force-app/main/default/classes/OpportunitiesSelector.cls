/* @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Opportunity
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 */

public virtual inherited sharing class OpportunitiesSelector extends ApplicationSelector {

    public enum Options {
		WITH_RECORDTYPE, WITH_OWNER
    }
    public static OpportunitiesSelector newInstance() {
		return (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class);
	}
	public static OpportunitiesSelector newInstance(Integer recordLimit) {
		return (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit);
    }
    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunitiesSelector selector = (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	  }

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */	
	public static OpportunitiesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunitiesSelector selector = (OpportunitiesSelector)Application.Selectors.newInstance(OpportunitiesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	} 

	public virtual override SObjectType getSObjectType() {
		return Opportunity.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Opportunity.Id,Opportunity.Name,Opportunity.StageName, Opportunity.IsClosed, Opportunity.ownerId
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Opportunity> selectById(Set<Id> ids) {
        System.debug('Coming1');
		return selectById(ids, new Set<Object>());
	}

    
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Opportunity> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        System.debug('Coming2');
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Opportunity.Id + ' in :ids')).endConditions();
        System.debug('qb>>>>'+qb);
        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}
		return builder;
	}
}