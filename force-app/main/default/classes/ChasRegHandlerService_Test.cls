/**
 * @description Test class for covering ChasRegHandlerService
 * @author Nathan Franklin
 * @date 2023-03-20
 * @changelog
 * 2023-08-04 - Mahesh Parvathaneni - Added tests for updateForExistingUser
 * 2023-08-31 - Mahesh Parvathaneni - updated test methods
 * 2023-09-19 - Mahesh Parvathaneni - updated test methods
*/
@IsTest
private with sharing class ChasRegHandlerService_Test {

	/**
	 * Scenario:
	 * Makes sure that when a person account / user record is not found, new records are provisioned to support the user login
	 * matchOrCreate should call createPersonAccount and getNewUserSObject
	 */
	@IsTest
	private static void testMatchOrCreateDoesAccountAndUserCreation() {

		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, false)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(personAccount, user);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.eq(new Set<String>{'123'}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>());
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenAnswer(new AnswerGetPeviouslyInsertedPersonAccountRecordAsMapAccount(personContact.Id));
		MockUtility.Mocks.when(mockRecordTypesSelector.selectByDeveloperName(fflib_Match.eqString('Account'), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, RecordType>{personAccountRecordType.Id => personAccountRecordType});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = new ChasRegHandlerService();
		User userForCreation = service.matchOrCreate(federationId, augmentedAttributes);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.never())).selectByContactId((Set<Id>)fflib_Match.anyObject());

		fflib_ArgumentCaptor apcnCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectByAPCN((Set<String>)apcnCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		System.assertEquals(new Set<String>{apcn}, (Set<String>)apcnCaptor.getValue());

		// capture and verify inserted Account record
		Account insertedAccount = ((List<Account>)MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase))[0];
		System.assertEquals(personAccount.FirstName, insertedAccount.FirstName);
		System.assertEquals(personAccount.LastName, insertedAccount.LastName);
		System.assertEquals(personAccount.PersonEmail, insertedAccount.PersonEmail);
		System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), insertedAccount.APCN__pc);
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), insertedAccount.OID_ID__pc);

		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{insertedAccount.Id}));

		System.assertEquals(federationId, userForCreation.FederationIdentifier);
		System.assertEquals(personContact.Id, userForCreation.ContactId);
		System.assertEquals(ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID, userForCreation.ProfileId);
		System.assertEquals(personAccount.FirstName, userForCreation.FirstName);
		System.assertEquals(augmentedAttributes.get('augmented_username'), userForCreation.Username);
	}

	/**
	 * Scenario:
	 * A person account record is found but without a user record
	 * matchOrCreate should call getNewUserSObject
	 */
	@IsTest
	private static void testMatchOrCreateDoesUserCreationWhenPersonAccountAlreadyExists() {

		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
			'PersonContactId' => personContact.Id
		});

		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(personAccount, user);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.eq(new Set<String>{'123'}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = new ChasRegHandlerService();
		User userForCreation = service.matchOrCreate(federationId, augmentedAttributes);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.never())).selectById((Set<Id>)fflib_Match.anyObject());

		fflib_ArgumentCaptor apcnCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectByAPCN((Set<String>)apcnCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		System.assertEquals(new Set<String>{apcn}, (Set<String>)apcnCaptor.getValue());

		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject());

		System.assertEquals(federationId, userForCreation.FederationIdentifier);
		System.assertEquals(personContact.Id, userForCreation.ContactId);
		System.assertEquals(ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID, userForCreation.ProfileId);
		System.assertEquals(personAccount.FirstName, userForCreation.FirstName);
		System.assertEquals(augmentedAttributes.get('augmented_username'), userForCreation.Username);
	}

	/**
	 * Scenario:
	 * A person account and a user record are both found. All the user attributes match the claims so no user update is necessary
	 */
	@IsTest
	private static void testMatchOrCreateNoNewRecordsNeededHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
			'PersonContactId' => personContact.Id
		});

		User userRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		userRecord = (User)ApplicationTestDataFactory.setUnwritableFields(userRecord, new Map<String, Object>{
			'ContactId' => personContact.Id,
			'IsPortalEnabled' => true
		});
		userRecord.IsActive = true;

		Auth.UserData userData = getUserData(personAccount, userRecord);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		//explicity make sure the user record matches all the claims for happy path scenario
		// this should avoid a dirty state requiring a DML update
		userRecord.Firstname = userData.firstName;
		userRecord.LastName = userData.lastName;
		userRecord.email = userData.email;
		userRecord.FederationIdentifier = augmentedAttributes.get('augmented_username');
		userRecord.Username = augmentedAttributes.get('augmented_username');

		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.eq(new Set<String>{'123'}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{userRecord.Id => userRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = new ChasRegHandlerService();
		User existingUser = service.matchOrCreate(federationId, augmentedAttributes);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlUpdate((List<SObject>)fflib_Match.anyObject());
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.never())).selectById((Set<Id>)fflib_Match.anyObject());

		fflib_ArgumentCaptor apcnCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectByAPCN((Set<String>)apcnCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		System.assertEquals(new Set<String>{apcn}, (Set<String>)apcnCaptor.getValue());

		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject());

		System.assertEquals(userRecord.Id, existingUser.Id);
		System.assertEquals(federationId, existingUser.FederationIdentifier);
		System.assertEquals(personAccount.FirstName, existingUser.FirstName);
		System.assertEquals(augmentedAttributes.get('augmented_username'), existingUser.Username);
	}

	/**
	 * Scenario:
	 * A person account and a user record are both found. The user record return in salesforce requires an update since some of it's attributes are out of sync with the claims
	 */
	@IsTest
	private static void testMatchOrCreateNoNewRecordsNeededByUserIsInDirtyState() {

		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
			'PersonContactId' => personContact.Id
		});

		User userRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		userRecord = (User)ApplicationTestDataFactory.setUnwritableFields(userRecord, new Map<String, Object>{
			'ContactId' => personContact.Id,
			'IsPortalEnabled' => true
		});
		userRecord.IsActive = true;

		Auth.UserData userData = getUserData(personAccount, userRecord);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		// setting FirstName field to this would mean that a DML update would be required
		userRecord.Firstname = 'OutOfSyncFirstName';
		userRecord.LastName = userData.lastName;
		userRecord.email = userData.email;
		userRecord.FederationIdentifier = augmentedAttributes.get('augmented_username');
		userRecord.Username = augmentedAttributes.get('augmented_username');

		// =====================================
		// Stubbing
		// =====================================
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.eq(new Set<String>{'123'}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{userRecord.Id => userRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = new ChasRegHandlerService();
		User returnedUser = service.matchOrCreate(federationId, augmentedAttributes);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.never())).selectById((Set<Id>)fflib_Match.anyObject());

		fflib_ArgumentCaptor apcnCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSSWAccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectByAPCN((Set<String>)apcnCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		System.assertEquals(new Set<String>{apcn}, (Set<String>)apcnCaptor.getValue());

		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.Id}), (Set<Object>)fflib_Match.anyObject());

		// capture and verify inserted Account record
		User updatedUser = ((List<User>)MockUtility.verifyAndCaptureUpdatedDmlRecords(mockDatabase))[0];
		System.assertEquals(userData.firstName, updatedUser.FirstName);
		System.assertEquals(userData.lastName, updatedUser.LastName);
		System.assertEquals(augmentedAttributes.get('augmented_username'), updatedUser.Username);
		System.assertEquals(augmentedAttributes.get('augmented_username'), updatedUser.FederationIdentifier);

		// make sure the user record returned is the same user record passed into dml update
		System.assertEquals(updatedUser, returnedUser);
	}

	/**
	 * Scenario:
	 * A person account and a user record are both found. The user record return in salesforce requires an update since some of it's attributes are out of sync with the claims
	 */
	@IsTest
	private static void testValidateAttributes() {

		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
			'PersonContactId' => personContact.Id
		});

		User userRecord = ApplicationTestDataFactory.getUsers(1, true)[0];

		Auth.UserData userData = getUserData(personAccount, userRecord);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = ChasRegHandlerService.newInstance();
		System.assert(service.validateAssertion(federationId, augmentedAttributes).isEmpty());

		Map<String, String> clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove('given_name');
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove('family_name');
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove('email');
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove('augmented_username');
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove(Label.AttributeCNumberMapping);
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		clonedAttributes = augmentedAttributes.clone();
		clonedAttributes.keySet().remove(Label.AttributeAPCNMapping);
		System.assertEquals(1, service.validateAssertion(federationId, clonedAttributes).size());

		Test.stopTest();
	}

	/**
	 * Scenario:
	 * An existing user record found. All the user attributes match the claims so no user update is necessary
	 */
	@IsTest
	private static void testUpdateForExistingUserNoUpdateNeededHappyPath() {
		// =====================================
		// Data Preparation
		// =====================================
		RecordType personAccountRecordType = ApplicationTestDataFactory.personAccountRecordTypeRecord;
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
			'PersonContactId' => personContact.Id
		});

		User userRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		userRecord = (User)ApplicationTestDataFactory.setUnwritableFields(userRecord, new Map<String, Object>{
			'ContactId' => personContact.Id,
			'IsPortalEnabled' => true
		});
		userRecord.IsActive = true;

		Auth.UserData userData = getUserData(personAccount, userRecord);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);
		String apcn = userData.attributeMap.get('https://auspost/apcn');

		// grab the attirbutes needed to pass into our method calls
		Map<String, String> augmentedAttributes = ChasRegHandlerService.getAugmentedAttributes(federationId, userData.attributeMap);

		//explicity make sure the user record matches all the claims for happy path scenario
		// this should avoid a dirty state requiring a DML update
		userRecord.Firstname = userData.firstName;
		userRecord.LastName = userData.lastName;
		userRecord.email = userData.email;
		userRecord.FederationIdentifier = augmentedAttributes.get('augmented_username');
		userRecord.Username = augmentedAttributes.get('augmented_username');

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{userRecord.Id => userRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasRegHandlerService service = new ChasRegHandlerService();
		User existingUser = service.updateForExistingUser(userRecord.Id, augmentedAttributes);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.never())).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{userRecord.Id}), (Set<Object>)fflib_Match.anyObject());

		System.assertEquals(userRecord.Id, existingUser.Id);
		System.assertEquals(federationId, existingUser.FederationIdentifier);
		System.assertEquals(personAccount.FirstName, existingUser.FirstName);
		System.assertEquals(augmentedAttributes.get('augmented_username'), existingUser.Username);
	}


	private static Auth.UserData getUserData(Account personAccount, User personUser) {
		// set our user data mock from the Auth Provider
		Id networkId = '0DB000000000000001';
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => personAccount.LastName + ', ' + personAccount.FirstName,
			'given_name' => personAccount.FirstName,
			'family_name' => personAccount.LastName,
			'email' => personAccount.PersonEmail,
			'https://auspost/apcn' => '123',
			'https://auspost/cnumber' => 'C0000000001',
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, personAccount.FirstName, personAccount.LastName, personAccount.FirstName + ' ' + personAccount.LastName,
													personAccount.PersonEmail, null, personUser.Username, null, 'Open ID Connect', 'https://communityurl/', attributeMap);
		return userData;
	}

	/**
	 * A simple Answer class that will return the last inserted record where AnswerGenericDMLInserted was used
	 */
	public class AnswerGetPeviouslyInsertedPersonAccountRecordAsMapAccount implements fflib_Answer {

		Id personContactId;

		public AnswerGetPeviouslyInsertedPersonAccountRecordAsMapAccount(Id personContactId) {
			this.personContactId = personContactId;
		}

		public Object answer(fflib_InvocationOnMock invocation) {
			Account previousRecord = (Account)MockUtility.mockDMLInsertedRecords[MockUtility.mockDMLInsertedRecords.size()-1];

			previousRecord = (Account)ApplicationTestDataFactory.setUnwritableFields(previousRecord, new Map<String, Object>{
				'PersonContactId' => personContactId
			});

			return new Map<Id, Account>{previousRecord.Id => previousRecord};
		}
	}
}