/**
 @description Controller for LWC on At Risk Business page
 @author Pratyush Chalasani
 @date 2023-04-20
 @changelog: 
 2023-04-20 - Pratyush Chalasani - Created
**/
public with sharing class AtRiskBusinessController {
	@testVisible
	private static Date revenueDate = System.today();

	@testVisible
	private static At_Risk_Business__c arb;

	public class ProductData {
		@AuraEnabled
		public List<String> selectedIDs = new List<String>();
		@AuraEnabled
		public List<ProductItem> products = new List<ProductItem>();
	}

	public class ProductItem {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String code;
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String level4Name;
		@AuraEnabled
		public Decimal revenue;
	}

	@AuraEnabled(cacheable=true)
	public static ProductData getProducts(String arbId) {
		try {
			ProductData data = new ProductData();

			At_Risk_Business__c arb = AtRiskBusinessSelector.newInstance().selectById(new Set<Id>{ arbId })[0];
	
			BudgetAndRevenueSelector revenueSelector = BudgetAndRevenueSelector.newInstance();
	
			Map<String, List<String>> financialYearMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(revenueDate);

			List<Budget_and_Revenue__c> revenues = revenueSelector.selectByOrganisationId(new Set<Id>{arb.Legal_Entity_Name__c}, financialYearMonths.keySet());

			Map<Id, Decimal> productRevenueMap = new Map<Id, Decimal>();
	
			Set<Id> productIDs = new Set<Id>();
	
			if (String.isNotBlank(arb.Product_IDs__c)) {
				data.selectedIDs = arb.Product_IDs__c.split(';');
				
				for (String id: productIDs) {
					productIDs.add(id);
				}
			}
	
			for (Budget_and_Revenue__c rev: revenues) {
				Id productId = rev.Product__c;

				productIDs.add(productId);

				Decimal productRevenue = productRevenueMap.get(productId);

				productRevenueMap.put(productId, addRevenue(productRevenue, rev, financialYearMonths));
			}
	
			ProductsSelector productsSelector = ProductsSelector.newInstance(0, new Map<Schema.SObjectType,Set<Schema.SObjectField>>{Product2.SObjectType => new Set<Schema.SObjectField>{Product2.ProductCode, Product2.APT_Product_Type__c, Product2.Product_Level_1__c, Product2.Product_Level_2__c, Product2.Product_Level_3__c, Product2.Product_Level_4__c}});

			List<Product2> products = productsSelector.selectByIdOrderByName(productIDs, null);

			for (Product2 product: products) {
				ProductItem item = new ProductItem();

				item.id         = product.Id;
				item.code       = product.ProductCode;
				item.name       = product.Name;
				item.type       = product.APT_Product_type__c;
				item.level4Name = product.Product_Level_4__c;
				item.revenue    = productRevenueMap.get(product.Id);

				data.products.add(item);
			}

			return data;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@testVisible
	private static Decimal addRevenue(Decimal existingRevenue, Budget_and_Revenue__c revenueRecord, Map<String, List<String>> financialYearMonths) {
		List<String> monthNames = financialYearMonths.get(revenueRecord.Financial_Year__c);

		Decimal addedRevenue = 0;

		for (String month: monthNames) {
			addedRevenue += ((Decimal)revenueRecord.get(month + '_Revenue_Amount__c'));
		}

		return (existingRevenue != null ? (existingRevenue + addedRevenue) : addedRevenue);
	}

    @AuraEnabled
	public static void saveSelection(String arbId, List<String> productIds) {
		// Converting to Set<Id> in order to pass it to selector
		Set<Id> productIdSet = new Set<Id>();

		for (String productId: productIds) {
			productIdSet.add(Id.valueOf(productId));
		}

		try {
			arb = new At_Risk_Business__c(Id = arbId);

			if (productIDs.isEmpty()) {
				arb.Product_IDs__c = null;
				arb.Products__c = null;
			} else {
				ProductsSelector productsSelector = ProductsSelector.newInstance(0, new Map<Schema.SObjectType,Set<Schema.SObjectField>>{Product2.SObjectType => new Set<Schema.SObjectField>{Product2.Name}});

				List<String> productNames = new List<String>();

				for (Product2 prod: productsSelector.selectByIdOrderByName(productIdSet, null)) {
					productNames.add(prod.Name);
				}

				arb.Product_IDs__c = String.join(productIds, ';');
				arb.Products__c = String.join(productNames, ';');
			}

			if (!Test.isRunningTest()) ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{arb});
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

}