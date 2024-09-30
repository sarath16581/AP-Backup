/**
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Selector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-05-10 - Nathan Franklin - Created
 * 2020-07-22 - Nathan Franklin - Added field override capability
 * 2021-10-01 - Nathan Franklin - Added new fields list
 * 2022-11-23 - Mahesh Parvathaneni - Added selectByCaseIds method
 * 2023-03-10 - Mahesh Parvathaneni - Updated WITH_EVENTMESSAGES_DESC_ORDER options
 * 2024-05-29 - Seth Heang - Added ConsignmentTrackingNumber__c, FurtherReferences__c, ProductID__c, IsDelivered__c into SOQL field list 
 * 2024-04-24 - Vasu Gorakati - Added selectByArticleNames method
 * 2024-09-23 - Rejeesh Raghavan - Added selectWithCasesByIdOrTrackingOrName method
 */
public virtual inherited sharing class ArticlesSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE, WITH_CONSIGNMENT, WITH_CHILDARTICLES,
		WITH_BILLINGACCOUNT, // using BillingAccountsSelector
		WITH_EVENTMESSAGES_DESC_ORDER,
		FILTER_BY_NETWORK_NOT_NULL
	}
	public enum ComplexSubQueryOptions {
		WITH_CASES
	}

	public static ArticlesSelector newInstance() {
		return (ArticlesSelector)Application.Selectors.newInstance(ArticlesSelector.class);
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ArticlesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ArticlesSelector selector = (ArticlesSelector)Application.Selectors.newInstance(ArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static ArticlesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ArticlesSelector selector = (ArticlesSelector)Application.Selectors.newInstance(ArticlesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Article__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Article__c.Name, Article__c.Billing_Account__c, Article__c.Sender_APCN__c, Article__c.Receiver_APCN__c, Article__c.Hide_Article__c, Article__c.ArticleID__c, Article__c.ActualWeight__c,
				Article__c.ArticleCount__c, Article__c.ArticleLodgementDate__c, Article__c.ArticleTransitAmountValue__c, Article__c.DeliveryInstructions__c,
				Article__c.DestinationPostCode__c, Article__c.ProductCategory__c, Article__c.ReceiverAddress__c, Article__c.ReceiverAddressLine1__c,
				Article__c.ReceiverAddressLine2__c, Article__c.ReceiverAddressLine3__c, Article__c.ReceiverAddressLine4__c, Article__c.ReceiverCity__c,
				Article__c.ReceiverState__c, Article__c.ReceiverPostcode__c, Article__c.ReceiverCountry__c, Article__c.ReceiverCountryName__c, Article__c.ReceiverName__c,
				Article__c.ReceiverEmail__c, Article__c.ReceiverCompany__c, Article__c.SenderAddress__c, Article__c.SenderAddressLine1__c, Article__c.SenderAddressLine2__c,
				Article__c.SenderAddressLine3__c, Article__c.SenderAddressLine4__c, Article__c.SenderCity__c, Article__c.SenderState__c, Article__c.SenderPostcode__c,
				Article__c.SenderCountry__c, Article__c.SenderCountryName__c, Article__c.SenderName__c, Article__c.SenderEmail__c, Article__c.SenderCompany__c,
				Article__c.ServiceCode__c, Article__c.SignatureRequiredFlag__c, Article__c.SubProduct__c, Article__c.ServiceQualifier__c, Article__c.Subscribed__c, Article__c.ExpectedDeliveryDate__c,
				Article__c.ConsignmentParcelCount__c, Article__c.ContentsItems__c, Article__c.ContentsItemsPayload__c, Article__c.InsuranceRequired__c,
				Article__c.InsuranceAmount__c, Article__c.InsuranceChargeAmount__c, Article__c.InsuranceSDR__c, Article__c.CTCDollarAmount__c, Article__c.AdditionalServices__c,
				Article__c.AdditionalServicesPayload__c, Article__c.CustCommDecisionCode__c, Article__c.CustCommDecisionDescription__c, Article__c.CustDelPrefOptionCode__c,
				Article__c.CustDelPrefDescription__c, Article__c.Notification__c, Article__c.RecordTypeId, Article__c.Description_of_Goods__c, Article__c.Customer_Ref__c,
				Article__c.Delivered__c, Article__c.TrackingID__c, Article__c.Consignment__c, Article__c.MLID__c, Article__c.HasExtraCover__c, Article__c.CID__c, Article__c.ConsignmentTrackingNumber__c,
				Article__c.FurtherReferences__c, Article__c.IsDelivered__c, Article__c.ProductID__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Article__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Article__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Article__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Article__c>((List<Article__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Article__c> selectByArticleIds(Set<String> ids) {
		return selectByArticleIds(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Article__c> selectByArticleIds(Set<String> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Article__c.ArticleID__c + ' in :ids')).endConditions();
		return new Map<Id, Article__c>((List<Article__c>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, Article__c> selectByTracking(Set<String> trackingIds, Boolean includeConsignmentSearch) {
		return selectByTracking(trackingIds, new Set<Object>(), includeConsignmentSearch);
	}
	public Map<Id, Article__c> selectByTracking(Set<String> trackingIds, Set<Object> selectorOptions, Boolean includeConsignmentSearch) {
		return selectByIdOrTracking(trackingIds, new Set<Id>(), selectorOptions, includeConsignmentSearch);
	}

	/**
	 * @description Run a simple query to get records based on case id's
	 */
	public virtual Map<Id, Article__c> selectByCaseIds(Set<Id> ids) {
		return selectByCaseIds(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Article__c> selectByCaseIds(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Article__c.Case__c + ' in :ids')).endConditions();
		return new Map<Id, Article__c>((List<Article__c>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, Article__c> selectByIdOrTracking(Set<String> trackingIds, Set<Id> ids, Boolean includeConsignmentSearch) {
		return selectByIdOrTracking(trackingIds, ids, new Set<Object>{}, includeConsignmentSearch);
	}
	public Map<Id, Article__c> selectByIdOrTracking(Set<String> trackingIds, Set<Id> ids, Set<Object> selectorOptions, Boolean includeConsignmentSearch) {
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(!trackingIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('ArticleID__c in :trackingIds'));
			conditionCount++;
		}
		if(includeConsignmentSearch) {
			conditions.add(new QueryBuilder.SimpleCondition('Consignment__r.ArticleID__c in :trackingIds'));
			conditionCount++;
		}
		if(!ids.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition('Id in :ids'));
			conditionCount++;
		}

		if(conditionCount == 1) {
			conditions.setConditionOrder('1');
		} else if(conditionCount == 2) {
			conditions.setConditionOrder('1 OR 2');
		} else if(conditionCount == 3) {
			conditions.setConditionOrder('1 OR 2 OR 3');
		}

		String soql = conditions.endConditions().toSoqlString();
		return new Map<Id, Article__c>((List<Article__c>)Database.query(soql));
	}
	/**
	 * description Queries Articles, with related cases, by the Name, ArticleId__c, ConsignmentTrackingNumber__c
	 * @param bindMap Map of Bind variables
	 * trackingIds set of trackingIds [Mandatory]
	 * caseRecordTypes set of case record types to filter on [Optional]
	 * closedCaseCutoffDate Case ClosedDate filter [Optional. Mandatory if caseRecordTypes is provided]
	 * @param complexQueryOptions Complex Sub Query options to include child relationships
	 * @return  `Map<Id, Article__c>`
	 */
	public Map<Id, Article__c> selectWithCasesByIdOrTrackingOrName(Map<String, Object> bindMap, Set<Object> complexQueryOptions) {
		
		QueryBuilder qb = newQueryBuilder(
			new Set<Object>{
				Options.WITH_RECORDTYPE
			})
			.addConditions()
			.add(new QueryBuilder.SimpleCondition('RecordTypeId != null'))
			.add(new QueryBuilder.SimpleCondition('Name IN :trackingIds'))
			.add(new QueryBuilder.SimpleCondition('Consignment__r.Name IN :trackingIds'))
			.add(new QueryBuilder.SimpleCondition('Consignment__r.ArticleID__c IN :trackingIds'))
			.add(new QueryBuilder.SimpleCondition('ConsignmentTrackingNumber__c IN :trackingIds'))
			.setConditionOrder('(1 AND (2 OR 3 OR 4 OR 5))')
			.endConditions();
		
			if(complexQueryOptions.contains(ComplexSubQueryOptions.WITH_CASES)){
				qb.addSubQuery(
					CasesSelector.newInstance(0, fieldOverrides)
						.newQueryBuilder(
							new Set<Object>{
								CasesSelector.Options.WITH_RECORDTYPE
								, CasesSelector.Options.WITH_ARTICLE})
						.addConditions()
						.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(true))
						.add(new QueryBuilder.SimpleCondition(Case.ClosedDate + ' >=:closedCaseCutoffDate'))
						.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false))
						.add(new QueryBuilder.SimpleCondition(' RecordType.DeveloperName  IN :caseRecordTypes'))
						.setConditionOrder('((1 AND 2) OR 3) AND 4')
						.endConditions()

						//sort by ClosedDate, as it will be NULL for Open Cases use NULLS FIRST
						.setOrder(new QueryBuilder.Order(Case.ClosedDate)
							.setSortingOrderDesc()
							.setNullsOrderFirst())
					, 'Cases__r'
				);
			}

			//sort by Article__c.RecordType.Name , so that Consignments are in the list before Articles
			qb.setOrder(new QueryBuilder.Order(Article__c.RecordType.Name)
				.setSortingOrderDesc());

		return new Map<Id, Article__c>(
			(List<Article__c>)
				Database.queryWithBinds(qb.toSoqlString(), bindMap, AccessLevel.USER_MODE));
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(selectorOptions), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_CONSIGNMENT)) {
			Set<Object> childOptions = selectorOptions.clone();
			childOptions.remove(Options.WITH_CHILDARTICLES);
			childOptions.remove(Options.WITH_CONSIGNMENT);
			builder.addRelatedFields(ArticlesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(childOptions), 'Consignment__r');
		}

		if(selectorOptions.contains(Options.WITH_CHILDARTICLES)) {
			Set<Object> childOptions = selectorOptions.clone();
			childOptions.remove(Options.WITH_CHILDARTICLES);
			childOptions.remove(Options.WITH_CONSIGNMENT);
			builder.addSubQuery(ArticlesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(childOptions), 'Articles__r');
		}

		if(selectorOptions.contains(Options.WITH_BILLINGACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Billing_Account__r');
		}

		if(selectorOptions.contains(Options.WITH_EVENTMESSAGES_DESC_ORDER)) {
			builder.addSubQuery(EventMessagesSelector.newInstance('ActualDateTime__c', 'Desc').setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Event_Messages__r');
		}

		if(selectorOptions.contains(Options.FILTER_BY_NETWORK_NOT_NULL)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Article__c.Network__c).ne('')).endConditions();
			builder.addConditions().add(new QueryBuilder.NullCondition(Article__c.Network__c).notNull()).endConditions();
		}
		return builder;
	}

	public virtual Map<Id, Article__c> selectByArticleNames(Set<String> names, String recordTypeName,  Set<String> sourceSystems,  Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.CompareCondition(Article__c.RecordTypeId).eq(SObjectType.Article__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId()))
				.add(new QueryBuilder.SimpleCondition(Article__c.Name + ' in :names'))
				.add(new QueryBuilder.SimpleCondition(Article__c.Source_System__c + ' in :sourceSystems'))

				.endConditions();
		Map<Id, Article__c> res = new Map<Id, Article__c>((List<Article__c>)Database.query(qb.toSoqlString()));
		return res;
	}

	/**
	* Returns Article list based on Article Name and record type
	* @param names set of Article name
	* @param recordTypeName Article record type
	* @param selectorOptions selector options to augment result set
	*/
 	public virtual List<Article__c> selectByArticleNames(Set<String> names, String recordTypeName,  Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(Article__c.Name + ' in :names'));
		if (recordTypeName != null){
			conditions.add(new QueryBuilder.SimpleCondition('RecordType.DeveloperName = :recordTypeName'));
		}
		String soql = conditions.endConditions().toSoqlString();
		return (List<Article__c>)Database.query(soql);
	}
}