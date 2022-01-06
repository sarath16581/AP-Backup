/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Selector
* @tag Selector
* @tag Group SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
* 2020-10-21 - Ranjeewa Silva	- Added new methods to select by developer name.
* 2020-12-18 - Seth Heang   - Added new methods to select by Group Type AND Group Name
* 2021-02-17 - Seth Heang - Updated - Add selectByGroupTypeAndDeveloperName method 
*/
public inherited sharing class GroupsSelector extends ApplicationSelector {

	public enum Options {
		WITH_OWNER
	}

	public static GroupsSelector newInstance() {
		return (GroupsSelector)Application.Selectors.newInstance(GroupsSelector.class);
	}
	public static GroupsSelector newInstance(Integer recordLimit) {
		return (GroupsSelector)Application.Selectors.newInstance(GroupsSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return Group.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Group.CreatedById, Group.CreatedDate, Group.DeveloperName, Group.DoesIncludeBosses, Group.DoesSendEmailToMembers,
				Group.Email, Group.Id, Group.LastModifiedById, Group.LastModifiedDate, Group.Name, Group.OwnerId,
				Group.QueueRoutingConfigId, Group.RelatedId, Group.Type
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Group> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Group> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Group.Id + ' in :ids')).endConditions();
		return new Map<Id, Group>((List<Group>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get Group records based on DeveloperName
	 * @param developerNames Set of developer names in the Groups retrieved
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByDeveloperName(Set<String> developerNames) {
		return selectByDeveloperName(developerNames, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get Group records based on DeveloperName
	 * @param developerNames Set of developer names in the Groups retrieved
	 * @param selectorOptions Additional selector options
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByDeveloperName(Set<String> developerNames, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Group.DeveloperName + ' in :developerNames')).endConditions();
		return new Map<Id, Group>((List<Group>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on group type and name
	 * @param groupType Type of the Group to be retrieved
	 * @param groupName Name of the Group to be retrieved
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByGroupTypeAndName(Set<String> groupType, Set<String> groupName) {
		return selectByGroupTypeAndName(groupType, groupName, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on group type and name
	 * @param groupType Type of the Group to be retrieved
	 * @param groupName Name of the Group to be retrieved
	 * @param selectorOptions Additional selector options
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByGroupTypeAndName(Set<String> groupType, Set<String> groupName, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(Group.Type + ' = :groupType'))
		.add(new QueryBuilder.SimpleCondition(Group.Name + ' = :groupName'))
		.endConditions();
        return new Map<Id, Group>((List<Group>)Database.query(qb.toSoqlString()));
        
	}

	/**
	 * @description Run a simple query to get records based on group type and name
	 * @param groupType Type of the Group to be retrieved
	 * @param groupDevName Developer Name of the Group to be retrieved
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByGroupTypeAndDeveloperName(Set<String> groupType, Set<String> groupDevName) {
		return selectByGroupTypeAndDeveloperName(groupType, groupDevName, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on group type and name
	 * @param groupType Type of the Group to be retrieved
	 * @param groupDevName Developer Name of the Group to be retrieved
	 * @param selectorOptions Additional selector options
	 * @return Group records with developer names passed in.
	 */
	public Map<Id, Group> selectByGroupTypeAndDeveloperName(Set<String> groupType, Set<String> groupDevName, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(Group.Type + ' = :groupType'))
		.add(new QueryBuilder.SimpleCondition(Group.DeveloperName + ' = :groupDevName'))
		.endConditions();
        return new Map<Id, Group>((List<Group>)Database.query(qb.toSoqlString()));
        
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		return builder;
	}



}