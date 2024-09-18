/**************************************************
Type:         Selector class for GroupedAccountProductRevenue__c
@test GroupedAccountProductRevSelector_Test
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
public virtual inherited sharing class GroupedAccountProductRevenueSelector extends ApplicationSelector {
	public enum Options {
		WITH_ACCOUNT,
		WITH_PRODUCT
	}

	public static GroupedAccountProductRevenueSelector newInstance() {
		return (GroupedAccountProductRevenueSelector)Application.Selectors.newInstance(GroupedAccountProductRevenueSelector.class);
	}
	public static GroupedAccountProductRevenueSelector newInstance(Integer recordLimit) {
		return (GroupedAccountProductRevenueSelector)Application.Selectors.newInstance(GroupedAccountProductRevenueSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return GroupedAccountProductRevenue__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				GroupedAccountProductRevenue__c.Id, 
				GroupedAccountProductRevenue__c.UID__c,
				GroupedAccountProductRevenue__c.AnchorOrganisation__c, 
				GroupedAccountProductRevenue__c.PrimaryProduct__c,
				GroupedAccountProductRevenue__c.FinancialYear__c,
				GroupedAccountProductRevenue__c.Rev1__c,
				GroupedAccountProductRevenue__c.Rev2__c,
				GroupedAccountProductRevenue__c.Rev3__c,
				GroupedAccountProductRevenue__c.Rev4__c,
				GroupedAccountProductRevenue__c.Rev5__c,
				GroupedAccountProductRevenue__c.Rev6__c,
				GroupedAccountProductRevenue__c.Rev7__c,
				GroupedAccountProductRevenue__c.Rev8__c,
				GroupedAccountProductRevenue__c.Rev9__c,
				GroupedAccountProductRevenue__c.Rev10__c,
				GroupedAccountProductRevenue__c.Rev11__c,
				GroupedAccountProductRevenue__c.Rev12__c,
 				GroupedAccountProductRevenue__c.Total_FY__c                
		};
	}

	public Map<Id, GroupedAccountProductRevenue__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public Map<Id, GroupedAccountProductRevenue__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.Id + ' in :ids')).endConditions();
		return new Map<Id, GroupedAccountProductRevenue__c>((List<GroupedAccountProductRevenue__c>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, GroupedAccountProductRevenue__c> selectByAnchorOrganisationIds(Set<Id> organisationIds) {
		return selectByAnchorOrganisationIds(organisationIds, new Set<Object>());
	}

	public Map<Id, GroupedAccountProductRevenue__c> selectByAnchorOrganisationIds(Set<Id> organisationIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.AnchorOrganisation__c + ' in :organisationIds')).endConditions();
		qb.addOrderDesc('CreatedDate');
		return new Map<Id, GroupedAccountProductRevenue__c>((List<GroupedAccountProductRevenue__c>)Database.query(qb.toSoqlString()));
	}
	
	public Map<Id, GroupedAccountProductRevenue__c> selectByAnchorOrganisationAndProductForFY(Set<Id> accountIds, Set<Id> productIds, Integer FY) {
		Set<Object> selectorOptions = new Set<Object>{
			Options.WITH_ACCOUNT,
			Options.WITH_PRODUCT
		};
		
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.AnchorOrganisation__c + ' IN :accountIds'))
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.PrimaryProduct__c + ' IN :productIds'))
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.FinancialYear__c + ' = :FY'))
			.endConditions();
		
		return new Map<Id, GroupedAccountProductRevenue__c>((List<GroupedAccountProductRevenue__c>)Database.query(qb.toSoqlString()));
	}
	
	/**
	 * @description Query revenues by accounts and products and financial years
	 */
	public Map<Id, GroupedAccountProductRevenue__c> selectByUniqueIds(Set<String> uniqueIds) {

		Integer min = 0;
		Integer max = 0;

		for (String uid : uniqueIds) {
			Integer fy = Integer.valueOf(uid.right(4));
			
			if (min == 0 || fy < min) {
				min = fy;
			}

			if (max == 0 || fy > max) {
				max = fy;
			}
		}

		return selectByUniqueIdsAndFY(uniqueIds, min, max);

		// QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.UID__c + ' in :uniqueIds')).endConditions();
		// return new Map<Id, GroupedAccountProductRevenue__c>((List<GroupedAccountProductRevenue__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Query revenues by accounts and products and financial years - OPTIMISED
	 */
	public Map<Id, GroupedAccountProductRevenue__c> selectByUniqueIdsAndFY(Set<String> uniqueIds, Integer minFY, Integer maxFY) {
		QueryBuilder qb = newQueryBuilder()
			.addConditions()
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.UID__c + ' in :uniqueIds'))
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.FinancialYear__c + ' >= :minFY'))
			.add(new QueryBuilder.SimpleCondition(GroupedAccountProductRevenue__c.FinancialYear__c + ' <= :maxFY'))
			.endConditions();
		return new Map<Id, GroupedAccountProductRevenue__c>((List<GroupedAccountProductRevenue__c>)Database.query(qb.toSoqlString()));
	}


	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'AnchorOrganisation__r');
		}

		if(selectorOptions.contains(Options.WITH_PRODUCT)) {
			builder.addRelatedFields(ProductsSelector.newInstance().newQueryBuilder(), 'PrimaryProduct__r');
		}

		return builder;
	}

}