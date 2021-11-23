/***
 * @author Ranjeewa Silva
 * @date 2021-03-09
 * @group Tests
 * @tag Case, Tests
 * @description Test Scenarios for attaching supporting documents to cases
 * @changelog
 * 2021-03-09 - Ranjeewa Silva - Created.
 */

@IsTest
private class CaseSupportingDocumentsController_Test {

    @IsTest
    static void testSearchCases() {
        // =====================================
        // Data Preparation
        // =====================================
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enterprise_Credit_Dispute_Claim').getRecordTypeId();

        List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
        for (Integer i=0; i < cases.size(); i++) {
            cases[i].ReferenceID__c = 'refid_' + i;
            cases[i].RecordTypeId = caseRecordTypeId;
        }

        List<String> searchTerms = new List<String>{'refid_1'};


        // =====================================
        // Stubbing
        // =====================================
        CasesSelector mockSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);


        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectOpenCasesByCaseNumberOrReferenceId((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id,Case>{cases[1].Id => cases[1]});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        Map<String, List<Case>> results = CaseSupportingDocumentsController.searchCases(searchTerms, new List<Id>{caseRecordTypeId});

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected to get valid search results; got null.');
        System.assertEquals(1, results.size(), 'Expected to get 1 case returned in search results');
        System.assert(results.containsKey(cases[1].ReferenceID__c), 'Expected to get the case matched based on Reference Id to be returned in search results');
    }

    @IsTest
    static void testUploadSupportingDocument() {
        // =====================================
        // Data Preparation
        // =====================================

        Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];


        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();


        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyList())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CaseSupportingDocumentsController.uploadSupportingDocument(caseRecord.Id, EncodingUtil.base64Encode(Blob.valueOf('test file contents')), 'testfile.csv');

        Test.stopTest();

        // should have inserted the new supporting document
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyList());
    }

    @IsTest
    static void testUploadSupportingDocumentUnexpectedException() {
        // =====================================
        // Data Preparation
        // =====================================

        Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];


        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();


        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyList())).thenThrow(new MockException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            CaseSupportingDocumentsController.uploadSupportingDocument(caseRecord.Id, EncodingUtil.base64Encode(Blob.valueOf('test file contents')), 'testfile.csv');
            System.assert(false, 'Expected to throw AuraHandledException in the case of an unexpected exception; but no exception thrown.');
        } catch (AuraHandledException auraEx) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected to throw AuraHandledException in the case of an unexpected exception; but different type of exception thrown.');
        }

        Test.stopTest();

        // should have attempted to insert the new supporting document
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyList());
    }

    private class MockException extends Exception {}
}