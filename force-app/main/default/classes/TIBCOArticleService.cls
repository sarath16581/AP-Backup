/**
 * @author Mohamed Atheek
 * @date 30.01.2014
 * @group Articles
 * @tags Cases, SSSW, Articles, Safe Drop, SAP-EM, Tibco
 * @domain Articles
 * @description
 * @changelog
 * 16.04.2016  kalpita.talwadekar@auspost.com.au	Updated	 Added SenderAPCN and ReceiverAPCN to the article queries
 * 03.05.2016  kalpita.talwadekar@auspost.com.au	Updated code to add Hide_Article__c field to the query
 * 12.05.2017  nathan.franklin@auspost.com.au	Added Safe_Drop_GUID__c field in Event message select
 * 16.01.2019  saiswetha.pingali@auspost.com.au	Added container_id__c field in Event message select
 * 27.02.2020  Hasantha.liyanage@auspost.com.au Added the external tracking ID and URL to the article query for ICO
 * 2020-03-13  nathan.franklin@auspost.com.au	Added additional fields to select and an additional contact matching method to link a sender/receiver contact to the search results
 * 2020-04-01  nathan.franklin@auspost.com.au	Rewired a few Data translation save() calls
 * 2020-04-01  nathan.franklin@auspost.com.au	Add class instance method to enable mocking
 * 22.05.2020  arjun.singh@auspost.com.au Added code to capture sorting details for MyNetwork Community
 * 01.09.2020  disha.kariya@auspost.com.au	Updated query to search contact matching name and email and then filtering in apex
 * 2020-09-27 - Nathan Franklin - Added ConsignmentTrackingNumber__c to SOQL
 * 2020-10-28 - Disha Kariya - Added get and set method for transient variables from EM which we do not save to Salesforce
 * 2021-05-07 - Ranjeewa Silva - Added AttachmentType__c and AttachmentGUID__c fields to Event Message SOQL
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
 * 2021-09-23 prerna.rahangdale@auspost.com.au added TruckId__c,FacilitySubLocationId__c,FacilitySubLocationName__c to query from event Messages for Agg WP40.
 * 2021-10-01 - Nathan Franklin - Refactor transient attributes
 * 2021-10-20 - prerna.rahangdale@auspost.com.au added VODV_Redirect__c to article SOQL.
 * 2022-04-11 - Mahesh Parvathaneni - added Outside_Delivery_Radius__c, Geo_Precision__c to event message SOQL
 * 2022-07-05 - Snigdha Sahu - REQ2851358 - added MLID to Article Query
 * 2023-03-01 - Dattaraj Deshmukh - added 'searchArticleRecordsInSFDC' method to wrap static method and to be able to use in mock.
 * 2023-10-05 - Jacob Isaac - added fields causing error on UI on event messages - REQ3312803
**/
public class TIBCOArticleService {

	/**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static TIBCOArticleService getInstance() {
		return (TIBCOArticleService)Application.Utilities.getInstance(TIBCOArticleService.class);
	}

	public static String TIBCO_ENDPOINT {
		get {
			AusPostSettings__c setting = AusPostSettings__c.getValues('TIBCO_EM');
			if (setting != null) {
				return setting.URL__c;
			} else {
				return 'please.configure.tibcoem.endpoint';
			}
		}
		private set;
	}

	/************************************************************
	 * Class instance methods
	 *	  These wrap the legacy static methods
	 *	  in order to provide proper mocking
	 ************************************************************/
	public TIBCOSearchResult search(String[] articleIds, Boolean searchSAPFirst, Boolean deprecated1 /*refreshCaseDetails*/, Boolean showMessages, Boolean deprecated2 /*linkToChildArticleIfSingleArticleConsignment*/, Boolean throwException) {
		return TIBCOArticleService.searchArticles(articleIds, searchSAPFirst, deprecated1 /*refreshCaseDetails*/, showMessages, deprecated2 /*linkToChildArticleIfSingleArticleConsignment*/, throwException);
	}

	/************************************************************
	 * Static methods
	 ************************************************************/

	//Searches SFDC first, if not found then searches SAP and stores the results in SFDC
	public static TIBCOSearchResult searchArticles(String[] articleIds) {
		return searchArticles(articleIds, false, false, true, false, false);
	}

