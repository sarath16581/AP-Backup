/**
* @author Pratyush Chalasani
* @date 2023-04-21
* @group Selector
* @tag Selector
* @tag Profile SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2023-04-21 - Pratyush Chalasani - Created
*/
public virtual inherited sharing class BudgetAndRevenueSelector extends ApplicationSelector {
	public static BudgetAndRevenueSelector newInstance() {
		return (BudgetAndRevenueSelector)Application.Selectors.newInstance(BudgetAndRevenueSelector.class);
	}
	
	public virtual override SObjectType getSObjectType() {
		return Budget_and_Revenue__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Budget_and_Revenue__c.Id, Budget_and_Revenue__c.Organisation__c, Budget_and_Revenue__c.Product__c, Budget_and_Revenue__c.Financial_Year__c,
			Budget_and_Revenue__c.Jan_Revenue_Amount__c, Budget_and_Revenue__c.Feb_Revenue_Amount__c, Budget_and_Revenue__c.Mar_Revenue_Amount__c, Budget_and_Revenue__c.Apr_Revenue_Amount__c, Budget_and_Revenue__c.May_Revenue_Amount__c, Budget_and_Revenue__c.Jun_Revenue_Amount__c,
			Budget_and_Revenue__c.Jul_Revenue_Amount__c, Budget_and_Revenue__c.Aug_Revenue_Amount__c, Budget_and_Revenue__c.Sep_Revenue_Amount__c, Budget_and_Revenue__c.Oct_Revenue_Amount__c, Budget_and_Revenue__c.Nov_Revenue_Amount__c, Budget_and_Revenue__c.Dec_Revenue_Amount__c 
		};
	}

	/**
	 * @description Query revenues by specific account
	 */
	public List<Budget_and_Revenue__c> selectByOrganisationId(Id organisationId) {
        QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(Budget_and_Revenue__c.Organisation__c + ' = :organisationId')).endConditions();

		return (List<Budget_and_Revenue__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Query revenues by accounts and financial years
	 */
	public List<Budget_and_Revenue__c> selectByOrganisationId(Set<Id> organisationIds, Set<String> financialYears) {
        QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(Budget_and_Revenue__c.Organisation__c + ' in :organisationIds')).endConditions();

		if (!financialYears.isEmpty()) {
			qb.addConditions().add(new QueryBuilder.SimpleCondition(Budget_and_Revenue__c.Financial_Year__c + ' in :financialYears')).endConditions();
		}

		return (List<Budget_and_Revenue__c>)Database.query(qb.toSoqlString());
	}
}