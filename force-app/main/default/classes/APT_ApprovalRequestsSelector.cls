/**
* @author Nasir Jawed
* @date 2022-12-02
* @description APT_ApprovalRequestsSelector helps to get values for the field of object  Apttus_Approval__Approval_Request__c .
* @changelog
*/
public virtual inherited sharing class APT_ApprovalRequestsSelector extends ApplicationSelector {
	public enum Options {
		WITH_USER, FILTER_APPROVAL_REQUEST
	}

	public static APT_ApprovalRequestsSelector newInstance() {
		return (APT_ApprovalRequestsSelector)Application.Selectors.newInstance(APT_ApprovalRequestsSelector.class);
	}
	public static APT_ApprovalRequestsSelector newInstance(Integer recordLimit) {
		return (APT_ApprovalRequestsSelector)Application.Selectors.newInstance(APT_ApprovalRequestsSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return Apttus_Approval__Approval_Request__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Apttus_Approval__Approval_Request__c.Id,Apttus_Approval__Approval_Request__c.Apttus_Approval__ChildObjectId__c,
			Apttus_Approval__Approval_Request__c.Apttus_Approval__Approver_Comments__c,Apttus_Approval__Approval_Request__c.Apttus_Approval__Approval_Status__c,
			Apttus_Approval__Approval_Request__c.Apttus_Approval__SubmissionComment1__c
			};
	}

	/**
	* @description Run a simple query to get records based on config id 
	*/
	public virtual List<Apttus_Approval__Approval_Request__c> selectByProdConfigId(Set<Id> prodConfigID) {
		return selectByProdConfigId(prodConfigID, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on config id  to get Approval_Request
	*/
	public virtual List<Apttus_Approval__Approval_Request__c> selectByProdConfigId(Set<Id> prodConfigID, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Approval__Approval_Request__c.Apttus_CQApprov__CartId__c + ' =:prodConfigID'))           
			.endConditions();           
		return new List<Apttus_Approval__Approval_Request__c>((List<Apttus_Approval__Approval_Request__c>)Database.query(qb.toSoqlString()));
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		
		if(selectorOptions.contains(Options.WITH_USER)) {
			builder.addRelatedFields(UsersSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_Approval__Actual_Approver__r');
		}        
		if (selectorOptions.contains(Options.FILTER_APPROVAL_REQUEST)) {
			builder.addConditions().add(new QueryBuilder.NullCondition(Apttus_Approval__Approval_Request__c.Apttus_Approval__ParentRequestId__c).notNull()).endConditions();
		}
		return builder;
	}

}