	//If searchSAPFirst = true, searches only SAP
	//If searchSAPFirst = false, searches SFDC first, if no results found then searches SAP and stores them in SFDC
	public static TIBCOSearchResult searchArticles(String[] articleIds, Boolean searchSAPFirst) {
		return searchArticles(articleIds, searchSAPFirst, false, true, false, false);
	}

	public static TIBCOSearchResult searchArticles(String[] articleIds, Boolean searchSAPFirst, Boolean deprecated1 /*refreshCaseDetails*/) {
		return searchArticles(articleIds, searchSAPFirst, deprecated1, true, false, false);
	}

	public static TIBCOSearchResult searchArticles(String[] articleIds, Boolean searchSAPFirst, Boolean deprecated1 /*refreshCaseDetails*/, Boolean showMessages, Boolean deprecated2 /*linkToChildArticleIfSingleArticleConsignment*/) {
		return searchArticles(articleIds, searchSAPFirst, deprecated1, showMessages, false, false);
	}

	public static TIBCOSearchResult searchArticles(String[] articleIds, Boolean searchSAPFirst, Boolean deprecated1 /*refreshCaseDetails*/, Boolean showMessages, Boolean deprecated2 /*linkToChildArticleIfSingleArticleConsignment*/, Boolean throwException) {
		TIBCOSearchResult result;
		if (searchSAPFirst) {
			result = searchArticlesInSAP(articleIds);
			if (foundArticle(result)) {

				// NOTE: An update was made to this to not clone the proxy objects that are passed in
				// This is to ensure the proxy objects generated from searchArticlesInSAP will be updated with their Salesforce Id's
				// We need these to map the transient attributes
				// NOTE: This whole search implementation should be reviewed and refactored
				TIBCODataTranslator translator = new TIBCODataTranslator(result.trackResults);
				translator.save(showMessages, throwException);

				// Grab the transient attributes that were retrieved from the SAP search and merge them into the new result object below
				// Not the best approach, but without revising this entire SAP search capability then this is probably the best way
				// Profiling shows 0-2ms to run this which is acceptable
				Map<String, Map<Id, Object>> transients = getTransientAttributesFromResult(result);

				result = searchArticlesInSFDC(articleIds);//this is done to make any formula fields like EventMessage.Status__c is available to use

				// after the result has been rebuilt, we need to inject the transients back into the final result fed back to the UI
				// NOTE: This is not a great design but unless searchArticlesMethod is fully refactored, there is probably not many other ways of doing this
				// Profiling shows 0-2ms to run this which is acceptable
				mergeTransientsIntoResult(result, transients);

			}
		} else {
			// NOTE: There is no use case to use transient attributes when we search in Salesforce before SAP-EM
			// Therefore, no transient capability has been built into this pathway
			result = searchArticlesInSFDC(articleIds);
			if (!result.success || result.trackResults.size() <= 0) {
				result = searchArticlesInSAP(articleIds);
				if (result.success && result.trackResults.size() > 0) {
					TIBCODataTranslator translator = new TIBCODataTranslator(result.trackResults);
					translator.save(showMessages, throwException);
					result = searchArticlesInSFDC(articleIds);//this is done to make any formula fields like EventMessage.Status__c is available to use
				}
			}
		}
		return result;
	}

	/************************************************************
	 * Class instance methods
	 *	  These wrap the legacy static methods
	 *	  in order to provide proper mocking
	 ************************************************************/
	public TIBCOSearchResult searchArticleRecordsInSFDC(String[] articleIdsInbound) {
		return TIBCOArticleService.searchArticlesInSFDC(articleIdsInbound);
	}

