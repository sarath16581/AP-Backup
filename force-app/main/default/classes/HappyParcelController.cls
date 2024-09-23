/**
 * @author Nathan Franklin
 * @date 2020-04-01
 * @group HappyParcel
 * @description Controller for Happy Parcel Lightning Application
 * @changelog
 * 2020-09-18 Disha Kariya Changes to display Network info based on WCC
 * 2020-09-18 - Ranjeewa Silva  - Updated runtime config to include featured scan event types.
 * 2020-09-23 - Disha Kariya  - Changes for error handling for network search
 * 2020-09-28 - Disha Kariya  - Added Safe drop eligibility status, set and unset methods.
 * 2020-10-19 - Ranjeewa Silva  - More fields returned in getNetwork() method.
 * 2020-10-22 - Disha Kariya  - Added Delivery ETA fields coming from Cognition as transient attributes
 * 2021-05-18 - Disha Kariya - Added notification preferences methods.
 * 2021-05-20 - Ranjeewa Silva - Added event message attachment type definitions to runtime config
 * 2021-06-15 - Ranjeewa Silva - Updated to return specific event message field set when embedded in My Network
 * 2021-10-01 - Nathan Franklin - Updated logic for transient attributes. Now more structured and linked to each article/event
 * 2021-08-02 - Mathew Jose - Added new methods to retrievethe overflow field sets associated with the event messages table.
 * 2021-08-02 - Prerna Rahangdale - Added a method to query the Knowledge article to show in warning when articles has VODV set to true.
 * 2022-04-14 - Mahesh Parvathaneni - Added a method to calculate the distance between geo-coordinates
 * 2024-05-17 - Seth Heang - Added methods for additional query to remote .NET API for retrieving StarTrack consignment/article details
 * 2024-05-21 - Seth Heang - Added methods to allow forceConsignment Search if applicable while quering SAP-EM article details
 * 2024-06-06 - Raghav Ravipati - Added methods to get critical incident knowledge articles based on network org Id
 * 2024-06-17 - Raghav Ravipati - Added changes related to Enquiry Mapping to filter using MappingModule field
 * 2024-06-24 - Seth Heang - updated queryTrackingApi method to reduce redundent SAP callout for a scenario where the article searched has no parent consignment
 * 2024-06-25 - Raghav Ravipati - Updated the Amazon s3 deliveryRepository API from V1 to V2 
 * 2024-07-17 - Seth Heang - Added POD related method calls from MyCustomerDeliveryProofPdfController so the permission is inherited
 * 2024-07-24 - Seth Heang - Added warningMessages attribute to TrackingArticle wrapper
 * 2024-09-03 - Raghav Ravipati - Accessibility check for knowledge__kav and Changed method return type for getCriticalIncidents as we are getting error is we have knowledge__kav as return type.
 */
