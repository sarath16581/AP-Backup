/**
 * @description Controller for handling in-case SAP-EM capability
 * NOTE: the dependence on GLOBAL is because the class is being used in an IFRAME
 * @author
 * @date
 * @group Articles
 * @domain SSSW
 * @changelog
 * 31.03.2016  kalpita.talwadekar@auspost.com.au   Updated to add apcn to article queries
 * 2017-10-05  nathan.franklin@auspost.com.au   Changing the copyarticle details to the new class.
 * 2020-05-10 - Nathan Franklin - Happy Parcel changes into class
 * 2020-08-04 - SaiSwetha Pingali - Fix for INC1639435- Set attributes readonly and supportsSelectableChildArticles to be able to create childcases
 * 2020-08-04 - Nathan Franklin - Removing the need for the CaseArticleUtility calls
 * 2020-10-08 - Disha Kariya - Allow safe drop attachment for child case creation
 * 2021-09-08	seth.heang@auspost.com.au		Uplift SF API version to 52
 * 2021-10-10 - Nathan Franklin - Changed the way attach delivery proof works
 * 2024-10-08 - George Nguyen - Included Unified cases in the search
 */
global with sharing class CaseSAPEMArticlesController {
	public Boolean showError {get; set;}
	public String articleID {get; set;}
	public Case currentCase {get;set;}
	public Boolean isConsignment;

	public String happyParcelAttributes {
		get {
			// attributes to pass into happy parcels
			//spingali - INC1639435 - Set attributes readonly and supportsSelectableChildArticles to be able to create child cases
			Map<String, Object> componentAttributes = new Map<String, Object> {
					'trackingId' => articleID,
					'supportsExternalLinkHandling' => true,
					'readonly' => true,
					'supportsSelectableChildArticles' => true,
					'supportsSafeDropAttachment' => isConsignment
			};
			return JSON.serialize(componentAttributes);
		}
		private set;
	}

	public CaseSAPEMArticlesController(ApexPages.StandardController controller){
		String cid = controller.getRecord().Id;
		if (cid != null) {

			Map<String, Object> searchParams = new Map<String, Object> {
				'recordTypeDeveloperNames' => new Set<String>{
					SSSWConstants.CASE_RT_SSSW_DELIVERY,
					SSSWConstants.CASE_RT_SSSW_FAX,
					SSSWConstants.CASE_RT_SSSW_GENERAL_ENQUIRY,
					SSSWConstants.CASE_RT_SSSW_SERVICE,
					SSSWConstants.CASE_RT_SSSW_SOCIAL_RECORD_TYPE,
					SSSWConstants.CASE_RT_SSSW_NCCC_DIRECT_EMAIL,

					SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME,
					SSSWConstants.UNIFIED_GENERAL_ENQUIRY_DEVELOPER_NAME
				},
				'caseIds' => new Set<Id>{cid}
			};

			Set<Object> selectorOptions = new Set<Object>{
				CasesSelector.Options.WITH_ARTICLE
			};

			Boolean matchAll = true;

			Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Case.getSObjectType() => new Set<SObjectField>{
					Case.Id,
					Case.IsClosed,
					Case.ReferenceID__c
				},
				Article__c.getSObjectType() => new Set<SObjectField>{
					Article__c.ReferenceID__c
				}
			};

			List<Case> cases = CasesSelector.newInstance(100, fieldOverrides).search(searchParams, selectorOptions, matchAll);

			if (cases.size() > 0) {
				currentCase = cases[0];
				articleID = currentCase.ArticleTest__r != null ? currentCase.ArticleTest__r.ReferenceID__c : currentCase.ReferenceID__c;
				isConsignment = currentCase.ArticleTest__r.RecordType !=null ? currentCase.ArticleTest__r.RecordType.Name.containsIgnoreCase('consignment') : false;
			}
		}
	}

	/**
	 * @param safeDropJSON This context of this variable is updated to mean delivery proof (safe drop + signatures)
	 */
	@RemoteAction
	global static String submit(String parentCaseId, String articlesJSON, String caseOriginator, Boolean hasSingleArticle, String safeDropJSON) {
		// the frontend uses this to redirect the user after the request has finished
		String result = parentCaseId;

		try {
			if(String.isEmpty(caseOriginator)) {
				caseOriginator = 'Customer';
			}
			System.debug('>>caseOriginator: ' + caseOriginator);

			//Case parentCase = [select id,Type,Subject,ContactId, ProductCategory__c,ProductSubCategory__c,EnquirySubType__c, isClosed, ReferenceID__c, CaseOriginator__c  from Case where id=:parentCaseId limit 1];
			Set<SObjectField> selectableFieldOverrides = ApplicationSelector.getAllCreatableFieldsBySObjectType(Case.SObjectType);
			selectableFieldOverrides.add(Case.IsClosed);
			Case parentCase = SSSWCasesSelector.newInstance(selectableFieldOverrides).selectById(new Set<Id>{Id.valueOf(parentCaseId)}).values()[0];
			Map<Id, Case> newCases = new Map<Id, Case>();
			List<Case> newChildCases = new List<Case>();

			// extract the list of selected consignment articles
			// at least one would always have to be selected
			List<String> articleIDs = (List<String>)JSON.deserialize(articlesJSON, Type.forName('List<String>'));
			System.debug('#################### articleIDs:' + articleIDs.size());

			// will always exist since the frontend queried SAP and got a refresh on the data
			Set<String> articlesToQuery = new Set<String>(articleIDs.clone());
			articlesToQuery.add(parentCase.ReferenceID__c);
			List<Article__c> articles = ArticlesSelector.newInstance().selectByArticleIds(articlesToQuery, new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE}).values();

			// grab a reference to the record by ArticleId
			Map<String, Article__c> mappedArticles = new Map<String, Article__c>();
			for(Article__c article : articles) {
				mappedArticles.put(article.ArticleID__c.toLowerCase(), article);
			}

			if(hasSingleArticle && parentCase.IsClosed && articleIDs.size() == 1) {
				// since the case is closed and there is only 1 article selected, we create a new case with the single selected article id
				Case clonedCase = cloneCase(parentCase);
				clonedCase.ReferenceID__c = articleIDs[0];
				clonedCase.ArticleTest__c = mappedArticles.get(articleIDs[0].toLowerCase()).Id;

				// insert record
				ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{clonedCase});

				result = clonedCase.Id;
				newCases.put(clonedCase.Id, clonedCase);
			} else if(parentCase.IsClosed && articleIDs.size() > 0) {
				// since the case is close and multiple articles are selected
				// we create a new parent case with the consignment id and attach each selected article to the parent case
				Case clonedCase = cloneCase(parentCase);

				// insert record
				ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{clonedCase});

				result = clonedCase.Id;

				for(String articleId: articleIDs){
					System.debug('creating new child case with ref id = ' + articleId);
					Case childCase = cloneCase(parentCase);
					childCase.ReferenceID__c = articleId;
					childCase.ArticleTest__c = mappedArticles.get(articleId.toLowerCase()).Id;
					childCase.ParentId = clonedCase.Id;
					childCase.CaseOriginator__c = caseOriginator;
					childCase.Bypass_Data_enforcement__c = true;

					newChildCases.add(childCase);
				}
			} else if(hasSingleArticle && !parentCase.IsClosed && articleIDs.size() == 1) {
				// case is still open, but only 1 article has been selected
				// rather than create a new child case, we simply update the current case ReferenceID with the select article
				Case caseUpdate = new Case(Id = parentCase.Id, ReferenceID__c = articleIDs[0], ArticleTest__c = mappedArticles.get(articleIDs[0].toLowerCase()).Id);

				// update record
				ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{caseUpdate});

			} else if(!parentCase.IsClosed && articleIDs.size() > 0) {
				// case is still open, so we only need to create any child child for the articles that have been selected
				// we only create cases for the articles that are not already attached to the parent case

				// grab a list of the articles attached to any existing child cases
				// this is used to ensure we don't create any more child cases with article ids that already exist
				Set<String> existingArticleIds = new Set<String>();
				List<Case> existingChildCases = SSSWCasesSelector.newInstance(new Set<SObjectField>{Case.Id, Case.ReferenceID__c}).selectChildCasesByParent(new Set<Id>{parentCase.Id}).values();
				for(Case childCase : existingChildCases) {
					if(!String.isEmpty(childCase.ReferenceID__c)) {
						existingArticleIds.add(childCase.ReferenceID__c.toLowerCase());
					}
				}

				for(String articleId: articleIDs) {
					if(!existingArticleIds.contains(articleId.toLowerCase())) {
						System.debug('creating new child case with ref id = ' + articleId);
						Case childCase = parentCase.clone(false, true);
						childCase.ReferenceID__c = articleId;
						childCase.ArticleTest__c = mappedArticles.get(articleId.toLowerCase()).Id;
						childCase.ParentId = parentCase.Id;
						childCase.CaseOriginator__c = caseOriginator;
						childCase.Bypass_Data_enforcement__c = true;

						newChildCases.add(childCase);
					}
				}
			}

			if(!newChildCases.isEmpty()) {
				// insert record
				ApplicationDatabase.getInstance().dmlInsert(newChildCases);
				//Create a map to send to enqueueJob
				for (Case c : newChildCases) {
					newCases.put(c.Id, c);
				}
				//Attach safe drop image
				System.debug('safeDropJSON'+safeDropJSON.length());
				List<String> deliveryProofArticleIds = (List<String>) JSON.deserialize(safeDropJSON, Type.forName('List<String>'));
				if(deliveryProofArticleIds.size() > 0 && newCases.size() > 0) {
					// build a list of cases to attach a delivery proof too based on what the user has selected in the UI
					// best to not assume everything will already be in upper case
					Set<Id> casesForDeliveryProof = new Set<Id>();
					for(String deliveryProofArticleId : deliveryProofArticleIds) {
						deliveryProofArticleId = (!String.isEmpty(deliveryProofArticleId) ? deliveryProofArticleId : '').toUpperCase();
						for(Case c : newCases.values()) {
							String referenceId = (!String.isEmpty(c.ReferenceID__c) ? c.ReferenceID__c : '').toUpperCase();
							if(referenceId == deliveryProofArticleId) {
								casesForDeliveryProof.add(c.Id);
							}
						}
					}

					if(!casesForDeliveryProof.isEmpty()) {
						// attach the pdf delivery proof to the case in an async process
						DeliveryProofService.getInstance().enqueueAttachAPDeliveryProof(casesForDeliveryProof);
					}
				}
			}
		} catch(Exception ex){
			result = 'Error: ' + ex.getMessage();
		}
		return result;
	}

	private static Case cloneCase(Case originalCase) {
		Case clonedCase = originalCase.clone(false, true);
		clonedCase.Unique_Case__c = '';
		clonedCase.Status = 'New';
		clonedCase.Permanent_Close__c = false;
		clonedCase.ResolutionCode__c = '';
		clonedCase.RelatedCase__c = originalCase.Id;
		clonedCase.Case_Milestone_Violation__c = false;
		clonedCase.Customer_Milestones_Violated__c = null;
		clonedCase.Internal_Milestones_Violated__c = null;
		clonedCase.Facility_Milestones_Violated__c = null;
		clonedCase.Customer_Email_Notification__c = null;
		clonedCase.Facility_Tier_Escalation_Email__c = null;
		return clonedCase;
	}
}