	public static TIBCOSearchResult searchArticlesInSFDC(String[] articleIdsInbound) {
		List<String> articleIds = new List<String>();

		for (String aID : articleIdsInbound) {
			if (!String.isBlank(aID)) {
				articleIds.add(aID);
			}
		}

		TIBCOSearchResult result = new TIBCOSearchResult();

		if (articleIds.isEmpty()) {
			return result;
		}

		List<Article__c> consignmentsAndArticles = [
				SELECT Id, Name, Sender_APCN__c, Receiver_APCN__c, Hide_Article__c,
						ArticleID__c, ActualWeight__c, ArticleCount__c, ArticleLodgementDate__c, ArticleTransitAmountValue__c, DeliveryInstructions__c, DestinationPostCode__c, ProductCategory__c,
						ReceiverAddress__c, ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c, ReceiverCity__c, ReceiverState__c,
						ReceiverPostcode__c, ReceiverCountry__c, ReceiverCountryName__c, ReceiverName__c, ReceiverEmail__c, ReceiverCompany__c,
						SenderAddress__c, SenderAddressLine1__c, SenderAddressLine2__c, SenderAddressLine3__c, SenderAddressLine4__c, SenderCity__c, SenderState__c,
						SenderPostcode__c, SenderCountry__c, SenderCountryName__c, SenderName__c, SenderEmail__c, SenderCompany__c,
						ServiceCode__c, SignatureRequiredFlag__c, SubProduct__c, ServiceQualifier__c, ExpectedDeliveryDate__c, ConsignmentParcelCount__c,
						ContentsItems__c, ContentsItemsPayload__c, InsuranceRequired__c, InsuranceAmount__c, InsuranceChargeAmount__c, InsuranceSDR__c,CTCDollarAmount__c,
						AdditionalServices__c, AdditionalServicesPayload__c, CustCommDecisionCode__c, CustCommDecisionDescription__c, CustDelPrefOptionCode__c, CustDelPrefDescription__c, Notification__c,
						Billing_Account__c, Billing_Account__r.Name, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Organisation__c, Billing_Account__r.Organisation__r.Name, Billing_Account__r.Organisation__r.LEGACY_ID__c,
						RecordTypeId, RecordType.Name, Delivered__c, TrackingID__c, ExternalTrackingID__c, ExternalTrackingURL__c, ConsignmentTrackingNumber__c, CaptureID_receiveronly__c, CaptureID_anyoneataddress__c,VODV_Redirect__c,MLID__c
				FROM Article__c
				WHERE ArticleID__c IN :articleIds or TrackingID__c in :articleIds
		];

		Map<String, List<Article__c>> consignmentToArticles = new Map<String, List<Article__c>>();
		List<Id> consArticleIds = new List<Id>();
		for (Article__c a : [
				SELECT Id, Name,Sender_APCN__c,Receiver_APCN__c,Hide_Article__c,
						ArticleID__c, ActualWeight__c, ArticleCount__c, ArticleLodgementDate__c, ArticleTransitAmountValue__c, DeliveryInstructions__c, DestinationPostCode__c, ProductCategory__c,
						ReceiverAddress__c, ReceiverAddressLine1__c, ReceiverAddressLine2__c, ReceiverAddressLine3__c, ReceiverAddressLine4__c, ReceiverCity__c, ReceiverState__c,
						ReceiverPostcode__c, ReceiverCountry__c, ReceiverCountryName__c, ReceiverName__c, ReceiverEmail__c, ReceiverCompany__c,
						SenderAddress__c, SenderAddressLine1__c, SenderAddressLine2__c, SenderAddressLine3__c, SenderAddressLine4__c, SenderCity__c, SenderState__c,
						SenderPostcode__c, SenderCountry__c, SenderCountryName__c, SenderName__c, SenderEmail__c, SenderCompany__c,
						ServiceCode__c, SignatureRequiredFlag__c, SubProduct__c, ServiceQualifier__c, ExpectedDeliveryDate__c, ConsignmentParcelCount__c,
						ContentsItems__c, ContentsItemsPayload__c, InsuranceRequired__c, InsuranceAmount__c, InsuranceChargeAmount__c, InsuranceSDR__c, CTCDollarAmount__c,
						AdditionalServices__c, AdditionalServicesPayload__c, CustCommDecisionCode__c, CustCommDecisionDescription__c, CustDelPrefOptionCode__c, CustDelPrefDescription__c, Notification__c,
						Consignment__r.ArticleID__c,
						Billing_Account__c, Billing_Account__r.Name, Billing_Account__r.LEGACY_ID__c, Billing_Account__r.Organisation__c, Billing_Account__r.Organisation__r.Name, Billing_Account__r.Organisation__r.LEGACY_ID__c,
						RecordTypeId, RecordType.Name, Delivered__c, TrackingID__c, ProductID__c, SubProductID__c, ConsignmentTrackingNumber__c, CaptureID_receiveronly__c, CaptureID_anyoneataddress__c,VODV_Redirect__c,MLID__c
				FROM Article__c
				WHERE Consignment__c IN :consignmentsAndArticles or TrackingID__c in :articleIds
		]) {
			List<Article__c> aList = consignmentToArticles.get(a.Consignment__r.ArticleID__c);
			if (aList == null) {
				aList = new List<Article__c>();
			}
			aList.add(a);
			consignmentToArticles.put(a.Consignment__r.ArticleID__c, aList);

			consArticleIds.add(a.Id);
		}

		Map<Id, List<EventMessage__c>> articleToEventMessages = new Map<Id, List<EventMessage__c>>();
		for (EventMessage__c e : [
				SELECT Id, Article__c, EventType__c, ActualDateTime__c, ActualLocation__c,
						ArticleCount__c, CommentText__c, DeviceUser__c, EventDescription__c, EventGeoLocation__Latitude__s,
						EventGeoLocation__Longitude__s, SenderID__c, SenderName__c, DeviceID__c, UserName__c, UserRole__c,
						FacilityOrganisationID__c, Facility__c, Facility__r.Name, Facility__r.Contact_Facility__c,
						PlannedDateTime__c, PlannedLocation__c, RoundNo__c, SignatoryName__c, SignatureXString__c,
						StatusText__c, WorkCentreText__c, EventID__c, EventMessageTransmissionDateTime__c, EstimatedDeliveryTimeSlot__c,
						TrackingID__c, TrackingContactType__c, TrackingContactAddress__c, TrackingNotificationServices__c,
						Status__c, Event_Location__c, Safe_Drop_GUID__c, Container_ID__c, PhysicalContainerID__c,
						SortOutputComp__c, SortOutputReason__c, RoutingResultSource__c, OCRVCS_DPID__c,
						OCRVCSPostcode__c, DefaultHeight__c, DefaultLength__c, DefaultWidth__c, DefaultWeight__c,
						VISALabelLine1__c, VISALabelLine2__c, SAR__c, SortDest__c, SortOutputStatus__c,
						SortInductMode__c, OCRVCSResultSource__c, OCRVCS_OS_Zone__c, DeliveryNetworkState__c, DeliveryNetworkPostcode__c,
						AttachmentType__c, AttachmentGUID__c, TruckId__c, FacilitySubLocationId__c, FacilitySubLocationName__c,
						Length__c, Height__c, Width__c, Weight__c, Volume__c, Cube__c, Outside_Delivery_Radius__c, Geo_Precision__c,State_Territory_Province__c,EventSource__c 

				FROM
						EventMessage__c
				WHERE Article__c IN :consignmentsAndArticles OR Article__c IN :consArticleIds
				order by ActualDateTime__c DESC
		]) {
			List<EventMessage__c> eList = articleToEventMessages.get(e.Article__c);
			if (eList == null) {
				eList = new List<EventMessage__c>();
			}
			eList.add(e);
			articleToEventMessages.put(e.Article__c, eList);
		}

		// we need to find contacts to link to each article in the search results
		// we use APCN and name/email combinations to identify which contacts to show as linked
		// TODO: Do articles and consignments
		Map<Id, Map<String, Contact>> contactMappings = findMatchingContacts(consignmentsAndArticles);

		for (Article__c a : consignmentsAndArticles) {
			result.trackResults.add(new TIBCOTrackingResultWrapper(a, consignmentToArticles, articleToEventMessages, contactMappings));
		}

		return result;
	}

