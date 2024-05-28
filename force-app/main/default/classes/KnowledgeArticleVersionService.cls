/******************************************************************************************************
 * @description 	Service class for knowledge__kav object trigger which performs following operations.
 * 					1. Creates the datacategory records based the recordtype of knowledge articles
 * 					2. Deletes the unwanted datacategories that are added on knowledge record
 *
 * @author 			Raghav Ravipati
 * @test			KnowledgeArticleVersionService_Test
 * @date 			2024-05-23
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
public class KnowledgeArticleVersionService {
	private static final String DATA_CATEGORY_GROUP_NAME = 'Article_Type';

	public static KnowledgeArticleVersionService getInstance() {
		return (KnowledgeArticleVersionService) Application.Utilities.getInstance(KnowledgeArticleVersionService.class);
	}
	/**
	 * @description	This method is used in the module class. It preares the required info, passes the info to inner calss and registers async work.
	 * @param articles list of articles trigger.new values
	 * @param uow instance of unit of work class
	 */
	public void createDataCategorySelection(List<Knowledge__kav> articles, ApplicationUnitOfWork uow) {
		Map<Id, String> recordTypeAndCategoryMap = getRecordTypeAndCategories(); // RecordtypeId and DatacategoryName, this helps in mapping a correct Datacategory based on recordTypeId
		Map<Id, Knowledge__kav> knowledgeMap = new Map<Id, Knowledge__kav>();
		Map<Id, String> parentIdAndCategoryMap = new Map<Id, String>();
		Map<Id, List<Knowledge__DataCategorySelection>> parentAndListOfCategories = new Map<Id, List<Knowledge__DataCategorySelection>>();

		for (Knowledge__kav article : articles) {
			if (recordTypeAndCategoryMap.containsKey(article.RecordTypeId)) {
				knowledgeMap.put(article.Id, article);
				parentIdAndCategoryMap.put(article.Id, recordTypeAndCategoryMap.get(article.RecordTypeId));
			}

			parentAndListOfCategories.put(article.id, new List<Knowledge__DataCategorySelection>());
		}

		//Registering Async Work
		//creating of Knowledge__kav via UI is not creating the Datacategory in the same transation so we are creation datacategory via Async
		AsyncCreateDataCategoryWorker asyncWorker = new AsyncCreateDataCategoryWorker();
		asyncWorker.recordTypeAndCategoryMap = recordTypeAndCategoryMap;
		asyncWorker.parentIdAndCategoryMap = parentIdAndCategoryMap;
		asyncWorker.parentAndListOfCategories = parentAndListOfCategories;
		asyncWorker.parentIds = knowledgeMap.keySet();
		uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncCreateDataCategoryWorker.class, asyncWorker));
	}
	/**
	 * @description	Method used to build a map of values which helps in filtering the articles.
	 * @return Map<Id, String> recordTypeId is Key and its resprective datacategory name is value.
	 */
	private Map<Id, String> getrecordTypeAndCategories() {
		Map<Id, String> recordTypeAndCategoryMap = new Map<Id, String>();
		Map<String, String> articleTypeMap = new Map<String, String>{
			'Critical_Incident' => 'Critical_Incident',
			'FAQ' => 'FAQ',
			'How_To' => 'How_To',
			'Manager' => 'Manager',
			'Product' => 'Product',
			'Push_EDM' => 'Share_Information',
			'Recovery_Team' => 'Recovery_Team',
			'Specialist_Skill' => 'Specialist_Skill',
			'StarTrack_How_To' => 'How_To_StarTrack',
			'Support' => 'Support'
		};

		for (RecordType recordType : (RecordTypesSelector.newInstance().selectByDeveloperName('Knowledge__kav', articleTypeMap.keySet())).values()) {
			if (articleTypeMap.containsKey(recordType.DeveloperName)) {
				recordTypeAndCategoryMap.put(recordType.Id, articleTypeMap.get(recordType.DeveloperName));
			}
		}

		return recordTypeAndCategoryMap;
	}

	public class AsyncCreateDataCategoryWorker extends ApplicationUnitOfWork.AsyncWorker {
		@TestVisible
		List<Knowledge__DataCategorySelection> insertDataCategorySelections = new List<Knowledge__DataCategorySelection>(); // holds DataCategorySelection records to insert
		@TestVisible
		List<Knowledge__DataCategorySelection> deleteDataCategorySelections = new List<Knowledge__DataCategorySelection>(); // holds DataCategorySelection records to delete
		@TestVisible
		Map<Id, String> recordTypeAndCategoryMap;
		@TestVisible
		Map<Id, String> parentIdAndCategoryMap;
		@TestVisible
		Map<Id, List<Knowledge__DataCategorySelection>> parentAndListOfCategories;
		@TestVisible
		Set<Id> parentIds;

		public override Type getClassType() {
			return AsyncCreateDataCategoryWorker.class;
		}

		/**
		 * The primary object that will be manipulated with this Async Worker.
		 * @return  SObjectType
		 */
		public override SObjectType getSObjectTypeGroup() {
			return Knowledge__DataCategorySelection.SObjectType;
		}

		/**
		 * To populate the Object params variable
		 * @param serialisedParams
		 */
		public override void deserialiseParams(String serialisedParams) {
			if (String.isNotBlank(serialisedParams)) {
				AsyncCreateDataCategoryWorker params = (AsyncCreateDataCategoryWorker) JSON.deserialize(serialisedParams, AsyncCreateDataCategoryWorker.class);
				parentIds = params.parentIds;
				recordTypeAndCategoryMap = params.recordTypeAndCategoryMap;
				parentIdAndCategoryMap = params.parentIdAndCategoryMap;
				parentAndListOfCategories = params.parentAndListOfCategories;
			}
		}

		/**
		 * Collects all the datacategories exist on the given articles and checks if there are any valid datacategories.
		 * Insert's a datacategory if the article is not having a valid the datacategory.
		 * Deletes all the invalid categories.
		 * @param uow
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			//Prepares list of unwanted datacategories to delete.
			//also updates the parentAndListOfCategories if we have correct datacategory.
			processDataCategories(parentIds);

			if (!insertDataCategorySelections.isEmpty()) {
				uow.registerNew(insertDataCategorySelections);
			}

			if (!deleteDataCategorySelections.isEmpty()) {
				uow.registerDeleted(deleteDataCategorySelections);
			}
		}

		public void processDataCategories(Set<Id> parentIds) {
			Map<String, Object> params = new Map<String, Object>{ 'parentIds' => parentIds };
			KnowledgeDataCategorySelectionsSelector dataCategorySelector = KnowledgeDataCategorySelectionsSelector.newInstance();

			for (Knowledge__DataCategorySelection dataCategorySelection : dataCategorySelector.search(params)) {
				//Filtering datacategory records whos group name is Article_Type.
				//Using if condition because DataCategoryGroupName field is not supported as filter in query's WHERE codition
				if (DATA_CATEGORY_GROUP_NAME.equalsIgnoreCase(dataCategorySelection.DataCategoryGroupName)) {
					String expectedCategoryName = parentIdAndCategoryMap.get(dataCategorySelection.ParentId);

					if (!expectedCategoryName.equalsIgnoreCase(dataCategorySelection.DataCategoryName)) {
						deleteDataCategorySelections.add(dataCategorySelection);
					} else {
						parentAndListOfCategories.get(dataCategorySelection.ParentId).add(dataCategorySelection);
					}
				}
			}

			//prepare new datacategories to insert
			for (Id articleId : parentIds) {
				if (parentAndListOfCategories.get(articleId) != null && parentAndListOfCategories.get(articleId).isEmpty()) {
					Knowledge__DataCategorySelection newDataCategory = new Knowledge__DataCategorySelection();
					newDataCategory.ParentId = articleId;
					newDataCategory.DataCategoryGroupName = DATA_CATEGORY_GROUP_NAME;
					newDataCategory.DataCategoryName = parentIdAndCategoryMap.get(articleId);

					insertDataCategorySelections.add(newDataCategory);
				}
			}
		}
	}
}