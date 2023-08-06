/*@author Yatika Bansal
*@date 2023-21-03
*@tag Selector
*@tag APT_Credit_Assessment__c
*@domain Core
*@description A very simple selector class that sits in the base domain
Ken McGuire 2023.04.19 Proposal field migration to opportunity
*/
public virtual inherited sharing class APT_CreditAssessmentSelector extends ApplicationSelector{

	public static APT_CreditAssessmentSelector newInstance() {
		return (APT_CreditAssessmentSelector)Application.Selectors.newInstance(APT_CreditAssessmentSelector.class);
	}

	public static APT_CreditAssessmentSelector newInstance(Integer recordLimit) {
		return (APT_CreditAssessmentSelector)Application.Selectors.newInstance(APT_CreditAssessmentSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return APT_Credit_Assessment__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			APT_Credit_Assessment__c.Id,APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c,APT_Credit_Assessment__c.APT_Status__c, APT_Credit_Assessment__c.APT_Proposal__c
		};
	}

	 /**
	 * @description Run a query to get records based on proposal id and (status or credit assessment status)
	 */
	public List<APT_Credit_Assessment__c> selectByProposalAndAssessStatus(Set<Id> proposalIds, Set<String> assessmentStatuses) {
		return selectByProposalAndAssessStatus(proposalIds, assessmentStatuses, new Set<Object>());
	}

	/**
	 * @description Run a query to get records based on proposal id and (status or credit assessment status)
	 */
	public List<APT_Credit_Assessment__c> selectByProposalAndAssessStatus(Set<Id> proposalIds, Set<String> assessmentStatuses, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.APT_Proposal__c + ' = :proposalIds')).endConditions();
		qb.addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c  + ' = :assessmentStatuses')).setConditionOrder('1 AND 2').endConditions();
		return (List<APT_Credit_Assessment__c>)Database.query(qb.toSoqlString());
	}
}