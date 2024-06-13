/**
 * Controller class for generating the Sade Drop / Signature PDF file (for attaching to the case)
 * NOTE: This assumes that the article has already been queried and cached locally in Salesforce
 *
 * @author Nathan Franklin
 * @date 2021-10-01
 * @changelog
 * 2021-11-09 - Nathan Franklin - Fixed bug with articles with multiple delivered scan events
 * 2024-05-31 - Seth Heang - Bulkify the Proof Of Delivery PDF generation to handle multiple deliveryEvents and generate multiple PDF pages
 **/
public with sharing class MyCustomerDeliveryProofPdfController {
	// Causes an error to be displayed on the page and will prevent the rendering of anything else
	public static String pageError { get; set; }

	public String articleId { get; set; }
	public static List<DeliveryProofAttributes> deliveryProofAttributes { get; set; }
	public static transient Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitions;
	public static Boolean isConsignment;

	/**
	 * @description	On VF page launch, it will build up a delivery proof result object and populate all necessary attributes for VF PDF display
	 */
	public MyCustomerDeliveryProofPdfController() {
		articleId = ApexPages.currentPage().getParameters().get('articleId');
		if (String.isEmpty(articleId)) {
			pageError = 'Tracking number is invalid';
		}
		eventTypeDefinitions = EventMessageUtil.getInstance().getEventMessageTypeDefinitions();
		// get consignment and child articles data
		List<Article__c> consignments = queryConsignmentByTrackingId(articleId);
		// build event message data into delivery proof result list
		deliveryProofAttributes = buildAttributesForPDFDisplay(getArticleIdsFromArticles(consignments));
		// enrich delivery proof result list with all relevent attributes
		deliveryProofAttributes = updateConsignedAndDeliveredArticleCount(deliveryProofAttributes, consignments);
		deliveryProofAttributes = updateTotalArticlesPerDeliveryEvent(deliveryProofAttributes);
		deliveryProofAttributes = formatFurtherReferencesFieldValueForDisplay(deliveryProofAttributes);
		deliveryProofAttributes = filterDeliveryEventsByArticleIdORConsignmentIdSearch(deliveryProofAttributes);
		deliveryProofAttributes = updateLastPageAttributeForPDFDisplay(deliveryProofAttributes);
	}

	/**
	 * @description	Update a flag to indicate if the delivery result is the last element so that the VF PDF page can correctly setup the page-break for the last page of PDF
	 * @param deliveryProofAttributes List<DeliveryProofAttributes>
	 * @return List<DeliveryProofAttributes>
	 */
	public List<DeliveryProofAttributes> updateLastPageAttributeForPDFDisplay(List<DeliveryProofAttributes> deliveryProofAttributes) {
		// Pass by reference set isLastPage to TRUE for many elements in the list, thus switch to Pass by Value instead so that only the last element has isLastPage set to TRUE
		DeliveryProofAttributes lastPOD = deliveryProofAttributes[deliveryProofAttributes.size() - 1].clone();
		lastPOD.isLastPage = true;
		deliveryProofAttributes[deliveryProofAttributes.size() - 1] = lastPOD;
		return deliveryProofAttributes;
	}

	/**
	 * @description	Filter the delivery result to remove unrelated articles from different unique delivery event if the article tracking number is provided
	 * 				If the consignment tracking number is provided, then don't filter anything.
	 * @param deliveryProofAttributes List<DeliveryProofAttributes>
	 * @return List<DeliveryProofAttributes>
	 */
	public List<DeliveryProofAttributes> filterDeliveryEventsByArticleIdORConsignmentIdSearch(List<DeliveryProofAttributes> deliveryProofAttributes) {
		if (isConsignment) {
			return deliveryProofAttributes;
		}
		// Get a unique delivery key from the article if the Proof of Delivery PDF generation is at article level
		String deliveryKeyEvent;
		for (DeliveryProofAttributes pod : deliveryProofAttributes) {
			if (pod.eventMessage.Article__r.ArticleID__c.equals(articleId)) {
				deliveryKeyEvent = pod.deliveryKey;
			}
			break;
		}
		// Keep only delivery result where the unique delivery key is matched and filter out the rest
		List<DeliveryProofAttributes> filterDeliveryResult = new List<DeliveryProofAttributes>();
		for (DeliveryProofAttributes pod : deliveryProofAttributes) {
			if (pod.deliveryKey.equals(deliveryKeyEvent)) {
				filterDeliveryResult.add(pod);
			}
		}
		return filterDeliveryResult;
	}

	/**
	 * @description	Validate if the tracking number belongs to a consignment tracking number
	 * @param	articles List<Article__c>
	 * @return Boolean
	 */
	public static Boolean isNotConsignmentTrackingID(List<Article__c> articles) {
		return articles.size() == 1 && articles.get(0).recordType.DeveloperName == 'Article' && articles.get(0).ConsignmentTrackingNumber__c != null ? true : false;
	}

	/**
	 * @description	Determine the number of consigned and delivered articles and update the delivery results to be used by the VF PDF Page
	 * @param podAttributes List<DeliveryProofAttributes>
	 * @param consignments List<Article__c>
	 * @return List<DeliveryProofAttributes>
	 */
	public List<DeliveryProofAttributes> updateConsignedAndDeliveredArticleCount(List<DeliveryProofAttributes> podAttributes, List<Article__c> consignments) {
		Integer latestConsignedArticleCount = calculateConsignedArticleCount(consignments);
		Integer latestDeliveredArticleCount = calculateDeliveredArticleCount(consignments);
		for (DeliveryProofAttributes pod : podAttributes) {
			pod.consigned = latestConsignedArticleCount;
			pod.delivered = latestDeliveredArticleCount;
		}
		return podAttributes;
	}

	/**
	 * @description	Determine the total articles count and compile the article tracking number into a list, and udpatethe delivery results to be used by VF PDF Page
	 * @param podAttributes List<DeliveryProofAttributes>
	 * @return List<DeliveryProofAttributes>
	 */
	public List<DeliveryProofAttributes> updateTotalArticlesPerDeliveryEvent(List<DeliveryProofAttributes> podAttributes) {
		Map<String, List<String>> deliveryKeyToArticles = new Map<String, List<String>>();
		// Compile a list of article and map under common a unique delivery event key
		for (DeliveryProofAttributes pod : podAttributes) {
			if (deliveryKeyToArticles.get(pod.deliveryKey) == null) {
				deliveryKeyToArticles.put(pod.deliveryKey, new List<String>{ pod.eventMessage.Article__r.ArticleID__c });
			} else {
				List<String> articleList = deliveryKeyToArticles.get(pod.deliveryKey);
				articleList.add(pod.eventMessage.Article__r.ArticleID__c);
				deliveryKeyToArticles.put(pod.deliveryKey, articleList);
			}
		}
		// prepare article lists and article count attribute for the VF PDF Page display
		for (DeliveryProofAttributes pod : podAttributes) {
			pod.articlesInDeliveryEvent = String.join(deliveryKeyToArticles.get(pod.deliveryKey), ', ');
			pod.articlesCountInDeliveryEvent = deliveryKeyToArticles.get(pod.deliveryKey).size();
		}
		return podAttributes;
	}

	/**
	 * @description	Determine the number of consigned articles from a list of articles.
	 * @param articles List<Article__c>
	 * @return Integer
	 */
	public Integer calculateConsignedArticleCount(List<Article__c> articles) {
		Integer consignedCount = 0;
		for (Article__c article : articles) {
			if (article.RecordType.Name == 'Article') {
				// make sure the consignment isn't counted
				consignedCount++;
			}
		}
		return consignedCount;
	}

	/**
	 * @description	Determine the number of successfully delivered article from a list of articles
	 * @param articles List<Article__c>
	 * @return Integer
	 */
	public Integer calculateDeliveredArticleCount(List<Article__c> articles) {
		Integer totalDelivered = 0;
		for (Article__c article : articles) {
			if (article.IsDelivered__c) {
				totalDelivered++;
			}
		}
		return totalDelivered;
	}

	/**
	 * @description	Retrieve article tracking number from a list of Articles and save as a set of string
	 * @param articles List<Article__c>
	 * @return Set<String>
	 */
	public static Set<String> getArticleIdsFromArticles(List<Article__c> articles) {
		Set<String> articleIdsStr = new Set<String>();
		for (Article__c article : articles) {
			articleIdsStr.add(article.ArticleID__c.toString());
		}
		return articleIdsStr;
	}

	/**
	 * @description	This method format the further references with line break for better UI display in the VF PDF page
	 * 				It also map the further reference from parent consignment down one level to article level for the purpose of VF PDG page.
	 * 				This is due to FieldSet's limitation where it cannot traverse up two levels from EventMessage->Article->Consignment
	 * @param podAttributes List<DeliveryProofAttributes>
	 * @return List<DeliveryProofAttributes>
	 */
	public List<DeliveryProofAttributes> formatFurtherReferencesFieldValueForDisplay(List<DeliveryProofAttributes> podAttributes) {
		for (DeliveryProofAttributes pod : podAttributes) {
			// bring it up one level, as the fieldSet only allow one-level traverse on its related object
			pod.eventMessage.Article__r.FurtherReferences__c = '\n' + pod.eventMessage.Article__r?.Consignment__r?.FurtherReferences__c?.replace(', ', '\n');
		}
		return podAttributes;
	}

	/**
	 * @description	Retrieve a snapshot of the current state of SafeDrop image file per article under the parent consignment if they exist in Salesforce
	 * 				Or, it's required to be downloaded. This is method is called, prior to retrieving SafeDrop image in bulk by happyParcelDeliveryProof LWC via multiple transactions
	 * 				or one image per transaction. This is down to bypass the hard limit of 3 Max Continuation Callout per Single Transaction in Salesforce.
	 * @return	List<SafeDropImageState> e.g. SafeDropImageState in JSON: ([{guidID: "guidId123456", requireDownload: true}])
	 */
	@AuraEnabled(Cacheable=false)
	public static List<SafeDropImageState> getCurrentStateOfSafeDropImageRequiredForDownload(String trackingId) {
		List<Article__c> consignments = queryConsignmentByTrackingId(trackingId);
		List<DeliveryProofAttributes> deliveryEventKeyList = buildAttributesForPDFDisplay(getArticleIdsFromArticles(consignments));
		// Build a list of State object with the latest State of SafeDrop image cache in Salesforce for the entire consignment set
		List<SafeDropImageState> safeDropImageStates = new List<SafeDropImageState>();
		for (DeliveryProofAttributes dpAttr : deliveryEventKeyList) {
			SafeDropImageState state = new SafeDropImageState();
			String guidID = dpAttr.eventMessage?.Safe_Drop_GUID__c;
			if (!String.isBlank(guidID)) {
				state.eventMessageId = dpAttr.eventMessage.Id;
				state.guidID = guidID;
				state.requireDownload = dpAttr.requiredSafeDropCallout != null ? dpAttr.requiredSafeDropCallout : false;
				safeDropImageStates.add(state);
			}
		}
		return safeDropImageStates;
	}

	/**
	 * @description	This method will query consignment records and related child articles regardless if passed in tracking Id belongs to an article or consignment
	 * @param	trackingId can be either an article number or consignment number
	 * @return	List<Article__c>
	 */
	public static List<Article__c> queryConsignmentByTrackingId(String trackingId) {
		List<Article__c> consignments = ArticlesSelector.newInstance()
			.selectByIdOrTracking(new Set<String>{ trackingId }, new Set<Id>(), new Set<Object>{ ArticlesSelector.Options.WITH_CONSIGNMENT, ArticlesSelector.Options.WITH_RECORDTYPE }, true)
			.values();
		Boolean requireConsignmentQuery = isNotConsignmentTrackingID(consignments);
		isConsignment = !requireConsignmentQuery;
		if (requireConsignmentQuery) {
			consignments = ArticlesSelector.newInstance()
				.selectByIdOrTracking(
					new Set<String>{ consignments.get(0).ConsignmentTrackingNumber__c },
					new Set<Id>(),
					new Set<Object>{ ArticlesSelector.Options.WITH_CONSIGNMENT, ArticlesSelector.Options.WITH_RECORDTYPE },
					true
				)
				.values();
		}
		return consignments;
	}

	/**
	 * @description	Build the delivery result wrapper attributes to be used for VF Page display
	 * @param	articleIds Set<String>
	 * @return	List<DeliveryProofAttributes> - each wrapper will generate exactly one VF Page
	 */
	public static List<DeliveryProofAttributes> buildAttributesForPDFDisplay(Set<String> articleIds) {
		eventTypeDefinitions = EventMessageUtil.getInstance().getEventMessageTypeDefinitions();
		List<DeliveryProofAttributes> podAttributes = new List<DeliveryProofAttributes>();
		// note the order is determined by the selector configuration
		Set<Object> selectorOptions = new Set<Object>{
			EventMessagesSelector.Options.WITH_SIGNATURE_FIELD,
			EventMessagesSelector.Options.WITH_ATTACHMENT,
			EventMessagesSelector.Options.WITH_ARTICLE,
			ArticlesSelector.Options.WITH_CONSIGNMENT
		};

		List<EventMessage__c> eventMessages = EventMessagesSelector.newInstance().selectByArticleNumber(articleIds, selectorOptions);
		Map<String, List<DeliveryProofAttributes>> deliveryEventKeyMap = buildDeliveryEventKeyMapFromValidEventMessages(eventMessages);

		// validate if there is no valid event message with safedrop/signature scan event
		if (deliveryEventKeyMap.size() == 0) {
			pageError = 'Tracking number is not associated to any safe drop or signature scan event';
			return null;
		}

		for (String deliveryKey : deliveryEventKeyMap.keySet()) {
			for (DeliveryProofAttributes pod : deliveryEventKeyMap.get(deliveryKey)) {
				EventMessage__c eventMessage = pod.eventMessage;
				DeliveryProofAttributes attributes = new DeliveryProofAttributes();
				attributes.isStarTrackProduct = validateIfProductIsStarTrack(eventMessage);

				Boolean isSignature = getSignatureFlagFromEventMessageTypeMapping(eventTypeDefinitions, eventMessage);
				Boolean isSafeDrop = getSafeDropFlagFromEventMessageTypeMapping(eventTypeDefinitions, eventMessage);

				if (eventMessage.Attachments != null) {
					for (Attachment att : eventMessage.Attachments) {
						if (att.Name.startsWith('Signature')) {
							attributes.signatureAttachmentId = att.Id;
						}
						if (att.Name.startsWith(SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME)) {
							attributes.safeDropAttachmentId = att.Id;
						}
					}
				}

				if (isSafeDrop && attributes.safeDropAttachmentId == null) {
					// article has a safe drop image to be retrieved and displayed
					// make a call out to retrieve the safe drop image

					// NOTE: this is at the conclusion of the continuation
					// NOTE: eventMessage.Safe_Drop_GUID__c should never be null because of the check above
					attributes.requiredSafeDropCallout = true; // LWC will subsequently retrieve safe drop image based on this flag
				}
				if (!isSafeDrop && (!isSignature || (isSignature && attributes.signatureAttachmentId == null))) {
					// there is an assumption that the signature is already there, no need for callout. Except SafeDrop.
					pageError = 'Tracking number is not associated to any safe drop or signature scan event';
					break;
				}
				attributes.eventMessage = eventMessage;
				attributes.deliveryKey = deliveryKey;
				podAttributes.add(attributes);
			}
		}
		return podAttributes;
	}

	/**
	 * @description	Use the API to pull back the filtered out image. The API blacks out faces and text on the images.
	 * @param	guidId String
	 * @param	eventMessageId String
	 * @return	Object
	 */
	@AuraEnabled(Continuation=true)
	public static Object getSafeDropImage(String guidId, String eventMessageId) {
		SafeDropUtility utility = SafeDropUtility.getInstance();
		HttpRequest req = utility.getHttpRequest(guidId);
		if (req == null) {
			pageError = 'Could not generate Safe Drop request';
			throw new AuraHandledException('Failed to download the image.');
		}
		Continuation con = new Continuation(60);
		con.addHttpRequest(req);
		con.continuationMethod = 'safeDropImageCallback';

		// Set the state and pass to the callback method
		Map<String, String> state = new Map<String, String>();
		state.put('guidId', guidId);
		state.put('eventMessageId', eventMessageId);
		con.state = state;

		return con;
	}

	/**
	 * @description	This is the callback for the async callout for retrieving the safe drop image.
	 * @param	labels List<String>
	 * @param	state Object - state passed from the continuation request method(getSafeDropImage)
	 * @return	Object
	 */
	@AuraEnabled
	public static Object safeDropImageCallback(List<String> labels, Object state) {
		// Retrieve the state
		Map<String, String> stateMap = (Map<String, String>) state;
		String eventMessageId = stateMap.get('eventMessageId');

		HttpResponse resp = Continuation.getResponse(labels[0]);

		String responseBody = resp.getBody();

		// parse the json
		SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

		if (response.isError) {
			pageError = response.errorMessage;
			throw new AuraHandledException('Failed to download the image.');
		} else {
			// NOTE: That in order to render a PDF image, it needs to be saved as an attachment since the Salesforce PDF renderer does not current support rendering images using data uri's.... awkward
			SafeDropUtility.getInstance().attachSafeDropToRecord(eventMessageId, EncodingUtil.base64Decode(response.imageBody));
		}
		return response;
	}

	/**
	 * @description	Transient attributes Wrapper that aren't stored in Salesforce but is required to be used for the VF page display
	 */
	public class DeliveryProofAttributes {
		public Integer consigned { get; set; }
		public Integer delivered { get; set; }
		public Boolean isStarTrackProduct { get; set; }
		public String articlesInDeliveryEvent { get; set; }
		public Integer articlesCountInDeliveryEvent { get; set; }
		public Id safeDropAttachmentId { get; set; }
		public Id signatureAttachmentId { get; set; }
		public String deliveryKey;
		public EventMessage__c eventMessage { get; set; } // Retrieve the specific event message for either the safe drop or signature image including Article & Consignment related object
		public Boolean requiredSafeDropCallout;
		public Boolean isLastPage { get; set; }
	}

	/**
	 * @description Build a map where key is a unique delivery event key and map to a valid list of delivery result
	 * 				Only valid EventMessage which contains a Signature or SafeDrop image is added to the delivery result.
	 * @param eventMessages List<EventMessage__c> All event messages that are associated to any article in the entire consignment set
	 * @return Map<String, List<DeliveryProofAttributes>>
	 */
	public static Map<String, List<DeliveryProofAttributes>> buildDeliveryEventKeyMapFromValidEventMessages(List<EventMessage__c> eventMessages) {
		Map<String, List<DeliveryProofAttributes>> deliveryEventKeyMap = new Map<String, List<DeliveryProofAttributes>>();
		eventTypeDefinitions = EventMessageUtil.getInstance().getEventMessageTypeDefinitions();
		// Make sure we only deal with eventmessages that are designated
		// this loops from oldest to newest
		for (EventMessage__c message : eventMessages) {
			Boolean hasSignature = getSignatureFlagFromEventMessageTypeMapping(eventTypeDefinitions, message);
			Boolean hasSafeDrop = getSafeDropFlagFromEventMessageTypeMapping(eventTypeDefinitions, message);
			if (hasSignature || hasSafeDrop) {
				// build a key to identify a unique delivery event key when a driver made a successful delivery
				String uniqueDeliveryEventKey = message.Article__r.ConsignmentTrackingNumber__c + ':' + message.ActualDateTime__c.toString();
				DeliveryProofAttributes pdfAttr = new DeliveryProofAttributes();
				pdfAttr.eventMessage = message;
				if (deliveryEventKeyMap.get(uniqueDeliveryEventKey) == null) {
					deliveryEventKeyMap.put(uniqueDeliveryEventKey, new List<DeliveryProofAttributes>{ pdfAttr });
				} else {
					deliveryEventKeyMap.get(uniqueDeliveryEventKey).add(pdfAttr);
				}
			}
		}
		return deliveryEventKeyMap;
	}

	/**
	 * @description	Validate if the product Id from EventMessage's Article belongs to StarTrack Product Range
	 * @param 		TIBCOArticleWrapper article
	 * @return 		Boolean
	 */
	private static Boolean validateIfProductIsStarTrack(EventMessage__c eventMessage) {
		//return true;
		return StarTrack_Constants.startrackProdIDs.containsKey(eventMessage.Article__r.ProductID__c);
	}

	/**
	 * @description Validate if the signature flag is true based on the EventType mapping from the custom metadata
	 * @param eventTypeDefinitions Map<String, EventMessageTypeMapping__mdt>
	 * @param eventMsg EventMessage__c
	 * @return Boolean
	 */
	public static Boolean getSignatureFlagFromEventMessageTypeMapping(Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitions, EventMessage__c eventMsg) {
		return (eventTypeDefinitions.get(eventMsg.EventType__c)?.IsSignatureOnDelivery__c == true && !String.isEmpty(eventMsg?.SignatureXString__c));
	}

	/**
	 * @description Validate if the safe drop flag is true based on the EventType mapping from the custom metadata
	 * @param eventTypeDefinitions Map<String, EventMessageTypeMapping__mdt>
	 * @param eventMsg EventMessage__c
	 * @return Boolean
	 */
	public static Boolean getSafeDropFlagFromEventMessageTypeMapping(Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitions, EventMessage__c eventMsg) {
		return (eventTypeDefinitions.get(eventMsg.EventType__c)?.IsSafeDrop__c == true && !String.isEmpty(eventMsg?.Safe_Drop_GUID__c));
	}

	/**
	 * @description State object used to keep track of the SafeDrop image state if it already exists in Salesforce
	 * 				Or, it may require an async callout to retrieve a new SafeDrop Image and store in Salesforce
	 */
	public class SafeDropImageState {
		@AuraEnabled
		public String guidID;
		@AuraEnabled
		public Boolean requireDownload; //indicate if the SafeDrop Image does not exist in SF, and require a download
		@AuraEnabled
		public Id eventMessageId;
	}
}