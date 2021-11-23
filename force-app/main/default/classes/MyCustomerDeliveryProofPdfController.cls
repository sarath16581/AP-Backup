/**
 * Controller class for generating the Sade Drop / Singature PDF file (for attaching to the case)
 * NOTE: This assumes that the article has already been queried and cached locally in Salesforce
 *
 * @author Nathan Franklin
 * @date 2021-10-01
 * @changelog
 * 2021-11-09 - Nathan Franklin - Fixed bug with articles with multiple delivered scan events
**/
public with sharing class MyCustomerDeliveryProofPdfController {

	// Causes an error to be displayed on the page and will prevent the rendering of anything else
	public String pageError { get; set; }

	public String articleId { get; set; }

	// Stores the continuation label
	private String safeDropRequestLabel;

	/**
	 * Attachment id's associated to the event message being rendered from
	 */
	public transient Id safeDropAttachmentId { get; set; }
	public transient Id signatureAttachmentId { get; set; }

	/**
	 * Retrieve the specific event message for either the safe drop or signature image
	 * We do this as a separate request so we can include Article & Consignment related object (without needing to select the data for all event messages)
	 */
	public EventMessage__c eventMessage { get; set; }

	public MyCustomerDeliveryProofPdfController() {
		articleId = ApexPages.currentPage().getParameters().get('articleId');

		if (String.isEmpty(articleId)) {
			pageError = 'Tracking number is invalid';
		}
	}

	/**
	 * The visualforce startup action to retrieve either the signature or the safe drop image
	 * NOTE: the object return which will mimic a PageReference however it will always return null (even in the continuation response)
	 */
	public Object getSafeDropOrSignature() {
		Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitions = EventMessageUtil.getInstance().getEventMessageTypeDefinitions();

		// note the order is determined by the selector configuration
		List<EventMessage__c> eventMessages = EventMessagesSelector.newInstance().selectByArticleNumber(new Set<String>{
				articleId
		}, new Set<Object>{
				EventMessagesSelector.Options.WITH_SIGNATURE_FIELD
		});

		EventMessage__c deliveryProofEventMessage = null;

		Boolean isSafeDrop = false;
		Boolean isSignature = false;

		// Make sure we only deal with eventmessages that are designated
		// this loops from oldest to newest
		for (EventMessage__c message : eventMessages) {
			// note the == true is needed with ?
			// NOTE: This is a little bit dodgy that we only support 1 eventmessage but it lines up with existing capability that would impact users if changed
			Boolean hasSignature = (eventTypeDefinitions.get(message.EventType__c)?.IsSignatureOnDelivery__c == true && !String.isEmpty(message.SignatureXString__c));
			Boolean hasSafeDrop = (eventTypeDefinitions.get(message.EventType__c)?.IsSafeDrop__c == true && !String.isEmpty(message.Safe_Drop_GUID__c));

			if (hasSignature || hasSafeDrop) {

				// reset our vars since this is a different delivered event message from before
				isSignature = hasSignature;
				isSafeDrop = hasSafeDrop;

				// set the delivered scan event as the one with the delivery proof
				deliveryProofEventMessage = message;
			}
		}

		if (deliveryProofEventMessage != null) {
			// enrich the individual eventMessage with Article__r and COnsignment__r details and the existing attachments associated to the event message
			Set<Object> selectorOptions = new Set<Object>{
					EventMessagesSelector.Options.WITH_SIGNATURE_FIELD, EventMessagesSelector.Options.WITH_ATTACHMENT, EventMessagesSelector.Options.WITH_ARTICLE, ArticlesSelector.Options.WITH_CONSIGNMENT
			};
			eventMessage = EventMessagesSelector.newInstance().selectById(new Set<Id>{
					deliveryProofEventMessage.Id
			}, selectorOptions).values()[0];

			if (eventMessage.Attachments != null) {
				for (Attachment att : eventMessage.Attachments) {
					if (att.Name.startsWith('Signature')) {
						signatureAttachmentId = att.Id;
					}

					if (att.Name.startsWith(SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME)) {
						safeDropAttachmentId = att.Id;
					}
				}
			}

			if (isSafeDrop && safeDropAttachmentId == null) {
				// article has a safe drop image to be retrieved and displayed
				// make a call out to retrieve the safe drop image

				// NOTE: this  at the conclusion of the continuation
				// NOTE: eventMessage.Safe_Drop_GUID__c should never be null because of the check above
				return getSafeDropImage(eventMessage.Safe_Drop_GUID__c);
			}

		}

		if (!isSafeDrop && (!isSignature || (isSignature && signatureAttachmentId == null))) {
			pageError = 'Tracking number is not associated to any safe drop or signature scan event';
		}

		return null;
	}

	/**
	 * Use the API to pull back the filtered out image.
	 * The API blacks out faces and text.
	 */
	public Object getSafeDropImage(String guidId) {

		SafeDropUtility utility = SafeDropUtility.getInstance();
		HttpRequest req = utility.getHttpRequest(guidId);
		if (req == null) {
			pageError = 'Could not generate Safe Drop request';
		}

		// Create a Continuation for the HTTPRequest
		// This is used for async requests
		Continuation con = new Continuation(60);
		safeDropRequestLabel = con.addHttpRequest(req);
		con.continuationMethod = 'safeDropImageCallback';

		// Return it to the system for processing
		return con;
	}

	/**
	 * This is the callback for the async callout for retrieving the safe drop image.
	 */
	public Object safeDropImageCallback() {
		HttpResponse resp = Continuation.getResponse(safeDropRequestLabel);

		String responseBody = resp.getBody();
		System.debug('SAFE-DROP API RAW REPONSE: ' + responseBody);

		// parse the json
		SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);
		System.debug('SAFE-DROP API PARSED REPONSE: ' + response);

		if (response.isError) {
			pageError = response.errorMessage;
		} else {
			// NOTE: That in order to render a PDF image, it needs to be saved as an attachment since the Salesforce PDF renderer does not current support rendering images using data uri's.... awkward
			safeDropAttachmentId = SafeDropUtility.getInstance().attachSafeDropToRecord(eventMessage.Id, EncodingUtil.base64Decode(response.imageBody)).Id;
		}

		return null;
	}
}