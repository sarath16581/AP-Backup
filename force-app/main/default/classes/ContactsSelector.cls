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
 * 2024-05-21 - Marcel HK - Added selector method `selectByCustomerSearchParams` for Customer Search (CSLU-107)
 * 2024-07-05 - Marcel HK - Updated ORDER BY for the selector method `selectByCustomerSearchParamsQB` (CSLU-955)
 * 2024-07-15 - Marcel HK - Added selector option WITH_RELATED_CASES to include related cases sub-query (CSLU-439)
 * 2024-07-15 - Marcel HK - Added enum `CustomerSearchCustomerType` and customer type filters (CSLU-446)
 * 2024-07-22 - Marcel HK - Added mailing address filters for the selector method `selectByCustomerSearchParamsQB` (CSLU-1072)
 * 2024-07-23 - Marcel HK - Removed 'Country' mailing address filters (CSLU-1072)
 * 2024-07-23 - Marcel HK - Allow match if MailingStreet equals addressLine1 + addressLine2 (CSLU-1106)
 * 2024-07-23 - Marcel HK - Added filters for accountId and abn/acn lookup (CSLU-447)
 * 2024-08-08 - Marcel HK - Update Address filters for `selectByCustomerSearchParamsQB` (CSLU-1072)
 * 2024-09-10 - SteveL - added method selectByReversedPhoneNumbers
 */
