/**
 * @description
 * Test class for StarTrackSupportCaseAutomationModule
 * @author Raman Raj Saxena
 * @date 2021-06-24
 * @group Tests
 * @domain StarTrack
 * @changelog
 */
@IsTest
private class StarTrackSupCaseAutomationModule_Test {

	@IsTest
	static void ensureCaseSecondaryPriorityIsSetOnBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = ''; // invalid case

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		StarTrackSupportCaseAutomationModule.newInstance().onBeforeInsert(cases, uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1] }), 
																								(Boolean)fflib_Match.eq(true)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	@IsTest
	static void ensureCaseSecondaryPriorityAreIsOnBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = 'High';

		List<Case> oldCases = cases.deepClone(true, false, false);
		oldCases[0].OwnerId = omniQueue.Id; // invalid case
		oldCases[0].Priority = 'High';

		oldCases[1].OwnerId = UserInfo.getUserId();
		oldCases[1].Priority = 'Low';

		oldCases[2].OwnerId = omniQueue.Id; 
		oldCases[2].Priority = ''; 

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		StarTrackSupportCaseAutomationModule.newInstance().onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1], cases[2] }), 
																								(Boolean)fflib_Match.eq(false)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  When a case is inserted with Article and case subject is not alraedy populated then, the before insert method will
	 *  update case Subject with Case's Call_Purpose__c and Article's Name.
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesCaseSubject() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;

		// update Article, Call Purpose, Pickup_Booking_Reference, Subject, Origin and RecordType
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;
		cases[0].Pickup_Booking_Reference__c = 'Test123';

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseAutomationModule module = StarTrackSupportCaseAutomationModule.newInstance();

		module.onBeforeInsert(cases, uow);
		Test.stopTest();

		String expectedCaseSubject = cases[0].Call_Purpose__c + ':' + cases[0].Pickup_Booking_Reference__c;
		// make sure fields were updated correctly
		System.assertEquals(expectedCaseSubject, cases[0].Subject, 'Expected Subject to be set on case');
	}

	/**
	 * Test:
	 *  When a case is inserted with Pickup_Booking_Reference and case subject is not alraedy populated then, the before update method will
	 *  update case Subject with Case's Call_Purpose__c and Pickup_Booking_Reference.
	 */
	@IsTest
	private static void testEnsureBeforeUpdatePopulatesCaseSubject() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;
		Map<Id, Case> existingCases = new Map<Id, Case>();
		existingCases.put(cases[0].Id, cases[0]);

		// update Pickup_Booking_Reference, Call Purpose, Subject, Origin and RecordType
		cases[0].Pickup_Booking_Reference__c = 'Test123';
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseAutomationModule module = StarTrackSupportCaseAutomationModule.newInstance();

		module.onBeforeUpdate(cases, existingCases, uow);

		Test.stopTest();
		String expectedCaseSubject = cases[0].Call_Purpose__c + ':' + cases[0].Pickup_Booking_Reference__c;
		// make sure fields were updated correctly
		System.assertEquals(expectedCaseSubject, cases[0].Subject, 'Expected Subject to be set on case');
	}

	/**
	 * Test:
	 *  When a Case_Update__c is updated on case as null and case record type is StarTrack_PUD_Enquiry/StarTrack_Pickup_Booking_Enquiry/
	 *  then update Case_Update_Time__c as null
	 */
	@IsTest
	private static void testEnsureBeforeUpdateUpdateCaseUpdateTime() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Case> oldCases = new List<Case>{ cases[0].clone(true) };
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;
		Map<Id, Case> existingCases = new Map<Id, Case>();
		oldCases[0].Case_Update__c = 'New Comment';
		existingCases.put(oldCases[0].Id, oldCases[0]);

		// update Pickup_Booking_Reference, Call Purpose, Subject, Origin and RecordType
		cases[0].Pickup_Booking_Reference__c = 'Test123';
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseAutomationModule module = StarTrackSupportCaseAutomationModule.newInstance();

		module.onBeforeUpdate(cases, existingCases, uow);
		Test.stopTest();

		// make sure fields were updated correctly
		System.assertEquals(null, cases[0].Case_Update_Time__c, 'Expected Subject to be set on case');
	}

	/**
	 * Test:
	 *  When a case subject is updated and case FCR__C is true and its current and previous status are not New/Reopened then update
	 *  then update the case's FCR__c as false.
	 */
	@IsTest
	private static void testEnsureBeforeUpdateUpdateReopenCase() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Case> oldCases = new List<Case>{ cases[0].clone(true) };
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;
		Map<Id, Case> existingCases = new Map<Id, Case>();
		oldCases[0].Case_Update__c = 'New Comment';
		oldCases[0].Status = 'Waiting on customer';
		existingCases.put(oldCases[0].Id, oldCases[0]);

		// update Pickup_Booking_Reference, Call Purpose, Subject, Origin and RecordType
		cases[0].Pickup_Booking_Reference__c = 'Test123';
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Status = 'Waiting on operations';
		cases[0].FCR__c = true;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseAutomationModule module = StarTrackSupportCaseAutomationModule.newInstance();

		module.onBeforeUpdate(cases, existingCases, uow);

		Test.stopTest();

		// make sure fields were updated correctly
		System.assertEquals(false, cases[0].FCR__c, 'Expected Subject to be set on case');
	}

	/**
	 * Test: Integration Scenario
	 *  When a case is inserted with Article and case subject is not alraedy populated then, the before insert method will
	 *  update case Subject with Case's Call_Purpose__c and Article's Name.
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesCaseSubjectIntegration() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;
		insert articles;
		// update Article, Call Purpose, Pickup_Booking_Reference, Subject, Origin and RecordType
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;
		cases[0].Pickup_Booking_Reference__c = 'Test123';

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		insert cases;

		Test.stopTest();

		String expectedCaseSubject = cases[0].Call_Purpose__c + ':' + cases[0].Pickup_Booking_Reference__c;
		List<Case> updatedCases = [SELECT Id, Subject FROM Case WHERE Id = :cases[0].Id];
		// make sure fields were updated correctly
		System.assertEquals(expectedCaseSubject, updatedCases[0].Subject, 'Expected Subject to be set on case');
	}

	/**
	 * Test: Integration Scenario
	 *  When a case is inserted with Pickup_Booking_Reference and case subject is not alraedy populated then, the before update method will
	 *  update case Subject with Case's Call_Purpose__c and Pickup_Booking_Reference.
	 */
	@IsTest
	private static void testEnsureBeforeUpdatePopulatesCaseSubjectIntegration() {
		// =====================================
		// Data Preparation
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		Map<Id, RecordType> validCaseRecordTypes = new RecordTypesSelector()
			.selectByDeveloperName('Case', new Set<String>{ 'StarTrack_Pickup_Booking_Enquiry' });
		Id pickupBookingRecordTypeId = validCaseRecordTypes.values()[0].Id;
		insert cases;

		// update Pickup_Booking_Reference, Call Purpose, Subject, Origin and RecordType
		cases[0].Pickup_Booking_Reference__c = 'Test123';
		cases[0].Call_Purpose__c = 'Test Purpose';
		cases[0].Subject = null;
		cases[0].Origin = 'Chat';
		cases[0].RecordTypeId = pickupBookingRecordTypeId;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		update cases;

		Test.stopTest();
		String expectedCaseSubject = cases[0].Call_Purpose__c + ':' + cases[0].Pickup_Booking_Reference__c;
		List<Case> updatedCases = [SELECT Id, Subject FROM Case WHERE Id = :cases[0].Id];
		// make sure fields were updated correctly
		System.assertEquals(expectedCaseSubject, updatedCases[0].Subject, 'Expected Subject to be set on case');
	}
}