	/**
	 * Try and match the contacts based on the details returned in the article search results
	 */
	@TestVisible
	private static Map<Id, Map<String, Contact>> findMatchingContacts(List<Article__c> consignmentsAndArticles) {
		// match the sender/receiver details on the articles to actual Contacts in Salesforce if they exist
		// search for both an APCN and details by Name/Email
		Set<String> apcnNumbers = new Set<String>();
		Set<String> nameSet = new Set<String>();
		Set<String> emailSet = new Set<String>();
		Set<String> usedKeys = new Set<String>();
//		String soqlMatchNamesEmails = '';
		for (Article__c a : consignmentsAndArticles) {

			// we search for both apcn and name/email (just incase the APCN is not in SF)
			if(!String.isEmpty(a.Receiver_APCN__c)) {
				apcnNumbers.add(a.Receiver_APCN__c);
			}
			if(!String.isEmpty(a.ReceiverName__c) && !String.isEmpty(a.ReceiverEmail__c) && !usedKeys.contains(a.ReceiverName__c.toLowerCase() + a.ReceiverEmail__c.toLowerCase())) {
//				soqlMatchNamesEmails += (!String.isEmpty(soqlMatchNamesEmails) ? ' OR ' : '') + ' (Name Like \'' + String.escapeSingleQuotes(a.ReceiverName__c) +  '%\' AND Email = \'' + String.escapeSingleQuotes(a.ReceiverEmail__c) + '\') ';
				nameSet.add(a.ReceiverName__c);
				emailSet.add(a.ReceiverEmail__c);

				// store an entry in usedKeys to ensure we are not duplicated our query conditions (this happens if a consignment contains articles with the same manifest details)
				usedKeys.add(a.ReceiverName__c.toLowerCase() + a.ReceiverEmail__c.toLowerCase());
			}

			// we search for both apcn and name/email (just incase the APCN is not in SF)
			if(!String.isEmpty(a.Sender_APCN__c)) {
				apcnNumbers.add(a.Sender_APCN__c);
			}
			if(!String.isEmpty(a.SenderName__c) && !String.isEmpty(a.SenderEmail__c) && !usedKeys.contains(a.SenderName__c.toLowerCase() + a.SenderEmail__c.toLowerCase())) {
//				soqlMatchNamesEmails += (!String.isEmpty(soqlMatchNamesEmails) ? ' OR ' : '') + ' (Name Like \'' + String.escapeSingleQuotes(a.SenderName__c) +  '%\' AND Email = \'' + String.escapeSingleQuotes(a.SenderEmail__c) + '\') ';
				nameSet.add(a.SenderName__c);
				emailSet.add(a.SenderEmail__c);
				// store an entry in usedKeys to ensure we are not duplicated our query conditions (this happens if a consignment contains articles with the same manifest details)
				usedKeys.add(a.SenderName__c.toLowerCase() + a.SenderEmail__c.toLowerCase());
			}
		}

		// based on the search params we have passed in we select all the applicable contacts
		String soql = 'Select Id, Name, Email, APCN__c From Contact Where APCN__c In :apcnNumbers ' + ((nameSet.size()>0) ? ' OR Name IN :nameSet' : '') + ((emailSet.size()>0) ? ' OR Email IN :emailSet' : '') + ' Order by Email, CRMCSSOID__c Nulls Last, APCN__c Nulls Last, CreatedDate';
		List<Contact> contacts = Database.query(soql);

		Map<String, Contact> apcnContactMappings = new Map<String, Contact>();
		Map<String, Contact> nameEmailContactMappings = new Map<String, Contact>();

		// map the name/email back to a contact for easy comparison
		for(Contact contact : contacts) {
			// map the apcn numbers back to a contact  for easy comparison
			if(!String.isEmpty(contact.APCN__c)) {
				apcnContactMappings.put(contact.APCN__c, contact);
			}
			if(!String.isEmpty(contact.Name) && !String.isEmpty(contact.Email)) {
				if(usedKeys.contains(contact.Name.toLowerCase() + contact.Email.toLowerCase())) {
					// if a contact has already been found for the name/email combination then we do not overwrite it
					if (nameEmailContactMappings.get(contact.Name.toLowerCase() + contact.Email.toLowerCase()) != null)
						continue;

					nameEmailContactMappings.put(contact.Name.toLowerCase() + contact.Email.toLowerCase(), contact);
				}
			}
		}
		Map<Id, Map<String, Contact>> output = new Map<Id, Map<String, Contact>>();
		for (Article__c a : consignmentsAndArticles) {
			// we search for both apcn and name/email (just incase the APCN is not in SF)
			if(!String.isEmpty(a.Receiver_APCN__c) && apcnContactMappings.containsKey(a.Receiver_APCN__c)) {
				if(output.get(a.Id) == null) output.put(a.Id, new Map<String, Contact>());
				output.get(a.Id).put('receiver', apcnContactMappings.get(a.Receiver_APCN__c));
			} else if(!String.isEmpty(a.ReceiverName__c) && !String.isEmpty(a.ReceiverEmail__c)) {
				if(nameEmailContactMappings.containsKey(a.ReceiverName__c.toLowerCase() + a.ReceiverEmail__c.toLowerCase())) {
					if(output.get(a.Id) == null) output.put(a.Id, new Map<String, Contact>());
					output.get(a.Id).put('receiver', nameEmailContactMappings.get(a.ReceiverName__c.toLowerCase() + a.ReceiverEmail__c.toLowerCase()));
				}
			}

			// we search for both apcn and name/email (just incase the APCN is not in SF)
			if(!String.isEmpty(a.Sender_APCN__c) && apcnContactMappings.containsKey(a.Sender_APCN__c)) {
				if(output.get(a.Id) == null) output.put(a.Id, new Map<String, Contact>());
				output.get(a.Id).put('sender', apcnContactMappings.get(a.Sender_APCN__c));
			} else if(!String.isEmpty(a.SenderName__c) && !String.isEmpty(a.SenderEmail__c)) {
				if(nameEmailContactMappings.containsKey(a.SenderName__c.toLowerCase() + a.SenderEmail__c.toLowerCase())) {
					if(output.get(a.Id) == null) output.put(a.Id, new Map<String, Contact>());
					output.get(a.Id).put('sender', nameEmailContactMappings.get(a.SenderName__c.toLowerCase() + a.SenderEmail__c.toLowerCase()));
				}
			}
		}

		return output;
	}

