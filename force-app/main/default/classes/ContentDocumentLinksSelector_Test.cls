/***
 * @description Test Class covering ContentDocumentLinksSelector
 * @author Nathan Franklin
 * @date 2020-10-05
 * @group Tests
 * @domain Core
 * @changelog
 * 21-07-2023 : hasantha.liyanage@auspost.com.au Added with contentDocument test
 */
@IsTest
private class ContentDocumentLinksSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ContentDocumentLinksSelector selector = ContentDocumentLinksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select from ContentDocumentLink: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ContentDocumentLinksSelector selector = ContentDocumentLinksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTVERSION, ContentDocumentLinksSelector.Options.WITH_CONTENTDOCUMENT});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ContentDocument\\.LatestPublishedVersion\\..*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select ContentVersion fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)ContentDocument\\.Title.*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select ContentDocument fields: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ContentDocumentLinksSelector selector = ContentDocumentLinksSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				ContentDocumentLink.SObjectType => new Set<SObjectField>{ContentDocumentLink.LinkedEntityId},
				ContentVersion.SObjectType => new Set<SObjectField>{ContentVersion.VersionNumber}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ContentDocumentLinksSelector.Options.WITH_CONTENTVERSION});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ContentDocument\\.LatestPublishedVersion\\..*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select ContentVersion fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)ContentDocument\\.LatestPublishedVersion\\.VersionNumber.*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select ContentVersion.VersionNumber: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)ContentDocument\\.LatestPublishedVersion\\.Title.*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query selects ContentVersion.Title but should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)LinkedEntityId.*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query does not select LinkedEntityId: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)ContentDocumentId.*?\\bfrom ContentDocumentLink\\b').matcher(soql).find(), 'Resulting query selects ContentDocumentId but should not: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorSearchAllIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];

		ContentVersion versionRecord = ApplicationTestDataFactory.getContentVersions(1, null, false)[0];
		insert versionRecord;

		Id documentId = [SELECT Id FROM ContentDocument].Id;
		ContentDocumentLink documentLinkRecord = new ContentDocumentLink();
		documentLinkRecord.LinkedEntityId = accountRecord.Id;
		documentLinkRecord.ContentDocumentId = documentId;
		documentLinkRecord.ShareType = 'I';
		documentLinkRecord.Visibility = 'AllUsers';
		insert documentLinkRecord;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// search entity only
		ContentDocumentLinksSelector selector = ContentDocumentLinksSelector.newInstance();
		Map<Id, ContentDocumentLink> results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1: ' + results);

		// documentId should have 2 entries, one for ethe current user that inserted and 1 for the entityId record we created
		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'documentIds' => documentId}, true);
		System.assertEquals(2, results.size(), 'Expected result size of 2: ' + results);

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'documentIds' => documentId, 'entityIds' => accountRecord.Id}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentDates' => Date.valueOf('2020-10-05')}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentDates' => Date.valueOf('2020-10-06')}, true);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentIntervals' => 'Weekly'}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentIntervals' => 'Daily'}, true);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentTypes' => 'DIFOT'}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentTypes' => 'Contract'}, true);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionRecordTypeId' => RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{'Report'}).values()[0].Id}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionRecordTypeId' => RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{'Contract'}).values()[0].Id}, true);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorSearchAnyIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];

		List<ContentVersion> versionRecords = ApplicationTestDataFactory.getContentVersions(2, null, false);
		versionRecords[1].Document_Interval__c = 'Monthly';
		versionRecords[1].Document_Date__c = Date.valueOf('2000-01-01');

		// this will insert 2 CDL records with a LinkedEntityId of the current user id
		insert versionRecords;

		versionRecords = [SELECT RecordTypeId, Title, ContentDocumentId, Document_Date__c, Document_Interval__c, Document_Type__c FROM ContentVersion];

		ContentDocumentLink documentLinkRecord = new ContentDocumentLink();
		documentLinkRecord.LinkedEntityId = accountRecord.Id;
		documentLinkRecord.ContentDocumentId = versionRecords[0].ContentDocumentId;
		documentLinkRecord.ShareType = 'I';
		documentLinkRecord.Visibility = 'AllUsers';
		insert documentLinkRecord;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// search entity only
		ContentDocumentLinksSelector selector = ContentDocumentLinksSelector.newInstance();
		Map<Id, ContentDocumentLink> results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'documentIds' => versionRecords[0].ContentDocumentId, 'entityIds' => accountRecord.Id}, false);
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentDates' => Date.valueOf('2020-10-05'), 'contentVersionDocumentIntervals' => new Set<String>{'Daily', 'Monthly'}}, false);
		System.assertEquals(3, results.size(), 'Expected result size of 3');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentDates' => new Set<Date>{Date.valueOf('2020-10-05'), Date.valueOf('2000-01-01')}, 'contentVersionDocumentIntervals' => 'Daily'}, false);
		System.assertEquals(3, results.size(), 'Expected result size of 3');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => accountRecord.Id, 'contentVersionDocumentIntervals' => 'Weekly', 'contentVersionDocumentTypes' => 'Contract'}, false);
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'documentIds' => new Set<Id>{versionRecords[0].ContentDocumentId, versionRecords[1].ContentDocumentId}}, false);
		System.assertEquals(3, results.size(), 'Expected result size of 3');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{'entityIds' => new Set<Id>{UserInfo.getUserId()}}, false);
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		// Search OR
		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{
				'entityIds' => new Set<Id>{UserInfo.getUserId()},
				'contentVersionDocumentFromDate' => Date.valueOf('1999-12-20'),
				'contentVersionDocumentToDate' => Date.valueOf('2000-01-20')
		}, false);
		System.assertEquals(3, results.size(), 'Expected result size of 3');

		// Search AND
		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{
				'entityIds' => new Set<Id>{UserInfo.getUserId()},
				'contentVersionDocumentFromDate' => Date.valueOf('1999-12-20'),
				'contentVersionDocumentToDate' => Date.valueOf('2000-01-20')
		}, true);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = ContentDocumentLinksSelector.newInstance();
		results = selector.search(new Map<String, Object>{
				'entityIds' => new Set<Id>{UserInfo.getUserId()},
				'contentVersionDocumentFromDate' => Date.valueOf('2000-12-20'),
				'contentVersionDocumentToDate' => Date.valueOf('2001-01-20')
		}, true);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		Test.stopTest();
	}
}