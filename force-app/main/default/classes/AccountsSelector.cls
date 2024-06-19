/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description Selector class for Account
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
 * 2020-05-14 - Disha Kariya - Updated to add sub query to get active memberships
 * 2020-09-28 - Lija Jawahar - Updated - select by Account number
 * 2021-01-12 - Arjun Singh - Updated to add code related to billing account creation in SAP feature
 * 2020-12-18 - Jansi - Added - WITH_TYPE_CUST_ACTIVE_BILLING_ACCOUNTS
 * 2021-03-22 - Jansi - Added 'WITH_RECENT_CREATED_CREDIT_ASSESMENT'
 * 2021-08-06 - Seth Heang - Added selectByLikedNameAndPersonAccountOrderByName
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2022-03-16 - Naveen Rajanna - REQ2656153 - Included missing fields to avoid SObjectException
 * 2022-06-12 - Sreenish Krishnan - Added new selector query based on APCN and Id
 * 2022-09-05 - Kamil / Nathan Franklin - Add new method and uplifted to 55
 * 2022-09-28 - Noel Lim - added new SObject Field, removed 3 debug statements
 * 2023-02-07 - Deepak Kemidi - remove minimum spend field reference from account object
 * 2023-03-17 - Naveen Rajanna - SMWD-397 - Added enums WITH_CREATEDBY_USER, WITH_LASTMODIFIEDBY_USER, WITH_FACILITY
 * 2023-05-01 - Naveen Rajanna - REQ2916371 - Changes to search function and Added enums WITH_PARENT_2LEVELS, WITH_PARENT_3LEVELS, WITH_PARENT_4LEVELS, WITH_PARENT_5LEVELS
 * 2023-06-21 - Naveen Rajanna - REQ2916371 - Modified selectByAPCNAndIdAndPersonAccount to have it's own logic instead of using search
 * 2023-04-08 - Yatika bansal - added new SObject Field
 * 2023-06-17 - Harry Wang - added new method selectByIdWithContactsAndOpportunities
 * 2024-06-18 - Sarath Burra - Added IndirectCustomer Field
 */
