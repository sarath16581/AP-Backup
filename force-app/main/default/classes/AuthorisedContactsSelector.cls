/**
 * @author Snehil Jaiswal
 * @date 2021-06-22
 * @group Selector
 * @tag Selector
 * @tag Authorised Contact
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2024-04-25 - Vasu Gorakati - Added new method selectByCaseId
 */
public virtual inherited sharing class AuthorisedContactsSelector extends ApplicationSelector {

	public static AuthorisedContactsSelector newInstance() {
		return (AuthorisedContactsSelector)Application.Selectors.newInstance(AuthorisedContactsSelector.class);
	}

	public virtual override SObjectType getSObjectType() {
		return AuthorisedContacts__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			AuthorisedContacts__c.Id, AuthorisedContacts__c.Initial_Contact__c, AuthorisedContacts__c.Contact_Email__c, AuthorisedContacts__c.Contact_Mobile_Number__c,
			AuthorisedContacts__c.Contact_Phone_Number__c, AuthorisedContacts__c.First_Name__c, AuthorisedContacts__c.Last_Name__c, AuthorisedContacts__c.Contact_Type__c, 
			AuthorisedContacts__c.Notification_Required__c, AuthorisedContacts__c.Pref_Method_of_Contact__c 
		};
	}

	public virtual List<AuthorisedContacts__c> selectByCaseId(Set<Id> ids) {
		return selectByCaseId(ids,new Set<Object>());
	}

	/**
	 * @param ids the case ids
	 * @param selectorOptions
	 *
	 * @return
	 */
	public virtual List<AuthorisedContacts__c> selectByCaseId(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(AuthorisedContacts__c.Case__c + ' in :ids')).endConditions();
		return (List<AuthorisedContacts__c>)Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}

	public static AuthorisedContactsSelector newInstance(Set<SObjectField> fieldOverrides) {
		return (AuthorisedContactsSelector) Application.Selectors.newInstance(AuthorisedContactsSelector.class)
			.setFieldOverrides(fieldOverrides);
	}
	
	/*
	* this method returns records with matching case Ids
	* @param caseId - set of case ids
	* @param selecterOptions - selector options to augment result set
	*/
	public Map<Id,AuthorisedContacts__c> selectByCaseIdOrderByName(Set<Id> caseIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);  
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions.add(new QueryBuilder.SimpleCondition(AuthorisedContacts__c.Case__c + ' IN :caseIds'));
		conditions.endConditions();
		qb.addOrderDesc(AuthorisedContacts__c.Initial_Contact__c);
		qb.addOrderAsc(AuthorisedContacts__c.Calc_First_Name__c);
		return new Map<Id, AuthorisedContacts__c>((List<AuthorisedContacts__c>)Database.query(qb.toSoqlString()));
	}

}