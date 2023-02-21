/**
 * @description
 * A very simple selector class that sits in the base domain
 *
 * @author Mahesh Parvathaneni
 * @date 2022-11-25
 * @group Selector
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @changelog
 * 2022-12-05	dattaraj.deshmukh@austpost.com.au	Added Options ENUM, added overridden 'newQueryBuilder()' method.
 * 													Added 'selectOpenCaseInvestigationsByCaseIds' method.
 * 2023-01-24 - Mahesh Parvathaneni - Added selectNetworkMileStoneViolatedOpenCaseInvestigations method
 * 2022-02-09	dattaraj.deshmukh@auspost.com.au	Added 'Stillunderinvestigation__c, Priority__c, CreatedDate & IsClosed__c' fields in getSObjectFieldList() method.
 * 2022-02-22	dattaraj.deshmukh@auspost.com.au	Added 'RecordTypeId' condition in query methods. 
 */

public virtual inherited sharing class CaseInvestigationsSelector extends ApplicationSelector {
	public enum Options {
		WITH_RECORDTYPES, WITH_CASE_DETAILS, WITH_ARTICLES, WITH_NETWORKS, WITH_OWNER_DETAILS 
	}

	public static CaseInvestigationsSelector newInstance() {
		return (CaseInvestigationsSelector)Application.Selectors.newInstance(CaseInvestigationsSelector.class);
	}

	public static CaseInvestigationsSelector newInstance(Integer recordLimit) {
		return (CaseInvestigationsSelector)Application.Selectors.newInstance(CaseInvestigationsSelector.class).setLimit(recordLimit);
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CaseInvestigationsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CaseInvestigationsSelector selector = (CaseInvestigationsSelector) Application.Selectors.newInstance(CaseInvestigationsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CaseInvestigationsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CaseInvestigationsSelector selector = (CaseInvestigationsSelector) Application.Selectors.newInstance(CaseInvestigationsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	

	public virtual override SObjectType getSObjectType() {
		return CaseInvestigation__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			CaseInvestigation__c.Id, CaseInvestigation__c.Article__c, CaseInvestigation__c.Case__c,
			CaseInvestigation__c.ReferenceID__c, CaseInvestigation__c.Network__c, CaseInvestigation__c.Status__c,  CaseInvestigation__c.Name,
			CaseInvestigation__c.LastContactCentreUpdate__c, CaseInvestigation__c.NetworkMilestoneCurrentTier__c, 
			CaseInvestigation__c.NetworkMilestoneLastViolationDatetime__c, CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c, 
			CaseInvestigation__c.MilestoneTimeStartDatetime__c, CaseInvestigation__c.RecordType__c, CaseInvestigation__c.NetworkMilestonesViolated__c,
			CaseInvestigation__c.NetworkTierEscalationEmail__c, CaseInvestigation__c.Stillunderinvestigation__c, CaseInvestigation__c.Priority__c, 
			CaseInvestigation__c.CreatedDate, CaseInvestigation__c.IsClosed__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, CaseInvestigation__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, CaseInvestigation__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Id + ' in :ids')).endConditions();
		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
	}

	

	/**
	 * Select case investigation records that are not closed and related to AP Network based on case Id
	 */
	public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseIds(Set<Id> caseIds, Set<Id> caseInvstigationRecordTypeIds) {
		return selectOpenCaseInvestigationsByCaseIds(caseIds, caseInvstigationRecordTypeIds, new Set<Object>());
	}

	/**
	 * Select case investigation records that are not closed and related to AP Network based on case Id
	 */
	public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseIds(Set<Id> caseIds, Set<Id> caseInvstigationRecordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Case__c + ' in :caseIds'))
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.RecordTypeId + ' in :caseInvstigationRecordTypeIds'))
				.add(new QueryBuilder.CompareCondition(CaseInvestigation__c.IsClosed__c).eq(false))
				.endConditions();

		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
	}

	/**
	* @description Return open case investigations where the network milestone is violated
	* @param violationDatetime Cutoff datetime (method will return case investigations that were violated)
	* @param recordTypeIds record type id set
	* @param selectorOptions Options
	* @return QueryLocator
	*/
	public virtual Database.QueryLocator selectNetworkMilestoneViolatedOpenCaseInvestigations(Datetime violationDatetime, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = selectNetworkMilestoneViolatedOpenCaseInvestigationsQueryBuilder(violationDatetime, recordTypeIds, selectorOptions);
		return Database.getQueryLocator(qb.toSoqlString());
	}

	/**
	* @description : simple query to return open case investigations where the network milestone is violated
	* @param violationDatetime Cutoff datetime (method will return case investigations that were violated)
	* @param recordTypeIds record type id set
	* @param selectorOptions - selector options
	*/
	public virtual QueryBuilder selectNetworkMilestoneViolatedOpenCaseInvestigationsQueryBuilder(Datetime violationDatetime, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.NullCondition(CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c).notNull())
				.add(new QueryBuilder.CompareCondition(CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c).lt(violationDatetime))
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.RecordTypeId + ' in :recordTypeIds'))
				.add(new QueryBuilder.CompareCondition(CaseInvestigation__c.IsClosed__c).eq(false))
				.endConditions();
		return qb;
	}

	/**
	 * Select case investigation records that are not closed and related to AP Network based on case Id, article number and network id
	 */
	public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseArticleNetworkId(Set<Id> caseIds, Set<String> articleNums, Set<Id> networkIds) {
		return selectOpenCaseInvestigationsByCaseArticleNetworkId(caseIds, articleNums, networkIds, new Set<Object>());
	}

	/**
	 * Select case investigation records that are not closed and related to AP Network based on case Id, article number and network id
	 */
	public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByCaseArticleNetworkId(Set<Id> caseIds, Set<String> articleNums, Set<Id> networkIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Case__c + ' in :caseIds'))
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.ReferenceID__c + ' in :articleNums'))
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Network__c + ' in :networkIds'))
				.add(new QueryBuilder.CompareCondition(CaseInvestigation__c.IsClosed__c).eq(false))
				.endConditions();
		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * Select case investigation records that are not closed and from list of passed network ids. 
	 */
	public virtual Map<Id, CaseInvestigation__c> selectOpenCaseInvestigationsByNetworkId(Set<Id> networkIds, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Network__c + ' in :networkIds'))
				.add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.RecordTypeId + ' in :recordTypeIds'))
				.add(new QueryBuilder.CompareCondition(CaseInvestigation__c.IsClosed__c).eq(false))
				
				.endConditions();
		return new Map<Id, CaseInvestigation__c>((List<CaseInvestigation__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * overridden method to generate QueryBuilder instance
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPES)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(selectorOptions), 'RecordType');
		}
		if(selectorOptions.contains(Options.WITH_CASE_DETAILS)) {
			builder.addRelatedFields(CasesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Case__r');
		}
		if(selectorOptions.contains(Options.WITH_ARTICLES)) {
			builder.addRelatedFields(ArticlesSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Article__r');
		}
		if(selectorOptions.contains(Options.WITH_NETWORKS)) {
			builder.addRelatedFields(NetworksSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Network__r');
		}
		if(selectorOptions.contains(Options.WITH_OWNER_DETAILS)) {
			builder.addRelatedFields(UsersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Owner');
		}
		return builder;
	}
}
