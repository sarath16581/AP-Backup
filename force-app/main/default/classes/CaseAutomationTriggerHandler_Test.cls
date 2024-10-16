/***
 * @description Test class for CaseAutomationTriggerHandler
 * @author Nathan Franklin
 * @date 2023-06-19
 * @changelog
 * 2024-07-29 - Seth Heang - update testForCoverage() to cover a new case record type 'UnifiedInvestigation'
 * 2024-08-20 - George Nguyen - Added extra unit test to cover for sobject types and registered modules
 */
@IsTest
private class CaseAutomationTriggerHandler_Test {

	/*
		Making sure that the right SObjectTypes are returned
	*/
	@IsTest
	private static void getUnitOfWorkSObjectTypes() {

		CaseAutomationTriggerHandler handler = new CaseAutomationTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(Case.SObjectType, handler.getsObjectType(), 'Should return Case sobject type');

		List<SObjectType> types = CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes();

		System.assert(types.contains(Case.SObjectType), 'Should have Case sobject type');
		System.assert(types.contains(Article__c.SObjectType), 'Should have Article__c sobject type');
		System.assert(types.contains(Task.SObjectType), 'Should have Task sobject type');
		System.assert(types.contains(CaseMilestone.SObjectType), 'Should have CaseMilestone sobject type');
		System.assert(types.contains(AuthorisedContacts__c.SObjectType), 'Should have AuthorisedContacts__c sobject type');
		System.assert(types.contains(PendingServiceRouting.SObjectType), 'Should have PendingServiceRouting sobject type');
		System.assert(types.contains(CaseInvestigation__c.SObjectType), 'Should have CaseInvestigation__c sobject type');
		System.assert(types.contains(ScheduledAction__c.SObjectType), 'Should have ScheduledAction__c sobject type');
	}

	/*
		Making sure that the right modules are registered with the right filters
	*/
	@IsTest
	private static void registerModules() {

		CaseAutomationTriggerHandler handler = new CaseAutomationTriggerHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(CaseAutomationTriggerHandler.class.getName());
		System.assert(recordFilterIndexes.containsKey(CaseAutomationClassificationModule.class), 'It should have CaseAutomationClassificationModule class registered');

		System.assert(recordFilterIndexes.containsKey(MyCustomerCaseArticlesModule.class), 'It should have MyCustomerCaseArticlesModule class registered');
		System.assertEquals(recordFilterIndexes.get(MyCustomerCaseArticlesModule.class), 'filterSSSW', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackCalculateCaseDepotModule.class), 'It should have StarTrackCalculateCaseDepotModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackCalculateCaseDepotModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackSupportCaseContactsModule.class), 'It should have StarTrackSupportCaseContactsModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackSupportCaseContactsModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackSupportCasePriorityModule.class), 'It should have StarTrackSupportCasePriorityModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackSupportCasePriorityModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackSupportCaseAutomationModule.class), 'It should have StarTrackSupportCaseAutomationModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackSupportCaseAutomationModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackSupportCaseOwnerModule.class), 'It should have StarTrackSupportCaseOwnerModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackSupportCaseOwnerModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackSupportCaseCustomerModule.class), 'It should have StarTrackSupportCaseCustomerModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackSupportCaseCustomerModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackDeliveryEnquiryProcessModule.class), 'It should have StarTrackDeliveryEnquiryProcessModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackDeliveryEnquiryProcessModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(StarTrackTrackingIDSearchModule.class), 'It should have StarTrackTrackingIDSearchModule class registered');
		System.assertEquals(recordFilterIndexes.get(StarTrackTrackingIDSearchModule.class), 'filterStarTrack', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CreditDisputeClaimCaseModule.class), 'It should have CreditDisputeClaimCaseModule class registered');
		System.assertEquals(recordFilterIndexes.get(CreditDisputeClaimCaseModule.class), 'filterCreditDisputeClaim', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseSkillBasedRoutingModule.class), 'It should have CaseSkillBasedRoutingModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseSkillBasedRoutingModule.class), 'filterSSSW', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseUnifiedProactiveMonitoringModule.class), 'It should have CaseUnifiedProactiveMonitoringModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseUnifiedProactiveMonitoringModule.class), 'filterUnified', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseLegacyAutomationModule.class), 'It should have CaseLegacyAutomationModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseLegacyAutomationModule.class), null, 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseOwnerMetricsModule.class), 'It should have CaseOwnerMetricsModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseOwnerMetricsModule.class), null, 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseSurveyInvitationModule.class), 'It should have CaseSurveyInvitationModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseSurveyInvitationModule.class), null, 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseAutomationClassificationModule.class), 'It should have CaseAutomationClassificationModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseAutomationClassificationModule.class), 'filterUnified', 'It should have the correct filter');

		System.assert(recordFilterIndexes.containsKey(CaseUnifiedMilestoneModule.class), 'It should have CaseUnifiedMilestoneModule class registered');
		System.assertEquals(recordFilterIndexes.get(CaseUnifiedMilestoneModule.class), 'filterUnified', 'It should have the correct filter');
	}
	
	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {

		CaseAutomationTriggerHandler handler = new CaseAutomationTriggerHandler();

		handler.registerModules();

		Id ssswRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'SSSW'}).keySet())[0];
		Id ssswSocialRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'Social'}).keySet())[0];
		Id starTrackRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'StarTrack'}).keySet())[0];
		Id unifiedInvestigationRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'UnifiedInvestigation'}).keySet())[0];

		List<Case> cases = ApplicationTestDataFactory.getCases(4, true);
		cases[0].RecordTypeId = ssswRecordType;
		cases[1].RecordTypeId = ssswSocialRecordType;
		cases[2].RecordTypeId = starTrackRecordType;
		cases[3].RecordTypeId = unifiedInvestigationRecordType;

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(cases);

		System.assertEquals(5, filteredGroupRecords.size());

		System.assertEquals(1, filteredGroupRecords.get('filterSSSW').size());
		System.assertEquals(cases[0].Id, filteredGroupRecords.get('filterSSSW')[0].Id);

		System.assertEquals(2, filteredGroupRecords.get('filterSSSWWithSocial').size());
		System.assertEquals(cases[0].Id, filteredGroupRecords.get('filterSSSWWithSocial')[0].Id);
		System.assertEquals(cases[1].Id, filteredGroupRecords.get('filterSSSWWithSocial')[1].Id);

		System.assertEquals(1, filteredGroupRecords.get('filterStarTrack').size());
		System.assertEquals(cases[2].Id, filteredGroupRecords.get('filterStarTrack')[0].Id);

		System.assertEquals(1, filteredGroupRecords.get('filterUnified').size());
		System.assertEquals(cases[3].Id, filteredGroupRecords.get('filterUnified')[0].Id);

		System.assertEquals(Case.SObjectType, handler.getSObjectType());

	}

}