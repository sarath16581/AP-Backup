/**
 * @description       : This module checks and retrieves Articles from SAP into SF
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-12-13 - Mahesh Parvathaneni - Added beforeInsert trigger event and checkDuplicateCaseInvestigationRecords method
 **/
public inherited sharing class CaseInvestigationArticleModule extends ApplicationDomain.Module {
	public static CaseInvestigationArticleModule newInstance() {
		return (CaseInvestigationArticleModule) Application.Utilities.newInstance(CaseInvestigationArticleModule.class);
	}

	// Setup which trigger events this module should respond to
	public CaseInvestigationArticleModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableBeforeInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow){
		checkDuplicateCaseInvestigationRecords((List<CaseInvestigation__c>) records);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, null, uow);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}

	/**
	 * function to check the duplicate case investigation records being created for same case, article and network.
	 */
	private void checkDuplicateCaseInvestigationRecords(List<CaseInvestigation__c> records){
		Set<Id> caseIds = new Set<Id>();
		Set<Id> networkIds = new Set<Id>();
		Set<String> articleReferences = new Set<String>();
		//case id + article reference id + network id is the key
		Set<String> existingCaseArticleNetworkKeys = new Set<String>();
		Set<String> caseArticleNetworkKeys = new Set<String>();

		for (CaseInvestigation__c ci : records) {
			String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
			if (caseArticleNetworkKeys.contains(key)) {
				//add error if there are duplicate records in the new list
				ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
			} else {
				caseArticleNetworkKeys.add(key);
			}

			if (ci.Case__c != null) {
				caseIds.add(ci.Case__c);
			}
			if (String.isNotBlank(ci.ReferenceID__c)) {
				articleReferences.add(ci.ReferenceID__c);
			}
			if (ci.Network__c != null) {
				networkIds.add(ci.Network__c);
			}
		}

		if (caseIds.size() > 0 || articleReferences.size() > 0 || networkIds.size() > 0) {
			//get existing case investigation related to the case, network and article reference ids
			for (CaseInvestigation__c eci : CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByCaseArticleNetworkId(caseIds, articleReferences, networkIds).values()) {
				String exisitngKey = eci.Case__c + eci.ReferenceID__c + eci.Network__c;
				existingCaseArticleNetworkKeys.add(exisitngKey);
			}

			for (CaseInvestigation__c ci : records) {
				String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
				if (existingCaseArticleNetworkKeys.contains(key)) {
					//add error if there are duplicate records
					ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
				}
			}
		}
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
				system.debug('>>>>>>>>>>>> referenceIds: ' + referenceIds);
				for(Article__c a: ArticlesSelector.newInstance().selectByArticleNames(referenceIds, new Set<Object>())) {
					referenceIds.remove(a.Name); // no need to fetch existing articles
				}
				if(referenceIds.isEmpty() == false) {
					//try {
						// Leveraging the searchByArticleIdsInSAP method to fetch the articles from SAP and then save it via the translator
						TIBCOSearchResult result = TibcoArticleService.getInstance().searchByArticleIdsInSAP(new List<String>(referenceIds));
						system.debug('>>>>>>>>>>>> result: ' + result);
						system.debug('>>>>>>>>>>>> result.trackResults: ' + result.trackResults);
						if (result.success && result.trackResults.isEmpty() == false) {
							TIBCODataTranslator translator = TIBCODataTranslator.newInstance();
							translator.translate(result.trackResults);
							translator.save(false, true);
						}
					//} catch(Exception exp){
						//UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseInvestigationArticleModule.class.getName(), 'retrieveArticles', SSSWConstants.CASE_INVESTIGATION_TRIGGER, LoggingLevel.ERROR);
					//}
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
