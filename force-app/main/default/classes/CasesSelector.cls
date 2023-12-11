/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Selector
 * @tag Selector
 * @tag Cases
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
 * 2020-05-10 - Nathan Franklin - Added fields
 * 2020-08-24 - Disha Kariya - Added with Network, with Article
 * 2020-08-28 - Disha Kariya - Moved With network Response to SSSWCasesSelector
 * 2020-10-18 - Nathan Franklin - Added selectByCaseNumber
 * 2021-02-19 - Ranjeewa Silva - Added selectOpenCasesByCaseNumberOrReferenceId
 * 2021-06-22 - Snehil Jaiswal - Added the subquery for related initial authorised contact 
 * 2021-08-06 - Seth Heang - Added selectByReferenceIdOrderByCreatedDate
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2021-11-26 - Ashapriya Gadi - Added enum WITH_SINGLE_EMAIL_MESSAGE_ASC_ORDER and a condition for it in the newQueryBuilder
 * 2022-02-22 - Naveen Rajanna - REQ2723199 Add fields to getSObjectFieldList
 * 2022-12-05 - Dattaraj Deshmukh - Added enum WITH_CHILD_INVESTIGATIONS and fields to getSObjectFieldList.
 * 2023-02-08 - Dattaraj Deshmukh - Added fields in getSObjectFieldList.
 * 2023-02-28 - Dattaraj Deshmukh - Added 'WITH_NETWORK_RESPONSE' options for SSSW MyNetwork Cases.
 * 2023-05-10 - Mahesh Parvathaneni - Added fields in getSObjectFieldList.
 * 2023-05-29 - Mahesh Parvathaneni - Added WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER enum in the options
 * 2023-08-16 - Hasantha Liyanage - Added fields in getSObjectFieldList.
 * 2023-12-04 - Steve L - added new methods: getClosedCasesByAccountIds, and getOpenCasesByAccountIds
 *
 */
