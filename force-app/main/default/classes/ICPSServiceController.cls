/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Controller
 * @tag Controller
 * @tag ICPS Service
 * @domain ICPS
 * @description Service Controller class for ICPS Object.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
public with sharing class ICPSServiceController {

	/**
	 * Record limit on ICPS search results
	 */
	private static final Integer SEARCH_LIMIT = 100;

	/**
	 * Return code if no article found in SAP EM
	 */
	private static final String NOT_EXIST_ARTICLE_RETURN_CODE = 'ESB-BUS-DATA-105';

	/**
	 * Field Overrides for ICPS Search Function
	 * In case of new fields required to be returned in the future update this field set
	 */
	private static final Set<SObjectField> ICPS_SEARCH_FIELD_OVERRIDES = new Set<SObjectField>{
			ICPS__c.Name,
			ICPS__c.MailCategory__c,
			ICPS__c.ItemType__c,
			ICPS__c.ReceiverName__c,
			ICPS__c.CountryofOrigin__c,
			ICPS__c.NumberofArticles__c,
			ICPS__c.Status__c
	};

	/**
	 * This method is used to get ICPS Cases given search parameters as a map and a match option
	 * note: This method only supports at most 9 search criteria as in searchParams
	 * @param searchParams Search Params passed in as Map<String, String> (e.g, Reference: '12818')
	 * @param matchAll Match options, true for 'AND', false for 'OR'
	 * @return list of ICPS meeting the search criteria
	 */
	@AuraEnabled
	public static List<ICPS__c> getICPSCases(Map<String, String> searchParams, Boolean matchAll) {
		try {
			return ICPSSelector.newInstance(SEARCH_LIMIT, ICPS_SEARCH_FIELD_OVERRIDES).search(searchParams, matchAll);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}

	}

	/**
	 * This method is used to clone an ICPS provided current ICPS Id
	 * @param icpsId Id of the ICPS to be cloned
	 * @return cloned ICPS__C record
	 */
	@AuraEnabled
	public static ICPS__c cloneICPS(String icpsId) {
		try {
			ICPS__c icps = ICPSSelector.newInstance(1).selectById(new Set<Id>{
					icpsId
			})[0];
			ICPS__c newICPS = new ICPS__c(
					RecordTypeId = icps.RecordTypeId,
					OwnerId = icps.OwnerId,
					CountryofOrigin__c = icps.CountryofOrigin__c,
					DemurrageStartDate__c = icps.DemurrageStartDate__c,
					Status__c = 'In Store',
					DutyStatus__c = icps.DutyStatus__c,
					ItemType__c = icps.ItemType__c,
					MailCategory__c = icps.MailCategory__c,
					OrderNumber__c = icps.OrderNumber__c,
					OtherStorageLocation__c = icps.OtherStorageLocation__c,
					StoredLocation__c = icps.StoredLocation__c
			);
			ApplicationDatabase.getInstance().dmlInsert(new List<ICPS__c>{newICPS});
			return newICPS;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to get ICPS record with child articles if found
	 * @param icpsId Id of the ICPS
	 * @return ICPS with articles
	 */
	@AuraEnabled
	public static ICPS__c getICPSWithArticles(String icpsId) {
		try {
			List<ICPS__c> icpsList = ICPSSelector.newInstance(1).selectById(new Set<Id>{icpsId}, new Set<Object>{ICPSSelector.Options.WITH_ICPS_ARTICLES});
			return icpsList[0];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to search ICPS Articles in SAP EM
	 * @param trackingId tracking Id to be used for search
	 * @return ICPSArticleTrackingResult wrapping required details
	 */
	@AuraEnabled
	public static ICPSArticleTrackingResult searchICPSArticlesInSAP(String trackingId) {
		try {
			TIBCOArticleService articleService = TIBCOArticleService.getInstance();
			TIBCOSearchResult searchResult = articleService.search(new String[] {trackingId}, true, false, false, false, true);
			ICPSArticleTrackingResult trackingResult = mapICPSArticles(trackingId, searchResult);

			return trackingResult;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to upsert ICPS articles and update related ICPS
	 * notes: Two dml calls are required as ICPS and ICPS Articles can't be updated in one DML
	 * @param articles articles to be upserted
	 * @param icps ICPS to be updated if not null
	 */
	@AuraEnabled
	public static void saveArticles(List<ICPSArticle__c> articles, ICPS__c icps) {
		try {
			// Update ICPS record if not null
			if (icps != null) {
				ApplicationDatabase.getInstance().dmlUpdate(new List<ICPS__c>{icps});
			}
			ApplicationDatabase.getInstance().dmlUpsert(articles, ICPSArticle__c.Id);
		} catch (Exception e) {
			// Changes will be rolled back and error message will be passed back to frontend if encounter any DML exceptions
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to send request to label print service
	 * @param icpsId ID of the ICPS record
	 * @return LabelPrintDetail wrapper of the PDF stream in base64 and ICPS Name
	 */
	@AuraEnabled
	public static LabelPrintDetail printLabel(String icpsId) {
		try {
			ICPS__c icps = ICPSSelector.newInstance(1).selectById(new Set<Id>{icpsId})[0];

			String icpsName = icps.Name;
			String pdfStream =  ICPSService.getInstance().retrieveBase64Labels(icps, UserInfo.getUserName());

			LabelPrintDetail labelPrintDetail = new LabelPrintDetail();
			labelPrintDetail.icpsName = icpsName;
			labelPrintDetail.pdfStream = pdfStream;

			return labelPrintDetail;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This method is used to map Tracking result from TIBCO Service to ICPSArticleTrackingResult
	 * @param articleNumber Article number or tracking Id
	 * @param searchResult TIBCOSearchResult from TIBCO Service
	 * @return ICPSArticleTrackingResult
	 */
	private static ICPSArticleTrackingResult mapICPSArticles(String articleNumber, TIBCOSearchResult searchResult) {
		ICPSArticleTrackingResult result = new ICPSArticleTrackingResult();
		List<TrackingArticle> trackingArticles = new List<TrackingArticle>();
		List<ConsignmentDetail> consignmentDetails = new List<ConsignmentDetail>();

		for (TIBCOTrackingResultWrapper tr: searchResult.trackResults) {
			TrackingArticle trackingArticle = new TrackingArticle();
			ConsignmentDetail consignmentDetail;
			trackingArticle.trackingId = articleNumber;
			if (searchResult.success && tr.Success) {
				if (tr.consignmentDetails != null) {
					consignmentDetail = new ConsignmentDetail();
					consignmentDetail.consignmentArticle = tr.consignmentDetails.proxyConsignment;
					consignmentDetails.add(consignmentDetail);
				} else {
					trackingArticle.article = tr.articleDetails.proxyArticle;
					mapArticleContentItems(trackingArticle.article, tr.articleDetails.transientAttributes.contentItems);
				}
			} else {
				if (!tr.Success) {
					String errorText = tr.resultDescription;
					if (tr.returnCode == NOT_EXIST_ARTICLE_RETURN_CODE) {
						errorText = 'Data for this item is not available.';
					}
					result.errors.add(errorText);
					trackingArticle.error = errorText;
				}
			}
			trackingArticles.add(trackingArticle);
		}
		if (!searchResult.success) {
			result.errors.addAll(searchResult.errors);
		}

		result.articles = trackingArticles;
		result.consignments = consignmentDetails;

		return result;
	}

	/**
	 * This method is used to extract and map content items from TIBCOArticleWrapper
	 * @param article core article
	 * @param contentItems content items wrapper from TIBCO service
	 */
	private static void mapArticleContentItems(Article__c article, TIBCOArticleWrapper.ArticleContentItem[] contentItems) {
		if (article != null && contentItems != null) {
			List<String> contents = new List<String>();
			Decimal weight = 0;
			Decimal value = 0;
			for (TIBCOArticleWrapper.ArticleContentItem item: contentItems) {
				if (String.isNotBlank(item.description)) {
					contents.add(item.description);
				}
				if (item.weight != null) {
					weight += Decimal.valueOf(item.weight);
				}
				if (item.value != null) {
					value += Decimal.valueOf(item.value);
				}
			}
			article.ContentsItems__c = String.join(contents, '; ');
			article.ActualWeight__c = weight;
			article.ArticleTransitAmountValue__c = value;
		}
	}

	/**
	 * Wrapper class for ICPS Article with Error status captured from SAP EM
	 */
	public class ICPSArticleTrackingResult {
		@AuraEnabled
		public List<String> errors = new List<String>();
		@AuraEnabled
		public List<ConsignmentDetail> consignments { get; set; }
		@AuraEnabled
		public List<TrackingArticle> articles = new List<TrackingArticle>();
	}

	public class TrackingArticle {
		@AuraEnabled
		public String trackingId { get; set; }
		@AuraEnabled
		public Article__c article { get; set; }
		@AuraEnabled
		public String error { get; set; }
	}

	public class ConsignmentDetail {
		@AuraEnabled
		public Article__c consignmentArticle { get; set; }
	}

	public class LabelPrintDetail {
		@AuraEnabled
		public String icpsName { get; set; }
		@AuraEnabled
		public String pdfStream { get; set; }
	}
}