public virtual inherited sharing class AccountsSelector extends ApplicationSelector {
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_ACTIVE_MEMBERSHIPS, WITH_ORGANISATION_ROLES, WITH_ORGANISATION_ROLES_PROSPECT_KNOWN, WITH_HOLDINGROLE,
		WITH_TYPE_CUST_ACTIVE_BILLING_ACCOUNTS, WITH_RECENT_CREATED_CREDIT_ASSESMENT, WITH_POSTOFFICEASSIGNED, WITH_NETWORK, WITH_PARENT,
		WITH_GRANDPARENT, WITH_CREATEDBY_USER, WITH_LASTMODIFIEDBY_USER, WITH_FACILITY, WITH_PARENT_2LEVELS, WITH_PARENT_3LEVELS,
		WITH_PARENT_4LEVELS, WITH_PARENT_5LEVELS
	}

	public static AccountsSelector newInstance() {
		return (AccountsSelector) Application.Selectors.newInstance(AccountsSelector.class);
	}
	public static AccountsSelector newInstance(Integer recordLimit) {
		return (AccountsSelector) Application.Selectors.newInstance(AccountsSelector.class).setLimit(recordLimit);
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AccountsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		AccountsSelector selector = (AccountsSelector) Application.Selectors.newInstance(AccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static AccountsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AccountsSelector selector = (AccountsSelector) Application.Selectors.newInstance(AccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Account.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				//CI-339 Remove references to minimum spend field from account object
				Account.Id, Account.Name, Account.Type, Account.OwnerId, Account.APLAC_Member__c, Account.LEGACY_ID__c, Account.Customer_Account_Group__c, Account.Organisation_Trading_Name__c,
				Account.BillingStreet, Account.BillingCity, Account.BillingState,
				Account.BillingPostalCode, Account.Phone, Account.Email__c, Account.ABN__c,
				Account.ACN__c, Account.Primary_Business_Solutions_Contact__c, Account.BillingCountry, Account.Role_Type_Roll_Up__c,
				Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry,
				Account.Holding_Role_Reference__c, Account.Is_Strategic_Account_StarTrack__c, Account.AccountNumber, Account.IsPersonAccount, Account.Business_Solutions_Customer__c, Account.Exclude_Notification_Automation__c, Account.Exclude_Subscription_Automation__c, Account.Sales_Director__c,
				Account.APCN__c, Account.APCN__pc, Account.Integration_Service_Mod_Date__c, Account.PersonContactId, Account.ServiceSLA__c, Account.Sales_Segment__c,Account.IndirectCustomer__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Account> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Account> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Account.Id + ' in :ids')).endConditions();
		return new Map<Id, Account>((List<Account>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Legacy Id's
	 */
	public Map<Id, Account> selectByAccountNumber(Set<String> accountNumbers) {
		return selectByAccountNumber(accountNumbers, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Legacy Id's
	 */
	public Map<Id, Account> selectByAccountNumber(Set<String> accountNumbers, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Account.LEGACY_ID__c + ' in :accountNumbers')).endConditions();
		return new Map<Id, Account>((List<Account>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on
	 */
	public Map<Id, Account> selectByLikedNameAndPersonAccountOrderByName(string name, boolean isPersonAccount) {
		return selectByLikedNameAndPersonAccountOrderByName(name, isPersonAccount, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on
	 */
	public Map<Id, Account> selectByLikedNameAndPersonAccountOrderByName(string name, boolean isPersonAccount, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
				.add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth(name))
				.add(new QueryBuilder.CompareCondition(Account.isPersonAccount).eq(isPersonAccount))
				.endConditions();
		qb.addOrderAsc(Account.Name);
		return new Map<Id, Account>((List<Account>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a SOQL based on the search parameters passed
	 */
	public List<Account> selectByAPCNAndIdAndPersonAccount(
			Map<String, Object> searchParams,
			String searchConditions,
			Schema.SobjectField orderByField
	) {
		QueryBuilder builder = newQueryBuilder();
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<String> apcns = (Set<String>) (searchParams.get('apcn') == null
			? new Set<String>()
			: (searchParams.get('apcn') instanceof Set<String> ? searchParams.get('apcn') : new Set<Id>{
				(Id) searchParams.get('apcn')
			}));
		Set<Id> accIds = (Set<Id>) (searchParams.get('accId') == null
			? new Set<Id>()
			: (searchParams.get('accId') instanceof Set<Id> ? searchParams.get('accId') : new Set<Id>{
				(Id) searchParams.get('accId')
			}));
		Boolean isPersonAccount = (Boolean) (searchParams.get('isPersonAccount') == null
			? null
			: (searchParams.get('isPersonAccount') instanceof Boolean
				? searchParams.get('isPersonAccount')
				: (Boolean) (searchParams.get('isPersonAccount'))));

		conditions.add(new QueryBuilder.SimpleCondition(Account.apcn__pc + ' IN :apcns'));
		conditions.add(new QueryBuilder.SimpleCondition(Account.Id + ' IN :accIds'));

		if (isPersonAccount != null) {
			conditions.add(new QueryBuilder.CompareCondition(Account.isPersonAccount).eq(isPersonAccount));
		}

		// ensure that the conditions order is the same as specified in Query Builder framework
		//an example: (1 OR 2) AND 3
		if (!String.isEmpty(searchConditions)) {
			conditions.setConditionOrder(searchConditions);
		}
		//note that this only caters to desc at the moment, if you need to use asc, then this method will need to be enhanced
		if (orderByField != null) {
			builder.addOrderDesc(orderByField);
		}

		String soql = conditions.endConditions().toSoqlString();
		return (List<Account>) Database.query(soql);
	}

	public List<Account> search(
		Map<String, Object> searchParams,
		Set<Object> selectorOptions,
		String searchConditions,
		Schema.SobjectField orderByField
	) {
		return search(searchParams, selectorOptions, searchConditions, orderByField, 'DESC');
	}

	/**
	* Run a SOQL based on the search parameters passed in
	* @param searchParams A map containing searchable values
							parentIds refers to Account.ParentId
							parentIdsLevel2 refers to Parent.ParentId (1st level Parent's parentIds)
							parentIdsLevel3 refers to Parent.Parent.ParentId (2nd level Parent's parentIds) and so on
	* @param selectorOptions Selector Options
	* @param searchConditions String containing condition order ex: (1 AND 2) OR 3
	* @param orderByField Account Field
	* @param sortDirection ASC or DESC
	* @return  `List<Account>`
	*/
	public List<Account> search(
		Map<String, Object> searchParams,
		Set<Object> selectorOptions,
		String searchConditions,
		Schema.SobjectField orderByField,
		String sortDirection
	) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Set<String> apcns = (Set<String>) (searchParams.get('apcn') == null ? new Set<String>() : (searchParams.get('apcn') instanceof Set<String> ? searchParams.get('apcn') : new Set<Id>{(Id) searchParams.get('apcn')}));
		Set<Id> accIds = (Set<Id>) (searchParams.get('accId') == null ? new Set<Id>() : (searchParams.get('accId') instanceof Set<Id> ? searchParams.get('accId') : new Set<Id>{(Id) searchParams.get('accId')}));
		Boolean isPersonAccount = (Boolean) (searchParams.get('isPersonAccount') == null ? null : (searchParams.get('isPersonAccount') instanceof Boolean ? searchParams.get('isPersonAccount') : (Boolean) (searchParams.get('isPersonAccount'))));
		Set<Id> parentIds = (Set<Id>)(searchParams.get('parentIds') == null ? new Set<Id>() : (searchParams.get('parentIds') instanceof Set<Id> ? searchParams.get('parentIds') : new Set<Id>{(Id)searchParams.get('parentIds')}));
		Set<Id> parentIdsLevel2 = (Set<Id>)(searchParams.get('parentIdsLevel2') == null ? new Set<Id>() : (searchParams.get('parentIdsLevel2') instanceof Set<Id> ? searchParams.get('parentIdsLevel2') : new Set<Id>{(Id)searchParams.get('parentIdsLevel2')}));
		Set<Id> parentIdsLevel3 = (Set<Id>)(searchParams.get('parentIdsLevel3') == null ? new Set<Id>() : (searchParams.get('parentIdsLevel3') instanceof Set<Id> ? searchParams.get('parentIdsLevel3') : new Set<Id>{(Id)searchParams.get('parentIdsLevel3')}));
		Set<Id> parentIdsLevel4 = (Set<Id>)(searchParams.get('parentIdsLevel4') == null ? new Set<Id>() : (searchParams.get('parentIdsLevel4') instanceof Set<Id> ? searchParams.get('parentIdsLevel4') : new Set<Id>{(Id)searchParams.get('parentIdsLevel4')}));
		Set<Id> parentIdsLevel5 = (Set<Id>)(searchParams.get('parentIdsLevel5') == null ? new Set<Id>() : (searchParams.get('parentIdsLevel5') instanceof Set<Id> ? searchParams.get('parentIdsLevel5') : new Set<Id>{(Id)searchParams.get('parentIdsLevel5')}));
		Set<Id> parentIdsLevel6 = (Set<Id>)(searchParams.get('parentIdsLevel6') == null ? new Set<Id>() : (searchParams.get('parentIdsLevel6') instanceof Set<Id> ? searchParams.get('parentIdsLevel6') : new Set<Id>{(Id)searchParams.get('parentIdsLevel6')}));

		if (!apcns.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Account.apcn__pc + ' IN :apcns'));
		}
		if (!accIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Account.Id + ' IN :accIds'));
		}
		if (isPersonAccount != null) {
			conditions.add(new QueryBuilder.CompareCondition(Account.isPersonAccount).eq(isPersonAccount));
		}
		if(!parentIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Account.ParentId + ' IN :parentIds'));
		}
		if(!parentIdsLevel2.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Parent.ParentId IN :parentIdsLevel2'));
		}
		if(!parentIdsLevel3.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Parent.Parent.ParentId IN :parentIdsLevel3'));
		}
		if(!parentIdsLevel4.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Parent.Parent.Parent.ParentId IN :parentIdsLevel4'));
		}
		if(!parentIdsLevel5.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Parent.Parent.Parent.Parent.ParentId IN :parentIdsLevel5'));
		}
		if(!parentIdsLevel6.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Parent.Parent.Parent.Parent.Parent.ParentId IN :parentIdsLevel6'));
		}

		// ensure that the conditions order is the same as specified in Query Builder framework
		//an example: (1 OR 2) AND 3
		if (!String.isEmpty(searchConditions)) {
			conditions.setConditionOrder(searchConditions);
		}

		// these will override the sorting parameters when they are requested from the getOrderBy method
		String sortingFieldOverride = orderByField != null ? String.valueOf(orderByField) : this.getOrderBy()[0].getSortingField();
		String sortingOrderOverride = (sortDirection != null && !String.isEmpty(sortDirection)) ? String.valueOf(sortDirection) : this.getOrderBy()[0].getSortingOrder();
		QueryBuilder.Order qbOrderBy = new QueryBuilder.Order(sortingFieldOverride, sortingOrderOverride);
		builder.setOrder(qbOrderBy); // override the default sorting

		String soql = conditions.endConditions().toSoqlString();
		return (List<Account>) Database.query(soql);
	}

	/**
	 * @param wcisCodes set of WCIS codes to query related LPO and CPO account records
	 * @param selectorOptions selector options
	 *
	 * @return Map of LPO and CPO accounts by Id
	 */
	public Map<Id, Account> selectLPOAndCPOAccountsByAccIds(Set<Id> accIds, Set<Object>selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions
				.add(new QueryBuilder.CompareCondition(Account.RecordTypeId).eq(SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId()))
				.add(new QueryBuilder.SimpleCondition(Account.Id + ' IN :accIds'))
				.add(new QueryBuilder.CompareCondition(Account.Licence_Type__c).eq('RP'))
				.add(new QueryBuilder.CompareCondition(Account.Licence_Type__c).eq('LPO'))
				.add(new QueryBuilder.CompareCondition('Parent.RecordType.DeveloperName').eq('Licence'))
				.add(new QueryBuilder.CompareCondition('Parent.Parent.RecordType.DeveloperName').eq('Business_Account'))
				.add(new QueryBuilder.SimpleCondition('Parent.ParentId IN :accIds'));
		String lConditionString = '1 AND ((2 AND 3) OR (4 AND 5 AND 6 AND 7))';
		conditions.setConditionOrder(lConditionString).endConditions();
		return new Map<Id, Account>((List<Account>) Database.query(qb.toSoqlString()));
	}
	/**
	 * @param postOfficeAssignedId set of Ids of Network__c records linked to the account via Post_Office_Assigned__c field
	 * @param selectorOptions selector options
	 *
	 * @return map of accounts by Ids
	 */
	public Map<Id, Account> selectByPostOfficeAssigned(Set<String> postOfficeAssignedOrgIds, Set<Object>selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
				.add(new QueryBuilder.SimpleCondition('Account.Post_Office_Assigned__r.Org_ID__c IN :postOfficeAssignedOrgIds'))
				.add(new QueryBuilder.SimpleCondition('Account.Post_Office_Assigned__r.Org_ID__c != NULL'))
				.endConditions();
		return new Map<Id, Account>((List<Account>) Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select Accounts with related contacts and opportunities given IDs of accounts, contacts and opportunities.
	 * @param contactIds IDs of related contacts
	 * @param oppIds IDs of related opportunities
	 * @param accIds IDs of accounts
	 * @param selectorOptions selector options
	 * @return list of account records by IDs
	 */
	public List<Account> selectByIdWithContactsAndOpportunities(Set<Id> contactIds, Set<Id> oppIds, Set<Id> accIds,  Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Account.Id + ' IN :accIds')).endConditions();
		qb.addSubQuery(ContactsSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Contact.Id + ' IN :contactIds')).endConditions(), 'Contacts');
		qb.addSubQuery(OpportunitySelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Opportunity.Id + ' IN :oppIds')).endConditions(), 'Opportunities');
		return Database.query(qb.toSoqlString());
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if (selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		if (selectorOptions.contains(Options.WITH_HOLDINGROLE)) {
			builder.addRelatedFields(HoldingReferenceRoleSelector.newInstance().newQueryBuilder(), 'Holding_Role_Reference__r');
		}

		if (selectorOptions.contains(Options.WITH_ACTIVE_MEMBERSHIPS)) {
			builder.addSubQuery(
					MembershipsSelector.newInstance().newQueryBuilder(new Set<Object>{
							MembershipsSelector.Options.FILTER_ACTIVE_STATUS
					}),
					'Memberships__r'
			);
		}

		if (selectorOptions.contains(Options.WITH_TYPE_CUST_ACTIVE_BILLING_ACCOUNTS)) {
			builder.addSubQuery(
					BillingAccountsSelector.newInstance()
							.newQueryBuilder(
									new Set<Object>{
											BillingAccountsSelector.Options.FILTER_CUST_TYPE, BillingAccountsSelector.Options.FILTER_ACTIVE
									}
							),
					'Billing_Accounts__r'
			);
		}

		if (selectorOptions.contains(Options.WITH_ORGANISATION_ROLES)) {
			builder.addSubQuery(OrganisationRoleSelector.newInstance().newQueryBuilder(), 'Organisation_Roles__r');
		}

		if (selectorOptions.contains(Options.WITH_ORGANISATION_ROLES_PROSPECT_KNOWN)) {
			builder.addSubQuery(
					OrganisationRoleSelector.newInstance()
							.newQueryBuilder(new Set<Object>{
									OrganisationRoleSelector.Options.FILTER_PROSPECT_KNOWN
							}),
					'Organisation_Roles__r'
			);
		}
		if (selectorOptions.contains(Options.WITH_RECENT_CREATED_CREDIT_ASSESMENT)) {
			builder.addSubQuery(
					CreditsAssessmentSelector.newInstance('CreatedDate', 'Desc', 1).newQueryBuilder(new Set<Object>{
					}),
					'Credit_Assessments__r'
			);
		}
		if (selectorOptions.contains(Options.WITH_POSTOFFICEASSIGNED)) {
			builder.addRelatedFields(NetworksSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Post_Office_Assigned__r');
		}
		if (selectorOptions.contains(Options.WITH_NETWORK)) {
			builder.addRelatedFields(NetworksSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Network_Facility__r');
		}
		if (selectorOptions.contains(Options.WITH_PARENT)) {
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_PARENT_2LEVELS)) {
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_PARENT_2LEVELS);
			clonedOptions.add(Options.WITH_PARENT);
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(clonedOptions), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_PARENT_3LEVELS)) {
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_PARENT_3LEVELS);
			clonedOptions.add(Options.WITH_PARENT_2LEVELS);
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(clonedOptions), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_PARENT_4LEVELS)) {
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_PARENT_4LEVELS);
			clonedOptions.add(Options.WITH_PARENT_3LEVELS);
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(clonedOptions), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_PARENT_5LEVELS)) {
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_PARENT_5LEVELS);
			clonedOptions.add(Options.WITH_PARENT_4LEVELS);
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(clonedOptions), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_GRANDPARENT)) {
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(new Set<Object>{
				Options.WITH_PARENT
			}), 'Parent');
		}
		if (selectorOptions.contains(Options.WITH_CREATEDBY_USER)) {
			builder.addRelatedFields(UsersSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'CreatedBy');
		}
		if (selectorOptions.contains(Options.WITH_LASTMODIFIEDBY_USER)) {
			builder.addRelatedFields(UsersSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'LastModifiedBy');
		}
		if (selectorOptions.contains(Options.WITH_FACILITY)) {
			//PREVENT RECURSION
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_FACILITY);
			builder.addRelatedFields(AccountsSelector.newInstance(0, fieldOverrides).newQueryBuilder(clonedOptions), 'Facility__r');
		}
		return builder;
	}

	/**
	* @description Retrieve archived accounts based on closure date
	* @param nDaysAgo Specify a day in the past to retrieve PendingServiceRouting records dated on that day or older
	* @param selectorOptions Options
	* @return QueryLocator
	*/
	public Database.QueryLocator selectArchivedAccountsByClosureDateLessThanEqualNDaysAgo(Integer nDaysAgo, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
				.add(new QueryBuilder.CompareCondition(Account.ArchivedDateTime__pc).lte(System.now().addDays(-nDaysAgo)))
				.add(new QueryBuilder.NullCondition(Account.Winning_Master_Record__pc).isNull())
				.add(new QueryBuilder.CompareCondition(Account.IsInactiveCustomer__pc).eq(true))
				.add(new QueryBuilder.NullCondition(Account.PersonContactId).notNull())
				.add(new QueryBuilder.NullCondition(Account.Special_Treatment_Notes__pc).isNull())
				.endConditions();
		return Database.getQueryLocator(qb.toSoqlString());
	}
}