/**
 * @description Test class covering ProductCategoryPopulationModule
 * @author Raghav Ravipati
 * @date 2024-09-17
 */
@isTest
public with sharing class ProductCategoryPopulationModuleTest {
	@isTest
	public static void triggerMethodsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> consignments = ApplicationTestDataFactory.getConsignments(1, false);
		insert consignments;

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, consignments[0].Id, false);
		insert articles;

		List<MiniCaseFieldMapping__c> enqMappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
		insert enqMappings;

		Contact con = TestDataProvider.createTestContact();
		insert con;

		List<Case> caseRecords = ApplicationTestDataFactoryCase.getCases(1, new Set<ID>{ con.Id }, false);
		caseRecords[0].RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'SSSWGeneralEnquiry' LIMIT 1].Id;

		insert caseRecords;

		LiveChatVisitor chatVisitor = new LiveChatVisitor();

		insert chatVisitor;

		LiveChatTranscript testScript = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, new List<Id>{ caseRecords[0].Id }, false)[0];
		testScript.ChatKey = '8f441452-eb7d-4142-8ae6-5b3f4a44f7d0';
		testScript.Body = 'ProductCategoryPopulationModule Test';
		testScript.LiveChatVisitorid = chatVisitor.id;
		testScript.Consignment__c = consignments[0].Id;

		insert testScript;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		LiveChatTranscript testScriptFromQuery = [SELECT CaseId, ProductCategory__c, ProductSubCategory__c FROM LiveChatTranscript WHERE Id = :testScript.Id];
		system.assert(testScriptFromQuery.ProductCategory__c != null, 'ProductCategoryPopulationModule populated ProductCategory__c');
		system.assert(testScriptFromQuery.ProductSubCategory__c != null, 'ProductCategoryPopulationModule populated ProductSubCategory__c');

		testScript.Consignment__c = articles[0].Id;
		testScript.ProductCategory__c = null;
		testScript.ProductSubCategory__c = null;

		update testScript;

		LiveChatTranscript testScriptFromQuery1 = [SELECT CaseId, ProductCategory__c, ProductSubCategory__c FROM LiveChatTranscript WHERE Id = :testScript.Id];

		system.assert(testScriptFromQuery1.ProductCategory__c == 'Domestic Parcels', 'ProductCategoryPopulationModule populated ProductCategory__c');
		system.assert(testScriptFromQuery1.ProductSubCategory__c == 'eParcel- Regular', 'ProductCategoryPopulationModule populated ProductSubCategory__c');
	}

	@isTest
	public static void getEnquiryMappinForArticlesTest() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> consignments = ApplicationTestDataFactory.getConsignments(1, false);
		insert consignments;

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, consignments[0].Id, false);
		insert articles;

		List<MiniCaseFieldMapping__c> enqMappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
		insert enqMappings;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		ProductCategoryPopulationModule module = new ProductCategoryPopulationModule();
		Map<Id, Map<String, MiniCaseFieldMapping__c>> enqMappingsMap = module.getEnquiryMappingForArticles(new Set<Id>{ consignments[0].Id });

		System.assert(enqMappingsMap.containsKey(consignments[0].Id), 'getEnquiryMappingForArticles returned a Map that has article Id as key');
		System.assert(enqMappingsMap.get(consignments[0].Id).size() > 0, 'getEnquiryMappingForArticles returned a Map that has values related to article Id');
		System.assert(enqMappingsMap.get(consignments[0].Id).containsKey('Classic'), 'getEnquiryMappingForArticles returned a Map that has Enquiry Mappings related to article Id');
	}

	@isTest
	public static void getMappingModelsFromCaseRecordsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		List<MiniCaseFieldMapping__c> enqMappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
		insert enqMappings;

		Contact con = TestDataProvider.createTestContact();
		insert con;

		List<Case> caseRecords = ApplicationTestDataFactoryCase.getCases(1, new Set<ID>{ con.Id }, false);
		caseRecords[0].RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'SSSWGeneralEnquiry' LIMIT 1].Id;

		insert caseRecords;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		ProductCategoryPopulationModule module = new ProductCategoryPopulationModule();
		Map<Id, String> casMappingsMap = module.getMappingModelsFromCaseRecords(new Set<Id>{ caseRecords[0].Id });

		System.assert(casMappingsMap.containsKey(caseRecords[0].Id), 'getMappingModelsFromCaseRecords returned a Map that has case Id as key');
		System.assert(casMappingsMap.get(caseRecords[0].Id) == 'Classic', 'Mapping model returned as a value based on the case id');
	}
}