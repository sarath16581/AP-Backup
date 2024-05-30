@isTest
public with sharing class KnowledgeArticleVersionTriggerHandlerTst {
	@isTest
	private static void knowledgeArticleVersionTriggerHandlerTest() {
		KnowledgeArticleVersionTriggerHandler handler = new KnowledgeArticleVersionTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(Knowledge__kav.SObjectType, handler.getSObjectType(), 'Expected Knowledge__kav sobject type');
		List<SObjectType> uowObjectTypes = KnowledgeArticleVersionTriggerHandler.getUnitOfWorkSObjectTypes();
		System.assert(uowObjectTypes.contains(Knowledge__DataCategorySelection.SObjectType), 'Expected valid list of sobject types to be returned');
	}
	@isTest
	private static void testFilters() {
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		KnowledgeArticleVersionTriggerHandler handler = new KnowledgeArticleVersionTriggerHandler();

		Map<String, List<SObject>> filteredRecords = handler.primeRecordFilters(criticalIncidents);

		System.assertEquals(1, filteredRecords.get('eligibleRecords').size(), 'filtered records');
	}
}