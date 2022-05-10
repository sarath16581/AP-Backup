/**
 * @author Ashapriya Gadi
 * @date 2021-11-17
 * @group Selector
 * @tag Selector
 * @tag Case SObject
 * @domain Service Delivery
 * @description A very simple selector class that sits in the Service Delivery domain
 * @changelog
 * 2021-11-17 - Ashapriya Gadi - Created
 * 2022-02-17 - Nathan Franklin - Fixed bug with newInstance
 */
public virtual inherited sharing class ServiceAdvisorsCasesSelector extends CasesSelector {
	
	private static final Set<String> SD_CASE_RECORD_TYPES = new Set<String>{
			'Sales_Ops_Delivery'
	};

	public static ServiceAdvisorsCasesSelector newInstance() {
		return (ServiceAdvisorsCasesSelector)Application.Selectors.newInstance(ServiceAdvisorsCasesSelector.class);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ServiceAdvisorsCasesSelector newInstance(Integer recordLimit,Set<SObjectField> fieldOverrides) {
		ServiceAdvisorsCasesSelector selector = (ServiceAdvisorsCasesSelector)Application.Selectors.newInstance(ServiceAdvisorsCasesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * Select cases based on Case Id and EntitlementId and createdById
	 * @param caseIds set of case ids.
	 * @param entitlementId String value for entitlementId
	 * @param createdBy String value for createdById
	 * @return matching case records
	 */
	public virtual List<Case> selectByIdsAndEntitlementIdAndCreatedBy(Set<Id> caseIds, String entitlementId,String createdBy) {
		return selectByIdsAndEntitlementIdAndCreatedBy(caseIds,entitlementId,createdBy, new Set<Object>());
	}

	/**
	* Select cases based on Case Id and EntitlementId and createdById
	* @param caseIds set of case ids.
	* @param entitlementId String value for entitlementId
	* @param createdBy String value for createdById
	* @param selectorOptions selector options to augment result set
	*/
	public virtual List<Case> selectByIdsAndEntitlementIdAndCreatedBy(Set<Id> caseIds, String entitlementId, String createdBy, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(Case.Id + ' in :caseIds'))
				.add(new QueryBuilder.SimpleCondition(Case.EntitlementId + ' = :entitlementId'))
				.add(new QueryBuilder.SimpleCondition(Case.CreatedById + ' = :createdBy'))
				.endConditions();

		String soql = qb.toSoqlString();
		return Database.query(soql);
	}
	public override virtual QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}
	
	public override virtual QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		
		// always make sure we are only returning service delivery cases
		builder.addConditions().add((new QueryBuilder.InCondition('RecordType.DeveloperName')).inCollection(SD_CASE_RECORD_TYPES)).endConditions();
		return builder;
	}
}