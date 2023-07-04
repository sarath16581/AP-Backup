/**
 * @description
 * Test class for Module to handle Adjustment__c object functionality
 * @author Pratyush Chalasani
 * @group Domain
 * @domain Adjustment
 * @changelog
 * 2023-06-28 - Pratyush Chalasani - Created
 *
 */
@isTest
private class AdjustmentModuleTest {
    @isTest
	static void test_AfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];

		testCase.AccountId = fflib_IDGenerator.generate(Account.getSObjectType());

		Disputed_Item__c testDI = ApplicationTestDataFactory.getDisputedItems(1, testCase.Id, true)[0];

		testDi.Case__c = testCase.Id;
		testDi.Is_APPC__c = 'Yes';
		testDi.Status__c = 'Verified Claim';
		testDi.Type__c = 'Discretionary Credit';

		Credit_Approval__c testCA = ApplicationTestDataFactory.getCreditApprovals(1, true)[0];

		testCA.Case__c = testCase.Id;
		testCA.Status__c = 'Approved';
		testCA.Type__c = 'Discretionary Credit';

		testCase = (Case)ApplicationTestDataFactory.setChildRelationships(testCase, new Map<String, List<SObject>>{
			'Credit_Adjustments__r' => new List<SObject>{testCA},
			'Disputed_Items__r' => new List<SObject>{testDI}
		});

		Adjustment__c testAdjustment = ApplicationTestDataFactory.getAdjustments(1, testCase.Id, true)[0];

		testAdjustment.Type__c = 'Discretionary Credit';

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectByIdWithCreditAapprovalsAndDisputedItems(new Set<Id>{testCase.Id}, null)).thenReturn(new Map<Id, Case>{testCase.Id => testCase});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eq(true), (String)fflib_Match.eq(AdjustmentModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AdjustmentModule module = AdjustmentModule.newInstance();

		module.onAfterInsert(new List<Adjustment__c>{testAdjustment}, mockUow);

		Test.stopTest();
		
		System.assertEquals(3, MockUtility.mockUnitOfWorkDMLs.size());
		
		System.assertEquals(true, ((Adjustment__c)MockUtility.mockUnitOfWorkDMLs[0]).Is_APPC__c, 'Is APPC flag should be carried over from Disputed Item');
		System.assertEquals(testAdjustment.Id, ((Disputed_Item__c)MockUtility.mockUnitOfWorkDMLs[1]).Adjustment__c, 'Disputed Item should be linked to Adjustment');
		System.assertEquals(testAdjustment.Id, ((Credit_Approval__c)MockUtility.mockUnitOfWorkDMLs[2]).Adjustment__c, 'Credit Approval should be linked to Adjustment');
	}

	@isTest
	static void test_AfterUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];

		testCase.AccountId = fflib_IDGenerator.generate(Account.getSObjectType());

		Disputed_Item__c testDI = ApplicationTestDataFactory.getDisputedItems(1, testCase.Id, true)[0];

		testDi.Case__c = testCase.Id;
		testDi.Is_APPC__c = 'Yes';
		testDi.Status__c = 'Verified Claim';
		testDi.Type__c = 'Discretionary Credit';

		Credit_Approval__c testCA = ApplicationTestDataFactory.getCreditApprovals(1, true)[0];

		testCA.Case__c = testCase.Id;
		testCA.Status__c = 'Approved';
		testCA.Type__c = 'Discretionary Credit';

		testCase = (Case)ApplicationTestDataFactory.setChildRelationships(testCase, new Map<String, List<SObject>>{
			'Credit_Adjustments__r' => new List<SObject>{testCA},
			'Disputed_Items__r' => new List<SObject>{testDI}
		});

		Adjustment__c testAdjustment = ApplicationTestDataFactory.getAdjustments(1, testCase.Id, true)[0];

		testAdjustment.Type__c = 'Discretionary Credit';

		Adjustment__c oldAdjustment = testAdjustment.clone(true, true, true, true);

		oldAdjustment.Case__c = null;

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectByIdWithCreditAapprovalsAndDisputedItems(new Set<Id>{testCase.Id}, null)).thenReturn(new Map<Id, Case>{testCase.Id => testCase});
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.eq(true), (String)fflib_Match.eq(AdjustmentModule.class.getName()))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AdjustmentModule module = AdjustmentModule.newInstance();

		module.onAfterUpdate(new List<Adjustment__c>{testAdjustment}, new Map<Id, Adjustment__c>{oldAdjustment.Id => oldAdjustment}, mockUow);

		Test.stopTest();
		
		System.assertEquals(3, MockUtility.mockUnitOfWorkDMLs.size());
		
		System.assertEquals(true, ((Adjustment__c)MockUtility.mockUnitOfWorkDMLs[0]).Is_APPC__c, 'Is APPC flag should be carried over from Disputed Item');
		System.assertEquals(testAdjustment.Id, ((Disputed_Item__c)MockUtility.mockUnitOfWorkDMLs[1]).Adjustment__c, 'Disputed Item should be linked to Adjustment');
		System.assertEquals(testAdjustment.Id, ((Credit_Approval__c)MockUtility.mockUnitOfWorkDMLs[2]).Adjustment__c, 'Credit Approval should be linked to Adjustment');
	}
}