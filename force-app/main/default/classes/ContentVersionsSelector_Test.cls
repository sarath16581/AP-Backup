/***
 * @description Test Class covering ContentVersionsSelector
 * @author Nathan Franklin
 * @date 2020-10-05
 * @group Tests
 * @domain Core
 * @changelog
 */
@IsTest
private class ContentVersionsSelector_Test {

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

		ContentVersionsSelector selector = ContentVersionsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom ContentVersion\\b').matcher(soql).find(), 'Resulting query does not select from ContentVersion: ' + soql);

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

		ContentVersionsSelector selector = ContentVersionsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ContentVersionsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom ContentVersion\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<ContentVersion> versionRecords = ApplicationTestDataFactory.getContentVersions(2, null, false);
		insert versionRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ContentVersionsSelector selector = ContentVersionsSelector.newInstance();
		Map<Id, ContentVersion> results = selector.selectById(new Set<Id>{versionRecords[0].Id});
		System.assertEquals(1, results.size());
		System.assertEquals(versionRecords[0].Id, results.values()[0].Id);

		Test.stopTest();

	}
    
    @IsTest
    private static void testSelectorLimit() {
        
        Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert accountRecord;
        accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];
        
        List<ContentVersion> versionRecords = ApplicationTestDataFactory.getContentVersions(2, null, false);
        versionRecords[1].Title = 'titleCV';
        versionRecords[1].Document_Interval__c = 'Monthly';
        versionRecords[1].Document_Date__c = datetime.now().date();
        versionRecords[1].Document_Type__c = 'DIFOT';
        
        insert versionRecords[1];
        
        versionRecords = [SELECT RecordTypeId, Title, ContentDocumentId, Document_Date__c, Document_Interval__c, Document_Type__c FROM ContentVersion WHERE Id=:versionRecords[1].Id];
        
        Test.startTest();
        
        Map<Id,ContentVersion> results =  ContentVersionsSelector.newInstance('Document_Date__c', 'Desc').selectByContentDocumentId(new Set<Id>{versionRecords[0].ContentDocumentId}, new set<Object>{ContentVersionsSelector.Options.IS_LATEST_VERSION});
        ContentVersionsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>> {Schema.getGlobalDescribe().get('ContentVersion') => new Set<SObjectField>{Schema.getGlobalDescribe().get('ContentVersion').getDescribe().fields.getMap().get('Title')}});
        ContentVersionsSelector.newInstance('Document_Date__c', 'Desc').selectByContentDocumentId(new Set<Id>{versionRecords[0].ContentDocumentId});
        System.assertEquals(1, results.size());
        
        Test.stopTest();
        
    }
}