/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description Test class for CompensationService
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
@IsTest
private class CompensationService_Test {

    @TestSetup
    static void setupData() {
        Test.startTest();
        // Creating users in async context to avoid mix DML issues
        // create a compensation user: allows to create compensation records but not allowed to create dupes or update bank account details
        List<TestDataFactory.UserDTO> userDTOs = new List<TestDataFactory.UserDTO>();
        TestDataFactory.UserDTO agent = new TestDataFactory.UserDTO();
        agent.profileName = 'SSSW - Service Agent';
        agent.permissionSetNames = new Set<String>{'CC_Compensation_User'};
        agent.userName = 'agent';
        agent.role = 'CEO/Reporting';
        userDTOs.add(agent);

        // create a super user: allows to create compensation records, update bank account details, create multiple compensations, send emails
        TestDataFactory.UserDTO superAgent = new TestDataFactory.UserDTO();
        superAgent.profileName = 'SSSW - Service Agent';
        superAgent.permissionSetNames = new Set<String>{'CC_Compensation_Supervisor'};
        superAgent.userName = 'Superagent';
        superAgent.role = 'CEO/Reporting';
        userDTOs.add(superAgent);

        TestDataFactory.InsertUsersQueueable queueable = new TestDataFactory.InsertUsersQueueable(userDTOs);
        System.enqueueJob(queueable);
        Test.stopTest();
    }

    /**
     * Testing of CurrentArticleId__c being updated whe the compensation record is getting created,
     * the value should get populated from the Case.ReferenceId__c field.
     */
    @IsTest
    static void testUpdateCurrentArticleInfoOnCompensationRecord() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{
                cases[0].Id => cases[0]
        });
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        CompensationService.getInstance().updateCurrentArticleInfoOnCompensationRecord(compensations);
        Test.stopTest();
        System.assertEquals(
                'REF0001',
                compensations[0].CurrentArticleId__c,
                'updateCurrentArticleInfoOnCompensationRecord : Current Article field should be updated'
        );
    }

    /**
     * testing when a case is created if a duplicate compensating for a reference ID is found through the system
     * this test is to check with duplicate compensations
     */
    @IsTest
    static void testGetCompensationRecordByCaseIdsDuplicatesFound() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(2, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        List<Compensation__c> compensations2 = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        compensations.addAll(compensations2);

        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockCasesSelector.selectByReferenceIdOrderByCreatedDate((Set<String>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockCompensationSelector.selectByCaseIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(compensations);
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        Map<Id, List<Compensation__c>> groupedCompensationByCaseIds = CompensationService.getInstance().getCompensationRecordByCaseIds(casesByIds.keySet());
        Test.stopTest();

        Boolean isDuplicatesFound = false;
        for (Compensation__c compensation : compensations) {
            List<Compensation__c> compensationsForCaseId = groupedCompensationByCaseIds.get(compensation.Case__c);
            if (!compensationsForCaseId.isEmpty() && compensationsForCaseId.size() > 0) {
                isDuplicatesFound = true;
            }
        }

        System.assertEquals(
                true,
                isDuplicatesFound,
                'updateCurrentArticleInfoOnCompensationRecord : Expecting more than one compensation records per reference'
        );
    }

    /**
     * Testing no duplicate compensations found per case's reference number
     */
    @IsTest
    static void testGetCompensationRecordByCaseIdsNoDuplicatesFound() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Case> cases = ApplicationTestDataFactory.getCases(2, 'REF0001', true);
        Map<Id, Case> casesByIds = new Map<Id, Case>();
        for(Case cse : cases) {
            casesByIds.put(cse.id, cse);
        }
        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        CompensationSelector mockCompensationSelector = (CompensationSelector) MockUtility.mockSelector(CompensationSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockCasesSelector.selectByReferenceIdOrderByCreatedDate((Set<String>) fflib_Match.anyObject())).thenReturn(casesByIds);
        MockUtility.Mocks.when(mockCompensationSelector.selectByCaseIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn((List<Object>) fflib_Match.anyObject());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        Map<Id, List<Compensation__c>> groupedCompensationByCaseIds = CompensationService.getInstance().getCompensationRecordByCaseIds(casesByIds.keySet());
        Test.stopTest();

        System.assertEquals(
                true,
                groupedCompensationByCaseIds.size() == 0,
                'testGetCompensationRecordByCaseIdsNoDuplicatesFound : since No existing compensation records for the case No records should return'
        );
    }
}