/**
 * @author Harry Wang
 * @date 2024-08-14
 * @tag ContentDocument
 * @description Test class for LinkContentDocument
 * @changelog
 * 2024-08-14 - Harry Wang - Created
 */
@IsTest
public with sharing class LinkContentDocument_Test {
	/**
	 * Test:
	 *  Ensures that the content document is linked without issues
	 */
	@IsTest
	private static void testLinkContentDocument() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(1, true);
		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Database.SaveResult> results = LinkContentDocument.linkContentDocument(new List<Id>{documentId}, accs[0].Id);
		System.assert(results[0].isSuccess(), 'Expected success');
		Test.stopTest();
	}
}