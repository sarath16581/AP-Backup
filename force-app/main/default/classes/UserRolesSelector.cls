/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Selector
* @tag Selector
* @tag UserRole SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId and selectbyDeveloperName Methods
*/
public virtual inherited sharing class UserRolesSelector extends ApplicationSelector {

	public static UserRolesSelector newInstance() {
		return (UserRolesSelector)Application.Selectors.newInstance(UserRolesSelector.class);
	}
	public static UserRolesSelector newInstance(Integer recordLimit) {
		return (UserRolesSelector)Application.Selectors.newInstance(UserRolesSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return UserRole.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				UserRole.CaseAccessForAccountOwner, UserRole.ContactAccessForAccountOwner, UserRole.DeveloperName, UserRole.ForecastUserId,
				UserRole.Id, UserRole.MayForecastManagerShare, UserRole.Name, UserRole.OpportunityAccessForAccountOwner, UserRole.ParentRoleId,
				UserRole.PortalAccountId, UserRole.PortalAccountOwnerId, UserRole.PortalRole, UserRole.PortalType, UserRole.RollupDescription
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, UserRole> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, UserRole> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(UserRole.Id + ' in :ids')).endConditions();
		return new Map<Id, UserRole>((List<UserRole>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on DeveloperName
	 */
	public Map<Id, UserRole> selectByDeveloperName(Set<String> developerNames) {
		return selectByDeveloperName(developerNames, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on DeveloperName
	 */
	public Map<Id, UserRole> selectByDeveloperName(Set<String> developerNames, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(UserRole.DeveloperName + ' in :developerNames')).endConditions();
		return new Map<Id, UserRole>((List<UserRole>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('Id', 'Desc')};
	}



}