/* @author Seth Heang
 * @date 2021-04-05
 * @group Tests
 * @tag Selector
 * @tag Sub Account Requests, APT_Sub_Account__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-04-05 - seth.heang@auspost.com.au - Created
 * 2022-05-30 - Seth Heang - updated getSObjectFieldList, Added selectByProposalId and Added WITH_ORGANISATION related list
 * 2023-03-21 - CI-703 Sarath Burra Added new field Is_Parcel_Send_Login_Required__c
 * 2023-10-27 - Harry Wang Added new method selectByChargeAccountId and selectByBillingAccountId and option FILTER_UNPROVISIONED_FOLLOWER_ONLY
 * 2023-10-30 - Ranjeewa Silva - Added selector options to select related billing account fields
 */
public inherited sharing class SubAccountRequestsSelector extends ApplicationSelector{
	public enum Options {
		WITH_SUB_ACCOUNT_CONTACT, WITH_ORGANISATION, WITH_BILLING_ACCOUNT, WITH_ST_PARENT_BILLING_ACCOUNT, FILTER_UNPROVISIONED_FOLLOWER_ONLY, FILTER_DRAFT_ERROR, FILTER_DRAFT_ERROR_PENDING
	}
	public static SubAccountRequestsSelector newInstance() {
		return (SubAccountRequestsSelector)Application.Selectors.newInstance(SubAccountRequestsSelector.class);
	}
	public static SubAccountRequestsSelector newInstance(Integer recordLimit) {
		return (SubAccountRequestsSelector)Application.Selectors.newInstance(SubAccountRequestsSelector.class).setLimit(recordLimit);
	}
	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static SubAccountRequestsSelector  newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SubAccountRequestsSelector  selector = (SubAccountRequestsSelector)Application.Selectors.newInstance(SubAccountRequestsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return APT_Sub_Account__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			APT_Sub_Account__c.Id, APT_Sub_Account__c.Name, APT_Sub_Account__c.APT_Account_Name_2__c,
			APT_Sub_Account__c.APT_Charge_Account__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Name__c, APT_Sub_Account__c.CreatedDate,
			APT_Sub_Account__c.APT_Sub_Account_Contact_Telephone__c, APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c,
			APT_Sub_Account__c.APT_Source_of_Sub_Account_Request__c, APT_Sub_Account__c.APT_Billing_Account_Number__c,
			APT_Sub_Account__c.ParentBillingAccount__c, APT_Sub_Account__c.ParentAccountRequest__c, APT_Sub_Account__c.AccountType__c,
			APT_Sub_Account__c.Sub_Account_Name__c, APT_Sub_Account__c.Sub_Account_Number__c, APT_Sub_Account__c.Transaction_Id__c,
			APT_Sub_Account__c.APT_Sub_Account_Request_Status__c, APT_Sub_Account__c.Sub_Account_Request_Status_Description__c,
			APT_Sub_Account__c.Lodgement_Point_to_Work_Centre_Code__c,APT_Sub_Account__c.APT_eLMS_Enabled__c, APT_Sub_Account__c.APT_eParcel_Enabled__c,
			APT_Sub_Account__c.APT_Postal_Address_Street_Name__c, APT_Sub_Account__c.APT_Postal_Address_Suburb__c,
			APT_Sub_Account__c.APT_Postal_Address_State__c, APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c,
			APT_Sub_Account__c.APT_Street_Address_Street_Name__c, APT_Sub_Account__c.APT_Street_Address_Suburb__c,
			APT_Sub_Account__c.APT_Street_Address_State__c, APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c, APT_Sub_Account__c.APT_Street_Address_Country_Code__c,
			APT_Sub_Account__c.APT_Billing_Account__c, APT_Sub_Account__c.APT_Postal_Address_Country_Code__c, APT_Sub_Account__c.OwnerId,
			APT_Sub_Account__c.Product__c, APT_Sub_Account__c.SubAccountContact__c,APT_Sub_Account__c.Is_Parcel_Send_Login_Required__c
		};
	}

	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual Map<Id, APT_Sub_Account__c> selectById(Set<Id> ids) {
		return selectByIds(ids, new Set<Object>());
	}


	/**
	* @description Run a simple query to get records based on Id's
	*/
	public virtual Map<Id, APT_Sub_Account__c> selectByIds(Set<Id> ids , Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.ID + ' in :ids')).endConditions();
		return new Map<Id, APT_Sub_Account__c>((List<APT_Sub_Account__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on charge Account request Id and status
	 */
	public virtual Map<Id, APT_Sub_Account__c> selectByChargeAcountRequestIdAndStatus(Set<Id> ids, Set<String> status) {
		return selectByChargeAcountRequestIdAndStatus(ids, status, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on charge Account request Id and status
	 */
	public virtual Map<Id, APT_Sub_Account__c> selectByChargeAcountRequestIdAndStatus(Set<Id> ids, Set<String> status, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Charge_Account__c + ' in :ids'))
		.add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c + ' = :status'))
		.endConditions();
		return new Map<Id, APT_Sub_Account__c>((List<APT_Sub_Account__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on proposal Id
	 * @param Set<id> proposalIds
	 * @return List<APT_Sub_Account__c>
	*/
	public virtual List<APT_Sub_Account__c> selectByProposalId(Set<Id> proposalIds) {
		return selectByProposalId(proposalIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on proposal Id
	 * @param Set<id> proposalIds
	 * @param Set<Object> selectorOptions
	 * @return Map<Id, APT_Sub_Account__c>
	*/
	public virtual List<APT_Sub_Account__c> selectByProposalId(Set<Id> proposalIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Quote_Proposal__c + ' in :proposalIds')).endConditions();
		return (List<APT_Sub_Account__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Select sub accounts by charge account Id with selector options
	 * @param chargeAccountIds charge account Id set
	 * @param selectorOptions selector options
	 * @return matching list of sub account
	 */
	public virtual List<APT_Sub_Account__c> selectByChargeAccountId(Set<Id> chargeAccountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Charge_Account__c + ' in :chargeAccountIds')).endConditions();
		return (List<APT_Sub_Account__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Select sub accounts by billing account Id with selector options
	 * @param billingAccountIds billing account Id set
	 * @param selectorOptions selector options
	 * @return matching list of sub account
	 */
	public virtual List<APT_Sub_Account__c> selectByBillingAccountId(Set<Id> billingAccountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Sub_Account__c.APT_Billing_Account__c + ' in :billingAccountIds')).endConditions();
		return (List<APT_Sub_Account__c>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_SUB_ACCOUNT_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'SubAccountContact__r');
		}
		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Organisation__r');
		}
		if(selectorOptions.contains(Options.WITH_BILLING_ACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'APT_Billing_Account__r');
		}
		if(selectorOptions.contains(Options.WITH_ST_PARENT_BILLING_ACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'ParentBillingAccount__r');
		}
		if(selectorOptions.contains(Options.FILTER_UNPROVISIONED_FOLLOWER_ONLY)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(APT_Sub_Account__c.AccountType__c).eq('Follower')).
					add(new QueryBuilder.CompareCondition(APT_Sub_Account__c.Sub_Account_Number__c).eq('')).
					add(new QueryBuilder.InCondition(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c).inCollection(new List<String>{'Draft', 'Error'})).
					endConditions();
		}
		if(selectorOptions.contains(Options.FILTER_DRAFT_ERROR)) {
			builder.addConditions().add(new QueryBuilder.InCondition(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c).inCollection(new List<String>{'Draft', 'Error'})).
					endConditions();
		}
		if(selectorOptions.contains(Options.FILTER_DRAFT_ERROR_PENDING)) {
			builder.addConditions().add(new QueryBuilder.InCondition(APT_Sub_Account__c.APT_Sub_Account_Request_Status__c).inCollection(new List<String>{'Draft', 'Error', 'Pending Charge Account'})).
					endConditions();
		}
		return builder;
	}
}