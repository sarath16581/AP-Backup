/**
 * @description       : Test class for OmniSkillsReportController
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2023-02-07 - George Nguyen - created
 **/
@IsTest
private without sharing class OmniSkillsReportController_Test {

	@IsTest
	static void getCases() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Case> expected = new Map<Id, Case>(ApplicationTestDataFactory.getCases(3, true));

		// =====================================
		// Stubbing
		// =====================================
		SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSSSWCasesSelector.selectById((Set<Id>)fflib_Match.eq(expected.keySet()))).thenReturn(expected);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Case> actual = new Map<Id, Case>(OmniSkillsReportController.getCases(new List<Id>(expected.keySet())));

		System.assert(actual.containsKey(expected.values()[0].id) , 'Should return the same records');
		System.assert(actual.containsKey(expected.values()[1].id), 'Should return the same records');
		System.assert(actual.containsKey(expected.values()[2].id), 'Should return the same records');

		Test.stopTest();

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Case.Id, Case.Status, Case.Priority, Case.CreatedDate, Case.CaseNumber, Case.Type, Case.ProductCategory__c, Case.ProductSubCategory__c, Case.EnquirySubType__c
		};
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockSSSWCasesSelector, 1)).setFieldOverrides(fieldOverrides);

	}

	@IsTest
	static void fetchReportData() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		List<ServiceChannel> serviceChannels = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true);
		Map<Id, PendingServiceRouting> pendingWorkRecords = new Map<Id, PendingServiceRouting>(OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannels[0].Id, cases.keySet(), true));
		String lastIdRetrieved;

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockPendingServiceRoutingSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		MockUtility.Mocks.startStubbing();
		//MockUtility.Mocks.when(mockPendingServiceRoutingSelector.search(searchParams, selectorOptions, true)).thenReturn(pendingWorkRecords.values());
		MockUtility.Mocks.when(mockPendingServiceRoutingSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(pendingWorkRecords.values());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		OmniSkillsReportController.JobOutput output = OmniSkillsReportController.fetchReportData(lastIdRetrieved);

		System.assertEquals(pendingWorkRecords.size(), output.records.size(), 'should contain the same list');
		System.assertEquals(pendingWorkRecords.values()[0].Id, output.records[0].Id, 'should contain the same list');
		System.assertEquals(pendingWorkRecords.values()[1].Id, output.records[1].Id, 'should contain the same list');
		System.assertEquals(true, output.isDone, 'less than MAX_RECORDS_PER_ITERATION');
		System.assertEquals(pendingWorkRecords.values()[pendingWorkRecords.size()-1].Id, output.lastId, 'should contain the last record'); 

		Test.stopTest();

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			PendingServiceRouting.SObjectType => new Set<SObjectField>{
				PendingServiceRouting.Id, PendingServiceRouting.RoutingPriority, PendingServiceRouting.SecondaryRoutingPriority, PendingServiceRouting.WorkItemId
			},
			Case.SObjectType => new Set<SObjectField>{
				Case.Id, Case.CreatedDate
			},
			SkillRequirement.SObjectType => new Set<SObjectField>{
				SkillRequirement.Id, SkillRequirement.SkillId
			},
			Skill.SObjectType => new Set<SObjectField>{
				Skill.DeveloperName, Skill.MasterLabel
			}
		};
		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockPendingServiceRoutingSelector, 1)).setFieldOverrides(fieldOverrides);
	}
}