/**
* @author Mathew Jose
* @date 2022-01-21
* @group Tests
* @tag CampaignContactAssignment__c
* @domain 
* @description Test class covering CampaignAssignmentController
* @changelog
* 2022-01-21 - Mathew Jose- Created
*/
@IsTest
Private class  CampaignAssignmentController_Test {

	/**
	* Test:
	* Fetching contact assignment records owned by the current user.
	**/
	@IsTest
	private static void testFetchingCampaignContactAssignments() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		accounts[0].ownerId = UserInfo.getUserId();
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, true);
        campaigns[0].ContactAssignmentDefaultStatus__c = 'Sent';
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id);
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true);
        //Set the contact lookup on CCA
        campaignContactAssignments[0].Contact__c = contacts[0].Id; 
		campaignContactAssignments[0] = (CampaignContactAssignment__c)ApplicationTestDataFactory.setUnwritableFields(campaignContactAssignments[0], new Map<String, Object>{'Organisation__r' => accounts[0], 'Contact__r' => contacts[0]});
		campaigns[0] = (Campaign)ApplicationTestDataFactory.setChildRelationships(Campaigns[0], new Map<String, List<SObject>>{'CampaignMembers' => campaignMembers,'Campaign_Contact_Assignments__r' => campaignContactAssignments});
		// =====================================
		// Stubbing
		// =====================================
		CampaignsSelector CampaignsSelector = (CampaignsSelector)MockUtility.mockSelector(CampaignsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(CampaignsSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<Campaign>(campaigns));
		MockUtility.Mocks.stopStubbing();
		// =====================================		
		Test.startTest();
		List<CampaignAssignmentController.AccountCampaignContactWrapper> assignments =  CampaignAssignmentController.getCampaignContactAssignments(campaigns[0].Id);
		Test.stopTest();
        System.AssertEquals(assignments.size(),1);        
        
    }

	/**
	* Test:
	* Updating contact assignments via the controller method.
	**/
	@IsTest
	private static void testSavingContactAssignments() {
		// =====================================
		// Data Preparation
		// =====================================
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		accounts[0].ownerId = UserInfo.getUserId();
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Sent';
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id);
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true);
		//Set the contact lookup on CCA
		campaignContactAssignments[0].Contact__c = contacts[0].Id; 
		campaignContactAssignments[0] = (CampaignContactAssignment__c)ApplicationTestDataFactory.setUnwritableFields(campaignContactAssignments[0], new Map<String, Object>{'Organisation__r' => accounts[0], 'Contact__r' => contacts[0]});
		campaigns[0] = (Campaign)ApplicationTestDataFactory.setChildRelationships(Campaigns[0], new Map<String, List<SObject>>{'CampaignMembers' => campaignMembers,'Campaign_Contact_Assignments__r' => campaignContactAssignments});

		CampaignAssignmentController.AccountCampaignContactWrapper assignmentWrap = new CampaignAssignmentController.AccountCampaignContactWrapper();
		assignmentWrap.assignmentId = campaignContactAssignments[0].Id;
		assignmentWrap.assignmentDefaultStatus = 'test';
		assignmentWrap.campaignContactId = contacts[0].Id;
		assignmentWrap.accountId = accounts[0].Id;
		List<CampaignAssignmentController.AccountCampaignContactWrapper>assignmentWrapList = new List<CampaignAssignmentController.AccountCampaignContactWrapper>{assignmentWrap};	

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());        
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignmentController.updateCampaignContactAssignments(assignmentWrapList);
		Test.stopTest();
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
        // no inserts
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());		
		System.assertEquals(1, MockUtility.mockDMLUpdatedRecords.size());

        
    }    
}