public virtual inherited sharing class CasesSelector extends ApplicationSelector {

	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_CONTACT, WITH_NETWORK, WITH_ARTICLE, WITH_CHILDINITIALCONTACT, WITH_SINGLE_EMAIL_MESSAGES_ASC_ORDER, WITH_BILLINGACCOUNT, WITH_ACCOUNT, 
		WITH_CHILD_INVESTIGATIONS, WITH_NETWORK_RESPONSE, WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER
	}

	public static CasesSelector newInstance() {
		return (CasesSelector)Application.Selectors.newInstance(CasesSelector.class);
	}
	public static CasesSelector newInstance(Integer recordLimit) {
		return (CasesSelector)Application.Selectors.newInstance(CasesSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CasesSelector newInstance(Set<SObjectField> fieldOverrides) {
		CasesSelector selector = (CasesSelector)Application.Selectors.newInstance(CasesSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CasesSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		CasesSelector selector = (CasesSelector)Application.Selectors.newInstance(CasesSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CasesSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		CasesSelector selector = (CasesSelector)Application.Selectors.newInstance(CasesSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return Case.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Case.Id, Case.AccountId, Case.BusinessHoursId, Case.CaseNumber, Case.Origin, Case.OwnerId, Case.Reason,
			Case.RecordTypeId, Case.IsSelfServiceClosed, Case.IsClosed, Case.IsClosedOnCreate, Case.ContactEmail, Case.ContactMobile,
			Case.ContactId, Case.ContactPhone, Case.CreatedById, Case.ClosedDate, Case.CreatedDate, Case.Description, Case.EntitlementId,
			Case.SlaExitDate, Case.SlaStartDate, Case.IsEscalated, Case.Comments, Case.LastModifiedDate, Case.LastModifiedById,
			Case.ParentId, Case.Priority, Case.ProductId, Case.FeedItemId, Case.Status, Case.IsStopped, Case.StopStartDate, Case.Subject,
			Case.Type, Case.SuppliedCompany, Case.SuppliedEmail, Case.SuppliedName, Case.SuppliedPhone, Case.ReferenceID__c, 
			Case.First_Email_Response__c, Case.StarTrack_Calc_Email_Address__c, Case.Owner_is_Queue__c, Case.Approval_Status__c, 
			Case.Business_Solutions_Customer__c, Case.Case_RecordType_Name__c, Case.StarTrack_RecordType__c, Case.ResolutionCode__c, 
			Case.Enquiry_Type__c, Case.Call_Purpose__c, Case.Auto_Email_Response_sent__c, Case.LastIncomingEmailAddress__c,
			Case.EnquirySubType__c, Case.Primary_Name__c, Case.Address1__c, Case.Secondary_Contact__c, Case.Address2__c,
			Case.Facility_Milestones_Violated__c, Case.Root_cause__c, Case.ArticleTest__c, Case.calc_case_consignment__c,
			Case.Last_Status_Change__c, Case.Article_Receiver_Address__c, Case.Article_Receiver_Postcode__c,
			Case.Article_Sender_Name__c, Case.Article_Sender_Address__c, Case.Description_of_contents__c, 
			Case.Description_of_packaging__c, Case.Related_Billing_Account__c, Case.Value_of_Goods__c, Case.Calc_Link_Account__c,
			Case.Checkbox__c, Case.Customer_Type__c, Case.Service_SLA__c, Case.Article_Receiver_Suburb__c, Case.Billing_Number__c

		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Case> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Case> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Case.Id + ' in :ids')).endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/*
	* this method returns records with matching ids And matching record type ids. 
	* it is being used in Domain filtering
	*/
	public List<Case> selectByIdsAndRecordTypeIds(Set<Id> ids, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
			.add(new QueryBuilder.SimpleCondition(Case.Id + ' IN :ids'))
			.add(new QueryBuilder.SimpleCondition(Case.RecordTypeId + ' IN :recordTypeIds'))
			.endConditions();

		return (List<Case>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on case numbers
	 */
	public virtual Map<Id, Case> selectByCaseNumber(Set<String> caseNumbers) {
		return selectByCaseNumber(caseNumbers, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on case numbers
	 */
	public virtual Map<Id, Case> selectByCaseNumber(Set<String> caseNumbers, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Case.CaseNumber + ' in :caseNumbers')).endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/**
	 * Select open cases based on Case Number or Reference Id
	 * @param caseReferences list of case references. a case reference could be a case number or case reference id.
	 * @return matching case records
	 */
	public virtual Map<Id, Case> selectOpenCasesByCaseNumberOrReferenceId(Set<String> caseReferences) {
		return selectOpenCasesByCaseNumberOrReferenceId(caseReferences, new Set<Object>());
	}

	/**
	 * Select open cases based on Case Number or Reference Id
	 * @param caseReferences list of case references. a case reference could be a case number or case reference id.
	 * @param selectorOptions selector options to augment result set
	 *
	 * @return
	 */
	public virtual Map<Id, Case> selectOpenCasesByCaseNumberOrReferenceId(Set<String> caseReferences, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false))
				.add(new QueryBuilder.SimpleCondition(Case.CaseNumber + ' in :caseReferences'))
				.add(new QueryBuilder.SimpleCondition(Case.ReferenceID__c + ' in :caseReferences'))
				.setConditionOrder('1 AND (2 OR 3)')
				.endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/**
	 * Select open cases based on Case Number or Reference Id
	 * @param caseReferences list of case references. a case reference could be a case number or case reference id.
	 * @param recordTypeIds If supplied, Only select cases for the Record Type Ids passed in. (Optional)
	 * @return matching case records
	 */
	public virtual Map<Id, Case> selectOpenCasesByCaseNumberOrReferenceId(Set<String> caseReferences, Set<Id> recordTypeIds) {
		return selectOpenCasesByCaseNumberOrReferenceId(caseReferences, recordTypeIds, new Set<Object>());
	}

	/**
	 * Select open cases based on Case Number or Reference Id
	 * @param caseReferences list of case references. a case reference could be a case number or case reference id.
	 * @param recordTypeIds If supplied, Only select cases for the Record Type Ids passed in. (Optional)
	 * @param selectorOptions selector options to augment result set
	 *
	 * @return
	 */
	public virtual Map<Id, Case> selectOpenCasesByCaseNumberOrReferenceId(Set<String> caseReferences, Set<Id> recordTypeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);

		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false));
		conditions.add(new QueryBuilder.SimpleCondition(Case.CaseNumber + ' in :caseReferences'));
		conditions.add(new QueryBuilder.SimpleCondition(Case.ReferenceID__c + ' in :caseReferences'));

		if (recordTypeIds != null && !recordTypeIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Case.RecordTypeId + ' in :recordTypeIds'));
			conditions.setConditionOrder('1 AND (2 OR 3) AND 4');
		} else {
			conditions.setConditionOrder('1 AND (2 OR 3)');
		}
		String soql = conditions.endConditions().toSoqlString();
		return new Map<Id, Case>((List<Case>)Database.query(soql));
	}

	/**
	 * @description Select Case based on case reference Id and order by created date in desc order
	 * @param referenceIds list of case references Id
	 * @return matching case records
	 */
	public virtual Map<Id, Case> selectByReferenceIdOrderByCreatedDate(Set<String> referenceIds) {
		return selectByReferenceIdOrderByCreatedDate(referenceIds, new Set<Object>());
	}

	/**
	 * @param accountIds account ids
	 * @param selectorOptions selectorOptions
	 * @description returns the closed case record by account id before a given number of months
	 *
	 * @return QueryBuilder
	 */
	public Map<Id,Case> getClosedCasesByAccountIds(Set<Id> accountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(Case.AccountId + ' in : accountIds'))
				.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(true))
				.endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @param accountIds account ids
	 * @param selectorOptions selectorOptions
	 * @description return the open case by the given account ids
	 * @return Map<Id,Case>
	 */
	public Map<Id,Case> getOpenCasesByAccountIds(Set<Id> accountIds, Set<Object> selectorOptions){
		QueryBuilder qb = newQueryBuilder(selectorOptions)
				.addConditions()
				.add(new QueryBuilder.SimpleCondition(Case.AccountId + ' in : accountIds'))
				.add(new QueryBuilder.CompareCondition(Case.IsClosed).eq(false))
				.endConditions();
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select Case based on case reference Id and order by created date in desc order
	 * @param referenceIds list of case references Id
	 * @return matching case records
	 */
	public virtual Map<Id, Case> selectByReferenceIdOrderByCreatedDate(Set<String> referenceIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
		.add(new QueryBuilder.SimpleCondition(Case.ReferenceID__c + ' in :referenceIds'))
		.endConditions();
		qb.addOrderDesc(Case.CreatedDate);
		return new Map<Id, Case>((List<Case>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}

		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'Contact');
		}
		
		if(selectorOptions.contains(Options.WITH_CHILDINITIALCONTACT)){
			builder.addSubQuery(AuthorisedContactsSelector.newInstance().newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(AuthorisedContacts__c.Initial_Contact__c + ' =  true')).endConditions(), 'Authorised_Contacts__r');
		}
	
		if(selectorOptions.contains(Options.WITH_NETWORK)) {
			builder.addRelatedFields(NetworksSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(new Set<Object>{NetworksSelector.Options.WITH_RECORDTYPE}), 'Network__r');
		}

		if(selectorOptions.contains(Options.WITH_ARTICLE)) {
			builder.addRelatedFields(ArticlesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE}), 'ArticleTest__r');
		}
		if(selectorOptions.contains(Options.WITH_SINGLE_EMAIL_MESSAGES_ASC_ORDER)) {
			//PREVENT RECURSION
			Set<Object> clonedOptions = selectorOptions.clone();
			clonedOptions.remove(Options.WITH_SINGLE_EMAIL_MESSAGES_ASC_ORDER);
			builder.addSubQuery(EmailMessagesSelector.newInstance(EmailMessage.CreatedDate, 'Asc', 1).newQueryBuilder(clonedOptions), 'EmailMessages');
		}
		if(selectorOptions.contains(Options.WITH_CHILD_INVESTIGATIONS)) {
			builder.addSubQuery(CaseInvestigationsSelector.newInstance().newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(CaseInvestigation__c.Status__c + ' != \'Closed\'' )).endConditions(), 'CaseInvestigations__r');
		}
		
		if(selectorOptions.contains(Options.WITH_BILLINGACCOUNT)) {
			builder.addRelatedFields(BillingAccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(), 'Related_Billing_Account__r');
		}
		if (selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(), 'Account');
		}
		if(selectorOptions.contains(Options.WITH_NETWORK_RESPONSE)) {
			builder.addSubQuery(NetworkResponsesSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(), 'Network_Responses1__r');
		}
		if(selectorOptions.contains(Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER)) {
			builder.addSubQuery(EmailMessagesSelector.newInstance(EmailMessage.CreatedDate, 'Asc', 0).setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'EmailMessages');
		}				
		return builder;
	}

}