/**
 * @description Webservice class to get the Enquiry Insights.
 * 	Called by Fullstop
 * @author Rejeesh Raghavan
 * @date 2024/09/17
 */
public with sharing class ResourceEnquiryInsightsV1 extends ResourceAPIService.IApi{
	//--uri params are case-sensitive & hence in lower case
	private enum PARAM_NAMES {
		tracking_id,
		case_type
	}
	//custom permission API to access this apex class
	@TestVisible private final static String PERMISSION_API_NAME='AccessRoutingInsightsAPI';
	@TestVisible private final static Integer MAX_TRACKING_ID_LENGTH = 32;
	@TestVisible private static String trackingId;
	@TestVisible private static String caseType;
	/**
	 * @description Override query method to get Enquiry Insights
	 * @return  `ResourceAPIService.IResourceResponse`
	 */
	public override ResourceAPIService.IResourceResponse query() {
		Object response;
		try {
			//check for access
			if(!FeatureManagement.checkPermission(PERMISSION_API_NAME)){
				return new ResourceAPIService.ResourceResponse(403,'Forbidden');
			}
			Map<String,String> params = requestParams.queryStringParams;
			//validate uri email & phone
			if(!params.isEmpty() && validateUriParams(params)){
				response = transformOutput(getEnquiryInsights(trackingId));
			}else{
				return new ResourceAPIService.ResourceResponse(400,'Bad Request');
			}
		} catch (Exception ex) {
			return new ResourceAPIService.ResourceResponse(500,'', ex);
		}
		return new ResourceAPIService.ResourceResponse(200, response);
	}
	/**
	 * @description validate params
	 * if trackingId isBlank => INVALID
	 * if trackingId > 32 characters => INVALID
	 * if trackingId < 32 characters => VALID
	 * Also used to populate class-level static variables to be easily accessed throughout the class.
	 * @param params request params
	 * @return  `Boolean` are params valid
	 */
	static Boolean validateUriParams(Map<String,String> params){
		trackingId = params.get(PARAM_NAMES.tracking_id.name());
		caseType = params.get(PARAM_NAMES.case_type.name());

		return isValidTrackingId(trackingId);
	}

	/**
	 * @description validate Tracking Id
	 * @param email 
	 * @return  `Boolean`
	 */
	static Boolean isValidTrackingId(String trackingId){
		return String.isNotBlank(trackingId) && trackingId.length()<=MAX_TRACKING_ID_LENGTH;
	}
	/**
	 * @description get Article__c & Cases based on tracking id
	 * @param paramType 
	 * @return  `List<SObject>`
	 */
	@TestVisible
	static List<SObject> getEnquiryInsights(String trackingId){
		List<Case> cases= new List<Case>();
		Set<String> consignmentIds = new Set<String>();
		//get articles. collect all consignmentIds from the articles
		for(Article__c article : getArticles(new Set<String>{trackingId})){
			consignmentIds.add(article.Name);
			consignmentIds.add(article.ArticleID__c);
			consignmentIds.add(article.ConsignmentTrackingNumber__c);
		}
		consignmentIds.remove(null);
		if(!consignmentIds.isEmpty()){
			//get all cases for articles & consignments
			for(Article__c article : getArticles(consignmentIds)){
				if(!article.Cases__r.isEmpty()){
					cases.addAll(article.Cases__r);
				}
			}
		}
		return cases;
	}
	/**
	 * @description Get articles for a collection of tracking id
	 * @param searchKeys collection of tracking Ids
	 * @return  `List<Article__c>` list of Article__c records
	 */
	@TestVisible
	static List<Article__c> getArticles(Set<String> searchKeys){
		//Article__c fields to be queried
		Set<SObjectField> articleFields = new Set<SObjectField>{
			Article__c.Id, Article__c.Name, Article__c.Source_System__c, Article__c.Consignment__c, Article__c.ConsignmentTrackingNumber__c
			, Article__c.ArticleID__c, Article__c.Consignment__r.Name, Article__c.Consignment__r.ArticleID__c
		};
		Set<Object> selectorOptions = new Set<Object>();
		Map<String, Object> bindMap = new Map<String, Object>();

		ArticlesSelector recordSelector = ArticlesSelector.newInstance(0, articleFields);
		
		bindMap.put('trackingIds', searchKeys);
		
		//use caseType param to filter case record types
		if(caseType== null || caseType.equalsIgnoreCase('allcontactcentre')){
			Set<String> caseRecordTypes = new Set<String>();
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.AP_CASE_RECORDTYPES);
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.ST_CASE_RECORDTYPES);
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.UNIFIED_CASE_RECORDTYPES);
			bindMap.put('caseRecordTypes',caseRecordTypes);
			bindMap.put('closedCaseCutoffDate',Date.today().addDays(-30));
		}
		return recordSelector.selectWithCasesByIdOrTrackingOrName(
			bindMap, selectorOptions
		).values();
	}
	/**
	 * @description Transform List of records to JSON structure for output.
	 * @param records 
	 * @return  `List<Map<String, Object>>`
	 */
	@TestVisible
	static Map<String, Object> transformOutput(List<Case> records){
		List<Object> listCases = new List<Object>();
		Map<String, Object> mapRecord = new Map<String, Object>()
			, mapCase  = new Map<String, Object>();
		//add tracking Id to response
		mapRecord.put(PARAM_NAMES.tracking_id.name(),trackingId);
		//loop through the Case records
		for(Case caseRecord: records){
			mapCase = ResourceCustomerInsightsV1.getCaseMapping(caseRecord);
			//removing tracking_id from Case, as it's not required in Enquiry Insights
			mapCase.remove(PARAM_NAMES.tracking_id.name());
			listCases.add(mapCase);
		}
		mapRecord.put('cases',listCases);
        return mapRecord;
	}
}