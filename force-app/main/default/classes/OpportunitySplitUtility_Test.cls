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

}