public with sharing class HappyParcelController {
	/**
	 * Apex property to access current network/ community
	 * Using lazy loading as it prevents multiple SOQL.
	 */
	public static Network networkDetail {
		get {
			if (networkDetail == null) {
				networkDetail = [
					SELECT Id, Name, Description
					FROM Network
					WHERE Id = :Network.getNetworkId()
				];
			}
			return networkDetail;
		}
		set;
	}
	/**
	 * Runtime config that is required for the HP lwc components
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> loadConfig() {
		return new Map<String, Object>{
			'articleFields' => getArticleDetailFieldSetConfig(),
			'consignmentFields' => getConsignmentDetailFieldSetConfig(),
			'signatureEventTypes' => getSignatureEventTypes(),
			'featuredScanEventTypes' => getFeaturedEventTypes(),
			'articleTypes' => ArticleUtil.getArticleTypes(),
			'eventMessageFields' => getEventMessageListFieldSetConfig(),
			'eventMessageOverflowFields' => getEventMessageOverflowListFieldSetConfig(),
			'eventMessageFeaturedOverflowFields' => getEventMessageFeaturedOverflowListFieldSetConfig(),
			'eventMessageTypeDefinitions' => EventMessageUtil.getEventMessageTypesByCategory(),
			'happyParcelStatusValues' => getHappyParcelStatusValues(),
			'manifestAssessmentMappings' => getManifestAssessmentValues(),
			'manifestAssessmentHappyThreshold' => 1000, // TODO, build into custom setting
			'eventMessageAttachmentTypeDefinitions' => EventMessageUtil.getEventMessageAttachmentTypes(),
			'VODVKnowledgeId' => queryVODVKnowledge()
		};
	}

	/**
	 * @description 	This will commence a callout to query tracking information from the standard interface
	 * 			NOTE: This is a synchronous query (not using continuation) which allows to run 2 simultaneous requests at the same time
	 * @param	String trackingId
	 * @param	Boolean forceConsignmentSearch
	 * @return	TrackingResult
	 */
	@AuraEnabled(Cacheable=false)
	public static TrackingResult queryTrackingApi(String trackingId, Boolean forceConsignmentSearch, String clearViewMappingModel) {
		try {
			TIBCOArticleService articleService = TIBCOArticleService.getInstance();
			TIBCOSearchResult searchResult;
			String consignmentId;

			// initial SAP callout
			searchResult = articleService.searchByArticleIdsInSAP(new List<String>{ trackingId });
			if (forceConsignmentSearch == true) {
				consignmentId = getConsignmentIdForForceConsignmentSearch(searchResult);
			}
			// Make another callout using consignment trackingId if forceConsignment is enabled and article has parent consignment
			if (consignmentId != null) {
				searchResult = articleService.search(new List<String>{ consignmentId }, true, false, false, false, true);
			} else {
				// process SAP response and passed in the response from initial callout
				searchResult = articleService.processTIBCOSearchResults(new List<String>{ trackingId }, searchResult, false, true);
			}

			//NOTE: TrackingResult class simply provides some structure around the returned object (including case consistency)
			//Also retrieves EAT details from transient attributes
			TrackingResult output = new TrackingResult(searchResult);

			// go through all the process results that will be outputted and provide the correct case clearview code mappings (for when a new case needs to be created)
			// this allows the clearview codes to be defaulted with the correct values in the mini case component (or any external caller to Happy Parcel) based on the article that was queried
			mapCaseTypesToArticleProducts(output, clearViewMappingModel);

			return output;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description		Perform additional query via SOAP API callout to dotNet API for retrieving StarTrack consignment/article details.
	 * @param		String consignmentNumber
	 * @param		String trackingResultString
	 * @return		Object
	 */
	@AuraEnabled(Cacheable=false Continuation=true)
	public static Object queryTrackingApiForStarTrack(String consignmentNumber, String trackingResultString) {
		TrackingArticle trackingResult = (TrackingArticle) System.JSON.deserialize(trackingResultString, TrackingArticle.class);
		Object result = HappyParcelService.getInstance().searchStarTrackAsync(StarTrack_Constants.TYPE_CONSIGNMENT, consignmentNumber, trackingResult);
		return result;
	}

	/**
	 * @description		Continuation Callback method for queryTrackingApiForStarTrack to handle ther response from dotNet API for StarTrack
	 * @param		Object state
	 * @return		Object
	 */
	@AuraEnabled(continuation=true)
	public static Object processStarTrackSearchResult(Object state) {
		return HappyParcelService.getInstance().processStarTrackSearchResult(state);
	}

	/**
	 * Used for Testing Purpose only.
	 * Static Continuation Methods require a state object, but Test.invokeContinuation cannot pass in arguments.
	 * Therefore, store the state as static class variable to allow CallBack method to work when testing.
	 * Source: https://salesforce.stackexchange.com/a/329949
	 *  */
	public static HappyParcelService.StateInfoStarTrack starTrackContState;
	public static Object processStarTrackSearchResult() {
		return HappyParcelService.getInstance().processStarTrackSearchResult(starTrackContState);
	}

	/**
	 * This queries the happy parcel end point to retrieve certain advanced information relating to the state of the parcel
	 */
	//Cacheable=true
	@AuraEnabled(Cacheable=false Continuation=true)
	public static Object queryAnalyticsApi(String trackingId) {
		HappyParcelService service = HappyParcelService.getInstance();
		Continuation con = service.getContinuation(trackingId);
		con.continuationMethod = 'processHappyParcelCallback';
		return con;
	}

	@AuraEnabled(Cacheable=false)
	public static HappyParcelService.Result processHappyParcelCallback(List<String> labels, Object state) {
		HttpResponse response = Continuation.getResponse(labels[0]);
		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.parseResponse(response);

		return result;
	}

	/**
	 * This will allow the Delivery Proof pdf to be downloaded from Happy Parcels UI
	 * This will return a base 64 string of the PDF content
	 */
	@AuraEnabled(Cacheable=true)
	public static String getDeliveryProofPdfBlob(String trackingId) {
		try {
			return EncodingUtil.base64Encode(DeliveryProofService.getInstance().getDeliveryProofPdfContent(trackingId));
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Retrieve the current Safe Drop Status and Information for a particular tracking article
	 * This is a single article either standalone or a part of a consignment
	 */
	@AuraEnabled
	public static SafeDropEligibilityService.EligibilityResponse getSafeDropStatus(String articleId) {
		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		SafeDropEligibilityService.EligibilityResponse result = service.getSafeDropStatus(articleId);

		return result;
	}

	/**
	 * Set the safe drop preference. This should always be a consignment when available
	 */
	@AuraEnabled
	public static String setSafeDropToEligible(String articleId) {
		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		return service.submitSafeDrop(articleId, 'ADD');
	}

	/**
	 * Unset the safe drop preference. This should always be a consignment when available
	 */
	@AuraEnabled
	public static String unsetSafeDropEligibility(String articleId) {
		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		return service.submitSafeDrop(articleId, 'DELETE');
	}

	/**
	 * Retrieve the current Notification Preference Status
	 */
	@AuraEnabled
	public static NotificationPreferencesService.NotificationPreferencesResponse getNotificationPreferences(Map<String, List<String>> searchStrings) {
		NotificationPreferencesService service = NotificationPreferencesService.getInstance();
		NotificationPreferencesService.NotificationPreferencesResponse result = service.getNotificationPreferences(searchStrings);

		return result;
	}

	/**
	 * Set/Unset Notification Preference Status
	 * This is a single value update as per the API
	 */
	@AuraEnabled
	public static String setNotificationPreferences(String searchStrings, Boolean setValue) {
		NotificationPreferencesService service = NotificationPreferencesService.getInstance();
		String result = service.setNotificationPreferences(searchStrings, setValue);

		return result;
	}

	/**
	 * Use the API to pull back the filtered out image.
	 * The API blacks out faces and text.
	 */
	@AuraEnabled(Continuation=true)
	public static Object getArticleImage(String guidId, String attachmentType) {
		// Get configurations from customsetting. Looks for data that matches with attachmentType else gets the default values.
		DigitalRepositoryAPIV2Settings__c apiConfig = DigitalRepositoryAPIV2Settings__c.getValues(attachmentType);
		// default config.
		if (apiConfig == null) {
			apiConfig = DigitalRepositoryAPIV2Settings__c.getValues('DefaultConfigurations');
		}

		if (String.isNotBlank(apiConfig.FileExtensionType__c)) {
			guidId += apiConfig.FileExtensionType__c;
		}
		// constructing Digital Repository V2 request
		DigitalRepositoryService digitalRepository = DigitalRepositoryService.getInstance();
		Continuation continuationRequest = digitalRepository.getContinuation(
			guidId,
			apiConfig.BucketName__c,
			apiConfig.BlurImage__c,
			Integer.valueOf(apiConfig.ResizePercentage__c),
			Integer.valueOf(apiConfig.ResizeThreshold__c)
		);
		continuationRequest.continuationMethod = 'safeDropImageCallback';

		// Return it to the system for processing
		return continuationRequest;
	}

	/**
	 * This is the callback for the async callout for retrieving the safe drop image.
	 */
	@AuraEnabled
	public static Object safeDropImageCallback(List<String> labels, Object state) {
		HttpResponse response = Continuation.getResponse(labels[0]);
		DigitalRepositoryService digitalRepository = DigitalRepositoryService.getInstance();
		// parse response
		DigitalRepositoryService.DocumentApiResponse parsedResponse = digitalRepository.parseResponse(response);

		return parsedResponse;
	}

	/**
	 * Returns Network details
	 */
	@AuraEnabled
	public static NetworkDetailsWrapper getNetwork(String wccString) {
		try {
			List<Network__c> networks = NetworksSelector.newInstance(
					new Set<SObjectField>{
						Network__c.Id,
						Network__c.Name,
						Network__c.Phone_Number__c,
						Network__c.Network_Address__c,
						Network__c.Mon__c,
						Network__c.Tue__c,
						Network__c.Wed__c,
						Network__c.Thu__c,
						Network__c.Fri__c,
						Network__c.Sat__c,
						Network__c.Sun__c,
						Network__c.CL_Mon__c,
						Network__c.CL_Tue__c,
						Network__c.CL_Wed__c,
						Network__c.CL_Thu__c,
						Network__c.CL_Fri__c,
						Network__c.CL_Sat__c,
						Network__c.CL_Sun__c,
						Network__c.Hatch_Mon__c,
						Network__c.Hatch_Tue__c,
						Network__c.Hatch_Wed__c,
						Network__c.Hatch_Thu__c,
						Network__c.Hatch_Fri__c,
						Network__c.Hatch_Sat__c,
						Network__c.Sun__c,
						Network__c.Hatch_Desc__c,
						Network__c.Org_ID__c,
						Network__c.Contact_Facility__c
					}
				)
				.selectByOrgId(new Set<String>{ wccString }, new Set<Object>{ NetworksSelector.Options.WITH_RECORDTYPE })
				.values();
			if (networks.size() > 0) {
				NetworkDetailsWrapper networkWrapper = new NetworkDetailsWrapper(networks[0], null);
				return networkWrapper;
			} else {
				return new NetworkDetailsWrapper(null, 'No network found');
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String getCriticalIncidents() {
		String newtorkOrgIdsWithIncidentsJSON;
		try {
			if(Schema.sObjectType.Knowledge__ka.isAccessible()){
				Map<String, List<Knowledge__kav>> newtorkOrgIdsWithIncidents = new Map<String, List<Knowledge__kav>>();
				//query critical incidents
				Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Knowledge__kav.Id, Knowledge__kav.NetworkOrgId__c, Knowledge__kav.Title, Knowledge__kav.UrlName, Knowledge__kav.KnowledgeArticleId };
				KnowledgeArticleVersionsSelector selector = KnowledgeArticleVersionsSelector.newInstance(fieldOverrides);
				Map<String, Object> searchParams = new Map<String, Object>();
				searchParams.put('recordTypeNames', new Set<String>{ 'Critical_Incident' });
				searchParams.put('IsLatestVersion', true);
				searchParams.put('statuses', new Set<String>{ 'Online' });

				//NetworkOrgId__c is longtext area field so we are Iterating over all the publised critical incidents and will fitler using if condition
				for (Knowledge__kav criticalIncident : selector.search(searchParams, true)) {
					String networkOrgIdAsString = criticalIncident.NetworkOrgId__c;

					if (String.isNotBlank(networkOrgIdAsString)) {
						for (String networkOrgId : networkOrgIdAsString.split(';')) {
							if (newtorkOrgIdsWithIncidents.containsKey(networkOrgId)) {
								newtorkOrgIdsWithIncidents.get(networkOrgId).add(criticalIncident);
							} else {
								newtorkOrgIdsWithIncidents.put(networkOrgId, new List<Knowledge__kav>{ criticalIncident });
							}
						}
					}
				}
				newtorkOrgIdsWithIncidentsJSON = JSON.serialize(newtorkOrgIdsWithIncidents);
			}

			return newtorkOrgIdsWithIncidentsJSON;
		} 
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Double getDistanceBetweenLocations(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
		try {
			LocationsService locService = LocationsService.getInstance();
			return locService.getDistanceBetweenLocations(Location.newInstance(lat1, lon1), Location.newInstance(lat2, lon2));
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Returns VODV Knowledge article to show in the warning when the VODV flag is set for Articles.
	 */
	private static Id queryVODVKnowledge() {
		try {
			AusPostSettings__c setting = AusPostSettings__c.getValues('VODVKnowledge');
			Id knowledgeId = setting != null ? Id.valueOf(setting.Record_Id__c) : null;
			return knowledgeId;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Returns a list of fields to be rendered in teh article details section of the UI
	 */
	private static List<FieldConfigItem> getArticleDetailFieldSetConfig() {
		List<FieldConfigItem> output = new List<FieldConfigItem>();
		/*for (Schema.FieldSetMember fm : SObjectType.Article__c.fieldSets.SAP_EM_Panel_Article_View.getFields()) {
			output.add(new FieldConfigItem(fm.getFieldPath(), fm.getLabel(), String.valueOf(fm.getType()) ));
		}*/
		//Leveraging the getFieldConfigs method to retrieve field specific metadata
		output = getFieldConfigs(SObjectType.Article__c.fieldSets.SAP_EM_Panel_Article_View);
		return output;
	}

	/**
	 * Returns a list of fields to be rendered in teh article details section of the UI
	 */
	private static List<FieldConfigItem> getConsignmentDetailFieldSetConfig() {
		List<FieldConfigItem> output = new List<FieldConfigItem>();

		/*for (Schema.FieldSetMember fm : SObjectType.Article__c.fieldSets.SAP_EM_Panel_Consignment_View.getFields()) {
			output.add(new FieldConfigItem(fm.getFieldPath(), fm.getLabel(), String.valueOf(fm.getType()) ));
		}*/
		//Leveraging the getFieldConfigs method to retrieve field specific metadata
		output = getFieldConfigs(SObjectType.Article__c.fieldSets.SAP_EM_Panel_Consignment_View);
		return output;
	}

	/**
	 * Returns a list of fields to be rendered in teh article details section of the UI
	 */
	private static List<FieldConfigItem> getEventMessageListFieldSetConfig() {
		List<FieldConfigItem> output = new List<FieldConfigItem>();

		// grab the field set to use and return field details based on the configuration.
		FieldSet eventMessageFieldSet = getEventMessageFieldSet();
		//Leveraging the getFieldConfigs method to retrieve field specific metadata
		if (eventMessageFieldSet != null) {
			/*for (Schema.FieldSetMember fm : eventMessageFieldSet.getFields()) {
				output.add(new FieldConfigItem(fm.getFieldPath(), fm.getLabel(), String.valueOf(fm.getType()) ));
			}*/
			output = getFieldConfigs(eventMessageFieldSet);
		}

		return output;
	}

	/**
	 * Returns a list of overflow fields to be rendered in event message table on the UI.
	 */
	private static List<FieldConfigItem> getEventMessageOverflowListFieldSetConfig() {
		List<FieldConfigItem> output = new List<FieldConfigItem>();
		// grab the field set to use and return field details based on the configuration.
		FieldSet eventMessageFieldSet = getEventMessageOverflowFieldSet();
		//Leveraging the getFieldConfigs method to retrieve field specific metadata
		if (eventMessageFieldSet != null) {
			/*for (Schema.FieldSetMember fm : eventMessageFieldSet.getFields()) {
				output.add(new FieldConfigItem(fm.getFieldPath(), fm.getLabel(), String.valueOf(fm.getType()) ));
			}*/
			output = getFieldConfigs(eventMessageFieldSet);
		}

		return output;
	}

	/**
	 * Returns a list of overflow fields to be rendered in the latest scans component on the UI.
	 */
	private static List<FieldConfigItem> getEventMessageFeaturedOverflowListFieldSetConfig() {
		List<FieldConfigItem> output = new List<FieldConfigItem>();
		// grab the field set to use and return field details based on the configuration.
		FieldSet eventMessageFieldSet = getEventMessageFeaturedOverflowFieldSet();
		//Leveraging the getFieldConfigs method to retrieve field specific metadata
		if (eventMessageFieldSet != null) {
			output = getFieldConfigs(eventMessageFieldSet);
		}
		return output;
	}
	/**
	 * Returns the field config attributes associated with each fields in the field set.
	 */
	public static List<FieldConfigItem> getFieldConfigs(FieldSet fs) {
		//Describe the Sobject associated with the field set to retrieve the fields.
		List<FieldConfigItem> fieldConfigList = new List<FieldConfigItem>();
		Schema.DescribeSObjectResult DescribeSObjectResultObj = fs.getSObjectType().getDescribe();
		//getting fields from the Sobject. This will help us fetch the help texts.
		Map<String, Schema.SObjectField> fieldMap = DescribeSObjectResultObj.fields.getMap();
		for (Schema.FieldSetMember fm : fs.getFields()) {
			fieldConfigList.add(new FieldConfigItem(fm.getFieldPath(), fm.getLabel(), String.valueOf(fm.getType()), fieldMap.get(fm.getFieldPath()).getDescribe().getInlineHelpText()));
		}
		return fieldConfigList;
	}
	/**
	 * Returns a list of event message types that are used for signature on delivery
	 */
	private static Set<String> getSignatureEventTypes() {
		Set<String> output = new Set<String>();
		for (EventMessageTypeMapping__mdt mapping : EventMessageUtil.getEventMessageTypes().values()) {
			if (mapping.IsSignatureOnDelivery__c) {
				output.add(mapping.Label);
			}
		}
		return output;
	}

	/**
	 * Returns a list of event message types that are considered as featured scans.
	 */
	private static Set<String> getFeaturedEventTypes() {
		Set<String> output = new Set<String>();
		for (EventMessageTypeMapping__mdt mapping : EventMessageUtil.getEventMessageTypes().values()) {
			if (mapping.IsFeatured__c) {
				output.add(mapping.Label);
			}
		}
		return output;
	}

	/**
	 * Loop through all the search results that will be outputted and provide the correct case clearview code mappings (for when a new case needs to be created)
	 * this allows the clearview codes to be defaulted with the correct values based on the article that was queried
	 */
	private static void mapCaseTypesToArticleProducts(TrackingResult result, String clearViewMappingModel) {
		Map<String, List<TrackingArticle>> articleMappingsMap = new Map<String, List<TrackingArticle>>();

		if (result.consignment != null) {
			String key = String.isEmpty(result.consignment.article.ProductCategory__c) ? '' : result.consignment.article.ProductCategory__c.trim();
			key += String.isEmpty(result.consignment.article.SubProduct__c) ? '' : result.consignment.article.SubProduct__c.trim();

			if (!String.isEmpty(key)) {
				if (articleMappingsMap.get(key) == null) {
					articleMappingsMap.put(key, new List<TrackingArticle>());
				}

				articleMappingsMap.get(key).add(result.consignment);
			}
		}

		for (TrackingArticle article : result.articles) {
			String key = String.isEmpty(article.article.ProductCategory__c) ? '' : article.article.ProductCategory__c.trim();
			key += String.isEmpty(article.article.SubProduct__c) ? '' : article.article.SubProduct__c.trim();

			if (!String.isEmpty(key)) {
				if (articleMappingsMap.get(key) == null) {
					articleMappingsMap.put(key, new List<TrackingArticle>());
				}

				articleMappingsMap.get(key).add(article);
			}
		}
		
		// get the clearview code mapping model to apply to the articles (different teams can have different clearview code mappings)
		// if no mapping model is provided, it defaults to Classic
		String mappingModel = 'Classic';
		if (String.isNotBlank(clearViewMappingModel)) {
			mappingModel = clearViewMappingModel;
		}

		// grab the clearview code mappings so we can default the clearview code fields in the mini case component
		// this happens after the search result have been loaded into the Happy Parcel LWC components
		// Note: We are filtering the mapping records using the mappingModel__c field this is just temporary filter and will be removed once all users moved to lightning.
		EnquiryMappingsSelector selector = EnquiryMappingsSelector.newInstance();

		for (MiniCaseFieldMapping__c mapping : selector.selectBySAPKeyAndMappingModel(articleMappingsMap.keySet(), new Set<String>{ mappingModel })) {
			if(articleMappingsMap.containsKey(mapping.SAPKey__c)){
				for (TrackingArticle article : articleMappingsMap.get(mapping.SAPKey__c)) {
					article.caseTypeMapping = mapping.Type__c;
					article.caseProductCategory = mapping.ProductCategory__c;
					article.caseProductSubCategory = mapping.ProductSubcategory__c;
				}
			}
		}
	}

	/**
	 * Grab the status config values that will be received from the happy parcel interface
	 */
	private static Map<String, HappyParcelStatusMapping__mdt> getHappyParcelStatusValues() {
		Map<String, HappyParcelStatusMapping__mdt> mappedStatuses = new Map<String, HappyParcelStatusMapping__mdt>();
		for (HappyParcelStatusMapping__mdt statusMapping : [SELECT APIMappingName__c, CustomIconName__c, HelpText__c, IsDefault__c, StatusText__c FROM HappyParcelStatusMapping__mdt]) {
			mappedStatuses.put(statusMapping.APIMappingName__c, statusMapping);
		}
		return mappedStatuses;
	}
	/**
	 * Grab the manifest assessment config values that will be received from happy parcel interface
	 */
	private static Map<String, HappyParcelManifestAssessmentMapping__mdt> getManifestAssessmentValues() {
		Map<String, HappyParcelManifestAssessmentMapping__mdt> mappedAssessmentTypeMappings = new Map<String, HappyParcelManifestAssessmentMapping__mdt>();
		for (HappyParcelManifestAssessmentMapping__mdt assessmentTypeMapping : [SELECT APIMappingName__c, HelpText__c, StatusText__c, IconName__c FROM HappyParcelManifestAssessmentMapping__mdt]) {
			mappedAssessmentTypeMappings.put(assessmentTypeMapping.APIMappingName__c, assessmentTypeMapping);
		}
		return mappedAssessmentTypeMappings;
	}

	/**
	 * Return the relevant Event Message field set based on where Happy Parcels is embedded. Specific field set
	 * is used when Happy Parcels is embedded with in My Network. Use default field set in all other cases.
	 *
	 * @return EventMessage__c field set to use
	 */
	private static FieldSet getEventMessageFieldSet() {
		// TODO - introduce a new custom metadata type to configure filed set name mapping based on context.
		// pass context (where happy parcels is embedded) as a parameter into loadConfig() method.
		// currently field set names are hard coded here.

		if (Network.getNetworkId() != null) {
			// happy parcels embedded in an experience builder site (community). query additional details of the site via propery.
			Network currentNetwork = networkDetail;
			// check the site name is 'mynetwork' and return my network specific field set
			if ('mynetwork'.equalsIgnoreCase(currentNetwork.Name)) {
				return SObjectType.EventMessage__c.fieldSets.MyNetwork_Event_Messages;
			}
		}
		// return default field set in all other cases
		return SObjectType.EventMessage__c.fieldSets.SAP_EM_Panel_Event_View;
	}

	/**
	 * Return the relevant Event Message overflow field set for event message table based on where Happy Parcels is embedded. Specific overflow fielset
	 * is used when Happy Parcels is embedded with in My Network. Use default field set in all other cases.
	 *
	 * @return EventMessage__c field set to use
	 */
	private static FieldSet getEventMessageOverflowFieldSet() {
		// TODO - introduce a new custom metadata type to configure filed set name mapping based on context.
		// pass context (where happy parcels is embedded) as a parameter into loadConfig() method.
		// currently field set names are hard coded here.

		if (Network.getNetworkId() != null) {
			// happy parcels embedded in an experience builder site (community). query additional details of the site leveraging apex propery.
			Network currentNetwork = networkDetail;
			// check the site name is 'mynetwork' and return my network specific overflow field set
			if ('mynetwork'.equalsIgnoreCase(currentNetwork.Name)) {
				// NOTE: Any additional fields add to this fieldset currently requires an update to TIBCOArticleService.searchArticlesInSFDC
				return SObjectType.EventMessage__c.fieldSets.MyNetworkEventMessagesOverflow;
			}
		}
		// return default overflow field set in all other cases
		// NOTE: Any additional fields add to this fieldset currently requires an update to TIBCOArticleService.searchArticlesInSFDC
		return SObjectType.EventMessage__c.fieldSets.HappyParcelEventOverflowView;
	}

	/**
	 * Return the relevant Event Message overflow field set for latest scan section based on where Happy Parcels is embedded. Specific overflow fieldset
	 * is used when Happy Parcels is embedded with in My Network. Use default field set in all other cases.
	 *
	 * @return EventMessage__c field set to use
	 */
	private static FieldSet getEventMessageFeaturedOverflowFieldSet() {
		// TODO - introduce a new custom metadata type to configure filed set name mapping based on context.
		// pass context (where happy parcels is embedded) as a parameter into loadConfig() method.
		// currently field set names are hard coded here.

		if (Network.getNetworkId() != null) {
			// happy parcels embedded in an experience builder site (community). query additional details of the site leveraging apex propery.
			Network currentNetwork = networkDetail;
			// check the site name is 'mynetwork' and return my network specific overflow field set
			if ('mynetwork'.equalsIgnoreCase(currentNetwork.Name)) {
				// NOTE: Any additional fields add to this fieldset currently requires an update to TIBCOArticleService.searchArticlesInSFDC
				return SObjectType.EventMessage__c.fieldSets.MyNetworkFeaturedOverflowView;
			}
		}
		// return default overflow field set in all other cases
		// NOTE: Any additional fields add to this fieldset currently requires an update to TIBCOArticleService.searchArticlesInSFDC
		return SObjectType.EventMessage__c.fieldSets.HappyParcelFeaturedOverflowView;
	}
	/**
	 * An arua wrapper. NOTE, this only supports a single consignment. There isn't any known use case where multiple consignments need to be supported
	 */
	public class TrackingResult {
		@AuraEnabled
		public List<String> errors = new List<String>();
		@AuraEnabled
		public TrackingArticle consignment;
		@AuraEnabled
		public List<TrackingArticle> articles = new List<TrackingArticle>();
		@AuraEnabled
		public Boolean requireAdditionalQueryForStarTrack; // indicate if additional call is required for StarTrack product
		@AuraEnabled
		public String totalArticlesDelivered;

		public TrackingResult(TIBCOSearchResult result) {
			errors.addAll(result.errors);

			Integer deliveredArticleCount = 0;
			Integer totalArticleCount = 0;
			// check if this result set has a consignment
			for (TIBCOTrackingResultWrapper resultWrapper : result.trackResults) {
				if (!resultWrapper.Success) {
					errors.add(resultWrapper.returnCode + ': ' + resultWrapper.resultDescription);
				} else {
					if (resultWrapper.consignmentDetails != null) {
						consignment = new TrackingArticle(resultWrapper.consignmentDetails);
						totalArticleCount = resultWrapper.consignmentDetails.articles.size();
						// also add all of the articles linked to the consignment
						for (TIBCOArticleWrapper article : resultWrapper.consignmentDetails.articles) {
							if (article.proxyArticle.IsDelivered__c == true) {
								deliveredArticleCount++;
							}
							// check if required to do ST search
							if (validateIfAdditionalQueryForStarTrackIsRequired(article)) {
								requireAdditionalQueryForStarTrack = true;
							}
							articles.add(new TrackingArticle(article));
						}
					} else {
						articles.add(new TrackingArticle(resultWrapper.articleDetails));
					}
				}
			}
			totalArticlesDelivered = deliveredArticleCount + ' / ' + totalArticleCount;
		}
	}

	/**
	 * @description	Validate if the product Id returned from SAP search belong to StarTrack Product Id Range,
	 * 				If so, then make additional callout to .NET API to retrieve additional attributes
	 * @param 		TIBCOArticleWrapper article
	 * @return 		Boolean
	 */
	private static Boolean validateIfAdditionalQueryForStarTrackIsRequired(TIBCOArticleWrapper article) {
		return StarTrack_Constants.startrackProdIDs.containsKey(article.proxyArticle.ProductID__c);
	}

	public class TrackingArticle {
		@AuraEnabled
		public String trackingId = '';
		@AuraEnabled
		public List<TrackingEventMessage> events = new List<TrackingEventMessage>();
		@AuraEnabled
		public Article__c article;
		@AuraEnabled
		public Contact senderContact;
		@AuraEnabled
		public Contact receiverContact;
		@AuraEnabled
		public String eddImageIconName;
		@AuraEnabled
		public String caseTypeMapping;
		@AuraEnabled
		public String caseProductCategory;
		@AuraEnabled
		public String caseProductSubCategory;
		@AuraEnabled
		public List<String> warningMessages;

		@AuraEnabled
		public TIBCOArticleWrapper.ArticleTransientAttributes transientAttributes;

		public TrackingArticle(TIBCOConsignmentWrapper consignment) {
			trackingId = consignment.proxyConsignment.ArticleID__c;
			article = consignment.proxyConsignment;
			senderContact = consignment.sender;
			receiverContact = consignment.receiver;

			for (TIBCOEventMessageWrapper eventMessageWrapper : consignment.eventMessages) {
				events.add(new TrackingEventMessage(eventMessageWrapper));
			}
		}
		public TrackingArticle(TIBCOArticleWrapper article) {
			trackingId = article.proxyArticle.ArticleID__c;
			this.article = article.proxyArticle;

			//TODO: Move these to transient attributes eventually
			senderContact = article.sender;
			receiverContact = article.receiver;
			eddImageIconName = article.eddImageIconName;

			transientAttributes = article.transientAttributes;

			for (TIBCOEventMessageWrapper eventMessageWrapper : article.eventMessages) {
				events.add(new TrackingEventMessage(eventMessageWrapper));
			}
		}
	}

	public class TrackingEventMessage {
		@AuraEnabled
		public EventMessage__c event;
		@AuraEnabled
		public TIBCOEventMessageWrapper.EventTransientAttributes transientAttributes;

		public TrackingEventMessage(TIBCOEventMessageWrapper eventMessageWrapper) {
			event = eventMessageWrapper.proxyEM;
			transientAttributes = eventMessageWrapper.transientAttributes;
		}
	}

	public class FieldConfigItem {
		@AuraEnabled
		public String fieldName;
		@AuraEnabled
		public String fieldLabel;
		@AuraEnabled
		public String fieldType;
		@AuraEnabled
		public String fieldHelpText;

		public FieldConfigItem(String fieldName, String fieldLabel, String fieldType, String fieldHelpText) {
			this.fieldName = fieldName;
			this.fieldLabel = fieldLabel;
			this.fieldType = fieldType;
			this.fieldHelpText = fieldHelpText;
		}
	}

	public class NetworkDetailsWrapper {
		@AuraEnabled
		public Network__c network;
		@AuraEnabled
		public String error;

		public NetworkDetailsWrapper(Network__c network, String error) {
			if (error != '') {
				this.error = error;
			}
			if (network != null) {
				this.network = network;
			}
		}
	}

	/**
	 * @description	Retrieve the parent consignment Id from the article level SAP-EM Response
	 * @param 	TIBCOSearchResult result
	 * @return 	String
	 */
	private static String getConsignmentIdForForceConsignmentSearch(TIBCOSearchResult result) {
		for (TIBCOTrackingResultWrapper tr : result.trackResults) {
			if (tr.articleDetails != null && tr.consignmentDetails == null) {
				return tr.articleDetails?.proxyArticle?.ConsignmentTrackingNumber__c;
			} else {
				return tr.consignmentDetails?.proxyConsignment?.ArticleID__c;
			}
		}
		return null;
	}

	/**
	 * @description	Use the API to pull back the filtered out image. The API blacks out faces and text on the images.
	 * @param	guidId String the image GUID
	 * @param	eventMessageId String Salesforce Id of the Event Message record that the image will be attached to 
	 * @return	Object
	 */
	@AuraEnabled(Continuation=true)
	public static Object getSafeDropImageForPOD(String guidId, String eventMessageId){
		Continuation continuationRequest = (Continuation) MyCustomerDeliveryProofPdfController.getSafeDropImage(guidId, eventMessageId);
		// replace the original continuation method (from MyCustomerDeliveryProofPdfController) with the correct one in HappyParcelController
		continuationRequest.continuationMethod = 'processSafeDropImageForPOD';

		return continuationRequest;
	}

	/**
	 * @description Callback method for the async callout for retrieving the safe drop image for the POD. Re-uses existing method on
	 * MyCustomerDeliveryProofPdfController to save image as attachment on the event message
	 */
	@AuraEnabled
	public static Object processSafeDropImageForPOD(List<String> labels, Object state) {
		return MyCustomerDeliveryProofPdfController.safeDropImageCallback(labels, state);
	}

	/**
	 * @description	Retrieve a snapshot of the current state of SafeDrop image file per article under the parent consignment if they exist in Salesforce
	 * 				Or, it's required to be downloaded. This is method is called, prior to retrieving SafeDrop image in bulk by happyParcelDeliveryProof LWC via multiple transactions
	 * 				or one image per transaction. This is down to bypass the hard limit of 3 Max Continuation Callout per Single Transaction in Salesforce.
	 * @return	List<SafeDropImageState> e.g. SafeDropImageState in JSON: ([{guidID: "guidId123456", requireDownload: true}])
	 */
	@AuraEnabled(Cacheable=false)
	public static List<MyCustomerDeliveryProofPdfController.SafeDropImageState> getCurrentStateOfSafeDropImageRequiredForDownload(String trackingId) {
		return MyCustomerDeliveryProofPdfController.getCurrentStateOfSafeDropImageRequiredForDownload(trackingId);
	}
}