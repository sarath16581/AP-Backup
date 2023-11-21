/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description Test class for CompensationUtilityModule
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
@IsTest
private class CompensationUtilityModule_Test {

    @TestSetup
    static void setupData() {
        Test.startTest();
        // create a super user: allows to create compensation records, update bank account details, create multiple compensations, send emails
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
        TestDataFactory.UserDTO superAgent = new TestDataFactory.UserDTO();
        superAgent.profileName = 'SSSW - Service Agent';
        superAgent.permissionSetNames = new Set<String>{'CC_Compensation_Supervisor'};
        superAgent.userName = 'Superagent';
        superAgent.role = 'CEO/Reporting';
        userDTOs.add(superAgent);

        // create a compensation user: allows to create compensation records but not allowed to create dupes or update bank account details
        TestDataFactory.UserDTO agent = new TestDataFactory.UserDTO();
        agent.profileName = 'SSSW - Service Agent';
        agent.permissionSetNames = new Set<String>{'CC_Compensation_User'};
        agent.userName = 'agent456';
        agent.role = 'CEO/Reporting';
        userDTOs.add(agent);

        // user with SSSW agent profile and without any permission sets assigned
        TestDataFactory.UserDTO normalUser = new TestDataFactory.UserDTO();
        normalUser.profileName = 'SSSW - Service Agent';
        normalUser.permissionSetNames = null;
        normalUser.userName = 'normalUser';
        normalUser.role = 'CEO/Reporting';
        userDTOs.add(normalUser);

        TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
        System.enqueueJob(queueable);
        Test.stopTest();
    }
    /**
     * Testing of field updates on the module for before insert
     */
    @IsTest
    static void testUpdateCurrentArticleInfoOnCompensationRecord() {
        // =====================================
        // Stubbing
        // =====================================
        CompensationService mockService = (CompensationService) MockUtility.mockUtility(CompensationService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        module.onBeforeInsert(compensations, uow);
        ((CompensationService) MockUtility.Mocks.verify(
                mockService,
                MockUtility.Mocks.times(1))).updateCurrentArticleInfoOnCompensationRecord((List<Compensation__c>) fflib_Match.eq(compensations)
        );
        // PMD warning
        System.assert(true);

        Test.stopTest();
    }
    /**
     * Testing of creating duplicate compensation records per Case reference without permissions,
     * should throw an error
     */
    @IsTest
    static void TestValidateMoreThanOneCompensationsPerReferenceIdNoPermissionsUser() {
        // =====================================
        // Data Preparation
        // =====================================
        User normalUser = [SELECT Id FROM User WHERE FirstName = 'normalUser'];
        List<Case> cases = ApplicationTestDataFactory.getCases(2, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        List<Compensation__c> compensations2 = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        compensations.addAll(compensations2);
        Map<Id, List<Compensation__c>> compensationsByCase = new Map<Id, List<Compensation__c>>();
        for (Compensation__c comp : compensations) {
            List<Compensation__c> compensationsGroup = compensationsByCase.get(comp.Case__c);
            if (compensationsGroup == null) {
                compensationsByCase.put(comp.Case__c, new List<Compensation__c>{
                        comp
                });
                continue;
            }
            compensationsGroup.add(comp);
        }
        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        CompensationService mockService = (CompensationService) MockUtility.mockUtility(CompensationService.class);
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockService.getCompensationRecordByCase((List<Case>) fflib_Match.anyObject())).thenReturn(compensationsByCase);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        system.runAs(normalUser) {
            module.onBeforeInsert(compensations, uow);
        }
        Test.stopTest();
        for(Compensation__c  comp : compensations){
            System.assertEquals(
                Label.CompensationMsgMoreThanOnePerCaseReference,
                comp.getErrors()[0].getMessage(),
                'TestValidateMoreThanOneCompensationsPerReferenceId: User should not be able to create more than one compensation record');
        }
    }

    /**
     * Testing of duplicate compensation record creation as a user with custom permission CC_Compensation_Supervisor,
     * should not throw any errors
     */
    @IsTest
    static void TestValidateMoreThanOneCompensationsPerReferenceIdAsASuperUser() {
        // =====================================
        // Data Preparation
        // =====================================
        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        List<Case> cases = ApplicationTestDataFactory.getCases(2, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        List<Compensation__c> compensations2 = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        compensations.addAll(compensations2);
        Map<Id, List<Compensation__c>> compensationsByCase = new Map<Id, List<Compensation__c>>();
        for (Compensation__c comp : compensations) {
            List<Compensation__c> compensationsGroup = compensationsByCase.get(comp.Case__c);
            if (compensationsGroup == null) {
                compensationsByCase.put(comp.Case__c, new List<Compensation__c>{
                        comp
                });
                continue;
            }
            compensationsGroup.add(comp);
        }
        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        CompensationService mockService = (CompensationService) MockUtility.mockUtility(CompensationService.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.getCompensationRecordByCaseIds((Set<Id>) fflib_Match.anyObject())).thenReturn(compensationsByCase);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        system.runAs(superagent) {
            module.onBeforeInsert(compensations, uow);
        }
        Test.stopTest();
        for(Compensation__c  comp : compensations){
            System.assertEquals(
                false,
                comp.hasErrors(),
                'TestValidateMoreThanOneCompensationsPerReferenceId: User with super user permissions should be able to create duplicate compensations');
        }
    }

    /**
     * Testing of agent user trying to create a compensation record where the related case doesn't have a
     * reference value
     */
    @IsTest
    static void TestValidateRelatedCaseDoesNotHaveAReferenceAsAnAgentUser() {
        // =====================================
        // Data Preparation
        // =====================================
        User agentUser = [SELECT Id FROM User WHERE FirstName = 'agent456'];
        List<Case> cases = ApplicationTestDataFactory.getCases(2, (String)null, true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, false);
        Map<Id, List<Compensation__c>> compensationsByCase = new Map<Id, List<Compensation__c>>();
        for (Compensation__c comp : compensations) {
            List<Compensation__c> compensationsGroup = compensationsByCase.get(comp.Case__c);
            if (compensationsGroup == null) {
                compensationsByCase.put(comp.Case__c, new List<Compensation__c>{
                        comp
                });
                continue;
            }
            compensationsGroup.add(comp);
        }

        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        CompensationService mockService = (CompensationService) MockUtility.mockUtility(CompensationService.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockService.getCompensationRecordByCaseIds((Set<Id>) fflib_Match.anyObject())).thenReturn(compensationsByCase);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        system.runAs(agentUser) {
            module.onBeforeInsert(compensations, uow);
        }
        Test.stopTest();

        for(Compensation__c  comp : compensations){
            System.assertEquals(
                Label.CompensationMsgCaseMustHaveReference,
                comp.getErrors()[0].getMessage(),
                'TestValidateRelatedCaseDoesNotHaveAReferenceAsAnAgentUser: User with super user permissions should be able to create duplicate compensations'
            );
        }
    }

    /**
     * Testing of super user trying to create a compensation record where the related case doesn't have a
     * reference value should allow the user to create the record
     */
    @IsTest
    static void TestValidateRelatedCaseDoesNotHaveAReferenceAsASuperUser() {
        // =====================================
        // Data Preparation
        // =====================================
        User superagent = [SELECT Id FROM User WHERE FirstName = 'Superagent'];
        List<Case> cases = ApplicationTestDataFactory.getCases(2, (String)null, true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, false);
        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CompensationTriggerHandler.getUnitOfWorkSObjectTypes());
        CompensationUtilityModule module = CompensationUtilityModule.newInstance();
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        system.runAs(superagent) {
            module.onBeforeInsert(compensations, uow);
        }
        Test.stopTest();

        for(Compensation__c  comp : compensations){
            System.assertEquals(
                    false,
                    comp.hasErrors(),
                    'TestValidateRelatedCaseDoesNotHaveAReferenceAsASuperUser: User with super user permissions should be able to create compensations without reference ID'
            );
        }
    }
}