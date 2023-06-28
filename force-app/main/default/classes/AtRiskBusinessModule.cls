/**
 * @description Domain Module to handle At_Risk_Business__c object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Pratyush Chalasani
 * @group Domain
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 *
 */
public inherited sharing class AtRiskBusinessModule extends ApplicationDomain.Module {
	private static List<String> monthNames = new List<String>{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

	public static AtRiskBusinessModule newInstance() {
		return (AtRiskBusinessModule) Application.Utilities.newInstance(AtRiskBusinessModule.class);
	}

	// Setup which trigger events this module should respond to
	public AtRiskBusinessModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		calculateRevenueAtRisk((List<At_Risk_Business__c>) records, (Map<Id, At_Risk_Business__c>) existingRecords, uow);
	}
	
	private void calculateRevenueAtRisk(List<At_Risk_Business__c> records, Map<Id, At_Risk_Business__c> existingRecords, ApplicationUnitOfWork uow){
		Map<String, List<String>> financialYearMonths = getFinancialYearsAndMonths(System.today());

		List<At_Risk_Business__c> recordsToUpdate = new List<At_Risk_Business__c>();

		Set<Id> organisationIDs = new Set<Id>();

		Map<Id, List<String>> revenueProductMap = new Map<Id, List<String>>();

		// First find all account and product IDs
		for (At_Risk_Business__c arb: records) {
			if (arb.Scale__c == 'Whole of Business') {
				arb.Product_IDs__c = null;
				arb.Products__c = null;
			}

			if (String.isNotBlank(arb.Product_IDs__c)) {
				revenueProductMap.put(arb.Id, arb.Product_IDs__c.split(';'));
			}
			
			organisationIDs.add(arb.Legal_Entity_Name__c);
		}

		List<Budget_and_Revenue__c> revenueList = BudgetAndRevenueSelector.newInstance().selectByOrganisationId(organisationIDs, financialYearMonths.keySet(), null);

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

			Decimal totalRevenue = 0;

			for (String year: fyRevenue.keySet()) {
				totalRevenue += fyRevenue.get(year);
			}

			arb.Date_of_Revenue_Calculation__c = System.today();
			arb.Value_of_Business_at_Risk__c = totalRevenue;
		}
	}

	/*
	 * @description Given a date, return the financial years and names of months going back 12 months (from before the month of the given date)
	 */
	@testVisible
	public static Map<String, List<String>> getFinancialYearsAndMonths(Date atRiskDate) {
		Integer year = atRiskDate.year();
		Integer month = atRiskDate.month();

		Map<String, List<String>> financialYearMonths = new Map<String, List<String>>();

		if (month == 7) {
			financialYearMonths.put(String.valueOf(year - 1), monthNames);
		} else {
			List<String> previousFYMonths = new List<String>();
			List<String> currentFYMonths = new List<String>();
	
			if (month <= 6) {
				for (Integer m = 6; m < 12; m++) {
					currentFYMonths.add(monthNames[m]);
				}
				for (Integer m = 0; m < (month - 1); m++) {
					currentFYMonths.add(monthNames[m]);
				}
				for (Integer m = (month - 1); m < 6; m++) {
					previousFYMonths.add(monthNames[m]);
				}
			} else {
				for (Integer m = 6; m < (month - 1); m++) {
					currentFYMonths.add(monthNames[m]);
				}
				
				for (Integer m = (month - 1); m < 12; m++) {
					previousFYMonths.add(monthNames[m]);
				}
				for (Integer m = 0; m < 6; m++) {
					previousFYMonths.add(monthNames[m]);
				}
				
			}
	
			financialYearMonths.put(String.valueOf(year - 1), previousFYMonths);
			financialYearMonths.put(String.valueOf(year), currentFYMonths);
		}

		return financialYearMonths;
	}
}