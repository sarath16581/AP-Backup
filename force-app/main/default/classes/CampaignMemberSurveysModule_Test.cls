/**
* @author Mathew Jose
* @date 2022-01-21
* @group Tests
* @tag module
* @tag CampaignMember
* @domain CampaignMembersDomain
* @description Test class covering CampaignMemberSurveysModule
* @changelog
* 2022-01-21 - Mathew Jose - Created
*/
@IsTest
private class CampaignMemberSurveysModule_Test {


	/**
	 * Test:
	 *  Ensures that the contact assignment record is updated to remove the Contact Id when the Campaign Member status is set to 'cancelled' (CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED)
	 *  NOTE: This should handle at least 2 different campaigns / campaign members
	 */
	@IsTest
	private static void testEnsureContactAssignmentContactIdIsRemovedWhenCampaignMemberCancelled() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Create two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		
		//Create two contacts
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, true);
		
		//Create two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		
		//Create two contact assignments (one for each campaign)
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(2,accounts[0].Id,campaigns[0].Id, true);
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		campaignContactAssignments[1].Contact__c = contacts[0].Id;
		
		//Create campaign members for the same contact in two different campaigns.
		List<CampaignMember> campaignMembersOld = new List<CampaignMember>{ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id)[0], ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[1].Id, contacts[0].Id)[0]};
		Map<Id,CampaignMember>campaignMembersOldMap = new Map<Id,CampaignMember>(campaignMembersOld);

		//Create new Map by cloning from the old values and updating the status
		List<CampaignMember> campaignMembersNew= new List<CampaignMember>{campaignMembersOld[0].clone(true),campaignMembersOld[1].clone(true)};
		campaignMembersNew[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[0], new Map<String, Object>{'Contact' => contacts[0], 'Status' => CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED});
		campaignMembersNew[1] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[1], new Map<String, Object>{'Contact' => contacts[0], 'Status' => CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED});		
		
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignContactAssignmentsSelector CampaignContactAssignmentsSelector = (CampaignContactAssignmentsSelector)MockUtility.mockSelector(CampaignContactAssignmentsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignContactAssignmentsSelector.selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(campaignContactAssignments);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignMemberSurveysModule module = CampaignMemberSurveysModule.newInstance();		
		module.removeCampaignContactAssignment(campaignMembersNew,campaignMembersOldMap, mockUow);
		Test.stopTest();
		((CampaignContactAssignmentsSelector)MockUtility.Mocks.verify(CampaignContactAssignmentsSelector, MockUtility.Mocks.times(1))).selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals(null, ((CampaignContactAssignment__c)MockUtility.mockUnitOfWorkDMLs[0]).Contact__c, 'Expected contact lookup is blanked out for assignment 1');
		System.assertEquals(null, ((CampaignContactAssignment__c)MockUtility.mockUnitOfWorkDMLs[1]).Contact__c, 'Expected contact lookup is blanked out for assignment 2');

	}

	/**
	 * Test:
	 *  Ensures that the contact assignment record is updated to remove the Contact Id when the Campaign Member status is inserted as 'cancelled' (CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED)
	 *  NOTE: This should handle at least 2 different campaigns / campaign members
	 */
	@IsTest
	private static void testEnsureContactAssignmentContactIdIsRemovedWhenCampaignMemberInsertedCancelled() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Create two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		
		//Create two contacts
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, true);
		
		//Create two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		
		//Create two contact assignments (one for each campaign)
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(2,accounts[0].Id,campaigns[0].Id, true);
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		campaignContactAssignments[1].Contact__c = contacts[0].Id;
		
		//Create campaign members for the same contact in two different campaigns.
		List<CampaignMember> campaignMembersNew = new List<CampaignMember>{ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id)[0], ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[1].Id, contacts[0].Id)[0]};
		campaignMembersNew[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[0], new Map<String, Object>{'Contact' => contacts[0], 'Status' => CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED});
		campaignMembersNew[1] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[1], new Map<String, Object>{'Contact' => contacts[0], 'Status' => CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED});		
		
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignContactAssignmentsSelector CampaignContactAssignmentsSelector = (CampaignContactAssignmentsSelector)MockUtility.mockSelector(CampaignContactAssignmentsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignContactAssignmentsSelector.selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(campaignContactAssignments);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignMemberSurveysModule module = CampaignMemberSurveysModule.newInstance();		
		module.removeCampaignContactAssignment(campaignMembersNew,null, mockUow);
		Test.stopTest();
		((CampaignContactAssignmentsSelector)MockUtility.Mocks.verify(CampaignContactAssignmentsSelector, MockUtility.Mocks.times(1))).selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals(null, ((CampaignContactAssignment__c)MockUtility.mockUnitOfWorkDMLs[0]).Contact__c, 'Expected contact lookup is blanked out for assignment 1');
		System.assertEquals(null, ((CampaignContactAssignment__c)MockUtility.mockUnitOfWorkDMLs[1]).Contact__c, 'Expected contact lookup is blanked out for assignment 2');
	}

	/**
	 * Test:
	 *  Ensures that the contact assignment record update is ignored when the Campaign Member status is set to something other than 'cancelled' (CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED)
	 *  NOTE: This should handle at least 2 different campaigns / campaign members
	 */
	@IsTest
	private static void testEnsureContactAssignmentUpdateIsIgnoredOnCampaignMemberUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Create two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		
		//Create two contacts
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, true);
		
		//Create two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		
		//Create two contact assignments (one for each campaign)
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(2,accounts[0].Id,campaigns[0].Id, true);
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		campaignContactAssignments[1].Contact__c = contacts[0].Id;
		
		//Create campaign members for the same contact in two different campaigns.
		List<CampaignMember> campaignMembersOld = new List<CampaignMember>{ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id)[0], ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[1].Id, contacts[0].Id)[0]};
		Map<Id,CampaignMember>campaignMembersOldMap = new Map<Id,CampaignMember>(campaignMembersOld);

		//Create new Map by cloning from the old values and updating the status to 'Sent'
		List<CampaignMember> campaignMembersNew= new List<CampaignMember>{campaignMembersOld[0].clone(true),campaignMembersOld[1].clone(true)};
		campaignMembersNew[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[0], new Map<String, Object>{'Contact' => contacts[0], 'Status' => 'Sent'});
		campaignMembersNew[1] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[1], new Map<String, Object>{'Contact' => contacts[0], 'Status' => 'Sent'});			
		
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignContactAssignmentsSelector CampaignContactAssignmentsSelector = (CampaignContactAssignmentsSelector)MockUtility.mockSelector(CampaignContactAssignmentsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignContactAssignmentsSelector.selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(campaignContactAssignments);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignMemberSurveysModule module = CampaignMemberSurveysModule.newInstance();		
		module.removeCampaignContactAssignment(campaignMembersNew,campaignMembersOldMap, mockUow);
		Test.stopTest();
		((CampaignContactAssignmentsSelector)MockUtility.Mocks.verify(CampaignContactAssignmentsSelector, MockUtility.Mocks.times(0))).selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(0, MockUtility.mockUnitOfWorkDMLs.size());
	}

	/**
	 * Test:
	 *  Ensures that the contact assignment record update is ignored when the Campaign Member status is set to something other than 'cancelled' (CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED)
	 *  NOTE: This should handle at least 2 different campaigns / campaign members
	 */
	@IsTest
	private static void testUnLinkCCAOnChangedContactStatus() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Create two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;

		//Create two contacts
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, true);

		//Create two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';

		//Create two contact assignments (one for each campaign)
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(2,accounts[0].Id,campaigns[0].Id, true);
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		//Create campaign members for the same contact in two different campaigns.
		List<CampaignMember> campaignMembersOld = new List<CampaignMember>{ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id)[0], ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[1].Id, contacts[0].Id)[0]};
		Map<Id,CampaignMember>campaignMembersOldMap = new Map<Id,CampaignMember>(campaignMembersOld);

		//Create new Map by cloning from the old values and updating the status to 'Sent'
		List<CampaignMember> campaignMembersNew= new List<CampaignMember>{campaignMembersOld[0].clone(true),campaignMembersOld[1].clone(true)};
		campaignMembersNew[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(campaignMembersNew[0], new Map<String, Object>{'Contact' => contacts[0], 'Status' => 'Change Status'});


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignContactAssignmentsSelector CampaignContactAssignmentsSelector = (CampaignContactAssignmentsSelector)MockUtility.mockSelector(CampaignContactAssignmentsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(CampaignContactAssignmentsSelector.selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(campaignContactAssignments);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignMemberSurveysModule module = CampaignMemberSurveysModule.newInstance();
		module.unLinkCampaignContactAssignment(campaignMembersNew,campaignMembersOldMap, mockUow);
		Test.stopTest();
		((CampaignContactAssignmentsSelector)MockUtility.Mocks.verify(CampaignContactAssignmentsSelector, MockUtility.Mocks.times(0))).selectByCampaignAndContact((Set<Id>)fflib_Match.anyObject(),(Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(0, MockUtility.mockUnitOfWorkDMLs.size());
	}

}