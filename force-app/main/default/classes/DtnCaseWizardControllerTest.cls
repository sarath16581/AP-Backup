/***
 * @author Ranjeewa Silva
 * @date 2020-11-02
 * @group Tests
 * @tag DirectToNetworkCaseCreation, Tests
 * @domain SSSW
 * @description Test Scenarios for Direct to Network Case creation
 * @changelog
 * 2020-11-02 - Ranjeewa Silva - Created.
 */

@IsTest
private class DtnCaseWizardControllerTest {
    @IsTest
    static void testDoDuplicateCheckWithExcludedProductCategory() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'test';
        newCase.ProductCategory__c = new List<String>(DtnCaseWizardController.DUPLICATE_CHECK_EXCLUDED_PRODUCT_CATEGORIES)[0];
        newCase.ProductSubCategory__c = 'testsubcategory';

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(false, result.isDuplicate, 'Expected false when product category is excluded from duplicate check.');
    }

    @IsTest
    static void testDoDuplicateCheckWithExcludedCaseType() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = DtnCaseWizardController.DUPLICATE_CHECK_EXCLUDED_CASE_TYPE;
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testsubcategory';

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(false, result.isDuplicate, 'Expected false when case type is excluded from duplicate check.');
    }

    @IsTest
    static void testDoDuplicateCheckWithExcludedProductSubCategory() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = DtnCaseWizardController.DUPLICATE_CHECK_EXCLUDED_PRODUCT_SUB_CATEGORY;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(false, result.isDuplicate, 'Expected false when product sub category is excluded from duplicate check.');
    }

    @IsTest
    static void testDoDuplicateCheckWhenNoOtherOpenCasesPresent() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(false, result.isDuplicate, 'Expected true when there are other open cases related to the article.');
    }

    @IsTest
    static void testDoDuplicateCheckWhenOtherOpenCasesPresent() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(true, result.isDuplicate, 'Expected true when there are other open cases related to the article.');
        System.assertEquals(false, result.canIgnoreDuplicate, 'Expected false as the user is not a designated HLC user.');
        System.assertEquals(System.Label.DirectToNetworkDuplicateCaseErrorMessage, result.errorMessage, 'Expected duplicate check error message for a user not designated as HLC user.');
    }

    @IsTest
    static void testDoDuplicateCheckForHLCUserWhenOtherOpenCasesPresent() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DuplicateCheckResult result = DtnCaseWizardController.doDuplicateCheck(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(true, result.isDuplicate, 'Expected true when there are other open cases related to the article.');
        System.assertEquals(true, result.canIgnoreDuplicate, 'Expected false as the user is not a designated HLC user.');
        System.assertEquals(System.Label.DirectToNetworkDuplicateCaseWarningMessage, result.errorMessage, 'Expected duplicate check warning message is returned for designated HLC user.');
    }

    @IsTest
    static void testCreateCaseDuplicateCasesPresent() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DTNCaseSaveResult result = DtnCaseWizardController.createCaseDirectToNetwork(newCase, false, false);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(DtnCaseWizardController.Status.DUPLICATE.name(), result.status, 'Expected DTN case creation to fail with status = DUPLICATE.');
        System.assertEquals(false, result.canIgnoreDuplicate, 'Expected false as the user is not a designated HLC user.');
        System.assertEquals(System.Label.DirectToNetworkDuplicateCaseErrorMessage, result.errorMessage, 'Expected to get duplicate check error as the user is not designated HLC user.');
        System.assertEquals(null, result.caseId, 'Expected case Id to be null when DTN case creation fails with duplicate error.');

        // should not have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert(new List<SObject>{newCase});
    }

    @IsTest
    static void testCreateCaseByHLCUserWhenDuplicateCasesPresentAndIgnoreDuplicatesOff() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DTNCaseSaveResult result = DtnCaseWizardController.createCaseDirectToNetwork(newCase, false, false);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(DtnCaseWizardController.Status.DUPLICATE.name(), result.status, 'Expected DTN case creation to fail with status = DUPLICATE.');
        System.assertEquals(true, result.canIgnoreDuplicate, 'Expected true as the user can ignore the duplicate as a designated HLC user.');
        System.assertEquals(System.Label.DirectToNetworkDuplicateCaseWarningMessage, result.errorMessage, 'Expected to get Duplicate Check warning as the user is a designated HLC user.');
        System.assertEquals(null, result.caseId, 'Expected case Id to be null when DTN case creation fails with duplicate error.');

        // should not have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert(new List<SObject>{newCase});
    }

    @IsTest
    static void testCreateCaseByHLCUserWhenDuplicateCasesPresentAndIgnoreDuplicatesOn() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        Group ssswNetworkQueue = ApplicationTestDataFactory.getGroups(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);
        GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(1);
        MockUtility.Mocks.when(mockGroupsSelector.selectByDeveloperName((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Group>{ssswNetworkQueue.Id => ssswNetworkQueue});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DTNCaseSaveResult result = DtnCaseWizardController.createCaseDirectToNetwork(newCase, true, false);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(DtnCaseWizardController.Status.SUCCESSFUL.name(), result.status, 'Expected DTN case creation to be successful.');
        System.assertNotEquals(null, result.caseId, 'Expected id of the newly inserted case to be populated but instead got null.');

        // should have inserted the new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newCase});
    }

    @IsTest
    static void testCreateCaseNoDuplicateCasesPresent() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        Group ssswNetworkQueue = ApplicationTestDataFactory.getGroups(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);
        GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.when(mockGroupsSelector.selectByDeveloperName((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Group>{ssswNetworkQueue.Id => ssswNetworkQueue});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DTNCaseSaveResult result = DtnCaseWizardController.createCaseDirectToNetwork(newCase, false, false);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(DtnCaseWizardController.Status.SUCCESSFUL.name(), result.status, 'Expected DTN case creation to be successful.');
        System.assertNotEquals(null, result.caseId, 'Expected id of the newly inserted case to be populated but instead got null.');

        // should have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newCase});
    }

    @IsTest
    static void testCreateCaseDMLException() {

        // =====================================
        // Data Preparation
        // =====================================
        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'testcasetype';
        newCase.ProductCategory__c = 'testproductcat';
        newCase.ProductSubCategory__c = 'testproductsubcat';

        Group ssswNetworkQueue = ApplicationTestDataFactory.getGroups(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        SSSWCasesSelector mockSSSWCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
        GroupMembersSelector mockGroupMembersSelector = (GroupMembersSelector)MockUtility.mockSelector(GroupMembersSelector.class);
        GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSSSWCasesSelector.countOpenCasesByReferenceId((Set<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.when(mockGroupMembersSelector.countByMyGroups((List<String>)fflib_Match.anyObject())).thenReturn(0);
        MockUtility.Mocks.when(mockGroupsSelector.selectByDeveloperName((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Group>{ssswNetworkQueue.Id => ssswNetworkQueue});
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        DtnCaseWizardController.DTNCaseSaveResult result = DtnCaseWizardController.createCaseDirectToNetwork(newCase, false, false);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a valid response instance but instead got null.');
        System.assertEquals(DtnCaseWizardController.Status.ERROR.name(), result.status, 'Expected DTNCaseSaveResult status = ERROR when there is an unexpected DML exception.');
        System.assertEquals(null, result.caseId, 'Expected case Id to be null when there is a DML error.');

        // should have attempted to insert new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newCase});
    }

    @IsTest
    static void testGetCaseDescriptionDefaultValue() {

        // =====================================
        // Data Preparation
        // =====================================

        Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
        newCase.ReferenceID__c = 'testrefid0000000';
        newCase.Type = 'Investigation';
        newCase.Description = null;


        // create a new routing rule in the database for SSSW_Routing to pick up
        // NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
        Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = :SSSWConstants.RECTYPEDESCRIPTION].Id;

        List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

        // Setup a rule that will match case based on type
        SSSWRouting__c routingRule = new SSSWRouting__c();
        routingRule.RecordTypeId = routingRuleRecordTypeId;
        routingRule.Match_Rules_On__c = 'All';
        routingRule.CaseType__c = 'Investigation';
        routingRule.IsActive__c = true;
        routingRule.DefaultCaseDetails__c = 'test message to network';
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        insert routesToInsert;

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        String result = DtnCaseWizardController.getCaseDescriptionDefaultValue(newCase);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected the default case description based on description rules but instead got null.');
        System.assertEquals(routingRule.DefaultCaseDetails__c, result, 'Expected the default case details beased on matching description rule.');
    }

    private class MockException extends Exception
    {
    }


}