	/**
	 * Grab a list of all the transients which we mapped but did not persist in Salesforce.
	 * TODO: This is a workaround since the current sarch method resets the TIBCOSearchResult result variable when it requeries the data in Salesforce after it's been populated from SAP
	 *          The search process should be refactored to negate the need for this workaround which could marginally cause a small performance impact
	 */
	private static Map<String, Map<Id, Object>> getTransientAttributesFromResult(TIBCOSearchResult result) {
		Map<String, Map<Id, Object>> output = new Map<String, Map<Id, Object>>{
				'articleTransients' => new Map<Id, Object>(),
				'eventMessageTransients' => new Map<Id, Object>()
		};

		for(TIBCOTrackingResultWrapper resultWrapper : result.trackResults) {
			if(resultWrapper.articleDetails != null) {
				output.get('articleTransients').put(resultWrapper.articleDetails.proxyArticle.Id, resultWrapper.articleDetails.transientAttributes);

				for(TIBCOEventMessageWrapper eventMessage : resultWrapper.articleDetails.eventMessages) {
					output.get('eventMessageTransients').put(eventMessage.proxyEM.Id, eventMessage.transientAttributes);
				}
			} else if(resultWrapper.consignmentDetails != null) {
				//NOTE: Consignment transient attributes are currently not implement
				//          When there is a use case, this can can be uncommented and the implementation can be finished
				//          An update to TIBCOConsignmentWrapper will also be required
				//output.get('articleTransients').put(resultWrapper.consignmentDetails.proxyConsignment.Id, resultWrapper.consignmentDetails.transientAttributes);

				for(TIBCOEventMessageWrapper eventMessage : resultWrapper.consignmentDetails.eventMessages) {
					output.get('eventMessageTransients').put(eventMessage.proxyEM.Id, eventMessage.transientAttributes);
				}
			}
		}

		return output;
	}

