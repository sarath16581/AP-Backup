/**
* @author Swati Mogadala
* @date 2024-10-10
* @group Selector
* @tag Selector
* @tag Revenue by Billing Account
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2024-08-01 - Swati Mogadala - Created 
*/
public virtual inherited sharing class RevenueByBillingAccountSelector extends ApplicationSelector {
	public static RevenueByBillingAccountSelector newInstance() {
		return (RevenueByBillingAccountSelector)Application.Selectors.newInstance(RevenueByBillingAccountSelector.class);
	}
	
	public virtual override SObjectType getSObjectType() {
		return Revenue_by_Billing_Account__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			Revenue_by_Billing_Account__c.Id,Revenue_by_Billing_Account__c.Customer_Mismatch__c
		};
	}

	/**
	 * @description Query duplicates revenues
	 */
	public List<Revenue_by_Billing_Account__c> selectByDups()
	{
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.CompareCondition(Revenue_by_Billing_Account__c.Customer_Mismatch__c).eq('Duplicate')).endConditions();

				
		return (List<Revenue_by_Billing_Account__c>)Database.query((qb.toSoqlString()));

	}
}