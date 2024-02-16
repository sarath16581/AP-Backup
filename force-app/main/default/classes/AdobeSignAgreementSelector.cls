/**
* @author Boris Bachovski
* @date 2024-01-31
* @changelog
* 2024-01-31 - Boris Bachovski - Created 
*/
public inherited sharing class AdobeSignAgreementSelector extends ApplicationSelector {

	public enum Options {}

	public static AdobeSignAgreementSelector newInstance() {
		return (AdobeSignAgreementSelector)Application.Selectors.newInstance(AdobeSignAgreementSelector.class);
	}

	public static AdobeSignAgreementSelector newInstance(Integer recordLimit) {
		return (AdobeSignAgreementSelector)Application.Selectors.newInstance(AdobeSignAgreementSelector.class).setLimit(recordLimit);
	}

	public static AdobeSignAgreementSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		AdobeSignAgreementSelector selector = (AdobeSignAgreementSelector) Application.Selectors.newInstance(AdobeSignAgreementSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public static AdobeSignAgreementSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AdobeSignAgreementSelector selector = (AdobeSignAgreementSelector) Application.Selectors.newInstance(AdobeSignAgreementSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return echosign_dev1__SIGN_Agreement__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			echosign_dev1__SIGN_Agreement__c.Id, echosign_dev1__SIGN_Agreement__c.Name, echosign_dev1__SIGN_Agreement__c.echosign_dev1__Account__c, echosign_dev1__SIGN_Agreement__c.ApttusContract__c, echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c	
		};
	}

	public List<echosign_dev1__SIGN_Agreement__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<echosign_dev1__SIGN_Agreement__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(echosign_dev1__SIGN_Agreement__c.Id + ' in :ids')).endConditions();
		return (List<echosign_dev1__SIGN_Agreement__c>)Database.query(qb.toSoqlString());
	}

	public List<echosign_dev1__SIGN_Agreement__c> selectByParentApttusContract(Set<Id> parentIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(echosign_dev1__SIGN_Agreement__c.ApttusContract__c + ' in :parentIds')).endConditions();
		return (List<echosign_dev1__SIGN_Agreement__c>)Database.query(qb.toSoqlString());
	}

	public List< echosign_dev1__SIGN_Agreement__c> selectOutForSignatureByApttusContractId(Set<Id> apttusContractIds, Set<Object>selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		conditions
				.add(new QueryBuilder.SimpleCondition(echosign_dev1__SIGN_Agreement__c.ApttusContract__c + ' IN :apttusContractIds'))
				.add(new QueryBuilder.CompareCondition(echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c).eq('Out for Signature'))
				.add(new QueryBuilder.CompareCondition(echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c).eq('Waiting for Counter-Signature'));
				conditions.setConditionOrder('1 AND (2 OR 3)').endConditions();

		qb.addOrder(new QueryBuilder.Order(echosign_dev1__SIGN_Agreement__c.CreatedDate).setSortingOrderDesc());

		return (List<echosign_dev1__SIGN_Agreement__c>) Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		return builder;
	}
}