/**************************************************
Type: Test class for OpportunityRevenueReportController
History:
--------------------------------------------------
2024-01-22Ken McGuire - Created
2024-07-31 		Ken McGuire	- added refresh revenue capability.
**************************************************/
@IsTest
private class OpportunityRevenueReportController_Test {
	@IsTest
	private static void testGetRevenueDataWithAccountHierarchy() {
       	// =====================================
		// Data Preparation
		// =====================================
		Account parentAcc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account relatedAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account childAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		childAccount.ParentId = parentAcc.Id;

		AccountRelationship__c accRelation = new AccountRelationship__c(ParentAccount__c = parentAcc.Id, RelatedAccount__c = relatedAccount.Id, Relationship__c='OPC');

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, parentAcc.Id, true)[0];
		oppRec.AccountId = parentAcc.Id;
		oppRec.DoNotUseAccountHierarchy__c = false;

		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbe= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];

		OpportunityLineItem oppProd = ApplicationTestDataFactory.getOpportunityLineItems(1, oppRec.Id, pbe.Id, true).get(0);
		oppProd.Quantity = 1;
		oppProd = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oppProd, new Map<String, Object>{'Product2Id' => prod.Id, 'Opportunity' => oppRec, 'Product2'=>prod});

        GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = parentAcc.Id, PrimaryProduct__c = prod.Id,
        FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(parentAcc.Id,prod.Id,'2023'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
        Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
        Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
        Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);

        GroupedAccountProductRevenue__c groupedRev2024 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = parentAcc.Id, PrimaryProduct__c = prod.Id,
        FinancialYear__c = 2024, UID__c = ProductRevenueService.getUID(parentAcc.Id,prod.Id,'2024'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
        Rev1__c = 440,Rev2__c = 550,Rev3__c = 660,Rev4__c = 770,
        Rev5__c = 880,Rev6__c = 990,Rev7__c = 1100,Rev8__c = 2200,
        Rev9__c = 3300,Rev10__c = 4400,Rev11__c = 5500,Rev12__c = 6600);
        
        GroupedRevenueSchedule__c existingSchedule = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__c = groupedRev2023.id,OpportunityProduct__c = oppProd.id,Opportunity__c = oppRec.id, Id = fflib_IDGenerator.generate(GroupedRevenueSchedule__c.getSObjectType()));
        GroupedRevenueSchedule__c createdSchedule = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__c = groupedRev2024.id,OpportunityProduct__c = oppProd.id,Opportunity__c = oppRec.id, Id = fflib_IDGenerator.generate(GroupedRevenueSchedule__c.getSObjectType()));

		// =====================================
		// Stubbing
		// =====================================        
		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		ProductRevenueService revenueService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
        ProductScheduleService scheduleService = (ProductScheduleService)MockUtility.mockUtility(ProductScheduleService.class);
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		AccountRelationshipSelector arSelector = (AccountRelationshipSelector)MockUtility.mockSelector(AccountRelationshipSelector.class);
		OpportunitiesSelector oppSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
		MockUtility.Mocks.when(accountsSelector.search((Map<String, Object>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(), (String)fflib_Match.anyObject(), (Schema.SObjectField)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(new List<Account>{parentAcc});
		MockUtility.Mocks.when(arSelector.selectByParent((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.when(arSelector.selectByOPCParentEndDateInFuture((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.when(oppSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.Id => oppRec});
		MockUtility.Mocks.when(revenueService.loadOpportunityInfo((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.Id => oppRec});
        MockUtility.Mocks.when(scheduleService.createUpdateRevenueSchedules((Set<Id>)fflib_Match.anyObject(),(boolean)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c>{existingSchedule,createdSchedule});
		MockUtility.Mocks.stopStubbing();
		
        productRevenueService.newInstance().OpportunityInfo.put(oppRec.id,oppRec);
		List<OpportunityRevenueReportController.RevenueData> revData = OpportunityRevenueReportController.getRevenueData(String.valueOf(oppRec.Id));
       	OpportunityRevenueReportController.RefreshRevenue(oppRec.id); 
        boolean hasPermission = OpportunityRevenueReportController.hasRefreshRevenuePermission();
        system.assertEquals(true,hasPermission,'User should have permission to refresh revenue');
		System.assert(!revData.isEmpty(), 'Controller failed to construct Revenue Data');
		System.assertEquals(parentAcc.Name, revData.get(0).companyName, 'Returned revenue data did not match the intended.');
	}
    
    @isTest
    private static void testPermissionDenied() {
        // Create a test user without any permission sets
        Profile p = [SELECT Id FROM Profile WHERE Name = 'BG Base' LIMIT 1]; 
        User noPermissionUser = new User(Alias = 'noperms', 
                                         Email='noperms@example.com', 
                                         EmailEncodingKey='UTF-8', 
                                         LastName='NoPermissions', 
                                         LanguageLocaleKey='en_US', 
                                         LocaleSidKey='en_US', 
                                         ProfileId = p.Id, 
                                         TimeZoneSidKey='Australia/Brisbane', 
                                         Username='noperms@example.com');
        
        // Insert the user
        insert noPermissionUser;
        
        // Run test as the created user without permission sets
        System.runAs(noPermissionUser) {
            boolean hasPermission = OpportunityRevenueReportController.hasRefreshRevenuePermission();
            System.assertEquals(false, hasPermission, 'User should not have permission to refresh revenue');
        }
    }

}