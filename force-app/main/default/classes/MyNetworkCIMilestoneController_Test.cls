/**
 * @File Name          : MyNetworkCIMilestoneController_Test.cls
 * @Description        : Test class for MyNetworkCIMilestoneController
 * @Author             : Mahesh Parvathaneni
 * @changelog
 **/

@IsTest
private class MyNetworkCIMilestoneController_Test {

	/**
	 * Scenario: Testing to get network milestones tier 1 for case investigation
	 */
	@IsTest
	private static void testGetCaseInvestigationNetworkMilestonesTier1() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].NetworkMilestoneCurrentTier__c = 1;
		caseInvestigations[0].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addHours(1);
		caseInvestigations[0].MilestoneTimeStartDatetime__c = Datetime.now().addHours(-10);

		List<BusinessHours> stdBusinessHours = [SELECT Id,Name FROM BusinessHours where Name = 'Service Delivery VIC'];

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		BusinessHoursSelector mockBusinessHoursSelector = (BusinessHoursSelector)MockUtility.mockSelector(BusinessHoursSelector.class);
		MilestoneService mockService = (MilestoneService)MockUtility.mockUtility(MilestoneService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
		MockUtility.Mocks.when(mockBusinessHoursSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(stdBusinessHours);
		MockUtility.Mocks.when(mockService.getBusinessHoursDiffInMinutes((Id)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject())).thenReturn(540);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyNetworkCIMilestoneController.NetworkMilestoneWrapper wrapper = MyNetworkCIMilestoneController.getCaseInvestigationNetworkMilestones(caseInvestigations[0].Id);

		Test.stopTest();

		System.assertNotEquals(false, wrapper.hasMilestonesViolated, 'Expected true but instead returned false.');
		System.assertEquals(MyNetworkCIMilestoneController.REMAINING, wrapper.status, 'Expected status as Remaining for Network Milestone');
		System.assertEquals('Network Tier 1', wrapper.networkTierName, 'Expected Network Tier 1 for the milestone');

		//should have attempted to call the Milestone Service
		((MilestoneService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(2))).getBusinessHoursDiffInMinutes((Id)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject());
	}

	/**
	 * Scenario: Testing to get network milestones which is violated for case investigation
	 */
	@IsTest
	private static void testGetCaseInvestigationNetworkMilestonesOpenViolation() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].NetworkMilestoneCurrentTier__c = 3;
		caseInvestigations[0].NetworkMilestoneNextViolationDatetime__c = Datetime.now().addHours(1);
		caseInvestigations[0].NetworkMilestoneLastViolationDatetime__c = Datetime.now().addHours(-5);
		caseInvestigations[0].MilestoneTimeStartDatetime__c = Datetime.now().addHours(-10);

		List<BusinessHours> stdBusinessHours = [SELECT Id,Name FROM BusinessHours where Name = 'Service Delivery VIC'];

		// =====================================
		// Stubbing
		// =====================================
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		BusinessHoursSelector mockBusinessHoursSelector = (BusinessHoursSelector)MockUtility.mockSelector(BusinessHoursSelector.class);
		MilestoneService mockService = (MilestoneService)MockUtility.mockUtility(MilestoneService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
		MockUtility.Mocks.when(mockBusinessHoursSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(stdBusinessHours);
		MockUtility.Mocks.when(mockService.getBusinessHoursDiffInMinutes((Id)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject())).thenReturn(540);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyNetworkCIMilestoneController.NetworkMilestoneWrapper wrapper = MyNetworkCIMilestoneController.getCaseInvestigationNetworkMilestones(caseInvestigations[0].Id);

		Test.stopTest();

		System.assertNotEquals(false, wrapper.hasMilestonesViolated, 'Expected true but instead returned false.');
		System.assertEquals(MyNetworkCIMilestoneController.OPEN_VIOLATION, wrapper.status, 'Expected status as Open Violation for Network Milestone');
		System.assertEquals('Network Tier 2', wrapper.networkTierName, 'Expected Network Tier 2 for the milestone');

		//should have attempted to call the Milestone Service
		((MilestoneService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getBusinessHoursDiffInMinutes((Id)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject(), (Datetime)fflib_Match.anyObject());
	}

}