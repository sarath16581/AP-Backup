/***
 * @description Test Class covering ContentDocumentsSelector
 * @author avula.jansirani@auspost.com.au
 * @date 2021-04-29
 * @group Tests
 * @domain Core
 * @changelog
 * 20-02-2024 - Boris Bachovski - Complete refactor with
 */
@IsTest
private class ContentDocumentsSelector_Test {
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		ContentDocumentsSelector selector = ContentDocumentsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom ContentDocument\\b').matcher(soql).find(), 'Resulting query does not select from ContentDocument: ' + soql);

		Test.stopTest();
	}

	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id FROM Account LIMIT 1];

		ContentVersion versionRecord = ApplicationTestDataFactory.getContentVersions(1, null, false)[0];
		insert versionRecord;

		Id documentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :versionRecord.Id].ContentDocumentId;
		
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, accountRecord.Id, documentId, false)[0];
		documentLinkRecord.ShareType = 'V';
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
		ContentDocumentsSelector selector = ContentDocumentsSelector.newInstance();
		Map<Id, ContentDocument> results;

		// documentId should have 2 entries, one for ethe current user that inserted and 1 for the entityId record we created
		selector = ContentDocumentsSelector.newInstance();
		results = selector.selectById(new Set<Id>{documentId});
		System.assertEquals(1, results.size(), 'Expected result size of 1: ' + results);

		Test.stopTest();

	}
}