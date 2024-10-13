/**
 * @description Test class for CaseUnifiedMilestoneModule module
 * @author George Nguyen
 * @date 2024-10-09
 * @changelog
 * 2024-10-09 - George Nguyen - Created.
 */
@IsTest
class CaseUnifiedMilestoneModuleTest {

	@IsTest
	static void testInitialisation() {
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name =: SSSWConstants.UNIFIED_ENTITLEMENTS LIMIT 1 ];
		List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(1, true,SSSWConstants.UNIFIED_ENTITLEMENTS,sla.Id,orgAaccounts[0].Id));
		EntitlementsSelector mockEntitlementSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementSelector.selectByNameAndAccountName((Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}))).thenReturn(entitlements);
		MockUtility.Mocks.stopStubbing();

		CaseUnifiedMilestoneModule module = CaseUnifiedMilestoneModule.newInstance();
		System.assertEquals(entitlements[0].Id, module.unifiedEntitlementId, 'should return the correct entitlement id');

		((EntitlementsSelector)MockUtility.Mocks.verify(mockEntitlementSelector, MockUtility.Mocks.times(1))).selectByNameAndAccountName((Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}));
	}	

	
	/*
		This test method focuses on testing the Unified Milestones only
	*/
	@IsTest
	static void testInsertUnifiedMilestones() {
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name =: SSSWConstants.UNIFIED_ENTITLEMENTS LIMIT 1 ];
		List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(1, true,SSSWConstants.UNIFIED_ENTITLEMENTS,sla.Id,orgAaccounts[0].Id));
		EntitlementsSelector mockEntitlementSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		Id unifiedInvestigationRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME).getRecordTypeId();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementSelector.selectByNameAndAccountName(
																		(Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), 
																		(Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS})
																	)).thenReturn(entitlements);
		MockUtility.Mocks.stopStubbing();

		List<Case> caseList = ApplicationTestDataFactoryCase.getCases(1, true);
		caseList[0].RecordTypeId = unifiedInvestigationRecordTypeId;
		caseList[0].Type = SSSWConstants.INVESTIGATION;
		caseList[0].EntitlementId = null;

		Test.startTest();
		CaseUnifiedMilestoneModule module = CaseUnifiedMilestoneModule.newInstance();
		module.onBeforeInsert(caseList, mockUow);
		Test.stopTest();

		System.assertEquals(module.unifiedEntitlementId, caseList[0].EntitlementId, 'Should be set to the unified entitlement id');
	}

	/*
		This test method focuses on testing the Unified Milestones only
	*/
	@IsTest
	static void testUpdateUnifiedMilestones() {
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name =: SSSWConstants.UNIFIED_ENTITLEMENTS LIMIT 1 ];
		List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(1, true,SSSWConstants.UNIFIED_ENTITLEMENTS,sla.Id,orgAaccounts[0].Id));
		EntitlementsSelector mockEntitlementSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector)MockUtility.mockSelector(CaseMilestonesSelector.class);
		ApplicationDatabase mockApplicationDatabase = MockUtility.mockDatabase();

		Id unifiedInvestigationRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME).getRecordTypeId();
		Id unifiedGeneralEnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME).getRecordTypeId();

		List<String> closedStatus = new List<String>(Utility.getCaseClosedStatus());
		MilestoneType milestoneType = ApplicationTestDataFactory.getMilestoneTypes(1, true)[0];

		Map<Id, Case> oldMap = new Map<Id, Case>();
		List<Case> caseList = new List<Case>();
		Case case1 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case1 = (Case)ApplicationTestDataFactory.setUnwritableFields(case1, new Map <String, Object>{ 'CreatedDate' => Datetime.now().addDays(-3)}); // simulating an older date
		case1.Type = SSSWConstants.CASE_TYPE_INVESTIGATION;
		case1.RecordTypeId = unifiedGeneralEnquiryRecordTypeId;
		caseList.add(case1);

		Case oldCase1 = case1.clone(true, true, true, true);
		oldCase1.Type = SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY;
		oldMap.put(oldCase1.Id, oldCase1);
		CaseMilestone caseMilestoneCase1 = ApplicationTestDataFactory.getCaseMilestones(1, true, false, false, milestoneType.Id, case1.Id)[0];
		caseMilestoneCase1.CompletionDate = null; // milestone is not completed
		caseMilestoneCase1.StartDate = null; // this is to test that it is being set to a date

		// Case to close
		Case case2 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case2.RecordTypeId = unifiedInvestigationRecordTypeId;
		case2.Type = SSSWConstants.INVESTIGATION;
		case2.Status = closedStatus[0]; // simulating closed case
		case2.IsStopped = false;
		caseList.add(case2);

		Case oldCase2 = case2.clone(true, true, true, true);
		oldCase2.Status = SSSWConstants.CASE_STATUS_NEW; // old case status set to New
		oldMap.put(oldCase2.Id, oldCase2);
		CaseMilestone caseMilestoneCase2 = ApplicationTestDataFactory.getCaseMilestones(1, true, false, false, milestoneType.Id, case2.Id)[0];
		caseMilestoneCase2.CompletionDate = null; // milestone is not completed

		// Case to re-open
		Case case3 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case3.RecordTypeId = unifiedInvestigationRecordTypeId;
		case3.Type = SSSWConstants.INVESTIGATION;
		case3.Status = SSSWConstants.CASE_STATUS_NEW; // simulating re-opened case
		case3.IsStopped = true;
		caseList.add(case3);

		Case oldCase3 = case3.clone(true, true, true, true);
		oldCase3.Status = closedStatus[0]; // old case status set to Closed
		oldMap.put(oldCase3.Id, oldCase3);
		CaseMilestone caseMilestoneCase3 = ApplicationTestDataFactory.getCaseMilestones(1, true, false, true, milestoneType.Id, case3.Id)[0];
		caseMilestoneCase3.CompletionDate = Datetime.now(); // milestone is completed

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementSelector.selectByNameAndAccountName(
																(Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), 
																(Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS})
															)).thenReturn(entitlements);

		MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCase(
																(Set<Id>)fflib_Match.eq(new Set<Id>{case1.Id}), 
																(Set<Object>)fflib_Match.eq(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED})
															)).thenReturn(new Map<Id, CaseMilestone>{caseMilestoneCase1.Id => caseMilestoneCase1});

		MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCase(
																(Set<Id>)fflib_Match.eq(new Set<Id>{case2.Id}), 
																(Set<Object>)fflib_Match.eq(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_VIOLATED, CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED})
															)).thenReturn(new Map<Id, CaseMilestone>{caseMilestoneCase2.Id => caseMilestoneCase2});

		MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCase(
																(Set<Id>)fflib_Match.eq(new Set<Id>{case3.Id}), 
																(Set<Object>)fflib_Match.eq(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_VIOLATED, CaseMilestonesSelector.Options.FILTER_COMPLETED})
															)).thenReturn(new Map<Id, CaseMilestone>{caseMilestoneCase3.Id => caseMilestoneCase3});
		MockUtility.Mocks.stopStubbing();

		Test.startTest();		
		CaseUnifiedMilestoneModule module = CaseUnifiedMilestoneModule.newInstance();
		module.onBeforeUpdate(caseList, oldMap, mockUow);
		Test.stopTest();

		System.assertEquals(true, case2.IsStopped, 'Should be stopped');
		System.assert(caseMilestoneCase2.CompletionDate != null, 'Completion date should filled in');

		System.assertEquals(false, case3.IsStopped, 'Should not be stopped');
		System.assert(caseMilestoneCase3.CompletionDate == null, 'Completion date should blanked out');		

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<CaseMilestone>) fflib_Match.eq(caseMilestoneCase2));
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<CaseMilestone>) fflib_Match.eq(caseMilestoneCase3));

		/**
		 * ====================================
		 * ============ Async Test ============
		 * ====================================
		 */

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class); // <-- grab the case update that was passed

		// THIS IS THE IMPORTANT TEST HERE TO MAKE SURE IT ONLY FIRED ONCE!
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		// verify both cases passed in were queued for updating
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();

		Set<Id> caseIdsEnqueued = ((Set<Id>) ((Map<String, Object>) stagedWorker.params).get('caseIds'));
		System.assertEquals(1, caseIdsEnqueued.size(), 'Expected to update 1 case');
		System.assertEquals(case1.Id, (new List<Id>(caseIdsEnqueued))[0], 'Expected to update 1 case');

	}

	/**
	 * This test method verifies Case Milestone Update which the Asyncworker will execute in async fashion
	 */
	@IsTest
	static void testAsyncUpdateCaseMilestoneWorker() {
		// =====================================
		// Data Preparation
		// =====================================
		CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector)MockUtility.mockSelector(CaseMilestonesSelector.class);
		MilestoneType milestoneType = ApplicationTestDataFactory.getMilestoneTypes(1, true)[0];

		Case case1 = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		case1 = (Case)ApplicationTestDataFactory.setUnwritableFields(case1, new Map <String, Object>{ 'CreatedDate' => Datetime.now().addDays(-3)}); // simulating an older date
		CaseMilestone caseMilestoneCase1 = ApplicationTestDataFactory.getCaseMilestones(1, true, false, false, milestoneType.Id, case1.Id)[0];
		caseMilestoneCase1.CompletionDate = null; // milestone is not completed
		caseMilestoneCase1.StartDate = null; // this is to test that it is being set to a date

		CaseUnifiedMilestoneModule.AsyncUpdateCaseMilestoneWorker worker = new CaseUnifiedMilestoneModule.AsyncUpdateCaseMilestoneWorker();
		Map<String, Object> params = new Map<String, Object>{ 'caseIds' => new Set<Id>{ case1.Id } };
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Stubbing
		// =====================================
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCase(
																(Set<Id>)fflib_Match.eq(new Set<Id>{case1.Id}), 
																(Set<Object>)fflib_Match.eq(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED})
															)).thenReturn(new Map<Id, CaseMilestone>{caseMilestoneCase1.Id => new CaseMilestone(Id = caseMilestoneCase1.Id)}); // returning a clean record for testing

		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.assertEquals(
			CaseUnifiedMilestoneModule.AsyncUpdateCaseMilestoneWorker.class,
			worker.getClassType(),
			'matching type'
		);
		System.assertEquals(Case.SObjectType, worker.getSObjectTypeGroup(), 'matching type');

		worker.deserialiseParams(JSON.serialize(params));
		System.assertEquals(1, worker.caseIds.size(), 'It should contain Case Set<Id> in params after deserialise');
		System.assertEquals(case1.Id, (new List<Id>(worker.caseIds))[0], 'It should contain Case Set<Id> in params after deserialise');

		worker.execute(mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1))
			.registerDirty(
				(List<CaseMilestone>) fflib_Match.eq(new List<CaseMilestone> {new CaseMilestone(Id = caseMilestoneCase1.Id, StartDate = worker.milestoneStartDate)}),
				fflib_Match.eqBoolean(false),
				fflib_Match.eqString(
					CaseUnifiedMilestoneModule.class.getName() +
					'.' +
					CaseUnifiedMilestoneModule.AsyncUpdateCaseMilestoneWorker.class.getName()
				)
			);

		Test.stopTest();
	}
}