/**
 * @description       : Test class for STCINetworkMilestoneViolationModule
 * @author            : Mahesh Parvathaneni
 * @domain            : Case Investigation
 * @changelog
 * 2022-02-08 - Mahesh Parvathaneni - created
 **/

@IsTest
private class STCINetworkMilestoneViolationModule_Test {

	/**
	 * Scenario: Testing the before insert trigger event
	 * Test to ensure the network violation fields are set on the records before insert when records are in open statuses
	 */
	@IsTest
	static void testBeforeInsertSetNetworkViolationFields() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0].MilestoneTimeStartDatetime__c = null;
		records[1].MilestoneTimeStartDatetime__c = null;
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'IsClosed__c' => false});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'IsClosed__c' => false});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCINetworkMilestoneViolationModule.newInstance().onBeforeInsert(records, mockUow);

		// make sure milestone time start date time has been populated
		System.assertNotEquals(null, records[0].MilestoneTimeStartDatetime__c, 'Expected milestone time start time set on case investigation but returned null');
		System.assertNotEquals(null, records[1].MilestoneTimeStartDatetime__c, 'Expected milestone time start time set on case investigation but returned null');

		Test.stopTest();
	}

	/**
	* Scenario: Testing the before update trigger event
	* Test to ensure the network violation fields are reset on the records before update when the records are in closed statuses 
	*/
	@IsTest
	static void testBeforeUpdateSetNetworkViolationFields() {

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
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'IsClosed__c' => true});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'IsClosed__c' => true});

		List<CaseInvestigation__c> oldRecords = new List<CaseInvestigation__c>{records[0].clone(true),records[1].clone(true)};
		oldRecords[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[0], new Map<String, Object>{'IsClosed__c' => false});
		oldRecords[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[1], new Map<String, Object>{'IsClosed__c' => false});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCINetworkMilestoneViolationModule.newInstance().onBeforeUpdate(records, new Map<Id, CaseInvestigation__c>(oldRecords), mockUow);

		// make sure milestone time start date time has been populated
		System.assertEquals(null, records[0].MilestoneTimeStartDatetime__c, 'Expected milestone time start time reset on case investigation but returned value');
		System.assertEquals(null, records[1].MilestoneTimeStartDatetime__c, 'Expected milestone time start time reset on case investigation but returned value');

		Test.stopTest();
	}

	/**
	* Scenario: Testing the after insert trigger event
	* Test to ensure the next milestone violation date time are calculated on the records after insert when the records have milestone timer start date populated 
	*/
	@IsTest
	static void testAfterInsertUpdateViolationDatetimeFields() {

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
		records[0].NetworkMilestoneCurrentViolatedTier__c = null;
		records[1].NetworkMilestoneCurrentViolatedTier__c = null;
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

		STCINetworkMilestoneViolationModule.newInstance().onAfterInsert(records, mockUow);

		//should have attempted to call the Milestone Service
		((MilestoneService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).calculateNextViolationDateForCaseInvestigation(new Set<Id>{records[0].Id, records[1].Id},
			STCINetworkMilestoneViolationModule.ENTITLEMENT_RULE_CASE_INVESTIGATION, STCINetworkMilestoneViolationModule.MILESTONE_TIER_TYPE_FACILITY);

		// should have attempted to update the case investigations
		((ApplicationDatabase)MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eqBoolean(false));

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	* Scenario: Testing the after update trigger event
	* Test to ensure the next milestone violation date time are calculated on the records after update when the records are updated with the current violated tiers 
	*/
	@IsTest
	static void testAfterUpdateUpdateViolationDatetimeFields() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0].MilestoneTimeStartDatetime__c = Datetime.now().addDays(-1);
		records[1].MilestoneTimeStartDatetime__c = Datetime.now().addDays(-1);
		records[0].NetworkMilestoneNextViolationDatetime__c = Datetime.now();
		records[1].NetworkMilestoneNextViolationDatetime__c = Datetime.now();
		records[0].NetworkMilestoneCurrentViolatedTier__c = 2;
		records[1].NetworkMilestoneCurrentViolatedTier__c = 2;

		List<CaseInvestigation__c> oldRecords = new List<CaseInvestigation__c>{records[0].clone(true),records[1].clone(true)};
		oldRecords[0].NetworkMilestoneCurrentViolatedTier__c = 1;
		oldRecords[1].NetworkMilestoneCurrentViolatedTier__c = 1;
		

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

		STCINetworkMilestoneViolationModule.newInstance().onAfterUpdate(records, new Map<Id, CaseInvestigation__c>(oldRecords), mockUow);

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