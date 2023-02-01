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