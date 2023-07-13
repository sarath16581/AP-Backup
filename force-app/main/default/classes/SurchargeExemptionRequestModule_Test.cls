/**
 * @description Test class covering SurchargeExemptionRequestModule
 * @author Pratyush Chalasani
 * @date 2023-07-12
 * @group Tests
 * @tag Domain
 * @tag Deal_Support_Request__c
 * @domain Core
 * @changelog
 * 2023-07-12	Pratyuh Chalasani - created
 */
@isTest
public class SurchargeExemptionRequestModule_Test {
	@isTest
    static void test_BeforeInsert() {
		// =====================================
        // Data Preparation
        // =====================================
		Sales_Segment_Reference__c testTeam = ApplicationTestDataFactory.getSalesSegmentReferences(1, true)[0];

		testTeam.Sales_Segment__c = 'Holding Sales Team';
		testTeam.SalesDirectorApprover__c = fflib_IDGenerator.generate(User.SObjectType);
		testTeam.GeneralManager__c = fflib_IDGenerator.generate(User.SObjectType);

        Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		testAccount.Sales_Segment__c = testTeam.Sales_Segment__c;

		RecordType testRT = new RecordType(Id = ApplicationTestDataFactory.surchargeExemptionRequestRecordType);

		List<Deal_Support_Request__c> testDSRs = ApplicationTestDataFactory.getDealSupportRequests(1, null, testAccount.Id, true);

		testDSRs[0].RecordTypeId = testRT.Id;

        // =====================================
        // Stubbing
        // =====================================

		RecordTypesSelector mockRTSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
        AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SalesSegmentReferenceSelector mockSSRSelector = (SalesSegmentReferenceSelector)MockUtility.mockSelector(SalesSegmentReferenceSelector.class);

        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRTSelector.selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Surcharge_Exemption_Request'})).thenReturn(new Map<Id, RecordType>{testRT.Id => testRT});
        MockUtility.Mocks.when(mockAccountsSelector.selectById(new Set<Id>{testAccount.Id})).thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.when(mockSSRSelector.selectByName(new Set<String>{testTeam.Sales_Segment__c})).thenReturn(new List<Sales_Segment_Reference__c>{testTeam});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        SurchargeExemptionRequestModule.newInstance().onBeforeInsert(testDSRs, null);

        Test.stopTest();

		Assert.areEqual(testTeam.SalesDirectorApprover__c, testDSRs[0].Sales_Director__c);
		Assert.areEqual(testTeam.GeneralManager__c, testDSRs[0].SalesTeamGeneralManager__c);
    }

	@isTest
    static void test_BeforeUpdate() {
		// =====================================
        // Data Preparation
        // =====================================
		Sales_Segment_Reference__c testTeam = ApplicationTestDataFactory.getSalesSegmentReferences(1, true)[0];

		testTeam.Sales_Segment__c = 'Holding Sales Team';
		testTeam.SalesDirectorApprover__c = fflib_IDGenerator.generate(User.SObjectType);
		testTeam.GeneralManager__c = fflib_IDGenerator.generate(User.SObjectType);

        Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		testAccount.Sales_Segment__c = testTeam.Sales_Segment__c;

		RecordType testRT = new RecordType(Id = ApplicationTestDataFactory.surchargeExemptionRequestRecordType);

		List<Deal_Support_Request__c> testDSRs = ApplicationTestDataFactory.getDealSupportRequests(1, null, testAccount.Id, true);

		testDSRs[0].RecordTypeId = testRT.Id;

		Deal_Support_Request__c oldDSR = testDSRs[0].clone(true, true, true, true);

		oldDSR.Organisation__c = null;

		Map<Id, Deal_Support_Request__c> oldDSRMap = new Map<Id, Deal_Support_Request__c>{oldDSR.Id => oldDSR};

        // =====================================
        // Stubbing
        // =====================================

		RecordTypesSelector mockRTSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
        AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		SalesSegmentReferenceSelector mockSSRSelector = (SalesSegmentReferenceSelector)MockUtility.mockSelector(SalesSegmentReferenceSelector.class);

        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRTSelector.selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Surcharge_Exemption_Request'})).thenReturn(new Map<Id, RecordType>{testRT.Id => testRT});
        MockUtility.Mocks.when(mockAccountsSelector.selectById(new Set<Id>{testAccount.Id})).thenReturn(new Map<Id, Account>{testAccount.Id => testAccount});
		MockUtility.Mocks.when(mockSSRSelector.selectByName(new Set<String>{testTeam.Sales_Segment__c})).thenReturn(new List<Sales_Segment_Reference__c>{testTeam});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        SurchargeExemptionRequestModule.newInstance().onBeforeUpdate(testDSRs, oldDSRMap, null);

        Test.stopTest();

		Assert.areEqual(testTeam.SalesDirectorApprover__c, testDSRs[0].Sales_Director__c);
		Assert.areEqual(testTeam.GeneralManager__c, testDSRs[0].SalesTeamGeneralManager__c);
    }
}