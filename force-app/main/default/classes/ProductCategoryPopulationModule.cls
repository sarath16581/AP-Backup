/**
 * @description Module to cover the population of ProductCategory__c and ProductSubcategory__c fields on live chat transcript object.
 * @author Raghav Ravipati
 * @date 2024-09-16
 * @changelog
 */
public inherited sharing class ProductCategoryPopulationModule extends ApplicationModule {
	private final String MAPPING_MODEL_UNIFIED = 'Unified';
	private final String MAPPING_MODEL_CLASSIC = 'Classic';

	public ProductCategoryPopulationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}
	/**@Description: This method executes the scenarios of before insert.
	 * @param records: Sobject records from trigger.new.
	 * @param uow: ApplicationUnitOfWork.
	*/
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		Set<Id> articleIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();

		List<LiveChatTranscript> transcripts = (List<LiveChatTranscript>) records;
		for (LiveChatTranscript chatTranscript : transcripts) {
			articleIds.add(chatTranscript.Consignment__c);

			if (String.isNotBlank(chatTranscript.CaseId)) {
				caseIds.add(chatTranscript.CaseId);
			}
		}
		
		if(!articleIds.isEmpty()){
			// Returns case Id and its related mapping model
			Map<Id, String> getMappingModelsFromCaseRecords = getMappingModelsFromCaseRecords(caseIds);
			// Maps ProductCategory__c and ProductSubcategory__c base on the the enqury mappings and its mapping model.
			mapProductCategoriesValues(transcripts, getMappingModelsFromCaseRecords, getEnquiryMappingForArticles(articleIds));
		}
	}
	/**
	 * @Description: This method executes the scenarios of before insert.
	 * @param records: Sobject records from trigger.new.
	 * @param existingRecords: Sobject records from trigger.old.
	 * @param uow: ApplicationUnitOfWork.
	*/
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		Set<Id> articleIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		List<LiveChatTranscript> transcripts = (List<LiveChatTranscript>) records;
		Map<Id, LiveChatTranscript> oldMapValues = (Map<Id, LiveChatTranscript>) existingRecords;

		for (LiveChatTranscript chatTranscript : transcripts) {
			if(oldMapValues.get(chatTranscript.Id).Consignment__c != chatTranscript.Consignment__c){
				articleIds.add(chatTranscript.Consignment__c);
			}
			if (String.isNotBlank(chatTranscript.CaseId)) {
				caseIds.add(chatTranscript.CaseId);
			}
		}

		if(!articleIds.isEmpty()){			
			Map<Id, String> getMappingModelsFromCaseRecords = getMappingModelsFromCaseRecords(caseIds);
			mapProductCategoriesValues(transcripts, getMappingModelsFromCaseRecords, getEnquiryMappingForArticles(articleIds));
		}
	}
	/**
	 * @Description: Calls a service class method to get the product category and product sub category from enqury mappings based on the article's ProductCategory__c and SubProduct__c fields.
	 * @param articleIds: Article ids from Livechat transcript object.
	 * @return A map of article Id and is respective enquiry mapping.
	 */
	@TestVisible
	private Map<Id, Map<String, MiniCaseFieldMapping__c>> getEnquiryMappingForArticles(Set<Id> articleIds) {
		Set<String> mappingModels = new Set<String>{MAPPING_MODEL_UNIFIED, MAPPING_MODEL_CLASSIC};
		
		EnquiryMappingService enquiryMappingInstance = EnquiryMappingService.getInstance();
		return enquiryMappingInstance.getEnquiryMappingsByMappingModelAndArticleIds(articleIds, mappingModels);
	}
	/**
	 * @Description: Queries the case record which is on the livechat transcript to determine its mapping model based on its recordtype 
	 * @param articleIds: Case ids from Livechat transcript object.
	 * @return A map of case Id and is respective mapping model.
	 */
	@TestVisible
	private Map<Id, String> getMappingModelsFromCaseRecords(Set<Id> caseIds) {
		// Case Selector to get its record type values
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Case.Id };
		Set<Object> selectorOptions = new Set<Object>{ CasesSelector.Options.WITH_RECORDTYPE };
		CasesSelector caseSelector = CasesSelector.newInstance(caseIds.size(), fieldOverrides);
		Map<Id, String> caseIdWithMappingModel = new Map<Id, String>();

		for (Case caseRecord : caseSelector.selectById(caseIds, selectorOptions).values()) {
			// check if the record type is unified
			if (CommonUtils.isUnifiedCase(caseRecord.RecordType.DeveloperName)) {
				caseIdWithMappingModel.put(caseRecord.Id, MAPPING_MODEL_UNIFIED);
			} else {
				caseIdWithMappingModel.put(caseRecord.Id, MAPPING_MODEL_CLASSIC);
			}
		}

		return caseIdWithMappingModel;
	}
	/**
	 * @Description: Maps the fields ProductCategory__c, ProductSubcategory__c of livechat based on the consignment and mapping model. 
	 * @param transcripts: Live chat transcript from trigger.new.
	 * @param mappingModelsFromCaseRecords: A map of case Id and is respective mapping model that are returned from getMappingModelsFromCaseRecords.
	 * @param articlesWithEnquiryMappings: A map of article Id and is respective enquiry mapping that are returned from getEnquiryMappingForArticles.
	 */
	@TestVisible
	private void mapProductCategoriesValues(
		List<LiveChatTranscript> transcripts,
		Map<Id, String> mappingModelsFromCaseRecords,
		Map<Id, Map<String, MiniCaseFieldMapping__c>> articlesWithEnquiryMappings
	) {
		for (LiveChatTranscript chatTranscript : transcripts) {
			String mappingModel = MAPPING_MODEL_UNIFIED;
			
			if (mappingModelsFromCaseRecords != null && articlesWithEnquiryMappings != null) {

				if (String.isNotBlank(chatTranscript.CaseId)) {
					mappingModel = mappingModelsFromCaseRecords.get(chatTranscript.CaseId);
				}
				if(chatTranscript.Consignment__c != null){					
					chatTranscript.ProductCategory__c = articlesWithEnquiryMappings.get(chatTranscript.Consignment__c).get(mappingModel).ProductCategory__c;
					chatTranscript.ProductSubcategory__c = articlesWithEnquiryMappings.get(chatTranscript.Consignment__c).get(mappingModel).ProductSubcategory__c;
				}
			}
		}
	}
}