	/**
	 * Merge the list of transients back into the result set after it has been rebuild using the SearchInSFDC method
	 * TODO: This is only necessary since the result object is reset after querying data in SAP. The whole search process should be reviewed and refactored to not require such extensive rebuilding and merging
	 * @param result NOTE: This is mutated!
	 */
	private static void mergeTransientsIntoResult(TIBCOSearchResult result, Map<String, Map<Id, Object>> transients) {

		for(TIBCOTrackingResultWrapper resultWrapper : result.trackResults) {
			if (resultWrapper.articleDetails != null) {
				if(transients.get('articleTransients')?.get(resultWrapper.articleDetails.proxyArticle.Id) != null) {
					resultWrapper.articleDetails.transientAttributes = (TIBCOArticleWrapper.ArticleTransientAttributes)transients.get('articleTransients').get(resultWrapper.articleDetails.proxyArticle.Id);
				}

				for (TIBCOEventMessageWrapper eventMessage : resultWrapper.articleDetails.eventMessages) {
					if(transients.get('eventMessageTransients')?.get(eventMessage.proxyEM.Id) != null) {
						eventMessage.transientAttributes = (TIBCOEventMessageWrapper.EventTransientAttributes)transients.get('eventMessageTransients').get(eventMessage.proxyEM.Id);
					}
				}
			} else if (resultWrapper.consignmentDetails != null) {
				//NOTE: Consignment transient attributes are currently not implement
				//          When there is a use case, this can can be uncommented and the implementation can be finished
				//          An update to TIBCOConsignmentWrapper will also be required
				//	if(transients.get('articleTransients')?.get(resultWrapper.consignmentDetails.proxyConsignment.Id) != null) {
				//		resultWrapper.consignmentDetails.transientAttributes = (TIBCOConsignmentWrapper.ConsignmentTransientAttributes)transients.get('articleTransients').get(resultWrapper.consignmentDetails.proxyConsignment.Id);
				//	}

				for (TIBCOEventMessageWrapper eventMessage : resultWrapper.consignmentDetails.eventMessages) {
					if(transients.get('eventMessageTransients')?.get(eventMessage.proxyEM.Id) != null) {
						eventMessage.transientAttributes = (TIBCOEventMessageWrapper.EventTransientAttributes)transients.get('eventMessageTransients').get(eventMessage.proxyEM.Id);
					}
				}
			}
		}
	}	

