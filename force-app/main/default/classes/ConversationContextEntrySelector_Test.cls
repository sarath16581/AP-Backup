/**
 * @description Unit tests for the selector class for the `ConversationContextEntry`
 * @changelog
 * 2024-09-02 - Marcel HK - Created
 */
@IsTest
public with sharing class ConversationContextEntrySelector_Test {
	@IsTest
	private static void testNewQueryBuilder() {
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
		ConversationContextEntrySelector selector = ConversationContextEntrySelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)SELECT Id, ParentId, CustomDetailContextKey, CustomDetailContextValue').matcher(soql).find(), 'Query does not select expected columns');

		Assert.isTrue(Pattern.compile('(?is)\\bFROM ConversationContextEntry\\b').matcher(soql).find(), 'Query does not select FROM ConversationContextEntry');
	}

	@IsTest
	private static void testNewQueryBuilderWithFieldOverrides() {
		// =====================================
		// Data Preparation
		// =====================================
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ ConversationContextEntry.Id };

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ConversationContextEntrySelector selector = ConversationContextEntrySelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)SELECT Id\\s+FROM').matcher(soql).find(), 'Query does not select expected columns');
	}

	@IsTest
	private static void testGetSelectByParentIdQuery() {
		// =====================================
		// Data Preparation
		// =====================================
		Id parentId = fflib_IDGenerator.generate(LiveChatTranscript.getSObjectType());

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ConversationContextEntrySelector selector = ConversationContextEntrySelector.newInstance(20);
		QueryBuilder qb = selector.getSelectByParentIdQuery(parentId, new Set<Object>());
		String soql = qb.toSoqlString();
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)\\bWHERE ParentId = \'' + parentId + '\'').matcher(soql).find(), 'Query does not filter on ParentId');
	}

	
	@IsTest
	private static void testSelectByParentId() {
		// =====================================
		// Data Preparation
		// =====================================
		Id parentId = fflib_IDGenerator.generate(LiveChatTranscript.getSObjectType());

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ConversationContextEntrySelector selector = ConversationContextEntrySelector.newInstance(20);
		Map<Id, ConversationContextEntry> result = selector.selectByParentId(parentId);
		Test.stopTest();

		Assert.areEqual(0, result.size(), 'Expected no results');
	}
}