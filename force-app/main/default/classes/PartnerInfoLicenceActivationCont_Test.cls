/**
 * @author Naveen Rajanna
 * @date 2023-03-17
 * @description SMWD-397 - Test class for PartnerInfoLicenceActivationController
 * @group Tests
 * @domain Account
 * @changelog
 */
@IsTest
private without sharing class PartnerInfoLicenceActivationCont_Test {
	/**
	 * Positive scenario - Test when all incomingLicence, facility and outgoingLicence details exists and is returned in the wrapper
	 */
	@IsTest
	static void testFetchInitDetailsAll() {
		// =====================================
		// Data Preparation
		// =====================================
		User adminUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1, true)[0];
		networkFacility.State__c = 'VIC';
		Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacility.Id, true)[0];
		List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, true));
		Account outgoingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[1].Id, facilityAccount.Id, true)[0];
		Account incomingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, facilityAccount.Id, true)[0];
		Contact incentContact =  ApplicationTestDataFactory.getContacts(1,orgAccounts[0].Id,true)[0];
		facilityAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			facilityAccount,
			new Map<String, Object>{
				'CreatedBy' => adminUser,
				'CreatedDate' => Datetime.now().addDays(-10),
				'LastModifiedBy' => adminUser,
				'LastModifiedDate' => Datetime.now().addDays(-5),
				'Parent' => outgoingLicence,
				'ParentId' => outgoingLicence.Id,
				'Network_Facility__r' => networkFacility
			}
		);
		outgoingLicence = (Account) ApplicationTestDataFactory.setUnwritableFields(
			outgoingLicence,
			new Map<String, Object>{
				'CreatedBy' => adminUser,
				'CreatedDate' => Datetime.now().addDays(-10),
				'LastModifiedBy' => adminUser,
				'LastModifiedDate' => Datetime.now().addDays(-5),
				'Facility__r' => facilityAccount,
				'Parent' => orgAccounts[1]
			}
		);
		incomingLicence = (Account) ApplicationTestDataFactory.setUnwritableFields(
			incomingLicence,
			new Map<String, Object>{
				'CreatedBy' => adminUser,
				'CreatedDate' => Datetime.now().addDays(-10),
				'LastModifiedBy' => adminUser,
				'LastModifiedDate' => Datetime.now().addDays(-5),
				'Facility__r' => facilityAccount,
				'Parent' => orgAccounts[0]
			}
		);

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockAccountsSelector.selectById(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ incomingLicence.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>{ AccountsSelector.Options.WITH_FACILITY })
				)
			)
			.thenReturn(new Map<Id, Account>{ incomingLicence.Id => incomingLicence });
		MockUtility.Mocks.when(
				mockAccountsSelector.selectById(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ incomingLicence.Id, incomingLicence.ParentId, facilityAccount.Id, outgoingLicence.Id }),
					(Set<Object>) fflib_Match.eq(
						new Set<Object>{ 
							AccountsSelector.Options.WITH_CREATEDBY_USER, AccountsSelector.Options.WITH_LASTMODIFIEDBY_USER, 
							AccountsSelector.Options.WITH_PARENT, AccountsSelector.Options.WITH_NETWORK, AccountsSelector.Options.WITH_CONTACT 
						}
					)
				)
			)
			.thenReturn(new Map<Id, Account>(new List<Account>{ incomingLicence, orgAccounts[0], facilityAccount, outgoingLicence }));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PartnerInfoLicenceActivationController.InitWrapper initWrapper = PartnerInfoLicenceActivationController.fetchInitDetails(
			incomingLicence.Id
		);
		Test.stopTest();

		System.Assert.isNotNull(initWrapper.domainURL, 'Expected domainURL to be populated in the initWrapper');
		System.Assert.areEqual(incomingLicence.Id, initWrapper.incomingLicence.Id, 'Expected Incoming Licence in the initWrapper');
		System.Assert.areEqual(facilityAccount.Id, initWrapper.facility.Id, 'Expected Facility in the initWrapper');
		System.Assert.areEqual(outgoingLicence.Id, initWrapper.outgoingLicence.Id, 'Expected Outgoing Licence in the initWrapper');
	}

	/**
	 * Positive scenario - Test scenario when outgoingLicence doesn't exist is handled and wrapper returns correctly
	 */
	@IsTest
	static void testFetchInitDetailsWithoutOutgoing() {
		// =====================================
		// Data Preparation
		// =====================================
		User adminUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1, true)[0];
		Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacility.Id, true)[0];
		List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		Account incomingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, facilityAccount.Id, true)[0];
		facilityAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			facilityAccount,
			new Map<String, Object>{
				'CreatedBy' => adminUser,
				'CreatedDate' => Datetime.now().addDays(-10),
				'LastModifiedBy' => adminUser,
				'LastModifiedDate' => Datetime.now().addDays(-5),
				'Network_Facility__c' => networkFacility.Id,
				'Network_Facility__r' => networkFacility
			}
		);
		incomingLicence = (Account) ApplicationTestDataFactory.setUnwritableFields(
			incomingLicence,
			new Map<String, Object>{
				'CreatedBy' => adminUser,
				'CreatedDate' => Datetime.now().addDays(-10),
				'LastModifiedBy' => adminUser,
				'LastModifiedDate' => Datetime.now().addDays(-5),
				'Facility__r' => facilityAccount,
				'Parent' => orgAccounts[0]
			}
		);

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockAccountsSelector.selectById(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ incomingLicence.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>{ AccountsSelector.Options.WITH_FACILITY })
				)
			)
			.thenReturn(new Map<Id, Account>{ incomingLicence.Id => incomingLicence });
		MockUtility.Mocks.when(
				mockAccountsSelector.selectById(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ incomingLicence.Id,incomingLicence.ParentId, facilityAccount.Id }),
					(Set<Object>) fflib_Match.eq(
						new Set<Object>{ AccountsSelector.Options.WITH_CREATEDBY_USER, AccountsSelector.Options.WITH_LASTMODIFIEDBY_USER, 
							AccountsSelector.Options.WITH_PARENT, AccountsSelector.Options.WITH_NETWORK, AccountsSelector.Options.WITH_CONTACT }
					)
				)
			)
			.thenReturn(new Map<Id, Account>(new List<Account>{ incomingLicence, orgAccounts[0], facilityAccount }));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PartnerInfoLicenceActivationController.InitWrapper initWrapper = PartnerInfoLicenceActivationController.fetchInitDetails(
			incomingLicence.Id
		);
		Test.stopTest();

		System.Assert.isNotNull(initWrapper.domainURL, 'Expected domainURL to be populated in the initWrapper');
		System.Assert.areEqual(incomingLicence.Id, initWrapper.incomingLicence.Id, 'Expected Incoming Licence in the initWrapper');
		System.Assert.areEqual(facilityAccount.Id, initWrapper.facility.Id, 'Expected Facility in the initWrapper');
		System.Assert.isNull(initWrapper.outgoingLicence, 'Expected Outgoing Licence to be null in the initWrapper');
	}

	/**
	 * Positive scenario - Test scenario when both incomingLicence and outgoingLicence are updated
	 */
	@IsTest
	static void testUpdateLicencesAll() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, true));
		Account incomingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, null, true)[0];
		Account outgoingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[1].Id, null, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Boolean retBoolean = PartnerInfoLicenceActivationController.updateLicences(incomingLicence.Id, outgoingLicence.Id);
		Test.stopTest();
		System.Assert.isTrue(retBoolean, 'Method must return true');
		System.Assert.areEqual(2, MockUtility.mockDMLUpdatedRecords.size());
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpdate((List<SObject>) fflib_Match.anyObject());
		Account incomingLicenceUpdated = (Account) MockUtility.mockDMLUpdatedRecords[0];
		Account outgoingLicenceUpdated = (Account) MockUtility.mockDMLUpdatedRecords[1];
		System.Assert.areEqual(
			AccountUtil.LICENCE_STATUS_ACTIVE,
			incomingLicenceUpdated.Licence_Status__c,
			'Expected incomingLicence Licence Status to be Active'
		);
		System.Assert.isTrue(
			incomingLicenceUpdated.LicenceManualActivationDate__c != null,
			'Expected incomingLicence Licence Manual Activation Date to be set'
		);
		System.Assert.isTrue(
			outgoingLicenceUpdated.LicenceManualDeactivationDate__c != null,
			'Expected outgoingLicence Licence Manual Deactivation Date to be set'
		);
	}

	/**
	 * Positive scenario - Test scenario when outgoingLicence doesn't exist is handled and incomingLicence is still updated
	 */
	@IsTest
	static void testUpdateLicencesWithoutOutgoing() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		Account incomingLicence = ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, null, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Boolean retBoolean = PartnerInfoLicenceActivationController.updateLicences(incomingLicence.Id, null);
		Test.stopTest();
		System.Assert.isTrue(retBoolean, 'Method must return true');
		System.Assert.areEqual(1, MockUtility.mockDMLUpdatedRecords.size());
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpdate((List<SObject>) fflib_Match.anyObject());
		Account incomingLicenceUpdated = (Account) MockUtility.mockDMLUpdatedRecords[0];
		System.Assert.areEqual(
			AccountUtil.LICENCE_STATUS_ACTIVE,
			incomingLicenceUpdated.Licence_Status__c,
			'Expected incomingLicence Licence Status to be Active'
		);
		System.Assert.isTrue(
			incomingLicenceUpdated.LicenceManualActivationDate__c != null,
			'Expected incomingLicence Licence Manual Activation Date to be set'
		);
	}

	/**
	 * Negative scenario - Exception Scenario for updateLicences
	 */
	@IsTest
	private static void testUpdateLicencesException() {
		// =====================================
		// Data Preparation
		// =====================================
		// None
		// =====================================
		// Stubbing
		// =====================================
		// None
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			Boolean retBoolean = PartnerInfoLicenceActivationController.updateLicences(null, null);
		} catch (Exception e) {
			System.Assert.isTrue(true, 'Expected Exception to be thrown');
		}
		Test.stopTest();
	}

	/**
	 * Negative scenario - Exception Scenario for fetchInitDetails
	 */
	@IsTest
	private static void testFetchInitDetailsException() {
		// =====================================
		// Data Preparation
		// =====================================
		// None
		// =====================================
		// Stubbing
		// =====================================
		// None
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			PartnerInfoLicenceActivationController.InitWrapper initWrapper = PartnerInfoLicenceActivationController.fetchInitDetails(null);
		} catch (Exception e) {
			System.Assert.isTrue(true, 'Expected Exception to be thrown');
		}
		Test.stopTest();
	}

	private class MockException extends Exception {
	}
}