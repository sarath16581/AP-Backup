/**
 * A common class for handling delivery proof capability
 *
 * @author Nathan Franklin
 * @date 2021-10-10
 * @changelog
 * prerna.rahangdale 12/09/2022  a new method to get the safedrop for the article tracking number.
 *
 */
public inherited sharing class DeliveryProofService {

	public static final String DELIVERY_PROOF_CASE_FILENAME = 'DeliveryProof.pdf';

	/**
	 * Grabs an instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static DeliveryProofService getInstance() {
		return (DeliveryProofService)Application.Utilities.getInstance(DeliveryProofService.class);
	}

	/**
	 * Attach AP delivery proof PDF to an AP CCC case.
	 * This capability will process the article on each case and extract the signature or safe drop and render then to a PDF which will be attached to a case record
	 */
	public void enqueueAttachAPDeliveryProof(Set<Id> caseIds) {
		// attach the pdf delivery proof to the case in an async process
		System.enqueueJob(new AttachAPDeliveryProofPdfQueueable(caseIds));
	}

	/**
	 * Attaches a delivery proof to a Case based on the linked article
	 * NOTE: .getContent is considered a callout, so now DML's can be executed before hand, the code can't run in a trigger etc...
	 *          Use the attachAPDeliveryProofPdf Queueable if necessary
	 */
	public void attachAPDeliveryProofPdf(Set<Id> caseIds) {

		List<Case> casesToAttach = SSSWCasesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.Id, Case.ReferenceID__c, Case.ArticleTest__c},
				Article__c.SObjectType => new Set<SObjectField>{Article__c.ArticleID__c}
		}).selectById(caseIds, new Set<Object>{CasesSelector.Options.WITH_ARTICLE}).values();

		Map<Id, String> articleToCaseMap = new Map<Id, String>();
		List<Attachment> attachmentsToInsert = new List<Attachment>();

		for(Case cse : casesToAttach) {
			if(!String.isEmpty(cse.ArticleTest__r?.ArticleID__c)) {
				articleToCaseMap.put(cse.Id, cse.ArticleTest__r.ArticleID__c);
			}
		}

		if(articleToCaseMap.size() > 0) {

			// iterate through and build a delivery proof PDF for each of the passed in articles/cases
			// fingers crossed there aren't more than 50!!
			for(Id caseId : articleToCaseMap.keySet()) {


				// getContentAsPDF is treated as a callout which fails in a test method
				// TODO: At some point, this could probably be externalised into a generic content class which can be mocked in a test method...
				Blob pdfData = getDeliveryProofPdfContent(articleToCaseMap.get(caseId));
				attachmentsToInsert.add(new Attachment(ParentId = caseId, Body = pdfData, ContentType = 'application/pdf', Name = DELIVERY_PROOF_CASE_FILENAME));

			}

			// insert the attachments for the cases that were created
			ApplicationDatabase.getInstance().dmlInsert(attachmentsToInsert);
		} else {
			System.debug('Delivery proof was not attached');
		}
	}

	/**
	 * Make a callout to retrieve the delivery proof PDF content based on the article passed in
	 * NOTE: This makes a callout so it can't be called in a trigger OR after any DML operations :)
	 */
	public Blob getDeliveryProofPdfContent(String trackingId) {
		return (Test.isRunningTest() ? Blob.valueOf('Test') : new PageReference('/apex/MyCustomerDeliveryProofPdfWrapper?articleId=' + EncodingUtil.urlEncode(trackingId, 'UTF-8')).getContentAsPDF());
	}

	/**
	 * Returns a list of articles that has delivery proofs available, either a signature or a safe drop guid
	 */
	public Set<String> getDeliveryProofAvailable(Set<String> articleIds) {
		Set<String> output = new Set<String>();
		for(Object articleId : getDeliveryProofAvailable(EventMessagesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{Article__c.SObjectType => new Set<SObjectField>{Article__c.ArticleID__c}}).selectByArticleNumber(articleIds, new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE, EventMessagesSelector.Options.WITH_SIGNATURE_FIELD}), true)) {
			output.add(String.valueOf(articleId).toUpperCase());
		}
		return output;
	}

	/**
	 * Returns a list of articles that has delivery proofs available, either a signature or a safe drop guid
	 */
	public Set<Id> getDeliveryProofAvailable(Set<Id> articleIds) {
		Set<Id> output = new Set<Id>();
		for(Object articleId : getDeliveryProofAvailable(EventMessagesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{Article__c.SObjectType => new Set<SObjectField>{Article__c.ArticleID__c}}).selectByArticleId(articleIds, new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE, EventMessagesSelector.Options.WITH_SIGNATURE_FIELD}).values(), false)) {
			output.add((Id)articleId);
		}
		return output;
	}

	/**
	 * Returns a list of articles that has delivery proofs available, either a signature or a safe drop guid
	 */
	private Set<Object> getDeliveryProofAvailable(List<EventMessage__c> eventMessages, Boolean returnAsArticleString) {
		Set<Object> output = new Set<Object>();
		Map<String, EventMessageTypeMapping__mdt> eventTypeDefinitions = EventMessageUtil.getEventMessageTypes();
		for(EventMessage__c message : eventMessages) {
			if(eventTypeDefinitions.get(message.EventType__c)?.IsSignatureOnDelivery__c == true && !String.isEmpty(message.SignatureXString__c)) {
				output.add((returnAsArticleString ? message.Article__r.ArticleID__c : message.Article__c));
			} else if(eventTypeDefinitions.get(message.EventType__c)?.IsSafeDrop__c == true && !String.isEmpty(message.Safe_Drop_GUID__c)) {
				output.add((returnAsArticleString ? message.Article__r.ArticleID__c : message.Article__c));
			}
		}

		return output;
	}

	/**
	  * @desciprion: Queueable class to attach delivery proof PDF to case if agent has selected checkbox in happyParcelDeliveryProof component
	  */
	public class AttachAPDeliveryProofPdfQueueable implements System.Queueable, Database.AllowsCallouts {
		Set<Id> caseIds;

		public AttachAPDeliveryProofPdfQueueable(Set<Id> caseIds) {
			this.caseIds = caseIds;
		}
		public void execute(QueueableContext qc) {

			try {
				DeliveryProofService.getInstance().attachAPDeliveryProofPdf(caseIds);
			} catch (Exception exp) {
				// Added exception to track any error
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 'DeliveryProofService', 'attachAPDeliveryProofPdf', null, LoggingLevel.ERROR);
			}

		}
	}

	/**
	 * Get the guid from the safe drop API service for the article Id.
	 * @param trackingNumber
	 *
	 * @return safe drop guid
	 */
	public static String getSafeDropGuidHttpRequest(String trackingNumber) {
		String guid ='';
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint('callout:SafeDropGuidAPI/'+EncodingUtil.urlEncode(trackingNumber,'UTF-8')+'/guid');
		req.setHeader('AUTH-KEY', '{!$Credential.Password}');
		try{
			HttpResponse response = (new Http()).send(req);
			if(response.getStatusCode() == 200){
				Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
				guid = (String)m.get('safeDropImageGuid');
			}
		}catch (Exception e){
			System.debug('Exception in DeliveryProofService ##  getSafeDropGuidHttpRequest ## in getting guid for article '+trackingNumber);
			throw new CalloutException(e);
		}
		return guid;
	}
}