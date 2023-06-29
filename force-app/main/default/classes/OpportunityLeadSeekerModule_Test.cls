/***
 * @description Test class for OpportunityLeadSeekerModule
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 */
@IsTest
private class OpportunityLeadSeekerModule_Test {
	/**
	 * Test:
	 * When a lead is inserted and the running user is a partner portal user with APS number, default the Lead Seeker checkbox and the Lead Source
	 */
	@isTest
	static void testLeadSeeker() {
		
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(OpportunityAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		
		Network__c network = ApplicationTestDataFactory.getLPONetwork(1, true)[0];
		Account account = ApplicationTestDataFactory.getFacilityAccounts(1, network.Id, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		contact.account = account; // set explicitly to prevent issues with traversal in the actual code
		User user = ApplicationTestDataFactory.getCommunityUsers(1, new List <Id> { contact.Id }, true)[0];
		user.contact = contact; // set explicitly to prevent issues with traversal in the actual code
		user.APSNumber__c = '1234';
		List <Opportunity> oppties = ApplicationTestDataFactory.getOpportunities(2, account.Id, false);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.selectById(new Set<Id> { user.Id }, 
															new Set <Object> { UsersSelector.Options.WITH_COMMUNITY_ACCOUNT }))
						.thenReturn(new Map <Id, User> { user.Id => user });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		OpportunityLeadSeekerModule module = new OpportunityLeadSeekerModule();
		module.currentUserId = user.Id;
		module.onBeforeInsert((List <SObject>)oppties, uow);
		
		Test.stopTest();

		System.Assert(oppties[0].LeadSource == OpportunityLeadSeekerModule.LEAD_SEEKER_OPPORTUNITY_LEAD_SOURCE, 'Expected opportunity record Lead Source to be ' + OpportunityLeadSeekerModule.LEAD_SEEKER_OPPORTUNITY_LEAD_SOURCE + '. Received ' + oppties[0].LeadSource);
		System.Assert(oppties[0].Lead_Seeker__c == true, 'Expected opportunity record Lead Seeker to be true.');
		System.Assert(oppties[0].APS_number__c == user.APSNumber__c, 'Expected opportunity APS Number to match User APS Number.');
		System.Assert(oppties[0].Hidden_Lead_Seeker_Lead_Owner__c == user.Email, 'Expected opportunity Hidden_Lead_Seeker_Lead_Owner__c Number to match User Email.');
	}

	/**
	 * test the Exception handling on the module onBeforeInsert method
	 */
	@isTest
	static void testExceptionHandling(){

		// =====================================
		// Data Preparation
		// =====================================
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		 // =====================================
		// Testing
		// =====================================
		Test.startTest();

		OpportunityLeadSeekerModule module = new OpportunityLeadSeekerModule();
		module.onBeforeInsert(null, null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}
}