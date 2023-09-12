/***
 */
public virtual inherited sharing class UserRecordAccessSelector extends ApplicationSelector {
	public static UserRecordAccessSelector newInstance() {
		return (UserRecordAccessSelector) Application.Selectors.newInstance(UserRecordAccessSelector.class);
	}
	public static UserRecordAccessSelector newInstance(Integer recordLimit) {
		return (UserRecordAccessSelector) Application.Selectors.newInstance(UserRecordAccessSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static UserRecordAccessSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		UserRecordAccessSelector selector = (UserRecordAccessSelector) Application.Selectors.newInstance(UserRecordAccessSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static UserRecordAccessSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		UserRecordAccessSelector selector = (UserRecordAccessSelector) Application.Selectors.newInstance(UserRecordAccessSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return UserRecordAccess.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			UserRecordAccess.RecordId,
			UserRecordAccess.HasReadAccess,
			UserRecordAccess.HasEditAccess,
			UserRecordAccess.HasDeleteAccess,
			UserRecordAccess.HasTransferAccess,
			UserRecordAccess.HasAllAccess
		};
	}

	/**
	 * @description Run a query to get record access for Current User
	 * @param recordId of which to return UserRecordAccess
	 */
	public UserRecordAccess selectById(Id recordId) {
		return selectById(new Set<Id>{ recordId }).get(recordId);
	}

	/**
	 * @description Run a query to get record access for Current User
	 * @param recordIds of which to return UserRecordAccess
	 */
	public Map<Id,UserRecordAccess> selectById(Set<Id> recordId) {
		return selectById(recordId, UserInfo.getUserId());
	}

	/**
	 * @description Run a query to get record access for Current User
	 * @param recordIds RecordIds of which to return UserRecordAccess
	 * @param userId RecordId of which to return UserRecordAccess
	 */
	public Map<Id,UserRecordAccess> selectById(Set<Id> recordIds, Id userId) {
		return new Map<Id,UserRecordAccess>((List<UserRecordAccess>)Database.query(
			newQueryBuilder()
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(UserRecordAccess.RecordId + ' IN :recordIds'))
				.add(new QueryBuilder.SimpleCondition(UserRecordAccess.UserId + ' = :userId'))
				.endConditions()
				.setOrder(new QueryBuilder.Order(UserRecordAccess.RecordId))
				.toSoqlString()
		));
	}
}