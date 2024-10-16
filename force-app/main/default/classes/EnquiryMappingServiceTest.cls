/**
 * @description Test class covering EnquiryMappingService
 * @author Raghav Ravipati
 * @date 2024-09-17
 */
@isTest
public class EnquiryMappingServiceTest {
	@IsTest
	public static void getEnquiryMappingsForConsignmentTest() {
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
		EnquiryMappingService enquiryService = EnquiryMappingService.getInstance();
		Map<Id, Map<String, MiniCaseFieldMapping__c>> enqMappingsMap = enquiryService.getEnquiryMappingsByMappingModelAndArticleIds(new Set<Id>{ consignments[0].Id }, new Set<String>{ 'Unified', 'Classic' });

		System.assert(enqMappingsMap.containsKey(consignments[0].Id), 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has article Id as key');
		System.assert(enqMappingsMap.get(consignments[0].Id).size() > 0, 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has values related to article Id');
		System.assert(enqMappingsMap.get(consignments[0].Id).containsKey('Classic'), 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has Enquiry Mappings related to article Id');
	}

	@IsTest
	public static void getEnquiryMappingsForArticleTest() {
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
		EnquiryMappingService enquiryService = EnquiryMappingService.getInstance();
		Map<Id, Map<String, MiniCaseFieldMapping__c>> enqMappingsMap = enquiryService.getEnquiryMappingsByMappingModelAndArticleIds(new Set<Id>{ articles[0].Id }, new Set<String>{ 'Unified', 'Classic' });

		System.assert(enqMappingsMap.containsKey(articles[0].Id), 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has article Id as key');
		System.assert(enqMappingsMap.get(articles[0].Id).size() > 0, 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has values related to article Id');
		System.assert(enqMappingsMap.get(articles[0].Id).containsKey('Classic'), 'getEnquiryMappingsByMappingModelAndArticleIds returned a Map that has Enquiry Mappings related to article Id');
	}
}
