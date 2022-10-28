/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Selector
 * @tag Selector
 * @tag ICPS
 * @domain ICPS
 * @description Selector class to provide a query interface to the ICPS SObject.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 * 2022-09-15 - Harry Wang - added new search params
 */
public inherited sharing class ICPSSelector extends ApplicationSelector {
	public enum Options {
		WITH_ICPS_ARTICLES
	}

	public static ICPSSelector newInstance() {
		return (ICPSSelector) Application.Selectors.newInstance(ICPSSelector.class);
	}

	public static ICPSSelector newInstance(Integer recordLimit) {
		return (ICPSSelector) Application.Selectors.newInstance(ICPSSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static ICPSSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ICPSSelector selector = (ICPSSelector) Application.Selectors.newInstance(ICPSSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ICPSSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ICPSSelector selector = (ICPSSelector)Application.Selectors.newInstance(ICPSSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ICPSSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		return (ICPSSelector)Application.Selectors.newInstance(ICPSSelector.class).setFieldOverrides(fieldOverrides);
	}

	protected override SObjectType getSObjectType() {
		return ICPS__c.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				ICPS__c.Id, ICPS__c.Name, ICPS__c.MailCategory__c, ICPS__c.StoredLocation__c,
				ICPS__c.ItemType__c, ICPS__c.ReceiverName__c, ICPS__c.CountryofOrigin__c, ICPS__c.NumberofArticles__c,
				ICPS__c.OwnerId, ICPS__c.DemurrageStartDate__c, ICPS__c.Status__c, ICPS__C.DutyStatus__c, ICPS__c.OrderNumber__c,
				ICPS__c.OtherStorageLocation__c, ICPS__c.RecordTypeId, ICPS__c.Articles__c, ICPS__c.StoreLocationReporting__c
		};
	}

	/**
	 * This method is used to search on ICPS object given search parameters as a map and a match option
	 * note: This method only supports at most 9 search criteria as in searchParams
	 * @param searchParams Search Parameters as Field-to-Value map, Supported Search Params:
	 * reference - exact match on ICPS Name or Migrated ICPS Reference
	 * recipient_name - %wildcard% match
	 * stored_location - exact match
	 * (from_first_notice_date, to_first_notice_date) - date range match
	 * (from_final_notice_date, to_final_notice_date) - date range match
	 * (from_holding_date, to_holding_date) - date range match
	 * (from_release_date, to_release_date) - date range match
	 * (from_date_returned, to_date_returned) - date range match
	 * (from_date_of_posting, to_date_of_posting) - date range match
	 * (from_delivery_date, to_delivery_date) - date range match
	 * @param matchAll Match options, true for 'AND', false for 'OR'
	 * @return List of ICPS__C meeting the search criteria
	 */
	public List<ICPS__c> search(Map<String, Object> searchParams, Boolean matchAll) {
		QueryBuilder builder = newQueryBuilder();
		QueryBuilder.ConditionsManager conditions = builder.addConditions();
		Integer conditionCount = 0;

		for (String field : searchParams.keySet()) {
			Object fieldValue = searchParams.get(field);
			if (!String.isBlank((String) fieldValue)) {
				if (field == 'reference') {
					String reference = fieldValue.toString();
					conditions.add(new QueryBuilder.SimpleCondition('(Name = :reference OR MigratedICPSReference__c = :reference)'));
				} else if (field == 'recipient_name') {
					String recipientName = '%' + fieldValue + '%';
					conditions.add(new QueryBuilder.SimpleCondition('ReceiverName__c LIKE :recipientName'));
				} else if (field == 'stored_location') {
					String storedLocation = fieldValue.toString();
					conditions.add(new QueryBuilder.SimpleCondition('StoredLocation__c = :storedLocation'));
				} else if (field == 'status') {
					String status = fieldValue.toString();
					conditions.add(new QueryBuilder.SimpleCondition('Status__c = :status'));
				} else if (field == 'article_number') {
					String articleNumber = fieldValue.toString();
					QueryBuilder subQueryBuilder = ICPSArticlesSelector.newInstance(0, new Set<SObjectField>{ICPSArticle__c.ICPS__c})
							.newQueryBuilder(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER});
					QueryBuilder.ConditionsManager subQueryConditions = subQueryBuilder.addConditions();
					subQueryConditions.add(new QueryBuilder.SimpleCondition(ICPSArticle__c.Name + ' = :articleNumber'));
					subQueryConditions.endConditions();
					conditions.add(new QueryBuilder.SimpleCondition('Id IN (' + subQueryBuilder.toSoqlString() + ')'));
				} else if (field == 'from_first_notice_date') {
					Date fromFirstNoticeDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('FirstNoticeDate__c >= :fromFirstNoticeDate'));
				} else if (field == 'to_first_notice_date') {
					Date toFirstNoticeDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('FirstNoticeDate__c <= :toFirstNoticeDate'));
				} else if (field == 'from_final_notice_date') {
					Date fromFinalNoticeDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('FinalNoticeDate__c >= :fromFinalNoticeDate'));
				} else if (field == 'to_final_notice_date') {
					Date toFinalNoticeDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('FinalNoticeDate__c <= :toFinalNoticeDate'));
				} else if (field == 'from_holding_date') {
					Date fromHoldingDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('HoldUntilDate__c >= :fromHoldingDate'));
				} else if (field == 'to_holding_date') {
					Date toHoldingDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('HoldUntilDate__c <= :toHoldingDate'));
				} else if (field == 'from_release_date') {
					Date fromReleaseDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('ABFInstructionDate__c >= :fromReleaseDate'));
				} else if (field == 'to_release_date') {
					Date toReleaseDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('ABFInstructionDate__c <= :toReleaseDate'));
				} else if (field == 'from_date_returned') {
					Date fromDateReturned = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DateReturned__c >= :fromDateReturned'));
				} else if (field == 'to_date_returned') {
					Date toDateReturned = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DateReturned__c <= :toDateReturned'));
				} else if (field == 'from_date_of_posting') {
					Date fromDateOfPosting = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DateOfPosting__c >= :fromDateOfPosting'));
				} else if (field == 'to_date_of_posting') {
					Date toDateOfPosting = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DateOfPosting__c <= :toDateOfPosting'));
				} else if (field == 'from_delivery_date') {
					Date fromDeliveryDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DeliveryDate__c >= :fromDeliveryDate'));
				} else if (field == 'to_delivery_date') {
					Date toDeliveryDate = Date.valueOf((String) fieldValue);
					conditions.add(new QueryBuilder.SimpleCondition('DeliveryDate__c <= :toDeliveryDate'));
				} else continue;
				conditionCount++;
			}
		}

		String conditionOrder = '';
		for (Integer i = 0; i < conditionCount; i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i + 1);
		}
		conditions.setConditionOrder(conditionOrder);
		String soql = conditions.endConditions().toSoqlString();
		return (List<ICPS__c>) Database.query(soql);
	}

	/**
	* @description Return ICPS List by ICPS Id set
	*/
	public List<ICPS__c> selectById(Set<Id> icpsIds) {
		return selectById(icpsIds, new Set<Object>());
	}

	/**
	* @description Return ICPS List by ICPS Id set given selector options
	*/
	public List<ICPS__c> selectById(Set<Id> icpsIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ICPS__c.Id + ' IN :icpsIds')).endConditions();
		return (List<ICPS__c>) Database.query(qb.toSoqlString());
	}

	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if (selectorOptions.contains(Options.WITH_ICPS_ARTICLES)) {
			builder.addSubQuery(ICPSArticlesSelector.newInstance(fieldOverrides).newQueryBuilder(), 'ICPS_Articles__r');
		}
		return builder;
	}
}