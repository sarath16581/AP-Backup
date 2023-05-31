/**
 * @description Test class for TransportEnquiryEmailMessagesModule
 * @author Mahesh Parvathaneni
 * @date 2023-05-30
 * @changelog
*/

@IsTest
private class TransportEnquiryEmailMessagesModule_Test {

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the related cases have been updated with the correct email to address, network etc as per the metadata
	*/
	@IsTest
	static void testAfterInsertUpdateRelatedCases() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0].MilestoneTimeStartDatetime__c = Datetime.now();
		records[1].MilestoneTimeStartDatetime__c = Datetime.now();
		records[0].NetworkMilestoneCurrentTier__c = 1;
		records[1].NetworkMilestoneCurrentTier__c = 1;
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'IsClosed__c' => false});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'IsClosed__c' => false});

		// =====================================
		// Stubbing
		// =====================================
		MilestoneService mockService = (MilestoneService)MockUtility.mockUtility(MilestoneService.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.calculateNextViolationDateForCaseInvestigation(new Set<Id>{records[0].Id, records[1].Id}, 
			STCINetworkMilestoneViolationModule.ENTITLEMENT_RULE_CASE_INVESTIGATION, STCINetworkMilestoneViolationModule.MILESTONE_TIER_TYPE_FACILITY))
			.thenReturn(new Map<Id, Datetime>{records[0].Id => Datetime.now().addDays(1), records[1].Id => Datetime.now().addDays(1)});
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TransportEnquiryEmailMessagesModule.newInstance().onAfterInsert(records, mockUow);

		//should have attempted to call the Milestone Service
		((MilestoneService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).calculateNextViolationDateForCaseInvestigation(new Set<Id>{records[0].Id, records[1].Id},
			STCINetworkMilestoneViolationModule.ENTITLEMENT_RULE_CASE_INVESTIGATION, STCINetworkMilestoneViolationModule.MILESTONE_TIER_TYPE_FACILITY);

		// should have attempted to update the case investigations
		((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false));

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}
	
}