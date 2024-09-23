/**
 * @author Harry Wang
 * @date 2024-06-05
 * @tag CSP
 * @description Test class for ABNChangeContactCloningQueueable
 * @changelog
 * 2024-06-05 - Harry Wang - Created
 */
@IsTest
public with sharing class ABNChangeContactCloningQueueable_Test {
	/**
	 * Test:
	 *  Ensures that the queueable is instantiated and executed
	 */
	@IsTest
	private static void testCloneContactQueueable() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> oldContacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, true);
		List<Contact> newContacts = ApplicationTestDataFactory.getContacts(1, accs[1].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), (Database.DMLOptions)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id jobId = System.enqueueJob(new ABNChangeContactCloningQueueable(oldContacts, newContacts));
		AsyncApexJob job = [SELECT Id , Status FROM AsyncApexJob WHERE Id=:jobId LIMIT 1];
		System.assertEquals('Queued', job.Status, 'Job is expected to be queued; Actual: ' + job.Status);
		Test.stopTest();
	}
}