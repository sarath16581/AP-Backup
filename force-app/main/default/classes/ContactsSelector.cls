/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag Contacts
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
 * 2020-11-18 - shashwat.nath@auspost.com.au updated to include Phone and Fax fields in the query
 * 2021-08-06 - Seth Heang - Added selectByLikedNameOrderByConsumerAndNameNullFirst, selectByLikedAnyPhoneOrderByName
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2022-07-19 - Sreenish Krishnan - Code upliftment to newinstance with map parameters and additional fields
 * 2022-09-05 - Nathan Franklin - Passed options and overrides to AccountsSelector
 * 2023-07-05 - Mahesh Parvathaneni - Added options WITH_BILLING_ACCOUNT
 * 2023-10-01 - Hasantha Liyanage - Added Contact.BillingAccount__c in getSObjectFieldList
 * 2024-01-22 - Hasantha Liyanage - Added selectPrimaryContactByAccount method
 * 2024-05-24 - Harry Wang - Added selectCloneableContactsByAccount
 */
public virtual inherited sharing class ContactsSelector extends ApplicationSelector {
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_ACCOUNT, WITH_BILLING_ACCOUNT
	}

	public static ContactsSelector newInstance() {
		return (ContactsSelector)Application.Selectors.newInstance(ContactsSelector.class);
	}
	public static ContactsSelector newInstance(Integer recordLimit) {
		return (ContactsSelector)Application.Selectors.newInstance(ContactsSelector.class).setLimit(recordLimit);
	}

	public static ContactsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		return (ContactsSelector) Application.Selectors.newInstance(ContactsSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);
	}

	public static ContactsSelector newInstance(Integer recordLimit, Map<SObjectType,Set<SObjectField>> fieldOverrides) {
		return (ContactsSelector) Application.Selectors.newInstance(ContactsSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);
	}

	public override SObjectType getSObjectType() {
		return Contact.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Name, Contact.APCN__c,
				Contact.Email, Contact.OID_ID__c, Contact.CRMCSSOID__c , Contact.Phone , Contact.Fax, Contact.MobilePhone, Contact.HomePhone, Contact.Salutation, Contact.Title,
				Contact.VerifiedMobile__c,Contact.Unique_Mobile__c, Contact.BillingAccount__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Contact> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Contact> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(Contact.Id + ' in :ids'))
			.endConditions();
		return new Map<Id, Contact>((List<Contact>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on account Id's
	 */
	public Map<Id, Contact> selectByAccount(Set<Id> accountIds) {
		return selectByAccount(accountIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Account Id's
	 */
	public Map<Id, Contact> selectByAccount(Set<Id> accountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(Contact.AccountId + ' in :accountIds'))
			.endConditions();
		return new Map<Id, Contact>((List<Contact>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description select primary contacts per given account ids
	 * @param accountIds list of account IDs
	 * @return List of primary contacts
	 */
	public List<Contact> selectPrimaryContactByAccount(Set<Id> accountIds) {
		return selectPrimaryContactByAccount(accountIds, new Set<Object>());
	}

	/**
	 * @description select primary contacts per given account ids
	 * @param accountIds list of account IDs
	 * @param selectorOptions selector options to be considered when query
	 * @return List of primary contacts
	 */
	public List<Contact> selectPrimaryContactByAccount(Set<Id> accountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(Contact.AccountId + ' in :accountIds'))
				.add(new QueryBuilder.SimpleCondition(Contact.ConveyancerContact__c + ' = true'))
				.endConditions();
		return (List<Contact>) Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on account Id's
	 */
	public Map<Id, Contact> selectByLikedNameOrderByConsumerAndNameNullFirst(string name) {
		return selectByLikedNameOrderByConsumerAndNameNullFirst(name, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on account Id's
	 */
	public Map<Id, Contact> selectByLikedNameOrderByConsumerAndNameNullFirst(string name, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'Account')
			.addConditions()
			.add(new QueryBuilder.LikeCondition(Contact.Name).likeAnyBoth(name))
			.endConditions();
		qb.addOrder(new QueryBuilder.Order('Account.IsPersonAccount').setSortingOrderAsc().setNullsOrderFirst())
			.addOrder(new QueryBuilder.Order(Contact.Name).setSortingOrderAsc().setNullsOrderFirst());
		return new Map<Id, Contact>((List<Contact>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select Contact by checking 'Like' operator on MobilePhone OR  Phone OR HomePhone and order by Name
	 * @param string phone
	 * @return matching Contact records
	 */
	public Map<Id, Contact> selectByLikedAnyPhoneOrderByName(string phone) {
		return selectByLikedAnyPhoneOrderByName(phone, new Set<Object>());
	}

	/**
	 * @description Select Contact by checking 'Like' operator on MobilePhone OR  Phone OR HomePhone and order by Name
	 * @param string phone
	 * @return matching Contact records
	 */
	public Map<Id, Contact> selectByLikedAnyPhoneOrderByName(string phone, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.LikeCondition(Contact.MobilePhone).likeAnyBoth(phone))
			.add(new QueryBuilder.LikeCondition(Contact.Phone).likeAnyBoth(phone))
			.add(new QueryBuilder.LikeCondition(Contact.HomePhone).likeAnyBoth(phone))
			.setConditionOrder('(1 OR 2 OR 3)')
			.endConditions();
		qb.addOrderAsc(Contact.Name);
		return new Map<Id, Contact>((List<Contact>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select cloneable contact by parent account ID.
	 * Cloneable contacts are active and maintained by Account Manager
	 * @param accountId parent account ID
	 * @return matching Contact records
	 */
	public List<Contact> selectCloneableContactsByAccount(Id accountId) {
		QueryBuilder qb = newQueryBuilder()
				.addConditions()
				.add(new QueryBuilder.CompareCondition(Contact.AccountId).eq(accountId))
				.add(new QueryBuilder.CompareCondition(Contact.Status__c).eq('Active'))
				.add(new QueryBuilder.CompareCondition(Contact.Record_Maintainer__c).eq('Account Manager'))
				.endConditions();
		return Database.query(qb.toSoqlString());
	}

	/**
	 * Grabs a new QueryBuilder
	 */
	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	/**
	 * Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if (selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		if (selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Account');
		}

		if (selectorOptions.contains(Options.WITH_BILLING_ACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'BillingAccount__r');
		}
		

		return builder;
	}

		// TODO: Activate Cache
		// 	/**
		// 	 * Builds a list of sobjects that were present in a query based on the selectorOptions.
		// 	* By tracking all sobjects used in a query, we can accurately purge any cache that may become stale after DML operations occur for those objects
		// 	* The purging is done as a part of the execution of the trigger
		// 	*/
		// 	@TestVisible
		// 	protected override Set<String> getUsedCachedSObjects(Set<Object> selectorOptions) {
		// 		Set<String> output = super.getUsedCachedSObjects(selectorOptions);
		
		// 		if(((Integer)selectorOptions & SELECTOR_OPTION_WITH_OWNER) == SELECTOR_OPTION_WITH_OWNER) {
		// 			output.add('User');
		// 		}
		
		// 		return output;
		// 	}
}