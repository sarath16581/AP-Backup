/* @author Seth Heang
 * @date 2020-11-05
 * @group Selector
 * @tag Selector
 * @tag Opp_Product_Classification__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class OpportunityProductClassificationSelector extends ApplicationSelector {
    public enum Options {
    }

    public static OpportunityProductClassificationSelector newInstance(){
        return (OpportunityProductClassificationSelector)Application.Selectors.newInstance(OpportunityProductClassificationSelector.class);
    }

    /**
	 * @description Integer Parameter to setLimit() of instance created
	 */
    public static OpportunityProductClassificationSelector newInstance(Integer recordLimit) {
        return (OpportunityProductClassificationSelector)Application.Selectors.newInstance(OpportunityProductClassificationSelector.class).setLimit(recordLimit);
    }

    /**
	 * @description Specifies the SObject API name: Opp_Product_Classification__c
	 */
    public virtual override SObjectType getSObjectType() {
		return Opp_Product_Classification__c.getSObjectType();
	}

    /**
	 * @description Specifies all OPC fields to be queried
	 */
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            Opp_Product_Classification__c.Id,
            Opp_Product_Classification__c.Jan_Schedule_Amount__c, 
            Opp_Product_Classification__c.Feb_Schedule_Amount__c, 
            Opp_Product_Classification__c.Mar_Schedule_Amount__c, 
            Opp_Product_Classification__c.Apr_Schedule_Amount__c,
            Opp_Product_Classification__c.May_Schedule_Amount__c,
            Opp_Product_Classification__c.Jun_Schedule_Amount__c,
            Opp_Product_Classification__c.Jul_Schedule_Amount__c,
            Opp_Product_Classification__c.Aug_Schedule_Amount__c,
            Opp_Product_Classification__c.Sep_Schedule_Amount__c,
            Opp_Product_Classification__c.Oct_Schedule_Amount__c,
            Opp_Product_Classification__c.Nov_Schedule_Amount__c,
            Opp_Product_Classification__c.Dec_Schedule_Amount__c,
            Opp_Product_Classification__c.Total_Actual_Revenue__c,
            Opp_Product_Classification__c.Total_Schedule_Amount__c,
            Opp_Product_Classification__c.Opportunity__c,
            Opp_Product_Classification__c.Financial_Year__c
		};
    }  
    
    /**
	 * @description Run a simple query to get records based on opportunity Id's
	 */
	public virtual Map<Id, Opp_Product_Classification__c> selectByOpportunity(Set<Id> opportunitiesIds) {
		return selectByOpportunity(opportunitiesIds, new Set<Object>());
    }
    
    /**
	 * @description Run a simple query to get records based on opportunity Id's
	 */
	public virtual Map<Id, Opp_Product_Classification__c> selectByOpportunity(Set<Id> opportunitiesIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
        .add(new QueryBuilder.SimpleCondition(Opp_Product_Classification__c.Opportunity__c + ' in :opportunitiesIds'))
        .endConditions();
        return new Map<Id, Opp_Product_Classification__c>((List<Opp_Product_Classification__c>)Database.query(qb.toSoqlString()));
    }
}