/**
 * @description       : This module checks and retrieves Articles from SAP into SF
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 **/
public inherited sharing class STCaseInvestigationArticleModule extends ApplicationDomain.Module {
	public static STCaseInvestigationArticleModule newInstance() {
		return (STCaseInvestigationArticleModule) Application.Utilities.newInstance(STCaseInvestigationArticleModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCaseInvestigationArticleModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, null, uow);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}

	void retrieveArticles(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		Set<String> referenceIds = new Set<String>();
		for(CaseInvestigation__c ci: records) {
			if(String.isBlank(ci.ReferenceId__c) == false && (existingRecords == null || ci.ReferenceId__c != existingRecords.get(ci.Id).ReferenceId__c)) {
				referenceIds.add(ci.ReferenceId__c);
			}
		}

		if (referenceIds.isEmpty() == false) {
			uow.registerAsyncWork(
				new ApplicationUnitOfWork.AsyncStagingWorker(
					AsyncCaseInvestigationArticleWorker.class,
					new Map<String, Object>{ 'referenceIds' => referenceIds }
				)
			);
		}
	}

	public without sharing class AsyncCaseInvestigationArticleWorker extends ApplicationUnitOfWork.AsyncWorker implements Database.AllowsCallouts {
		@TestVisible
		Set<String> referenceIds;

		/*
		 * This method takes the referenceIds and check if there Articles with the same name if there aren't then it retrieves those articles from SAP and stores them in SF
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			if(referenceIds.isEmpty() == false) {
				// check if they exist in SF first
				//for(Article__c a: ArticlesSelector.newInstance().selectByArticleNames(referenceIds, new Set<Object>())) {
				//	referenceIds.remove(a.Name); // no need to fetch existing articles
				//}
				if(referenceIds.isEmpty() == false) {
					try {
						// Leveraging the searchByArticleIdsInSAP method to fetch the articles from SAP and then save it via the translator
						TIBCOSearchResult result = TibcoArticleService.getInstance().searchByArticleIdsInSAP(new List<String>(referenceIds));
						if (result.success && result.trackResults.isEmpty() == false) {
							TIBCODataTranslator translator = TIBCODataTranslator.newInstance();
							translator.translate(result.trackResults);
							translator.save(false, true);
						}
					} catch(Exception exp){
						UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, STCaseInvestigationArticleModule.class.getName(), 'retrieveArticles', SSSWConstants.CASE_INVESTIGATION_TRIGGER, LoggingLevel.ERROR);
					}
				}
			}
		}

		public override Type getClassType() {
			return AsyncCaseInvestigationArticleWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return CaseInvestigation__c.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			AsyncCaseInvestigationArticleWorkerParameters params = (AsyncCaseInvestigationArticleWorkerParameters) JSON.deserialize(
				serialisedParams,
				AsyncCaseInvestigationArticleWorkerParameters.class
			);
			referenceIds =  params.referenceIds;
		}
	}

	public class AsyncCaseInvestigationArticleWorkerParameters {
		@TestVisible
		Set<String> referenceIds;
	}

}
