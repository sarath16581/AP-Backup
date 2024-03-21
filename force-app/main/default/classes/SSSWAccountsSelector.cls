/***
 * A very simple selector class that sits in the base domain
 *
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
 * 2021-05-19 - Disha Kariya - Added fields for personal accounts.
 * 2023-08-04 - Added field Account.is_Inactive_Customer__pc in getSObjectFieldList
 * 2023-10-02 - Boris Bachovski - Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
 * 2024-03-07 - Mahesh Parvathaneni - Added new instance method that allows FOR UPDATE
 */
public virtual inherited sharing class SSSWAccountsSelector extends AccountsSelector {

	public enum Options {
		FILTER_PERSON_ACCOUNT_ONLY
	}

	public static SSSWAccountsSelector newInstance() {
		return (SSSWAccountsSelector)Application.Selectors.newInstance(SSSWAccountsSelector.class);
	}
	public static SSSWAccountsSelector newInstance(Integer recordLimit) {
		return (SSSWAccountsSelector)Application.Selectors.newInstance(SSSWAccountsSelector.class).setLimit(recordLimit);
	}

	public static SSSWAccountsSelector newInstance(Boolean forUpdate) {
		return (SSSWAccountsSelector)Application.Selectors.newInstance(SSSWAccountsSelector.class).setForUpdate(forUpdate);
	}

	/**
	 * Grab the base fields and extend by adding new fields specific to the domain of this selector
	 */
	public virtual override Set<SObjectField> getSObjectFieldList() {
		Set<SObjectField> fields = super.getSObjectFieldList();
		fields.addAll(new Set<SObjectField>{
				Account.PersonContactId, Account.APCN__pc, Account.OID_ID__pc, Account.CRMCSSOID__pc, Account.IsPersonAccount, Account.VerifiedMobile__pc, Account.PersonMobilePhone, Account.PersonEmail,
				Account.IsInactiveCustomer__pc
		});
		return fields;
	}

	/**
	 * @description Run a simple query to get records based on APCN's for person accounts
	 */
	public Map<Id, Account> selectByAPCN(Set<String> apcns) {
		return selectByAPCN(apcns, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on APCN's for person accounts
	 */
	public Map<Id, Account> selectByAPCN(Set<String> apcns, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Account.APCN__pc + ' in :apcns')).endConditions();
		return new Map<Id, Account>((List<Account>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.FILTER_PERSON_ACCOUNT_ONLY)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Account.IsPersonAccount).eq(true)).endConditions();
		}

		return builder;
	}
}