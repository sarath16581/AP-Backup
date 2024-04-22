/**
 * @description Domain Module to handle At_Risk_Business__c object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding TriggerHandler class
 * @author Pratyush Chalasani
 * @group Domain
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 *
 */
public inherited sharing class AtRiskBusinessRevenueModule extends ApplicationModule {
	@testVisible
	private static Date calculationDate = System.today();
	
	public static AtRiskBusinessRevenueModule newInstance() {
		return (AtRiskBusinessRevenueModule) Application.Utilities.newInstance(AtRiskBusinessRevenueModule.class);
	}

	// Setup which trigger events this module should respond to
	public AtRiskBusinessRevenueModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		calculateRevenueAtRisk((List<At_Risk_Business__c>) records, (Map<Id, At_Risk_Business__c>) existingRecords);
	}
	
	private void calculateRevenueAtRisk(List<At_Risk_Business__c> records, Map<Id, At_Risk_Business__c> existingRecords){
		Map<String, List<String>> financialYearMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(calculationDate);

		List<At_Risk_Business__c> filteredRecords = new List<At_Risk_Business__c>();

		Set<Id> organisationIDs = new Set<Id>();

		Map<Id, List<String>> revenueProductMap = new Map<Id, List<String>>();

		// Filter records which have changed Scale or Product ID fields,
		// and collect account IDs
		for (At_Risk_Business__c arb: records) {
			At_Risk_Business__c oldARB = existingRecords.get(arb.Id);

			if ((arb.Scale__c != oldARB.Scale__c) || (arb.Products_IDs__c != oldARB.Products_IDs__c) || (arb.Recalculate_Revenue__c == true)) {
				// Reset recalculation flag
				arb.Recalculate_Revenue__c = false;

				if (arb.Scale__c == 'Whole of Business') {
					arb.Products_IDs__c = null;
					arb.Products__c = null;
				}

				if (String.isNotBlank(arb.Products_IDs__c)) {
					revenueProductMap.put(arb.Id, arb.Products_IDs__c.split(';'));
				}
				
				organisationIDs.add(arb.Legal_Entity_Name__c);

				filteredRecords.add(arb);
			}
		}

		if (!filteredRecords.isEmpty()) {
			List<Budget_and_Revenue__c> revenueList = BudgetAndRevenueSelector.newInstance().selectByOrganisationId(organisationIDs, financialYearMonths.keySet());

			Map<Id, List<Budget_and_Revenue__c>> orgRevenueMap = new Map<Id, List<Budget_and_Revenue__c>>();

			for (Budget_and_Revenue__c revenue: revenueList) {
				List<Budget_and_Revenue__c> orgRevenues = orgRevenueMap.get(revenue.Organisation__c);

				if (orgRevenues == null || orgRevenues.isEmpty()) {
					orgRevenues = new List<Budget_and_Revenue__c>();

					orgRevenueMap.put(revenue.Organisation__c, orgRevenues);
				}

				orgRevenues.add(revenue);
			}

			// Here is where we calculate the total revenue in the 12 months to date for each ARB record
			for (At_Risk_Business__c arb: records) {
				// Revenue total for each financial year record
				Map<String, Decimal> fyRevenue = new Map<String, Decimal>();

				// first set everything to zero
				for (String fy: financialYearMonths.keySet()) {
					fyRevenue.put(fy, 0);
				}

				// Get the revenue records for the linked account
				List<Budget_and_Revenue__c> revenues = orgRevenueMap.get(arb.Legal_Entity_Name__c);

				// Get the list of products selected for this ARB record
				List<Id> productIDs = revenueProductMap.get(arb.Id);

				Decimal totalRevenue = 0;
				
				if (revenues != null) {
					for (Budget_and_Revenue__c rev: revenues) {
						if ((arb.Scale__c == 'Whole of Business') || (productIDs != null && productIDs.contains(String.valueOf(rev.Product__c)))) {
							Decimal revenue = fyRevenue.get(rev.Financial_Year__c);
				
							List<String> months = financialYearMonths.get(rev.Financial_Year__c);
				
							for (String m: months) {
								Decimal r = (Decimal)(rev.get(m + '_Revenue_Amount__c'));
				
								if (r != null) {
									revenue += r;
								}
							}
				
							fyRevenue.put(rev.Financial_Year__c, revenue);
						}
					}

					for (String year: fyRevenue.keySet()) {
						totalRevenue += fyRevenue.get(year);
					}
				}

				arb.Date_of_Revenue_Calculation__c = calculationDate;
				arb.Value_of_Business_at_Risk__c = totalRevenue;
			}
		}
	}
}