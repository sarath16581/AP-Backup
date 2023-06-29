/**
 * @description
 * Test class for StarTrackDeliveryEnquiryProcessModule
 * @author Madhusudhan
 * @date 2021-07-02
 * @group Tests
 * @domain StarTrack
 * @changelog
 * 2023-06-19 - Nathan Franklin - updated unit of work source to CaseAutomationTriggerHandler
 */
@IsTest
private class StarTrackDeliveryEnquiryModule_Test {
	/**
	 * Test: When as case is inserted with No_Data_Change__c and Consignment_Shortage__c as TRUE,
	 * Before Insert trigger will update these fields to FALSE based on the values that are present in few other fields.
	 */
	@IsTest
	private static void testEnsureBeforeInsertupdatesNoDataChangeandConsignmentShortageFlagstoFalse() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, false);

		// set fields required to update No_Data_Change__c
		cases[0].No_Data_Change__c = true;
		cases[0].Number_of_No_Data_Consignment_Updates__c = 1;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// set fields required to udpate Consignment_Shortage__c
		cases[1].Consignment_Shortage__c = true;
		cases[1].Approval_Status__c = 'Draft';
		cases[1].Enquiry_Type__c = 'Incorrect Delivery';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackDeliveryEnquiryProcessModule module = StarTrackDeliveryEnquiryProcessModule.newInstance();

		module.onBeforeInsert(cases, uow);

		Test.stopTest();

		// make sure fields were updated correctly
		System.assertEquals(false, cases[0].No_Data_Change__c, 'Expected No_Data_Change flag to be set as FALSE on case');

		System.assertEquals(false, cases[1].Consignment_Shortage__c, 'Expected Consignment_Shortage flag to be set as FALSE on case');
	}

	/**
	 * Test: When as case is inserted with No_Data_Change__c and Consignment_Shortage__c as TRUE,
	 * Before Update trigger will update these fields to FALSE based on the values that are present in few other fields.
	 */
	@IsTest
	private static void testEnsureBeforeUpdateupdatesNoDataChangeandConsignmentShortageFlagstoFalse() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);

		// set fields required to update No_Data_Change__c
		cases[0].No_Data_Change__c = true;
		cases[0].Number_of_No_Data_Consignment_Updates__c = 1;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// set fields required to udpate Consignment_Shortage__c
		cases[1].Consignment_Shortage__c = true;
		cases[1].Approval_Status__c = 'Draft';
		cases[1].Enquiry_Type__c = 'Incorrect Delivery';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackDeliveryEnquiryProcessModule module = StarTrackDeliveryEnquiryProcessModule.newInstance();

		module.onBeforeUpdate(cases, new Map<Id, Case>(cases), uow);

		Test.stopTest();

		// make sure fields were updated correctly
		System.assertEquals(false, cases[0].No_Data_Change__c, 'Expected No_Data_Change flag to be set as FALSE on case');

		System.assertEquals(false, cases[1].Consignment_Shortage__c, 'Expected Consignment_Shortage flag to be set as FALSE on case');
	}

	/**
	 * Test: Integratio Scenario,
	 * 1. When a case(Delivery Enquiry) is inserted/updated with No_Data_Change__c as TRUE,
	 * Tigger will set the Flag to FALSE and an Activity is created with Case Details.
	 * 2. When a case(Delivery Enquiry) is inserted/updated with Consignment_Shortage__c as TRUE,
	 * Tigger will set the Flag to FALSE and Record is submitted for Approval.
	 */
	@IsTest
	private static void testEnsureRecordSubmittedforApprovalAndActivityIsCreatedIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, false);

		// set fields required to update No_Data_Change__c
		cases[0].No_Data_Change__c = true;
		cases[0].Number_of_No_Data_Consignment_Updates__c = 1;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// set fields required to udpate Consignment_Shortage__c
		cases[1].Consignment_Shortage__c = true;
		cases[1].Approval_Status__c = 'Draft';
		cases[1].Enquiry_Type__c = 'Incorrect Delivery';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		insert cases;

		Test.stopTest();

		Set<Id> caseIds = new Set<Id>{ cases[0].Id, cases[1].Id };
		Map<Id, Case> updatedCases = new Map<Id, Case>([SELECT Id, No_Data_Change__c, Consignment_Shortage__c, Approval_Status__c, Status FROM Case WHERE Id = :caseIds]);
		List<Task> caseRelatedActivity = new List<Task>([SELECT Id, WhatId FROM Task WHERE WhatId = :cases[0].Id]);

		// make sure fields were updated correctly
		System.assertEquals(false, updatedCases.get(cases[0].Id).No_Data_Change__c, 'Expected No_Data_Change flag to be set as FALSE on case');
		System.assertEquals(false, updatedCases.get(cases[1].Id).Consignment_Shortage__c, 'Expected Consignment_Shortage flag to be set as FALSE on case');

		// make sure activity is created on case
		System.assertEquals(1, caseRelatedActivity.size(), 'Expected activity to be created on case');

		// make sure fields updated from Approval process
		System.assertEquals('Shortage Request Submitted', updatedCases.get(cases[1].Id).Approval_Status__c, 'Expected Approval_Status field to be updated on case');
		System.assertEquals('Awaiting Approval', updatedCases.get(cases[1].Id).Status, 'Expected Status field to be updated on case');
	}
}