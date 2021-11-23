/**
* @description Test class for covering ChasJitLoginHandler
* @author Nathan Franklin
* @date 2020-04-24
* @group Tests
* @tags Service, Chas, Help and Support, H&S, Jit, login, login handler
* @domain Help and Support
* @changelog
*/
@IsTest
private with sharing class ChasJitLoginHandler_Test {

	/**
	 * Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitCreateUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
		});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		System.debug(user);

		// =====================================
		// Stubbing
		// =====================================
		// stub service class since we don't need to test it here
		ChasJitService mockService = (ChasJitService)MockUtility.mockUtility(ChasJitService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.validateAssertion(fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject())).thenReturn(new List<String>());
		MockUtility.Mocks.when(mockService.matchOrCreate(fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject())).thenReturn(user);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitLoginHandler loginHandler = new ChasJitLoginHandler();

		// can ignore attributes that aren't being used by passing null
		User createdUser = loginHandler.createUser(null, null, null, 'nathan@test.com', new Map<String, String>(), '');

		// make sure the method behaved
		((ChasJitService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).validateAssertion(fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject());
		((ChasJitService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchOrCreate(fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitUpdateUser() {

		// =====================================
		// Data Preparation
		// =====================================
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// stub service class since we don't need to test it here
		ChasJitService mockService = (ChasJitService)MockUtility.mockUtility(ChasJitService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.updateExistingUser(fflib_Match.anyId(), fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject())).thenReturn(user);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitLoginHandler loginHandler = new ChasJitLoginHandler();

		// can ignore attributes that aren't being used by passing null
		loginHandler.updateUser(user.Id, null, null, null, 'nathan@test.com', new Map<String, String>(), '');

		// make sure the method behaved
		((ChasJitService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).updateExistingUser(fflib_Match.anyId(), fflib_Match.anyString(), (Map<String, String>)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}
}