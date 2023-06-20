/**
 * @description
 * Test class for StarTrackSupportCaseContactsModule
 * @author Snehil Jaiswal
 * @date 2021-06-25
 * @group Tests
 * @domain Startrack
 * @changelog
 * 2023-06-19 - Nathan Franklin - updated unit of work source to CaseAutomationTriggerHandler
 */
@IsTest
private class StarTrackSupportCaseContactsModule_Test {
	/**
	 * Test:
	 * When startrack case is inserted, populate the initial caller details on case.
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesInitialCallerDetails() {
		// =====================================
		// Data Preparation
		// =====================================

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> caseList = ApplicationTestDataFactory.getCases(7, false);

		// Update the recordtype , suppliedemail and origin
		for (Case c : caseList) {
			c.RecordTypeId = ApplicationTestDataFactory.casestarTrackDeliveryEnquiryRecordType;
			c.SuppliedEmail = 'test@salesforce.com';
			c.Origin = 'Email';
			c.Recent_Caller_First_Name__c = 'Test';
		}
		caseList[1].Recent_Caller_First_Name__c = null;
		caseList[2].Recent_Caller_Pref_Method_of_Contact__c = 'Phone';
		caseList[3].Recent_Caller_Phone_Number__c = '673846889';
		caseList[4].Recent_Contact_Mobile_Number__c = '627867878';
		caseList[5].Recent_Caller_Email__c = 'test@salesforce.com';
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseContactsModule module = StarTrackSupportCaseContactsModule.newInstance();

		module.onBeforeInsert(caseList, uow);
		String expectedInitialCallerFirstName = 'Test';
		String expectedRecentCallerType = 'Sender';
		// make sure fields were updated correctly
		System.assertEquals(
			expectedInitialCallerFirstName,
			caseList[0].Initial_Caller_First_Name__c,
			'Expected Initial Caller FirstName to be set on case'
		);
		System.assertEquals(
			expectedRecentCallerType,
			caseList[1].Recent_Caller_Type__c,
			'Expected Recent Caller Type to be set on case'
		);

		Test.stopTest();
	}

	/**
	 * Test:
	 * When startrack case is inserted, Populates Initial Caller Details and Creates authorised contact
	 */
	@IsTest
	private static void testEnsureAfterInsertPopulatesInitialCallerDetails() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> caseList = ApplicationTestDataFactory.getCases(7, true);

		// Update the recordtype , suppliedemail and origin
		for (Case c : caseList) {
			c.RecordTypeId = ApplicationTestDataFactory.casestarTrackDeliveryEnquiryRecordType;
			c.SuppliedEmail = 'test@salesforce.com';
			c.Origin = 'Email';
			c.Recent_Caller_First_Name__c = 'Test';
		}
		caseList[1].Recent_Caller_First_Name__c = null;
		caseList[2].Recent_Caller_Pref_Method_of_Contact__c = 'Phone';
		caseList[3].Recent_Caller_Phone_Number__c = '673846889';
		caseList[4].Recent_Contact_Mobile_Number__c = '627867878';
		caseList[5].Recent_Caller_Email__c = 'test@salesforce.com';
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseContactsModule module = StarTrackSupportCaseContactsModule.newInstance();

		module.onAfterInsert(caseList, uow);
		List<AuthorisedContacts__c> autContact = [SELECT Id FROM AuthorisedContacts__c WHERE Case__c = :caseList[0].Id];
		Test.stopTest();

		// make sure related contact has been created on case
		System.assertNotEquals(autContact, null, 'Expected related contact inserted on case');
	}

	/**
	 * Test:
	 * When startrack case is updated, check and update the related contact or create related contact
	 */
	@IsTest
	private static void testEnsureBeforeUpdateContactDetailIntegrityCreateAuthorisedContact() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> caseList = ApplicationTestDataFactory.getCases(1, true);
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
		Map<Id, Case> oldCaseList = new Map<Id, Case>();

		oldCaseList.put(caseList[0].Id, caseList[0].clone(true));
		// Update the recordtype , suppliedemail and origin
		caseList[0].RecordTypeId = ApplicationTestDataFactory.casestarTrackDeliveryEnquiryRecordType;
		caseList[0].SuppliedEmail = 'test@salesforce.com';
		caseList[0].Origin = 'Email';
		caseList[0].ArticleTest__c = articles[0].Id;
		caseList[0].Recent_Caller_First_Name__c = 'Test';

		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockCasesSelector.selectById(
					new Set<Id>{ caseList[0].Id },
					new Set<Object>{ CasesSelector.Options.WITH_CHILDINITIALCONTACT }
				)
			)
			.thenReturn(new Map<Id, Case>(caseList));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		StarTrackSupportCaseContactsModule module = StarTrackSupportCaseContactsModule.newInstance();

		module.onBeforeUpdate(caseList, oldCaseList, uow);
		List<AuthorisedContacts__c> autContact = [SELECT Id FROM AuthorisedContacts__c WHERE Case__c = :caseList[0].Id];

		Test.stopTest();

		// make sure related contact has been created on case
		System.assertNotEquals(autContact, null, 'Expected related contact inserted on case');
		((CasesSelector) MockUtility.Mocks.verify(mockCasesSelector, 1))
			.selectById(
				new Set<Id>{ caseList[0].Id },
				new Set<Object>{ CasesSelector.Options.WITH_CHILDINITIALCONTACT }
			);
	}

	/**
	 * Test: Integration Scenario
	 * Inserts case, links the caseId to the Authorised contact to see if authorised contact is getting
	 * updated from case details
	 */
	@IsTest
	private static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Testing
		// =====================================

		test.startTest();

		insert cases;
		insert articles;

		// create authorised contact with case id
		AuthorisedContacts__c authCon = new AuthorisedContacts__c();
		authCon.First_Name__c = 'Test';
		authCon.Last_Name__c = 'AuthorisedContact';
		authCon.Initial_Contact__c = true;
		authCon.Case__c = cases[0].Id;

		insert authCon;

		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].Recent_Caller_First_Name__c = 'Test2';

		update cases;

		Map<Id, Case> casesContacts = CasesSelector.newInstance()
			.selectById(new Set<Id>{ cases[0].Id }, new Set<Object>{ CasesSelector.Options.WITH_CHILDINITIALCONTACT });
		List<AuthorisedContacts__c> authContactList = casesContacts.get(cases[0].Id).Authorised_Contacts__r;

		test.stopTest();

		// make sure related contact has been created on case
		System.assertEquals(1, authContactList.size(), 'Expected result size of 1');

		// make sure field is updated with the right data
		System.assertEquals(
			'Test2',
			authContactList[0].First_Name__c,
			'Expected authorised contact firstname to be updated'
		);
	}
}