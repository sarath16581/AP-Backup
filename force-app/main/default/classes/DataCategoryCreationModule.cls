/**
 * @description
 * Domain Module that calls a service to create and deleted Datacategories
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Raghav Ravipati
 * @date 2024-05-23
 * @test DataCategoryCreationModuleTest
 * @changelog
 */
public class DataCategoryCreationModule extends ApplicationModule {
	public static DataCategoryCreationModule newInstance() {
		return (DataCategoryCreationModule) Application.Utilities.newInstance(DataCategoryCreationModule.class);
	}
	// Setup which triggers this module should respond to
	public DataCategoryCreationModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			KnowledgeArticleVersionService knowledgeService = KnowledgeArticleVersionService.getInstance();
			knowledgeService.createDataCategorySelection((List<Knowledge__kav>) records, uow);
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(
				ex,
				UserInfo.getOrganizationId(),
				String.valueOf(Knowledge__kav.SObjectType),
				DataCategoryCreationModule.class.getName(),
				'onAfterInsert',
				'Knowledge Article Version Trigger',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			KnowledgeArticleVersionService knowledgeService = KnowledgeArticleVersionService.getInstance();
			knowledgeService.createDataCategorySelection((List<Knowledge__kav>) records, uow);
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(
				ex,
				UserInfo.getOrganizationId(),
				String.valueOf(Knowledge__kav.SObjectType),
				DataCategoryCreationModule.class.getName(),
				'onAfterUpdate',
				'Knowledge Article Version Trigger',
				LoggingLevel.ERROR
			);
		}
	}
}