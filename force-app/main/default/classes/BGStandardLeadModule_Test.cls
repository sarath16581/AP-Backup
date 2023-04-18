/**
 * @description
 * Test class for BGStandardLeadModule
 * @author Pratyush Chalasani
 * @date 2023-03-27
 * @group Tests
 * @domain BGStandardLead
 * @changelog
 */
@IsTest
private class BGStandardLeadModule_Test {
	/**
	 * Test:
	 *  When a Lead is converted, the before update will check the CreatedDates of the Lead and Opportunity records
	 *  and check that the Lead was created after the Opportunity
	 */
	@IsTest
	private static void testDontConvertLeadUsingExistingOpportunity() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(LeadTriggerHandler.getUnitOfWorkSObjectTypes());
		Opportunity testOpp = ApplicationTestDataFactory.getOpportunities(1, fflib_IDGenerator.generate(Account.getSObjectType()), true)[0];

		testOpp = (Opportunity)ApplicationTestDataFactory.setUnwritableFields(testOpp, new Map<String, Object>{'CreatedDate' => System.Now().addDays(-1)});

		List<Lead> testLeads = ApplicationTestDataFactory.getLeads(5, true);

		// Lead 0: Positive test: BG Standard and Lead Seeker, and ConvertedOpportunityId will be changed (this should be blocked from linking to old opp)
		testLeads[0].RecordTypeId = ApplicationTestDataFactory.leadBGStandardRecordType;
		testLeads[0].Lead_Seeker__c = true;

		// Lead 1: Negative test: BG Standard and Lead Seeker, and ConvertedOpportunityId will be changed, but LeadSeekerConversionOverride__c will be ticked
		testLeads[1].RecordTypeId = ApplicationTestDataFactory.leadBGStandardRecordType;
		testLeads[1].Lead_Seeker__c = true;
		testLeads[1].LeadSeekerConversionOverride__c = true;

		// Lead 2: Negative test: BG Standard and Lead Seeker, but ConvertedOpportunityId has not changed
		testLeads[2].RecordTypeId = ApplicationTestDataFactory.leadBGStandardRecordType;
		testLeads[2].Lead_Seeker__c = true;
		testLeads[2] = (Lead)ApplicationTestDataFactory.setUnwritableFields(testLeads[2], new Map<String, Object>{'ConvertedOpportunityId' => testOpp.Id, 'CreatedDate' => System.Now()});

		// Lead 3: Negative test: BG Standard but not Lead Seaker
		testLeads[3].RecordTypeId = ApplicationTestDataFactory.leadBGStandardRecordType;

		// Lead 4: Negative test: not BG Standard and not Lead Seaker (do nothing here)

		Map<Id, Lead> oldMap = new Map<Id, Lead>(testLeads);

		// Lead 0 & 1: Ensure ConvertedOpportunityId value has changed (make sure to do this after creating the oldMap above)
		testLeads[0] = (Lead)ApplicationTestDataFactory.setUnwritableFields(testLeads[0], new Map<String, Object>{'ConvertedOpportunityId' => testOpp.Id, 'CreatedDate' => System.Now()});
		testLeads[1] = (Lead)ApplicationTestDataFactory.setUnwritableFields(testLeads[1], new Map<String, Object>{'ConvertedOpportunityId' => testOpp.Id, 'CreatedDate' => System.Now()});

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitiesSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitiesSelector.selectById(new Set<Id>{ testOpp.Id })).thenReturn(new Map<Id, Opportunity>{testOpp.Id => testOpp});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BGStandardLeadModule module = BGStandardLeadModule.newInstance();

		module.onBeforeUpdate(testLeads, oldMap, uow);

		// Positive
		Assert.isTrue(testLeads[0].hasErrors());
		Assert.areEqual(testLeads[0].getErrors()[0].message, Label.leadSeakerIntoExistingOpportunity);

		// Negative
		Assert.isFalse(testLeads[1].hasErrors());
		Assert.isFalse(testLeads[2].hasErrors());
		Assert.isFalse(testLeads[3].hasErrors());
		Assert.isFalse(testLeads[4].hasErrors());

		Test.stopTest();
	}
}