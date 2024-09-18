/**
 * @description Service class for enquiry mapping object (MiniCaseFieldMapping__c)
 * @author Raghav Ravipati
 * @date 2024-09-16
 * @changelog
 */
public with sharing class EnquiryMappingService {
	private final String ARTICLE_RECORD_TYPE_CONSIGNMENT = 'Consignment';
	private final String ARTICLE_RECORD_TYPE_ARTICLE = 'Article';
	/**
	 * Returns a new instance of the service
	 * @return new instance
	 */
	public static EnquiryMappingService getInstance() {
		return (EnquiryMappingService) Application.Utilities.getInstance(EnquiryMappingService.class);
	}
	/**
	 * @description: Calls a service class method to get the product category and product sub category from enqury mappings based on the article's ProductCategory__c and SubProduct__c fields.
	 * @param articleIds: Article object record ids.
	 * @param mappingModels: picklist values from MappingModel__c field of MiniCaseFieldMapping__c
	 * @return A map of article Id and is respective enquiry mapping.
	 */
	public Map<Id, Map<String, MiniCaseFieldMapping__c>> getEnquiryMappingsByMappingModelAndArticleIds(Set<Id> articleIds, Set<String> mappingModels) {
		Set<String> sapKeys = new Set<String>();
		Map<Id, String> articleSAPKeyMap = new Map<Id, String>();
		// Iterate over the articles to construct the SAP key which is used to get the matching MiniCaseFieldMapping__c 
		for (Article__c article : queryArticles(articleIds).values()) {
			String sapKey = constructSapKey(article);

			if(String.isNotBlank(sapKey)){				
				articleSAPKeyMap.put(article.Id, sapKey);
				sapKeys.add(sapKey);
			}
		}
		// Hold SapKey and its matching MiniCaseFieldMapping__c
		Map<String, Map<String, MiniCaseFieldMapping__c>> sapKeyWithEnquiryKeyMap = getSapKeyAndEnquiryMapingMap(sapKeys, mappingModels);
		// Map of article Id and is respective enquiry mapping.
		Map<Id, Map<String, MiniCaseFieldMapping__c>> articleIdAndEligibleMappings = new Map<Id, Map<String, MiniCaseFieldMapping__c>>();

		for (Id articleId : articleIds) {
			String sapKey = articleSAPKeyMap.get(articleId);
			if (String.isNotBlank(sapKey) && sapKeyWithEnquiryKeyMap.containsKey(sapKey)) {
				articleIdAndEligibleMappings.put(articleId, sapKeyWithEnquiryKeyMap.get(sapKey));
			}
		}

		return articleIdAndEligibleMappings;
	}
	/**
	 * @description: Query articles by Ids.
	 * @param articleIds: Article object record ids.
	 * @return A map of article Id and article.
	 */
	private Map<Id, Article__c> queryArticles(Set<Id> articleIds){
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Article__c.SubProduct__c, Article__c.ProductCategory__c };
		Set<Object> selectorOptions = new Set<Object>{ ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_RECORDTYPE };
		ArticlesSelector articleSelector = ArticlesSelector.newInstance(articleIds.size(), fieldOverrides);
		Map<Id, Article__c> articlesMap = articleSelector.selectById(articleIds, selectorOptions);

		return articlesMap;
	}
	/**
	 * @description: Construct the sapkey. If the parameter passed is consignment, the we use the recent related articles fields and if the param is an article we use the records field.
	 * @param articleIds: Article object record ids.
	 * @return sapKey string.
	 */
	private String constructSapKey(Article__c article) {
		String sapKey;
		
		if (article.RecordType.DeveloperName == ARTICLE_RECORD_TYPE_ARTICLE) {
		  sapKey =
			(String.isEmpty(article.ProductCategory__c) ? '' : article.ProductCategory__c.trim()) +
			(String.isEmpty(article.SubProduct__c) ? '' : article.SubProduct__c.trim());
		} 
		// If consignment, the we use the recent related article's fields
		else if (article.RecordType.DeveloperName == ARTICLE_RECORD_TYPE_CONSIGNMENT && article.Articles__r.size() > 0) {
		  Article__c childArticle = article.Articles__r[0];
		  sapKey =
			(String.isEmpty(childArticle.ProductCategory__c) ? '' : childArticle.ProductCategory__c.trim()) +
			(String.isEmpty(childArticle.SubProduct__c) ? '' : childArticle.SubProduct__c.trim());
		}
	
		return sapKey;
	  }

	/**
	 * @description: Returns Map of MiniCaseFieldMapping__c wtih Sap Key as a key. 
	 * @param sapKeys: sapKeys that are related to the articles.
	 * @param mappingModels: mappingModel__c pick list values of MiniCaseFieldMapping__c object
	 * @return Map of MiniCaseFieldMapping__c wtih Sap Key as a key.
	 */
	private Map<String, Map<String, MiniCaseFieldMapping__c>> getSapKeyAndEnquiryMapingMap(Set<String> sapKeys, Set<String> mappingModels){
		// Query Enquiry Mappings
		EnquiryMappingsSelector selector = EnquiryMappingsSelector.newInstance();
		Map<String, Map<String, MiniCaseFieldMapping__c>> sapKeyWithEnquiryKeyMap = new Map<String, Map<String, MiniCaseFieldMapping__c>>();

		// Creates a Map where key is sap key and value is map of MiniCaseFieldMapping__c
		for (MiniCaseFieldMapping__c enquiryMapping : selector.selectBySAPKeyAndMappingModel(sapKeys, mappingModels)) {
			if(sapKeyWithEnquiryKeyMap.containsKey(enquiryMapping.SAPKey__c)){
				sapKeyWithEnquiryKeyMap.get(enquiryMapping.SAPKey__c).put(enquiryMapping.MappingModel__c, enquiryMapping);
			}else{
				sapKeyWithEnquiryKeyMap.put(enquiryMapping.SAPKey__c, new  Map<String, MiniCaseFieldMapping__c>{enquiryMapping.MappingModel__c => enquiryMapping});
			}
		}

		return sapKeyWithEnquiryKeyMap;
	}
}