	/*
	@Obsolete
	NOTE: please use TIBCOArticleService.getInstance().searchByArticleIdsInSAP(articleIdsInbound) instead.
	*/
	public static TIBCOSearchResult searchArticlesInSAP(String[] articleIdsInbound) {
		return TIBCOArticleService.getInstance().searchByArticleIdsInSAP(articleIdsInbound);
	}

	// moved to local method for better mocking
	public TIBCOSearchResult searchByArticleIdsInSAP(List<String> articleIdsInbound) {
		List<String> articleIds = new List<String>();

		for (String aID : articleIdsInbound) {
			if (!String.isBlank(aID)) {
				articleIds.add(aID);
			}
		}

		TIBCOSearchResult result = new TIBCOSearchResult();

		if (articleIds.isEmpty()) {
			return result;
		}

		AuspostTrackEventService.EventManagement_v1Endpoint1 service = new AuspostTrackEventService.EventManagement_v1Endpoint1();
		service.endpoint_x = TIBCO_ENDPOINT;
		//service.endpoint_x = 'http://webapi-ptestext.npe.auspost.com.au/PTEST/Services/TransportAndLogisticsServices/EventManagement_v1';
		// https://salesforce-bw.auspost.com.au:10542/Services/TransportAndLogisticsServices/EventManagement_v1
		//service.timeout_x = 2*60*1000;
		service.timeout_x = Integer.valueOf(Label.TIBCO_TIME_OUT_VAL);  // Nandan : changed to configure Timeout settings for P2 issue
		service.Header = new AuspostCommonSchema.InterfaceHeader();
		service.Header.InterfaceName = 'queryArticle';
		service.Header.InterfaceVersion = '1.0';
		service.Header.MessageType = 'Request';
		service.Header.BusinessReferenceID = articleIds[0];
		service.Header.SourceSystemID = 'SFDC';
		service.Header.SourceInformation = '';
		service.Header.Timestamp = System.now();

		try {
			System.debug('---Before sending request');
			System.debug('---Headers' + service.Header);
			AuspostQueryTrackEventsSchema.TrackingResults_element trackResults = service.queryTrackEvents_v1(articleIds, 'NAMED_USER');
			System.debug('---After sending request' + trackResults);
			System.debug('>>>> response: ' + json.serialize(trackResults));

			for (AuspostQueryTrackEventsSchema.TrackingResults tr : trackResults.TrackingResult) {
				result.trackResults.add(new TIBCOTrackingResultWrapper(tr));
			}
		} catch (Exception e) {
			result.success = false;
			result.errors.add(e.getMessage());
		}

		return result;
	}

	private static Boolean foundArticle(TIBCOSearchResult result) {
		if (!result.success || result.trackResults.size() <= 0) {
			return false;
		}

		for (TIBCOTrackingResultWrapper tr : result.trackResults) {
			if (tr.articleDetails != null || tr.consignmentDetails != null) {
				return true;
			}
		}
		return false;
	}
}