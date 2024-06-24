/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Selector
* @tag Selector
* @tag Case SObject
* @domain SSSW
* @description A very simple selector class that sits in the SSSW domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Methods
* 2020-08-24 - Disha Kariya - Added fields override with Map
* 2020-08-28 - Disha Kariya - Added With Network Response
* 2021-12-02 - Alex Volkov - Added selectCasesEligibleForReopenByOwnerAndDate method
* 2022-11-21 - Thang Nguyen - DDS-13756 Added CHASEnquiryType__c field
* 2023-03-23 - StephenL - Modified this selector to include the WITH_ARTICLE option
* 2023-05-30 - StephenL - Modified this selector to include the WITH_CONTACT option
* 2023-05-30 - StephenL - Introduced a new selector method to select Cases based on UserId or User's Contact's APCN
*/
public virtual inherited sharing class SSSWCasesSelector extends CasesSelector {
	public enum Options {
		WITH_NETWORK_RESPONSE,
		RETURN_QUERY_LOCATOR,
		WITH_ARTICLE,
		WITH_CONTACT
	}
	private static final Set<String> SSSW_CASE_RECORD_TYPES = new Set<String>{
			'SSSWDelivery',
			'SSSWFax',
			'SSSWGeneralEnquiry',
			'SSSWService',
			'Social_Record_Type',
			'NCCCDirectEmail'
	};

	public static SSSWCasesSelector newInstance() {
		return (SSSWCasesSelector)Application.Selectors.newInstance(SSSWCasesSelector.class);
	}
	public static SSSWCasesSelector newInstance(Integer recordLimit) {
		return (SSSWCasesSelector)Application.Selectors.newInstance(SSSWCasesSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SSSWCasesSelector newInstance(Set<SObjectField> fieldOverrides) {
		SSSWCasesSelector selector = (SSSWCasesSelector)Application.Selectors.newInstance(SSSWCasesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *                          This approach removes data consistency and prevents possible caching of results
	 */
	public static SSSWCasesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		SSSWCasesSelector selector = (SSSWCasesSelector)Application.Selectors.newInstance(SSSWCasesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SSSWCasesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		SSSWCasesSelector selector = (SSSWCasesSelector)Application.Selectors.newInstance(SSSWCasesSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @description Grab the base fields and extend by adding new fields specific to the domain of this selector
	 */
	public virtual override Set<SObjectField> getSObjectFieldList() {
		Set<SObjectField> fields = super.getSObjectFieldList();
		fields.addAll(new Set<SObjectField>{
				Case.Address3__c, Case.Address3Country__c, Case.Address3Line2__c, Case.Address3Postcode__c, Case.Address3State__c, Case.Address3Suburb__c,
				Case.Address4__c, Case.Address4Country__c, Case.Address4Line2__c, Case.Address4Postcode__c, Case.Address4State__c, Case.Address4Suburb__c,
				Case.AllocateToQueue__c, Case.APS_Number__c, Case.ArticleCount__c, Case.ArticleTest__c, Case.ArticleType__c, Case.Billing_Number__c,
				Case.Case_Reopen_Date__c, Case.Case_Reopen_Status__c, Case.CaseLocality__c, Case.CaseOriginator__c, Case.CashOnDelivery__c,
				Case.CCU3rdPartyReference__c, Case.CCUEnquiryType__c, Case.CCUItemContents__c, Case.CCUServiceUsed__c, Case.CCUYourReference__c,
				Case.CollectionCardColour__c, Case.Complaint__c, Case.Completed_Customer_Conversion__c, Case.Contact_Email__c, Case.Contact_Mobile__c,
				Case.CRN__c, Case.Customer_Email_Notification__c, Case.Customer_Milestones_Violated__c, Case.Customer_Number__c, Case.Customer_Relationship__c,
				Case.Customer_Type__c, Case.DateofIncident__c, Case.DDC_Receiver_First_Name__c, Case.DDC_Receiver_Last_Name__c, Case.Deployment_Duration__c,
				Case.EmailThreadID__c, Case.Employee_Email__c, Case.Employee_Lastname__c, Case.Employee_Mobile__c, Case.EnquirySubType__c,
				Case.ExtraCover__c, Case.Facility_Milestones_Violated__c, Case.Facility_Tier_Escalation_Email__c, Case.First_Name__c, Case.FirstName1__c,
				Case.FirstName2__c, Case.FirstName3__c, Case.FirstName4__c, Case.FirstName5__c, Case.FirstName6__c, Case.FirstName7__c, Case.Full_Name__c, Case.Initiated_By__c,
				Case.Internal_Milestones_Violated__c, Case.Internal_Tier_Escalation_Email__c, Case.Investigation_Date__c, Case.Is_Complaint__c, Case.IsCR__c,
				Case.IsHLC__c, Case.Issue_Resolution__c, Case.Last_Name__c, Case.LastName1__c, Case.LastName2__c, Case.LastName3__c, Case.LastName4__c, Case.LastName5__c,
				Case.LastName6__c, Case.LastName7__c, Case.Lodgement_Network__c, Case.MPB_BSP_Enquiry_Type__c, Case.MPB_BSP_Tech_Enquiry_Type__c, Case.Network__c,
				Case.Network_Response__c, Case.NetworkComments__c, Case.NPSRequired__c, Case.NPSScheduledDate__c, Case.NPSTagDate__c, Case.Number_of_Cases__c,
				Case.Originating_Network__c, Case.Permanent_Close__c, Case.PrimaryContactFirstName__c, Case.PrimaryContactLastName__c, Case.Product__c,
				Case.ProductCategory__c, Case.ProductSubCategory__c, Case.Reason_Code__c, Case.Refer_to_Third_Party__c, Case.ReferenceID__c, Case.RelatedCase__c,
				Case.Resolution_Result__c, Case.Resolution_Status__c, Case.ResolutionCode__c, Case.Role__c, Case.Send_Case_Comments__c, Case.Service_Now_Ticket_Number__c,
				Case.SignatureOnDelivery__c, Case.SLACharterBreach__c, Case.SLATargetDate__c, Case.Source__c, Case.Time_to_Resolve_mins__c, Case.Updated_Case_Comments__c,
				Case.Vendor_Case_Number__c, Case.CHASEnquiryType__c
		});
		return fields;
	}

	/**
	 * @description Run a simple query to get records based on a partial match of ReferenceID__c
	 */
	public virtual Map<Id, Case> selectByReferenceIdPartial(String referenceId) {
		return selectByReferenceIdPartial(referenceId, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on a partial match of ReferenceID__c
	 */
	public virtual Map<Id, Case> selectByReferenceIdPartial(String referenceId, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.LikeCondition(Case.ReferenceID__c).likeAnyRight(referenceId)).endConditions();
		String soql = qb.toSoqlString();
		return new Map<Id, Case>((List<Case>)Database.query(soql));
	}

	/**
	 * @description Run a simple query to get open cases based on ReferenceID__c
	 */
	public virtual Map<Id, Case> selectChildCasesByParent(Set<Id> parentIds) {
		return selectChildCasesByParent(parentIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get open cases based on ReferenceID__c
	 */
	public virtual Map<Id, Case> selectChildCasesByParent(Set<Id> parentIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Case.ParentId + ' in :parentIds')).endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get open cases based on ReferenceID__c
	 */
	public virtual Map<Id, Case> selectOpenCasesByReferenceId(Set<String> referenceIds) {
		return selectOpenCasesByReferenceId(referenceIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get open cases based on ReferenceID__c
	 */
	public virtual Map<Id, Case> selectOpenCasesByReferenceId(Set<String> referenceIds, Set<Object> selectorOptions) {
		return new Map<Id, Case>((List<Case>)Database.query(getOpenCasesByReferenceIdQueryBuilder(referenceIds, selectorOptions).toSoqlString()));
	}

	/**
	 * @description Return a count of all open cases based on ReferenceID__c
	 */
	public virtual Integer countOpenCasesByReferenceId(Set<String> referenceIds) {
		return countOpenCasesByReferenceId(referenceIds, new Set<Object>());
	}

	/**
	 * @description Return a count of all open cases based on ReferenceID__c
	 */
	public virtual Integer countOpenCasesByReferenceId(Set<String> referenceIds, Set<Object> selectorOptions) {
		return Database.countQuery(getOpenCasesByReferenceIdQueryBuilder(referenceIds, selectorOptions).toCountString());

	}

	/**
	 * @param runningUserId a user Id
	 * @param runningUserAPCN an APCN value
	 * @param selectorOptions selectorOptions
	 * @description Return a map based on the runningUserid or an APCN value
	 *
	 * @return ap<Id, Case>
	 */
	public virtual Map<Id, Case> selectCasesByCreatedByUserAndCaseOrigin(Id runningUserId, String runningUserAPCN, Set<Object> selectorOptions) {
		return new Map<Id, Case>((List<Case>)Database.query(getCasesByCreatedByUserAndCaseOrigin(runningUserId, runningUserAPCN, selectorOptions).toSoqlString()));
	}

	/**
	 * @description Return cases eligible for reopen before specified reopen date
	 * @param pOwnerIds Filter by owner
	 * @param pReopenDate Cutoff date (method will return cases eligible for reopen before, but not including this date)
	 * @param selectorOptions Options
	 * @return Object - either map of selected cases or a query locator
	 */
	public virtual Object selectCasesEligibleForReopenByOwnerAndDate(Set<String> pOwnerIds, Datetime pReopenDate, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false))
				  .add(new QueryBuilder.CompareCondition(Case.Case_Reopen_Date__c).lt(pReopenDate));
		conditions.add(new QueryBuilder.NullCondition(Case.ProductCategory__c).notNull());
		conditions.add(new QueryBuilder.NullCondition(Case.ProductSubCategory__c).notNull());
		conditions.add(new QueryBuilder.NullCondition(Case.EnquirySubType__c).notNull());
		conditions.add(new QueryBuilder.CompareCondition(Case.IsHLC__c).eq(false));
		conditions.add(new QueryBuilder.CompareCondition(Case.IsCR__c).eq(false));
		//First condition in this selector is always the record type list, method specific conditions start with 2
		String lConditionString = '1 AND 2 AND 3 AND ((4 AND 5 AND 6) OR (7 AND 8))';
		if (pOwnerIds != null && !pOwnerIds.isEmpty()){
			conditions.add(new QueryBuilder.SimpleCondition(Case.OwnerId + ' in :pOwnerIds'));
			lConditionString += ' AND 9';
		}
		conditions.setConditionOrder(lConditionString).endConditions();
		qb.addOrderDesc('Case_Reopen_Date__c');
		Object vResult;
		if (selectorOptions.contains(Options.RETURN_QUERY_LOCATOR)) {
			vResult = Database.getQueryLocator(qb.toSoqlString());
		}
		else {
			vResult = new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
		}
		return vResult;
	}

	/**
	 * @param runningUserId a user Id
	 * @param runningUserAPCN an APCN value
	 * @param selectorOptions selectorOptions
	 * @description Return a map based on the runningUserid or an APCN value
	 *
	 * @return QueryBuilder
	 */
	public virtual QueryBuilder getCasesByCreatedByUserAndCaseOrigin (Id runningUserId, String runningUserAPCN, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.CompareCondition(Case.CreatedById).eq(runningUserId));
		conditions.add(new QueryBuilder.CompareCondition(Case.Origin).ne(SSSWConstants.CASE_ORIGIN_DIRECT_EMAIL));
		//Condition order 1 is for the recordType.developername condition which is in the newQueryBuilder method
		//condition 2 - case.createdById, condition 3 - case.Origin
		String conditionOrder = '1 AND 2 AND 3';
		conditions.setConditionOrder(conditionOrder).endConditions();
		qb.addOrderDesc('LastModifiedDate');

		return qb;
	}

	private virtual QueryBuilder getOpenCasesByReferenceIdQueryBuilder(Set<String> referenceIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.InCondition(Case.ReferenceID__c).inCollection(referenceIds))
				.add(new QueryBuilder.SimpleCondition(Case.ReferenceID__c + ' in :referenceIds'))
				.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false))
				.endConditions();
		return qb;
	}

	public override virtual QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public override virtual QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		// always make sure we are only returning SSSW cases
		// NOTE: need to use .inCollection to build these values out since we can't bind SSSW_CASE_RECORD_TYPES because it may not be available as a local variable from where this is being called
		builder.addConditions().add((new QueryBuilder.InCondition('RecordType.DeveloperName')).inCollection(SSSW_CASE_RECORD_TYPES)).endConditions();

		if(selectorOptions.contains(Options.WITH_NETWORK_RESPONSE)) {
			builder.addSubQuery(NetworkResponsesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(), 'Network_Responses1__r');
		}

		if(selectorOptions.contains(Options.WITH_ARTICLE)) {
			builder.addRelatedFields(ArticlesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE}), 'ArticleTest__r');
		}

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}), 'Contact');
		}

		return builder;
	}

}