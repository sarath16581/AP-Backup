/**
 * @description Test class for MilestoneService
 * @author Mahesh Parvathaneni
 * @date 09/02/2023
 * @changelog
 * 2023-02-28	Mahesh Parvathaneni	- Added test method for getBusinessHoursDiffInMinutes
 * 2023-04-28	Mahesh Parvathaneni - Updated tests for testCalculateNextViolationDateForCaseInvestigation to include the business/non-business hours
 */

@IsTest
private class MilestoneService_Test {

	/**
	 * Scenario: Test to ensure the next violated date time are configured for case investigations based on entitlement rule, escalation hierarchy configuration
	 */
	@IsTest
	static void testCalculateNextViolationDateForCaseInvestigation() {

		// =====================================
		// Data Preparation
		// =====================================
		//test data for escalation hierarchy
		List<Escalation_Hierarchy__c> ehRecs = ApplicationTestDataFactory.getEscalationHierarchies(1, 'ST Case Investigation', true);
		ehRecs[0].Facility_Tier_1__c = 600;
		ehRecs[0].Facility_Tier_2__c = 600;

		//test data for entitlement rules
		List<Entitlement_Rule__c> eRules = ApplicationTestDataFactory.getEntitlementRules(1, 'ST Case Investigation', ehRecs[0].Id, true);
		eRules.addAll(ApplicationTestDataFactory.getEntitlementRules(1, 'ST Case Investigation 1', ehRecs[0].Id, true));
		eRules[0].Rule__c = 'recordtype__c=StarTrack MyNetwork';
		eRules[1].Rule__c = 'customer_type__c=SMB||priority=High'; //invalid rule as the fields are not there in the case investigation object
		eRules[0] = (Entitlement_Rule__c)ApplicationTestDataFactory.setUnwritableFields(eRules[0], new Map<String, Object>{'RecordType.DeveloperName' => 'Case_Investigation'});
		eRules[1] = (Entitlement_Rule__c)ApplicationTestDataFactory.setUnwritableFields(eRules[1], new Map<String, Object>{'RecordType.DeveloperName' => 'Case_Investigation'});
		eRules[0] = (Entitlement_Rule__c)ApplicationTestDataFactory.setUnwritableFields(eRules[0], new Map<String, Object>{'Escalation_Hierarchy__r' => ehRecs[0]});
		eRules[1] = (Entitlement_Rule__c)ApplicationTestDataFactory.setUnwritableFields(eRules[1], new Map<String, Object>{'Escalation_Hierarchy__r' => ehRecs[0]});

		//test data for case investigations
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		//create start date time Feb 21, 2023 at 11:00:00 AM in the local timezone.
		records[0].MilestoneTimeStartDatetime__c = DateTime.newInstance(2023, 2, 21, 11, 0, 0);
		records[0].NetworkMilestoneCurrentTier__c = 1;
		records[0].NetworkMilestoneNextViolationDatetime__c = null;
		//create start date time Feb 20, 2023 at 11:00:00 AM in the local timezone.
		records[1].MilestoneTimeStartDatetime__c = DateTime.newInstance(2023, 2, 20, 11, 0, 0);
		records[1].NetworkMilestoneCurrentTier__c = 2;
		//create violation date time at Feb 20, 2023 at 7:00:00 AM in the local timezone (outside business hours).
		records[1].NetworkMilestoneNextViolationDatetime__c = DateTime.newInstance(2023, 2, 20, 7, 0, 0);
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'RecordType__c' => 'StarTrack MyNetwork'});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'RecordType__c' => 'StarTrack MyNetwork'});

		//get the business hours from the org
		List<BusinessHours> stdBusinessHours = [SELECT Id,Name FROM BusinessHours where Name = 'Service Delivery VIC'];

		// =====================================
		// Stubbing
		// =====================================
		EntitlementRulesSelector mockEntitlementRulesSelector = (EntitlementRulesSelector)MockUtility.mockSelector(EntitlementRulesSelector.class);
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		BusinessHoursSelector mockBusinessHoursSelector = (BusinessHoursSelector)MockUtility.mockSelector(BusinessHoursSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementRulesSelector.selectActiveRulesByRecordTypeDevNames(new Set<String>{'Case_Investigation'}, new Set<Object>{EntitlementRulesSelector.Options.WITH_ESCALATION_HIERARCHY})).thenReturn(new Map<Id, Entitlement_Rule__c>{eRules[0].Id => eRules[0], eRules[1].Id => eRules[1]});
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById(new Set<Id>{records[0].Id, records[1].Id})).thenReturn(new Map<Id, CaseInvestigation__c>{records[0].Id => records[0], records[1].Id => records[1]});
		MockUtility.Mocks.when(mockBusinessHoursSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(stdBusinessHours);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Datetime> violationDatetimeResult = MilestoneService.getInstance().calculateNextViolationDateForCaseInvestigation(new Set<Id>{records[0].Id, records[1].Id}, 'Case_Investigation', 'Facility_Tier');

		// make sure the next milestone violation date time has been populated
		System.assertEquals(2, violationDatetimeResult.keySet().size(), 'Expected calculated milestone violation on the records');
		System.assertNotEquals(null,violationDatetimeResult.get(records[0].Id), 'Expected violation date time on the record');
		System.assertNotEquals(null,violationDatetimeResult.get(records[1].Id), 'Expected violation date time on the record');

		Test.stopTest();
	}


	/**
	 * Scenario: Test to ensure the conversion of strings to date, date time and boolean
	 */
	@IsTest
	static void testStringMethods() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Date d = MilestoneService.getInstance().stringToDate('02-02-2022');
		System.assertNotEquals(null, d , 'Expected date to be returned');

		Datetime dt = MilestoneService.getInstance().stringToDatetime('02-02-2022 08:32 am');
		System.assertNotEquals(null, dt , 'Expected datetime to be returned');

		Boolean b = MilestoneService.getInstance().stringToBoolean('yes');
		System.assertEquals(true, b, 'Expected true');

		Test.stopTest();
	}

	@IsTest
	static void testGetBusinessHoursDiffInMinutes() {
		// =====================================
		// Data Preparation
		// =====================================
		//create start date time Feb 27, 2023 at 11:00:00 AM in the local timezone.
		DateTime startDatetime = DateTime.newInstance(2023, 2, 27, 11, 0, 0);
		//create end date time Feb 28, 2023 at 10:00:00 AM in the local timezone.
		DateTime endDatettime = DateTime.newInstance(2023, 2, 28, 10, 0, 0);
		//get the business hours from the org
		List<BusinessHours> stdBusinessHours = [SELECT Id,Name FROM BusinessHours where Name = 'Service Delivery VIC'];
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//start and end time are in business hours
		Decimal result = MilestoneService.getInstance().getBusinessHoursDiffInMinutes(stdBusinessHours[0].Id, startDatetime, endDatettime);
		Integer hours = result.intValue()/60;
		System.assertEquals(9, hours, 'Expected 9 business hours to be returned');
		
		//start time is outside the business hours
		//create start date time Feb 27, 2023 at 07:00:00 PM in the local timezone.
		startDatetime = DateTime.newInstance(2023, 2, 27, 19, 0, 0);
		result = MilestoneService.getInstance().getBusinessHoursDiffInMinutes(stdBusinessHours[0].Id, startDatetime, endDatettime);
		hours = result.intValue()/60;
		System.assertEquals(2, hours, 'Expected 2 business hours to be returned');

		Test.stopTest();

	}
}