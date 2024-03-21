/**
 * Test class for AdobeSignDeleteDraftsBatch
 *
 * @changelog:
 * 2024-20-02 Boris B - Created
*/
@IsTest
private class AdobeSignDeleteDraftsBatchTest {
	@IsTest
	public static void testDeleteDraftAgreementsOlderThanXDaysExecute() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, contact.Id, opp.Id, true)[0];
		// Formula field
		apttusContract = (Apttus__APTS_Agreement__c)ApplicationTestDataFactory.setUnwritableFields(apttusContract, new Map<String, Object>{ 'DaysUntilContractExpires__c' => '10' });
		// Draft Agreement
		echosign_dev1__SIGN_Agreement__c agreement = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(1, apttusContract.Id, true)[0];
		// Content Version + Content Document + Content Document Link
		ContentDocument cd = new ContentDocument();
		ApplicationTestDataFactory.generateRecordIds(new List <SObject> { cd });
		cd = (ContentDocument)ApplicationTestDataFactory.setUnwritableFields(cd, new Map<String, Object>{ 'ParentId' => agreement.Id });
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, cd.Id, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, account.Id, cd.Id, true)[0];
		documentLinkRecord.Visibility = 'AllUsers';
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'LinkedEntityId' => agreement.Id });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocument' => cd });
		documentLinkRecord = (ContentDocumentLink)ApplicationTestDataFactory.setUnwritableFields(documentLinkRecord, new Map <String, Object>{ 'ContentDocumentId' => cd.Id });

		// =====================================
		// Stubbing
		// =====================================
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), 
				(Set<Object>)fflib_Match.eq(new Set<Object>{ ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT }),
				fflib_Match.anyBoolean()
			)).thenReturn(new Map<Id, ContentDocumentLink>{ documentLinkRecord.Id => documentLinkRecord });

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());

		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		List <echoSign_dev1__SIGN_Agreement__c> agreements = new List <echoSign_dev1__SIGN_Agreement__c> { agreement };
		AdobeSignDeleteDraftsBatch batch = new AdobeSignDeleteDraftsBatch();

		Test.startTest();
		
		// batch.execute(null, agreements); 
		batch.execute(null, new List <echoSign_dev1__SIGN_Agreement__c> { agreement });

		Test.stopTest();

		fflib_ArgumentCaptor deleteCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlDelete((List<SObject>)deleteCaptor.capture(), fflib_Match.anyBoolean());
		List <Object> deletedRecords = (List <Object>)deleteCaptor.getAllValues();
		Set <Id> recordIds = new Set <Id> ();
		for (Object deletedRecordsList : deletedRecords) {
			List <SObject> records = (List <SObject>)deletedRecordsList;
			for (SObject record : records) {
				recordIds.add(record.Id);
			}
		}

		System.assert(recordIds.contains(agreement.Id), 'Expected Agreement to be deleted');
		System.assert(recordIds.contains(cd.Id), 'Expected Content Document to be deleted');
	}

	@IsTest
	public static void testDeleteDraftAgreementsOlderThanXDaysStartBatch() {
		// =====================================
		// Data Preparation
		// =====================================

		// =====================================
		// Stubbing
		// =====================================
		AdobeSignAgreementSelector mockAgreementSelector = (AdobeSignAgreementSelector) MockUtility.mockSelector(AdobeSignAgreementSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAgreementSelector.selectDraftAgreementsOlderThan(fflib_Match.anyInteger(), 
				(Set<Object>)fflib_Match.eq(new Set<Object>{ AdobeSignAgreementSelector.Options.FILTER_DRAFT_STATUS })
			)).thenReturn(Database.getQueryLocator([SELECT Id FROM echoSign_dev1__SIGN_Agreement__c]));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AdobeSignDeleteDraftsBatch batch = new AdobeSignDeleteDraftsBatch();
		Database.QueryLocator ql = batch.start(null);

		Test.stopTest();

		System.assertNotEquals(null, ql, 'Expect a valid query locator to be returned');
		
		((AdobeSignAgreementSelector) MockUtility.Mocks.verify(mockAgreementSelector, MockUtility.Mocks.times(1))).selectDraftAgreementsOlderThan(fflib_Match.anyInteger(), (Set<Object>)fflib_Match.eq(new Set<Object>{ AdobeSignAgreementSelector.Options.FILTER_DRAFT_STATUS }));
	}
}