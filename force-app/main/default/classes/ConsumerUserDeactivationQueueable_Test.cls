/**
 * This apex class is test class for ConsumerUserDeactivationQueueable
 *
 *
 * @changelog:
 * 2023-10-01 Steve L - Created
*/
@IsTest
private class ConsumerUserDeactivationQueueable_Test {
	/**
	 * test deactivateConsumerUsers and execute method from ConsumerUserDeactivationQueueable, expect to result a list of User with blanked out fields
	 */
	@IsTest
	private static void testDeactivateConsumerUsers() {
		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
		});

		List<User> users = ApplicationTestDataFactory.getUsers(12, true);
		for (User user : users) {
			user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{
					'ContactId' => personContact.Id,
					'IsPortalEnabled' => true,
					'APCN__c' => '321312',
					'OID_ID__c' => '3425234',
					'FederationIdentifier' => 'example+32hjb2jh@example.com'
			});
			user.IsActive = true;
		}

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,User>(users));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ConsumerUserDeactivationQueueable service = new ConsumerUserDeactivationQueueable(new Set<Id> {personContact.Id});
		System.enqueueJob(service);

		Test.stopTest();

		for (User user : users) {
			System.assert(!user.IsActive, 'IsActive not correctly turned off');
			System.assert(!user.IsPortalEnabled, 'IsPortalEnabled not correctly turned off');
			System.assertEquals(null, user.APCN__c, 'Expecting APCN__c to be blanked out');
			System.assertEquals(null, user.OID_ID__c, 'Expecting OID_ID__c to be blanked out');
			System.assertEquals(null, user.FederationIdentifier, 'Expecting FederationIdentifier to be blanked out');
		}
	}
}