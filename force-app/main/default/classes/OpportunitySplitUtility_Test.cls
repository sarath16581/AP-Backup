/* @author 
 * @date 2020-10-07
 * @group Tests
 * @tag Selector
 * @tag OpportunitySplit
 * @domain Core
 * @description test class for OpportunitySplitUtility
 * @changelog
 * 2020-10-07 - arjun.singh@austpost.com.au - Created
 * 2021-03-24 - disha.kariya@austpost.com.au - Updated unwritable field Current Owner Role on User
 * 2023-05-17 - Ranjeewa Silva - Added tests to cover opportunity splits automation on opportunity creation and transfer to a new owner.
 */
@IsTest
public with sharing class OpportunitySplitUtility_Test {
	@IsTest
	private static void directContributionValidationsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.directContributionOverlayType,'Solution Specialist' , true)[0];	   
		

		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);

		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
		List<OpportunitySplit> splitList = new List<OpportunitySplit>();
		splitList.add(opportunitySplitRecord);
			cntrl.opportunitySplitValidations(splitList, null);
			List<Apexpages.Message> validationMsg = ApexPages.getMessages() ;
			System.assert(String.valueOf(validationMsg[0]).contains(Label.DIRECT_CONTRIBUTION_MSG));
		Test.stopTest();
	}
	@IsTest
	private static void overlayContributionValidationsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Direct Contribution' , true)[0];	   
		

		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);

		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
		List<OpportunitySplit> splitList = new List<OpportunitySplit>();
		splitList.add(opportunitySplitRecord);
			cntrl.opportunitySplitValidations(splitList, null);
			List<Apexpages.Message> validationMsg = ApexPages.getMessages() ;
			System.assert(String.valueOf(validationMsg[0]).contains(Label.OVERLAY_CONTRIBUTION_MSG));
		Test.stopTest();
	}
	@IsTest
	private static void ovelayBlankValidationsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Direct Contribution' , true)[0];	   
		opportunitySplitRecord.Overlay_Type__c = '';

		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);

		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
		List<OpportunitySplit> splitList = new List<OpportunitySplit>();
		splitList.add(opportunitySplitRecord);
			cntrl.opportunitySplitValidations(splitList, null);
			List<Apexpages.Message> validationMsg = ApexPages.getMessages() ;
			System.assert(String.valueOf(validationMsg[0]).contains(Label.SPLIT_OVERLAY_TYPE_CHECK));
		Test.stopTest();
	}
	
	@IsTest
	private static void totalPercentValidationsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		List<User> uRecordList = ApplicationTestDataFactory.getUsers(2, true);
		
		OpportunitySplit solutionSpecialistFirstRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecordList[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Solution Specialist' , true)[0];	   
		solutionSpecialistFirstRecord.SplitPercentage = 60;
		OpportunitySplit solutionSpecialistSecondRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecordList[1].Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Solution Specialist' , true)[0];	   
		solutionSpecialistSecondRecord.SplitPercentage = 60;

		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		OpportunitiesSplitSelector opportunitySplitSelector = (OpportunitiesSplitSelector)MockUtility.mockSelector(OpportunitiesSplitSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		Map<Id, OpportunitySplit> mockOPPSplitMap = new Map<Id, OpportunitySplit>();
		mockOPPSplitMap.put(solutionSpecialistFirstRecord.Id, solutionSpecialistFirstRecord);
		mockOPPSplitMap.put(solutionSpecialistSecondRecord.Id, solutionSpecialistSecondRecord);
		
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);
		MockUtility.Mocks.when(opportunitySplitSelector.selectByOpportunity(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPSplitMap);

		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
			List<OpportunitySplit> splitList = new List<OpportunitySplit>();
			splitList.add(solutionSpecialistFirstRecord);
			splitList.add(solutionSpecialistSecondRecord);
			cntrl.opportunitySplitValidations(splitList, null);
			List<Apexpages.Message> validationMsg = ApexPages.getMessages() ;
			System.assert(String.valueOf(validationMsg[0]).contains(Label.TOTAL_PERCENT_MSG));
		Test.stopTest();
	}
	
	@IsTest
	private static void updateTeamMemberRoleTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		List<User> uRecordList = ApplicationTestDataFactory.getUsers(1, true);
		OpportunitySplit splitRecordRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecordList[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Solution Specialist' , true)[0];			   
		OpportunityTeamMember teamMember = ApplicationTestDataFactory.getOpportunityTeamMembers(1, opportunityRecord.Id, uRecordList[0].Id, 'Service Partner', 'Read', true)[0];
		
		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		OpportunitiesSplitSelector opportunitySplitSelector = (OpportunitiesSplitSelector)MockUtility.mockSelector(OpportunitiesSplitSelector.class);
		OpportunityTeamMembersSelector teamSelector = (OpportunityTeamMembersSelector)MockUtility.mockSelector(OpportunityTeamMembersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
	   // set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		Map<Id, OpportunitySplit> mockOPPSplitMap = new Map<Id, OpportunitySplit>{splitRecordRecord.Id => splitRecordRecord};
		Map<Id, OpportunityTeamMember> mockMemberMap = new Map<Id, OpportunityTeamMember>{teamMember.Id => teamMember};
		
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);
		MockUtility.Mocks.when(opportunitySplitSelector.selectByOpportunity(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPSplitMap);
		MockUtility.Mocks.when(teamSelector.selectByOpportunityAndUsers(new Set<Id>{opportunityRecord.Id}, new Set<Id>{uRecordList[0].Id})).thenReturn(mockMemberMap);

		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
			List<OpportunitySplit> splitList = new List<OpportunitySplit>();
			splitList.add(splitRecordRecord);
			cntrl.updateTeamMemberRole(splitList, null);
			System.assertEquals(mockMemberMap.values()[0].TeamMemberRole , 'Solution Specialist') ;
		Test.stopTest();
	}
	
	@IsTest
	private static void populateOpportunityOwnerRoleTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opportunityRecord.ownerId = uRecord.Id ;
		
		OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];	   
		
		// =====================================
		// Stubbing
		// =====================================

		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);

		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
		List<OpportunitySplit> splitList = new List<OpportunitySplit>();
		splitList.add(opportunitySplitRecord);
			cntrl.populateOpportunityOwnerRole(splitList);
			System.assertEquals(splitList[0].Overlay_Type__c , 'Direct Contribution');
		Test.stopTest();
	}
	
	@IsTest
	private static void updateUserRoleOnOpportunitySplitsTest() {
	   // =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		UserRole uRole = ApplicationTestDataFactory.getUserRoles(1, true)[0];
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		uRecord.UserRole = new UserRole(Id=uRole.Id, RollupDescription = 'TestRole');
		//Updated unwritable field on User
		uRecord = (User)ApplicationTestDataFactory.setUnwritableFields(uRecord, new Map<String, Object>{'Current_Owner_Role__c' => 'TestRole'});
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opportunityRecord.ownerId = uRecord.Id ;
		
		
		OpportunitySplit opportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord.Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];	   
		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSplitSelector opportunitySplitSelector = (OpportunitiesSplitSelector)MockUtility.mockSelector(OpportunitiesSplitSelector.class);
	  
		UsersSelector usrSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, OpportunitySplit> mockOPPSplitMap = new Map<Id, OpportunitySplit>{opportunitySplitRecord.Id => opportunitySplitRecord};
		MockUtility.Mocks.when(opportunitySplitSelector.selectByOpportunity(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPSplitMap);
		Map<Id, User> mockUsrMap = new Map<Id, User>{uRecord.Id => uRecord};
		MockUtility.Mocks.when(usrSelector.selectById(new Set<Id>{uRecord.Id}, new Set<Object>{UsersSelector.Options.WITH_ROLE})).thenReturn(mockUsrMap);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		List<Opportunity> oppList = new List<Opportunity>{opportunityRecord};
		OpportunityUtility_part2.updateUserRoleOnOpportunitySplits(oppList);
		System.assertEquals(mockOPPSplitMap.values()[0].Split_Member_Role_At_Opportunity_Closure__c , 'TestRole');
		Test.stopTest();
	}
	
	@IsTest
	private static void opportunitySplitDeleteTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		List<User> uRecordList = ApplicationTestDataFactory.getUsers(1, true);
		OpportunitySplit splitRecordRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecordList[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Solution Specialist' , true)[0];			   
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
	   // set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
			List<OpportunitySplit> splitList = new List<OpportunitySplit>();
			splitList.add(splitRecordRecord);
			cntrl.createOpportunitySplitHistoryOnDelete(splitList);
		Test.stopTest();
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}
	@IsTest
	private static void createOpportunitySplitHistoryTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		List<User> uRecordList = ApplicationTestDataFactory.getUsers(1, true);
		OpportunitySplit splitRecordRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecordList[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType,'Solution Specialist' , true)[0];			   
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
	   // set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
			List<OpportunitySplit> splitList = new List<OpportunitySplit>();
			splitList.add(splitRecordRecord);
			cntrl.createOpportunitySplitHistory(splitList);
		Test.stopTest();
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}	
	
	@IsTest
	private static void populateSplitMemberRoleAtOpportunityClosureTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		UserRole uRole = ApplicationTestDataFactory.getUserRoles(1, true)[0];
		List<User> uRecord = ApplicationTestDataFactory.getUsers(2, true);
		uRecord[1].UserRole = new UserRole(Id=uRole.Id, RollupDescription = 'TestRole');
		//Updated unwritable field on User
		uRecord[1] = (User)ApplicationTestDataFactory.setUnwritableFields(uRecord[1], new Map<String, Object>{'Current_Owner_Role__c' => 'TestRole'});
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opportunityRecord.stageName = '	Closed/Won';
		OpportunitySplit existingOpportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord[0].Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];
		existingOpportunitySplitRecord.SplitPercentage = 100;
		OpportunitySplit newOpportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord[1].Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];			  
		newOpportunitySplitRecord.SplitPercentage = 0;
		newOpportunitySplitRecord.Split_Member_Role_At_Opportunity_Closure__c = null;
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		OpportunitiesSplitSelector opportunitySplitSelector = (OpportunitiesSplitSelector)MockUtility.mockSelector(OpportunitiesSplitSelector.class);
		UsersSelector usrSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		Map<Id, OpportunitySplit> mockOPPSplitMap = new Map<Id, OpportunitySplit>{existingOpportunitySplitRecord.Id => existingOpportunitySplitRecord, newOpportunitySplitRecord.Id => newOpportunitySplitRecord};
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);
		MockUtility.Mocks.when(opportunitySplitSelector.selectByOpportunity(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPSplitMap);
		Map<Id, User> mockUsrMap = new Map<Id, User>{uRecord[1].Id => uRecord[1]};
		MockUtility.Mocks.when(usrSelector.selectById(new Set<Id>{uRecord[1].Id}, new Set<Object>{UsersSelector.Options.WITH_ROLE})).thenReturn(mockUsrMap);
		MockUtility.Mocks.stopStubbing();
		
		Map<Id, OpportunitySplit> mockOPPSplitMapVar = new Map<Id, OpportunitySplit>{existingOpportunitySplitRecord.opportunityId => existingOpportunitySplitRecord, newOpportunitySplitRecord.opportunityId => newOpportunitySplitRecord};
			
		OpportunitySplitUtility cntrl = new OpportunitySplitUtility();
		Test.startTest();
			List<OpportunitySplit> splitList = new List<OpportunitySplit>();
			splitList.add(newOpportunitySplitRecord);
			cntrl.populateSplitMemberRoleAtOpportunityClosure(splitList);
			System.assertEquals(splitList[0].Split_Member_Role_At_Opportunity_Closure__c , splitList[0].Split_Member_Current_Role__c);
		Test.stopTest();
		
	}
	@IsTest
	private static void OpportunitySplitQueueableUtilTest() {
	   // =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		UserRole uRole = ApplicationTestDataFactory.getUserRoles(1, true)[0];
		List<User> uRecord = ApplicationTestDataFactory.getUsers(2, true);
		uRecord[1].UserRole = new UserRole(Id=uRole.Id, RollupDescription = 'TestRole');
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opportunityRecord.ownerId = uRecord[1].Id ;
		opportunityRecord.stageName = '	Closed/Won';
		user usrTemp = uRecord[1];
		
		
		OpportunitySplit existingOpportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord[0].Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];
		existingOpportunitySplitRecord.SplitPercentage = 100;
		OpportunitySplit newOpportunitySplitRecord = ApplicationTestDataFactory.getOpportunitySplits(1, opportunityRecord.Id, uRecord[1].Id, ApplicationTestDataFactory.directContributionOverlayType,null , true)[0];			  
		newOpportunitySplitRecord.SplitPercentage = 0;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		OpportunitiesSelector opportunitySelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		OpportunitiesSplitSelector opportunitySplitSelector = (OpportunitiesSplitSelector)MockUtility.mockSelector(OpportunitiesSplitSelector.class);
		UsersSelector usrSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{opportunityRecord.Id => opportunityRecord};
		Map<Id, OpportunitySplit> mockOPPSplitMap = new Map<Id, OpportunitySplit>{existingOpportunitySplitRecord.Id => existingOpportunitySplitRecord, newOpportunitySplitRecord.Id => newOpportunitySplitRecord};
		
		MockUtility.Mocks.when(opportunitySelector.selectById(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPMap);
		MockUtility.Mocks.when(opportunitySplitSelector.selectByOpportunity(new Set<Id>{opportunityRecord.Id})).thenReturn(mockOPPSplitMap);
		Map<Id, User> mockUsrMap = new Map<Id, User>{usrTemp.Id => usrTemp, uRecord[0].Id => uRecord[0]};
		MockUtility.Mocks.when(usrSelector.selectById(new Set<Id>{usrTemp.Id, uRecord[0].Id}, new Set<Object>{UsersSelector.Options.WITH_ROLE})).thenReturn(mockUsrMap);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		Map<Id, Opportunity> mockOPPWithOldOwner = new Map<Id, Opportunity>{uRecord[0].Id => opportunityRecord};
		OpportunitySplitQueueableUtil OpportunitySplitQueueableUtilCtr = new OpportunitySplitQueueableUtil(mockOPPWithOldOwner);
		  Test.startTest();
			System.enqueueJob(OpportunitySplitQueueableUtilCtr);
		  Test.stopTest();
		  
		  ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
		  ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure overlay types are filtered based on the filters passed in.
	 */
	@IsTest
	static void testGetSpecialistUserGroupOverlayTypeMappings() {
		// =====================================
		// Data Preparation
		// =====================================
		List<SalesOverlayTypeMapping__mdt> overlayTypeMappings = getOverlayTypeMappings(4, true);

		// configure overlayTypeMappings[0] to support auto assignment on opportunity creation and keep splits on opportunity transfer
		overlayTypeMappings[0].AutoAssignOnOpportunityCreation__c = true;
		overlayTypeMappings[0].KeepSplitsOnOpportunityTransfer__c = true;

		// configure overlayTypeMappings[1] to only support auto assignment on opportunity creation
		overlayTypeMappings[1].AutoAssignOnOpportunityCreation__c = true;
		overlayTypeMappings[1].KeepSplitsOnOpportunityTransfer__c = false;

		// configure overlayTypeMappings[2] to only support keep splits on opportunity transfer
		overlayTypeMappings[2].AutoAssignOnOpportunityCreation__c = false;
		overlayTypeMappings[2].KeepSplitsOnOpportunityTransfer__c = true;

		// configure overlayTypeMappings[3] to support neither of auto assignment on opportunity creation and keep splits on opportunity transfer
		overlayTypeMappings[3].AutoAssignOnOpportunityCreation__c = false;
		overlayTypeMappings[3].KeepSplitsOnOpportunityTransfer__c = false;

		// inject overlay types metadata so we can test different configurations
		OpportunitySplitUtility.overlayTypesMetadata = new Map<String,SalesOverlayTypeMapping__mdt> {
				overlayTypeMappings[0].MasterLabel => overlayTypeMappings[0],
				overlayTypeMappings[1].MasterLabel => overlayTypeMappings[1],
				overlayTypeMappings[2].MasterLabel => overlayTypeMappings[2],
				overlayTypeMappings[3].MasterLabel => overlayTypeMappings[3]
		};

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// retrieve overlay type mappings when no filters are specified
		Map<String, Set<String>> overlayGroupMappings = OpportunitySplitUtility.getInstance().getSpecialistUserGroupOverlayTypeMappings(new Set<OpportunitySplitUtility.OverlayTypeFilters>());
		System.assertEquals(4, overlayGroupMappings.size(), 'Expected to return all available overlay type mappings when no filters are specified.');

		// retrieve overlay type mappings when filters are set to 'null'
		overlayGroupMappings = OpportunitySplitUtility.getInstance().getSpecialistUserGroupOverlayTypeMappings(null);
		System.assertEquals(4, overlayGroupMappings.size(), 'Expected to return all available overlay type mappings when filters are null.');

		overlayGroupMappings = OpportunitySplitUtility.getInstance().getSpecialistUserGroupOverlayTypeMappings(new Set<OpportunitySplitUtility.OverlayTypeFilters>{
				OpportunitySplitUtility.OverlayTypeFilters.SUPPORTS_AUTO_ASSIGNMENT
		});
		System.assertEquals(2, overlayGroupMappings.size(), 'Expected to return only overlay types configured to support auto assignment');

		overlayGroupMappings = OpportunitySplitUtility.getInstance().getSpecialistUserGroupOverlayTypeMappings(new Set<OpportunitySplitUtility.OverlayTypeFilters>{
				OpportunitySplitUtility.OverlayTypeFilters.SUPPORTS_KEEP_SPLITS
		});
		System.assertEquals(2, overlayGroupMappings.size(), 'Expected to return only overlay types configured to support keep splits');

		Test.stopTest();
	}

	/**
	 * Test to ensure eligible overlay types are returned for users based on their membership in sales specialist public groups.
	 */
	@IsTest
	static void testGetEligibleOverlayContributionTypes() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);
		List<SalesOverlayTypeMapping__mdt> overlayTypeMappings = OpportunitySplitUtility.overlayTypesMetadata.values();

		// =====================================
		// Stubbing
		// =====================================
		GroupMembershipService mockGroupMembershipService = ((GroupMembershipService) MockUtility.mockUtility(GroupMembershipService.class));

		// set up responses
		Map<String, Set<Id>> groupMembershipResponse = new Map<String, Set<Id>>{
				overlayTypeMappings[0].SalesSpecialistGroupName__c => new Set<Id>{users[0].Id, users[1].Id},
				overlayTypeMappings[1].SalesSpecialistGroupName__c => new Set<Id>{users[0].Id}
		};
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupMembershipService.expandGroupMembership((Set<String>)fflib_Match.anyObject(),(Set<GroupMembershipService.MemberTypes>) fflib_Match.anyObject())).thenReturn(groupMembershipResponse);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<String>> results = OpportunitySplitUtility.getInstance().getEligibleOverlayContributionTypes(new Set<Id>{users[0].Id, users[1].Id, users[2].Id}, new Set<OpportunitySplitUtility.OverlayTypeFilters>());

		Test.stopTest();

		System.assertEquals(2, results.size(), 'Only eligible users must be included in the returned results map');
		System.assert(results.containsKey(users[0].Id), 'Eligible user must be included in the returned results map');
		System.assert(results.containsKey(users[1].Id), 'Eligible user must be included in the returned results map');
		System.assert(!results.containsKey(users[2].Id), 'Ineligible user must not be included in the returned results map');

		System.assertEquals(2, results.get(users[0].Id).size(), 'All eligible overlay types must be returned for the user');
		System.assert(results.get(users[0].Id).contains(overlayTypeMappings[0].MasterLabel), 'All eligible overlay types must be returned for the user');
		System.assert(results.get(users[0].Id).contains(overlayTypeMappings[1].MasterLabel), 'All eligible overlay types must be returned for the user');
		System.assertEquals(1, results.get(users[1].Id).size(), 'All eligible overlay types must be returned for the user');
		System.assert(results.get(users[1].Id).contains(overlayTypeMappings[0].MasterLabel), 'All eligible overlay types must be returned for the user');
	}

	/**
	 * Test to ensure opportunity splits corresponding to overlay types passed in are created by the async worker and
	 * assigned to the opportunity owner.
	 */
	@IsTest
	static void testAsyncAutoAssignOpportunitySplitsWorker() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<User> opportunityOwners = ApplicationTestDataFactory.getUsers(2, true);
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
		// set up opportunity owners. opportunityOwners[2] owns two separate opportunities.
		opportunities[0].OwnerId = opportunityOwners[0].Id;
		opportunities[1].OwnerId = opportunityOwners[1].Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam> params = new List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam>();
		params.add(new OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam(opportunities[0].Id, opportunities[0].OwnerId, new Set<String>{'overlay1', 'overlay2'}));
		params.add(new OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam(opportunities[1].Id, opportunities[1].OwnerId, new Set<String>{'overlay1'}));

		OpportunitySplitUtility.AsyncAutoAssignOpportunitySplitsWorker worker = new OpportunitySplitUtility.AsyncAutoAssignOpportunitySplitsWorker();
		worker.deserialiseParams(Json.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		System.assertEquals(OpportunitySplitUtility.AsyncAutoAssignOpportunitySplitsWorker.class, worker.getClassType(), 'Expected to return the class type of the concrete worker class');
		System.assertEquals(OpportunitySplit.SObjectType, worker.getSObjectTypeGroup(), 'Expected to return OpportunitySplit sobject type');

		fflib_ArgumentCaptor argCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)argCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<SObject> insertedRecords = (List<SObject>) argCaptor.getValue();

		System.assertEquals(3, insertedRecords.size(), 'Expected to create opportunity splits for each overlay type for each user');
		System.assert(insertedRecords instanceof List<OpportunitySplit>, 'Expected to create opportunity splits for each overlay type for each user');
	}

	/**
	 * Test to ensure opportunity split snapshots passed in are reconciled by the async worker.
	 */
	@IsTest
	static void testAsyncReconcileOpportunitySplitsWorker() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		// setup 3 users
		// users[0] was the opportunity owner before transfer
		// users[1] is the new opportunity owner
		// users[2] is some other user who had overlay contribution split on opportunity before transfer
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		// set up new opportunity owner.
		opportunity.OwnerId = users[1].Id;

		// 2 overlay splits before transfer. one owned by previous opportunity owner - users[0]. other overlay split owned by
		// some other user users[2]
		List<OpportunitySplit> overlaySplitsBeforeTransfer = ApplicationTestDataFactory.getOpportunitySplits(2, opportunity.Id, users[0].Id, null, 'test', true);
		// setup overlay split owned by users[2]
		overlaySplitsBeforeTransfer[1] = (OpportunitySplit) ApplicationTestDataFactory.setUnwritableFields(overlaySplitsBeforeTransfer[1], new Map<String, Object>{
				'SplitOwnerId' => users[2].Id,
				'Overlay_Type__c' => 'test2'
		});

		// setup overlay splits after transfer. split owned by previous opportunity owner is now transferred across to new owner - users[1]
		List<OpportunitySplit> overlaySplitsAfterTransfer = ApplicationTestDataFactory.getOpportunitySplits(2, opportunity.Id, opportunity.OwnerId, null, 'test', true);
		// setup overlay split owned by users[2]
		overlaySplitsAfterTransfer[1] = (OpportunitySplit) ApplicationTestDataFactory.setUnwritableFields(overlaySplitsAfterTransfer[1], new Map<String, Object>{
				'SplitOwnerId' => users[2].Id,
				'Overlay_Type__c' => 'test2'
		});

		opportunity = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunity, new Map<String, List<SObject>>{'OpportunitySplits' => overlaySplitsAfterTransfer});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		OpportunitiesSelector mockOpportunitiesSelector = (OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class);
		OpportunitySplitUtility mockOpportunitySplitUtility = (OpportunitySplitUtility) MockUtility.mockUtility(OpportunitySplitUtility.class);

		// set up responses
		Map<Id, Set<String>> eligibleOverlayTypesResponse = new Map<Id, Set<String>>{
				users[0].Id => new Set<String>{'test1', 'test2'} // users[0] is eligible on 2 overlay types.
		};

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>{
				opportunity.Id =>opportunity
		});
		MockUtility.Mocks.when(mockOpportunitySplitUtility.getEligibleOverlayContributionTypes((Set<Id>)fflib_Match.anyObject(),(Set<OpportunitySplitUtility.OverlayTypeFilters>)fflib_Match.anyObject())).thenReturn(eligibleOverlayTypesResponse);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam param = new OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam(opportunity.Id, users[0].Id);
		param.addOpportunitySplitSnapshot(new OpportunitySplitUtility.OpportunitySplitSnapshot(overlaySplitsBeforeTransfer[0]));
		OpportunitySplitUtility.AsyncReconcileOpportunitySplitsWorker worker = new OpportunitySplitUtility.AsyncReconcileOpportunitySplitsWorker();
		worker.deserialiseParams(Json.serialize(new Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam>{opportunity.Id => param}));
		worker.execute(mockUow);

		Test.stopTest();

		System.assertEquals(OpportunitySplitUtility.AsyncReconcileOpportunitySplitsWorker.class, worker.getClassType(), 'Expected to return the class type of the concrete worker class');
		System.assertEquals(OpportunitySplit.SObjectType, worker.getSObjectTypeGroup(), 'Expected to return OpportunitySplit sobject type');

		fflib_ArgumentCaptor insertedSplitsArgCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)insertedSplitsArgCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<SObject> insertedRecords = (List<SObject>) insertedSplitsArgCaptor.getValue();

		System.assertEquals(1, insertedRecords.size(), 'Expected to create opportunity split for previous owner');
		System.assert(insertedRecords instanceof List<OpportunitySplit>, 'Expected to create opportunity split record for previous owner');

		fflib_ArgumentCaptor deletedSplitsArgCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDeleted((List<SObject>)deletedSplitsArgCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<SObject> deletedRecords = (List<SObject>) deletedSplitsArgCaptor.getValue();

		System.assertEquals(1, deletedRecords.size(), 'Expected to delete overlay opportunity split transferred to new owner');
		System.assert(deletedRecords instanceof List<OpportunitySplit>, 'Expected to delete overlay opportunity split record transferred to new owner');
	}

	public static List<SalesOverlayTypeMapping__mdt> getOverlayTypeMappings(Integer count, Boolean generateIds) {
		return (List<SalesOverlayTypeMapping__mdt>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(SalesOverlayTypeMapping__mdt.SObjectType, new Map<SObjectField, Object> {
				SalesOverlayTypeMapping__mdt.DeveloperName => 'OverlayType%count%',
				SalesOverlayTypeMapping__mdt.MasterLabel => 'OverlayType%count%',
				SalesOverlayTypeMapping__mdt.SalesSpecialistGroupName__c => 'Group%count%',
				SalesOverlayTypeMapping__mdt.AutoAssignOnOpportunityCreation__c => true,
				SalesOverlayTypeMapping__mdt.KeepSplitsOnOpportunityTransfer__c => true,
				SalesOverlayTypeMapping__mdt.DefaultPercentageAssignedOnCreation__c => 100
		}, count), generateIds);
	}
}