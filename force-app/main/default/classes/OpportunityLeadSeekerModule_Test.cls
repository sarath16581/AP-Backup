/***
 * @description Test class for OpportunityLeadSeekerModule
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 */
@IsTest
private class OpportunityLeadSeekerModule_Test {
	/**
	 * 
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
															new Set <Object> { UsersSelector.Options.WITH_CONTACT, 
																				ContactsSelector.Options.WITH_ACCOUNT, 
																				AccountsSelector.Options.WITH_RECORDTYPE }))
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
	}
}