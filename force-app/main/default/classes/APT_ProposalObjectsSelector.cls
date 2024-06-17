/*@author Sri Harsha
*@date 2022-04-22
*@group Selector
*@tag Selector
*@tag Apttus_Proposal__Proposal__c
*@domain Apttus
*@description A very simple selector class for Apttus_Proposal__Proposal__c to get createddate
*@changelog:
*2022-05-30 - Seth Heang - updated getSObjectFieldList
*2022-05-30 - Nasir JAwed Added method selectByConfigIds
*2022-08-15 - Seth Heang - Added recordLimit, fieldOverrides to newInstance() method
*2022-11-22 - Harry Wang - added selector method for sales intermediary
*2022-12-06 - Nasir Jawed - Added field APT_Use_Offline_Rates__c
*2023-02-16 - Nasir JAwed Added method selectByOpportunityId
*2023-04-08 - Yatika bansal Added few fields ,selector option, updated newQueryBuilder method
*2023-04-11 - Nasir Jawed -Added method newInstance for fieldOverride
*2023-07-06 - Yatika bansal Added new field APT_Contract_Number__c
* 2023-07-20 - Yatika bansal Added new field APT_Postbillpay_Included__c
* 2023-07-25 - Nasir Jawed Added new option WITH_OPPORTUNITY
*/
public virtual inherited sharing class APT_ProposalObjectsSelector extends ApplicationSelector {
	public enum Options {
		WITH_ORGANISATION,WITH_ACCOUNT,WITH_OPPORTUNITY
	}

	public static APT_ProposalObjectsSelector newInstance() {
		return (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class);
	}
	public static APT_ProposalObjectsSelector newInstance(Integer recordLimit) {
		return (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setLimit(recordLimit);
	}
	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_ProposalObjectsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		APT_ProposalObjectsSelector selector = (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	 /**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static APT_ProposalObjectsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		APT_ProposalObjectsSelector selector = (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	*@param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	*This approach removes data consistency and prevents possible caching of results
	*/
	public static APT_ProposalObjectsSelector newInstance(Integer recordLimit, Map<Schema.SObjectType,Set<Schema.SObjectField>> fieldOverrides) {
		APT_ProposalObjectsSelector selector = (APT_ProposalObjectsSelector)Application.Selectors.newInstance(APT_ProposalObjectsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus_Proposal__Proposal__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus_Proposal__Proposal__c.Id,Apttus_Proposal__Proposal__c.createddate,Apttus_Proposal__Proposal__c.Apttus_Proposal__Proposal_Expiration_Date__c,Apttus_Proposal__Proposal__c.APT_Method_of_Payment__c,
			Apttus_Proposal__Proposal__c.APT_Use_Offline_Rates__c, Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary__c,Apttus_Proposal__Proposal__c.Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c,Apttus_Proposal__Proposal__c.Apttus_QPApprov__Approval_Status__c,
			Apttus_Proposal__Proposal__c.RecordTypeId,Apttus_Proposal__Proposal__c.Apttus_QPConfig__PriceListId__c,Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c, Apttus_Proposal__Proposal__c.APT_Date_of_Generation_Rate_Card__c,
			Apttus_Proposal__Proposal__c.Apttus_QPConfig__ConfigurationFinalizedDate__c,Apttus_Proposal__Proposal__c.APT_Opportunity_Key_contact__c , Apttus_Proposal__Proposal__c.OwnerId,Apttus_Proposal__Proposal__c.APT_Contract_Number__c,Apttus_Proposal__Proposal__c.Is_Startrack_Proposal__c , Apttus_Proposal__Proposal__c.APT_Postbillpay_Included__c,Apttus_Proposal__Proposal__c.APT_Document_Generation_in_Progress__c, Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c};
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual Map<Id, Apttus_Proposal__Proposal__c> selectByConfigId(Set<Id> configIds) {
		return selectByConfigId(configIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual Map<Id, Apttus_Proposal__Proposal__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.ID + ' = :configIds'))
			.endConditions();
		return new Map<Id, Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
	}
	/**
	 * @description Run a simple query to get records based on Proposal id
	 */
	public virtual List<Apttus_Proposal__Proposal__c> selectByConfigIds(Set<Id> ProposalIds) {
		return selectByConfigIds(ProposalIds, new Set<Object>());
	}

	public virtual List<Apttus_Proposal__Proposal__c> selectByConfigIds(Set<Id> ProposalIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.ID + ' = :ProposalIds'))
			.endConditions();
		return new List<Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
	}

	/**
	* Returns a query locator to retrieve Proposal (Apttus_Proposal__Proposal__c) records based on the account ids passed in. If set of account ids
	* is null or empty, returns all Proposal records having a parent account.
	* Query results are ordered by parent account Id desc
	* @param accountIds set of parent account ids. returns all child Proposal records associated with a parent account if null
	* or empty set is supplied.
	* @param selectorOptions set of additional selector options to augment the result set
	* @return query locator of Apttus_Proposal__Proposal__c records
	*/
	public Database.QueryLocator selectByAccountOrderByAccountIdQueryLocator(Set<Id> accountIds, Set<Object> selectorOptions) {

		Set<Object> options = (selectorOptions != null ? selectorOptions : new Set<Object>());
		options.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);

		QueryBuilder qb = newQueryBuilder(options);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		if (accountIds != null && !accountIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c + ' in :accountIds'));
		} else {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c + ' != null'));
		}

		qb = conditions.endConditions().addOrderDesc(Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c);
		return Database.getQueryLocator(qb.toSoqlString());
	}

	 /**
	 * @description Run a simple query to get records based on opportunity id
	*/
	public Map<Id, Apttus_Proposal__Proposal__c> selectByOpportunityIds(Set<Id> oppIds) {
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c + ' IN :oppIds')).endConditions();
		return new Map<Id, Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
	}

	public List<Apttus_Proposal__Proposal__c> selectByOpportunityId(Set<Id> oppIds) {
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal__c.Apttus_Proposal__Opportunity__c + ' IN :oppIds')).endConditions();
		return new List<Apttus_Proposal__Proposal__c>((List<Apttus_Proposal__Proposal__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		if (selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Apttus_Proposal__Account__r');
		}
		if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'Apttus_Proposal__Account__r');
		}
		if(selectorOptions.contains(Options.WITH_OPPORTUNITY)) {
			builder.addRelatedFields(OpportunitySelector.newInstance().newQueryBuilder(), 'Apttus_Proposal__Opportunity__r');
		}
		return builder;
	}

}