public virtual inherited sharing class ContactsSelector extends ApplicationSelector {
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_ACCOUNT, WITH_BILLING_ACCOUNT, WITH_RELATED_CASES
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
				Contact.VerifiedMobile__c,Contact.Unique_Mobile__c, Contact.BillingAccount__c, Contact.IncentCredential__c
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
	 * @param selectorOptions Set<Object> selectorOptions
	 * @param reversedPhoneNumbers Set<String> a collection of reversed phone numbers
	 * @description returns a list of Contacts based on either matching on ReverseMobilePhone__c, ReverseVerifiedMobile__c, or ReversePhone__c
	 *
	 * @return Map<Id, Contact>
	 */
	public Map<Id, Contact> selectByReversedPhoneNumbers(Set<Object> selectorOptions, Set<String> reversedPhoneNumbers) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.InCondition(Contact.ReverseMobilePhone__c).inCollection(reversedPhoneNumbers))
				.add(new QueryBuilder.InCondition(Contact.ReverseVerifiedMobile__c).inCollection(reversedPhoneNumbers))
				.add(new QueryBuilder.InCondition(Contact.ReversePhone__c).inCollection(reversedPhoneNumbers))
				.setConditionOrder('(1 OR 2 OR 3)')
				.endConditions();
		return new Map<Id, Contact>((List<Contact>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Execute SOQL query and return a Map with Contact objects matching the search parameters.
	 * 
	 * This method was intially developed for CSLU-107 and is used by class `UnifiedCustomerSearchController`.
	 * 
	 * @param params - The search parameters to build the query from.
	 * @param selectorOptions - The Selector framework options used when building the query.
	 * @return Map of Contact objects which matched the query criteria.
	 */
	public Map<Id, Contact> selectByCustomerSearchParams(CustomerSearchParameters params, Set<Object> selectorOptions) {
		String queryString = selectByCustomerSearchParamsQB(params, selectorOptions);
		return new Map<Id, Contact> ((List<Contact>) Database.query(queryString));
	}

	/**
	 * @description Build the query string used to find Contact records which match the search paramters. If parameter
	 * is provided, it will be added to the SOQL query using 'AND' operators. Some parameters match on more than one
	 * field, so use the 'OR' operator.
	 * 
	 * For example: `WHERE (FirstName LIKE 'Joan%' OR PreferredName LIKE 'Joan%') AND LastName LIKE 'Watson%'`
	 * 
	 * This method was intially developed for CSLU-107 and is used by class `UnifiedCustomerSearchController`.
	 * 
	 * @param params - The search parameters to build the query from.
	 * @param selectorOptions - The Selector framework options used when building the query.
	 * @return SOQL query string
	 */
	@TestVisible
	private String selectByCustomerSearchParamsQB(CustomerSearchParameters params, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager cm = qb.addConditions();

		// An array used to dynamically add conditions depending if fields are present in the criteria
		List<String> conditionsOrder = new List<String>();

		/**
		 * Add the First Name to the search query criteria
		 */
		String firstName = params.firstName?.trim();
		if(String.isNotBlank(firstName)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.FirstName).likeAnyRight(firstName));
			cm.add(new QueryBuilder.LikeCondition(Contact.Preferred_Name__c).likeAnyRight(firstName));
			// (FirstName OR Preferred_Name__c)
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ')');
		}

		/**
		 * Add the Last Name to the search query criteria
		 */
		String lastName = params.lastName?.trim();
		if(String.isNotBlank(lastName)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.LastName).likeAnyRight(lastName));
			// (LastName)
			conditionsOrder.add('(' + (n + 1) + ')');
		}

		/**
		 * Add the Email Address to the search query criteria
		 */
		String emailAddress = params.emailAddress?.trim();
		if(String.isNotBlank(emailAddress)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.Email).eq(emailAddress));
			cm.add(new QueryBuilder.CompareCondition(Contact.VerifiedEmail__c).eq(emailAddress));

			// (Email OR VerifiedEmail__c)
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ')');
		}

		/**
		 * Add the Phone Number to the search query criteria
		 * TODO: Investigate better ways to query phone number across multiple fields (e.g. ContactPointPhone object)
		 */
		String phoneNumber = params.phoneNumber?.trim();
		if(String.isNotBlank(phoneNumber)) {
			// Clean and reverse the phone number for querying the reverse phone fields
			String reversePhone = Util.reversePhoneString(phoneNumber);

			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.ReverseMobilePhone__c).eq(reversePhone));
			cm.add(new QueryBuilder.CompareCondition(Contact.ReverseVerifiedMobile__c).eq(reversePhone));
			cm.add(new QueryBuilder.CompareCondition(Contact.ReversePhone__c).eq(reversePhone));

			// (ReverseMobilePhone__c OR ReverseVerifiedMobile__c OR ReversePhone__c)
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ' OR ' + (n + 3) + ')');
		}

		/**
		* If `customerType` is specified, apply the filter accordingly.
		* If not specified, the default will return all customer types (i.e. no filter applied).
		*/
		if(params.customerType == CustomerSearchCustomerType.CONSUMER) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.IsPersonAccount).eq(true));
			conditionsOrder.add(String.valueOf(n + 1));
		} else if(params.customerType == CustomerSearchCustomerType.ORGANISATION) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.IsPersonAccount).eq(false));
			conditionsOrder.add(String.valueOf(n + 1));
		}

		/**
		 *  Add the Address to the search query criteria.
		 */
		String addressStreet1 = params.addressStreet1?.trim();
		String addressStreet2 = params.addressStreet2?.trim();
		String addressCity = params.addressCity?.trim();
		String addressState = params.addressState?.trim();
		String addressPostalCode = params.addressPostalCode?.trim();
		if(String.isNotBlank(addressStreet1) && String.isNotBlank(addressStreet2)) {
			// Where both addressStreet1 and addressStreet2 are set, try a few different possible data combinations
			Integer n = cm.conditions.size();
			String combinedAddressLines = addressStreet1 + ' ' + addressStreet2;
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet).likeAnyRight(addressStreet1));
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet2__c).likeAnyRight(addressStreet2));
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet).likeAnyRight(combinedAddressLines));
			conditionsOrder.add('((' + (n + 1) + ' AND ' + (n + 2) + ') OR ' + (n + 3) + ')');
		} else if(String.isNotBlank(addressStreet1)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet).likeAnyRight(addressStreet1));
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet2__c).likeAnyRight(addressStreet1));
			// MailingStreet OR MailingStreet2__c
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ')');
		} else if(String.isNotBlank(addressStreet2)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet).likeAnyRight(addressStreet2));
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingStreet2__c).likeAnyRight(addressStreet2));
			// MailingStreet OR MailingStreet2__c
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ')');
		}
		if(String.isNotBlank(addressCity)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingCity).likeAnyRight(addressCity));
			conditionsOrder.add(String.valueOf(n + 1));
		}
		if(String.isNotBlank(addressState)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.LikeCondition(Contact.MailingState).likeAnyRight(addressState));
			conditionsOrder.add(String.valueOf(n + 1));
		}
		if(String.isNotBlank(addressPostalCode)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.MailingPostalCode).eq(addressPostalCode));
			conditionsOrder.add(String.valueOf(n + 1));
		}

		/**
		 *  Add the Organization (Account) details to the search query criteria.
		 */
		if(String.isNotBlank(params.accountId)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition(Contact.AccountId).eq(params.accountId));
			conditionsOrder.add(String.valueOf(n + 1));
		}
		String abnAcn = params.abnAcn?.trim();
		if(String.isNotBlank(abnAcn)) {
			Integer n = cm.conditions.size();
			cm.add(new QueryBuilder.CompareCondition('Account.' + String.valueOf(Account.ABN__c)).eq(abnAcn));
			cm.add(new QueryBuilder.CompareCondition('Account.' + String.valueOf(Account.ACN__c)).eq(abnAcn));
			// ABN__c OR ACN__c
			conditionsOrder.add('(' + (n + 1) + ' OR ' + (n + 2) + ')');
		}

		// Join dynamic conditions with 'AND' operator
		cm.setConditionOrder(String.join(conditionsOrder, ' AND '));
		cm.endConditions();
					
		// Configure results order
		qb.setOrder(new QueryBuilder.Order(Contact.UnifiedDataScore__c).setSortingOrderDesc().setNullsOrderLast());
		qb.addOrder(new QueryBuilder.Order(Contact.FirstName).setSortingOrderAsc().setNullsOrderLast());
		qb.addOrder(new QueryBuilder.Order(Contact.LastName).setSortingOrderAsc().setNullsOrderLast());

		return qb.toSoqlString();
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

		if(selectorOptions.contains(Options.WITH_RELATED_CASES)) {
			builder.addSubQuery(CasesSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Cases');
		}

		return builder;
	}

  /**
   * @description A wrapper class used to pass parameters for the search query.
   * This object is modeled based on the `CustomerSearchForm.SearchRequest` object but is re-defined here to avoid
   * creating a dependency with the `CustomerSearchForm` class.
   */
	public class CustomerSearchParameters {
		public String firstName;
		public String lastName;
		public String emailAddress;
		public String phoneNumber;
		public CustomerSearchCustomerType customerType;
		public String addressStreet1;
		public String addressStreet2;
		public String addressCity;
		public String addressState;
		public String addressPostalCode;
		public Id accountId;
		public String abnAcn;
	}

	public enum CustomerSearchCustomerType {
		ORGANISATION, CONSUMER
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