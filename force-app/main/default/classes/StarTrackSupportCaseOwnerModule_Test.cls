/**
 * @description
 * Test class for StarTrackSupportCaseOwnerModule
 * @author Madhusudhan
 * @date 2021-06-17
 * @group Tests
 * @domain StarTrack
 * @changelog
 * 2021-11-09 Naveen Rajanna REQ2656153 - Fix failing test class
 * 2022-08-25 Mahesh Parvathaneni DDS-11558 - Added test method testEnsureCaseStatusNotPopulatedSTHSTrackingForm
 */
@IsTest
private class StarTrackSupportCaseOwnerModule_Test {
    /**
     *  Test: User to test change of case owner
     */
    @testSetup
    static void createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support'];
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User supportUser = new User(
            Alias = 'stspUser',
            Email = 'user@testorg.com.au',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = r.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'user@testorg.a'
        );
        Database.insert(supportUser);
    }

    /**
     *  Test: BeforeUpdate Scenario, change the case owner to see status updated to "Awaiting Investigation"
     */

    @IsTest
    private static void testEnsureBeforeUpdatePopulatesCaseStatusandMilestonesCompletionDate() {
        // =====================================
        // Data Preparation
        // =====================================

        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        List<Case> oldCases = new List<Case>{ cases[0].clone(true), cases[1].clone(true) };
        List<CaseMilestone> relatedMilestones = new List<CaseMilestone>();

        // Set the status, recordtypeId on case
        cases[0].Status = 'New';
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

        // Change Owner
        cases[0].OwnerId = Userinfo.getUserId();

        // =====================================
        // Stubbing
        // =====================================
        CaseMilestonesSelector mockCaseMilestonesSelector = (CaseMilestonesSelector) MockUtility.mockSelector(
            CaseMilestonesSelector.class
        );

        // Set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCaseMilestonesSelector.selectByCase(new Set<Id>{ cases[0].Id }))
            .thenReturn(new Map<Id, CaseMilestone>(relatedMilestones));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCaseOwnerModule module = StarTrackSupportCaseOwnerModule.newInstance();
        module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

        Test.stopTest();

        // Make sure the method behaved
        ((CaseMilestonesSelector) MockUtility.Mocks.verify(mockCaseMilestonesSelector, 1))
            .selectByCase(new Set<Id>{ cases[0].Id });

        // Make sure fields updated correctly
        System.assertEquals(
            'Awaiting Investigation',
            cases[0].Status,
            'Expected status to be Awaiting Investigation on case'
        );
    }

    /**
     *  Scenario: Integration Scenario, change the case owner to see status updated to "Awaiting Investigation"
     */
    @IsTest
    public static void testEnsureCaseStatusPopulatedIntegration() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);

        cases[0].Status = 'New';
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

        // =====================================
        // Testing
        // =====================================

        Test.startTest();

        User supportUser = [SELECT Id, Name FROM User WHERE Alias = :'stspUser' LIMIT 1];

        System.runAs(supportUser) {
            insert cases;
        }

        // Change owner
        cases[0].OwnerId = Userinfo.getUserId();
        update Cases;

        List<Case> updatedCases = [SELECT Id, Status FROM Case WHERE Id = :cases[0].Id];

        Test.stopTest();

        // Make sure fields were updated correctly
        System.assertEquals(
            'Awaiting Investigation',
            updatedCases[0].Status,
            'Expected status to be Awaiting Investigation on case'
        );
    }

    /**
     *  Scenario: StarTrack Tracking Enquiry Form Scenario, case created by AP Integration user has case status not updated to "Awaiting Investigation"
     */
    @IsTest
    public static void testEnsureCaseStatusNotPopulatedSTHSTrackingForm() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].Status = 'New';
        cases[0].Origin = 'Web';
        cases[0].Subject = 'Tracking Enquiry';
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        List<Case> oldCases = new List<Case>{ cases[0].clone(true) };

        //get ap user
        User apUser = ApplicationTestDataFactory.getUsers(1, true)[0];
        oldCases[0].ownerId = apUser.Id;
        cases[0].OwnerId = UserInfo.getUserId();
		

        // =====================================
		// Stubbing
		// =====================================
        UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
        GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockUsersSelector.selectByName(new Set<String>{'AP Integration'})).thenReturn(new Map<Id, User>{apUser.Id => apUser});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================

        Test.startTest();

        StarTrackSupportCaseOwnerModule module = StarTrackSupportCaseOwnerModule.newInstance();
        module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

        // should have attempted to call UsersSelector
        ((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).selectByName((Set<String>)fflib_Match.eq(new Set<String>{'AP Integration'}));

        // Make sure fields were updated correctly
        System.assertEquals(
            'New',
            cases[0].Status,
            'Expected status to be New on case'
        );
    }
}