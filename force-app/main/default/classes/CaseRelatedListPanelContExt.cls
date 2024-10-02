/**
  * @author	   :
  * @date		 :
  * @description  : test class for Controller for CN18 form
  */
/*******************************  History ************************************************
03/01/2016  kalpita.talwadekar@auspost.com.au   updated the class to add the codes to accomodate the service now responses and the cn18 attachment updates
March-16  kalpita.talwadekar@auspost.com.au   updated the class to add the codes to accomodate duplicate cases
27/03/2017 Eric.Shen@auspost.com.au   Comment out AP Integration profile   -REQ1080244
22/05/2017  nathan.franklin@auspost.com.au	 Adding Safe drop guid retrieval from EventMessage__c
11/10/2017 boris.bachovski@auspost.com.au	   Merged code from CaseRelatedListSafeDropController (deleted)
26/02/2018 nanda.kothamasu@auspost.com.au	   to fix Case Error "Maximum View State Size Limit..." used transient on vairables
26/11/2018 saiswetha.pingali@auspost.com.au	 Added new field container_Id__c for REQ1469903
2021-10-14 - Nathan Franklin - Changed attach safe drop image to delivery proof pdf
2022-06-06 - Talib Raza - INC1979490: condition added for cc email address
2022-10-03 - Jacob Isaac - REQ2976037: removed condition for cc email address
2024-09-20 - Vasu Gorakati - Case Hand-off - Voice call records visibility to classic users
*******************************  History ************************************************/
public with sharing class CaseRelatedListPanelContExt {

	enum DeliveryProofAvailability {
		AVAILABLE, NOT_AVAILABLE, EXISTS
	}

	public Id caseId { get; set; }
	public transient List<EmailMessage> emails { get; private set; } //transient
	public List<CaseComment> caseComments { get; private set; }

	public Boolean currentUserIsPartOfOmniGroup {
		get {
			return OmniChannelService.currentUserIsPartOfOmniGroup;
		}
	}

	public List<AttachmentWrapper> attachments { get; private set; }
	public List<EventMessage__c> eventMessages { get; private set; }
	public Boolean isConsignmentCase { get; private set; }
	public TIBCOSearchResult articleSearchResult { get; private set; }
	public List<EmailMessage> emailsNetworkResp { get; private set; }
	public List<Fax__c> faxesNetworkResp { get; private set; }
	public transient List<StatusTracking__c> statusTrackingHistory { get; private set; }  //transient
	public transient List<StatusTracking__c> fieldTrackingHistory { get; private set; }   //transient
	public List<CaseComment> serviceNowResp { get; private set; }
	public transient List<Attachment> cn18Attachments { get; private set; } //transient
	public String disclaimer { get; set; }
	public List<Case> duplicateCases { get; private set; }
	public List<VoiceCall> voiceCalls { get; private set; }

	/**
	 * Can be removed after the next successful deployment.
	 * This is required for deployment of Visualforce page that still references below attributes
	 */
	public String safeDropGUID { get; set; }
	public Boolean safeDropAttachmentExists { get; set; }
	/**
	 * END
	 */

	/**
	 * Determines whether we can show the button to attach the delivery proof PDF or not
	 * We only do this based on the following:
	 * 1. The deliveryproof attachment does not already exist
	 * 2. The linked article has a delivery proof available
	 *
	 * NOTE: Transient since we want this value to be reset on next load
	 */
	/*public transient Boolean showAttachDeliveryProof {
		get {
			if(showAttachDeliveryProof == null) {
				showAttachDeliveryProof = (canAttachDeliveryProof(caseId) == DeliveryProofAvailability.AVAILABLE);
			}
			return showAttachDeliveryProof;
		}
		private set;
	}*/
	//Moving the logic away from getter to constructor in order to prevent the scenarios where case Id goes blank.
	public Boolean showAttachDeliveryProof {get;set;}

	public CaseRelatedListPanelContExt(ApexPages.StandardController stdController) {

		Id caseId = stdController.getId();
		this.caseId = caseId;

		if (caseId != null) {
			emails = getEmails(caseId);
			caseComments = getCaseComments(caseId);
			attachments = getAttachments(caseId);
			//added method to display duplicate case
			duplicateCases = getDuplicateCases(caseId);
			//added to display the list of cn18 forms created
			cn18Attachments = getcn18Attachments(caseId);
			//added to display the service now responses under the network responses
			serviceNowResp = getserviceNowResp(caseId);
			initArticlesAndEventMessages(caseId);
			QM__c qm = QM__c.getOrgDefaults();
			getNetworkEmail(qm);
			getRtdListFaxStatusTrack(caseId, qm);
			voiceCalls = getVoiceCalls(caseId);
			//Moving showAttachDeliveryProof calculation inside the constructor.
			showAttachDeliveryProof = (canAttachDeliveryProof(caseId) == DeliveryProofAvailability.AVAILABLE);				
		}
	}

	/**
	 * After a safe drop image has been attached, this is an actionFunction that will reload the attachments list.
	 */
	public void reloadAttachments() {
		//Reset showAttachDeliveryProof 
		showAttachDeliveryProof = (canAttachDeliveryProof(caseId) == DeliveryProofAvailability.AVAILABLE);
		//fetch attachments
		attachments = getAttachments(caseId);
	}

	/**
	 @description  method to retrieve the service now responses to display them in the network responses
	 @param	Id caseId
	 @return   List<CaseComment>
	 @return   NA
	 */
	private List<CaseComment> getserviceNowResp(Id caseId) {
		List<CaseComment> commentList = new List<CaseComment> ();
		try {
			//String pId = [Select Id from Profile where Name ='AP Integration' limit 1].Id; 27-Mar-17 Eric Shen  This profile is decommissioned
			String apIntUser = [Select Id from User where Name = 'AP Integration' limit 1].Id;
			String query = 'SELECT Id, IsPublished, CommentBody, CreatedBy.Name, CreatedById, CreatedDate ' +
					' FROM CaseComment WHERE ParentId = :caseId ' +
					' and CreatedById =: apIntUser ORDER BY CreatedDate DESC';

			commentList = Database.query(query);
		} catch (Exception exp) {
			//log the exception
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					CaseRelatedListPanelContExt.class.getName(), 'getserviceNowResp',
					'', LoggingLevel.ERROR);
		}
		return commentList.isEmpty() ? null : commentList;
	}

	/**
	  @description  method to retrieve the duplicate cases
	  @param	Id caseId
	  @return   List<Case>
	  @return   NA
	  */
	private List<Case> getDuplicateCases(Id caseId) {
		String referenceId = [Select ReferenceId__c, Id from Case where Id = :CaseId].ReferenceId__c;
		String query = 'Select id, CaseNumber, ReferenceID__c, Contact.Name, Status, Origin, CreatedDate from Case where ' +
				' ReferenceID__c= : referenceId ' +
				' and status!=\'Closed\' and ReferenceId__c!=null and Id != :caseId ';
		List<Case> caseList = Database.query(query);
		return caseList.isEmpty() ? null : caseList;

	}

	/**
	  @description  method to retrieve the cn18 attachments
	  @param	Id caseId
	  @return   List<Attachment>
	  @return   NA
	  */
	private List<Attachment> getcn18Attachments(Id caseId) {
		String nameLike = 'CN 18%';
		String query = 'SELECT Id, Name, BodyLength, LastModifiedDate, IsPrivate, CreatedById, ' +
				' CreatedBy.Name, CreatedDate, ParentId FROM Attachment WHERE ParentId = :caseId ' +
				' and Name like :nameLike ORDER BY LastModifiedDate DESC';

		List<Attachment> commentList = Database.query(query);
		return commentList.isEmpty() ? null : commentList;
	}

	private List<EmailMessage> getEmails(Id caseId) {

		String query = 'SELECT Id, Status, HtmlBody, textBody, Subject, FromAddress, ToAddress, CcAddress, MessageDate, incoming FROM EmailMessage WHERE ParentId = :caseId ORDER BY MessageDate DESC';

		List<EmailMessage> tempList = Database.query(query);
		List<EmailMessage> emailList = new List<EmailMessage>();

		// INC1979490: Removed the condition to exclude emails if 'ToAddress' and 'FromAddress' are equal
		emailList.addall(tempList);
		/*for (EmailMessage em : tempList) {
			if (em.ToAddress != em.FromAddress) {
				emailList.add(em);
			}
		}*/

		return emailList.isEmpty() ? null : emailList;
	}

	private void getNetworkEmail(QM__c qm) {

		if (emails != null && emails.size() > 0) {
			emailsNetworkResp = new List<EmailMessage>();
			String networkValue = qm.NetworkEmail__c;


			for (EmailMessage em : emails) {
				// INC1979490: condition added for cc email address //REQ2976037: removing CC email Address condition
				if (em.ToAddress != null && em.CcAddress != null && em.ToAddress.containsIgnoreCase(networkValue)) {
					emailsNetworkResp.add(em);
				}
			}
		}
	}

	private void getRtdListFaxStatusTrack(Id caseId, QM__c qm) {
		String filter = qm.SSWFaxEmailService__c;


		for (Case c : [
				SELECT (
						SELECT Id, Name, FieldsChanged__c, OwnerValue__c, Status__c, Network__c, Agent__c,
								EscalationTier__c, StartDate__c, EndDate__c, BusinessTime__c, CreatedDateList__c,
								NetworkResponseValue__c, NetworkCommentsValue__c, CreatedById
						FROM Status_Tracking__r
						ORDER BY StartDate__c DESC
				), (
						SELECT Id, Name, To__c, From__c
						FROM Faxes__r
						WHERE To__c = :filter
				)
				From Case c
				WHERE id = :caseId
		]) {
			if (c.Faxes__r.size() > 0) {
				faxesNetworkResp = new List<Fax__c>();
				for (Fax__c faxNR : [
						SELECT id, Name, To__c, From__c, Subject__c
						FROM Fax__c
						WHERE Case__c = :caseId AND To__c = :filter
				]) {
					faxesNetworkResp.add(faxNR);
				}
			}

			if (c.Status_Tracking__r.size() > 0) {
				statusTrackingHistory = new List<StatusTracking__c>();
				fieldTrackingHistory = new List<StatusTracking__c>();
				for (StatusTracking__c st : c.Status_Tracking__r) {
					if (String.isNotBlank(st.FieldsChanged__c)) { // Nandan : Added value check for field changed field
						if (st.FieldsChanged__c.containsIgnoreCase('Owner') ||
								st.FieldsChanged__c.containsIgnoreCase('Status')) {
							statusTrackingHistory.add(st);
						}

						if (st.FieldsChanged__c.containsIgnoreCase('Network Response') ||
								st.FieldsChanged__c.containsIgnoreCase('Network Comments')) {
							fieldTrackingHistory.add(st);
						}
					}
				}
			}
		}
	}

	private List<CaseComment> getCaseComments(Id caseId) {

		String query = 'SELECT Id, IsPublished, CommentBody, CreatedBy.Name, CreatedById, CreatedDate FROM CaseComment WHERE ParentId = :caseId ORDER BY CreatedDate DESC';

		List<CaseComment> commentList = Database.query(query);
		return commentList.isEmpty() ? null : commentList;
	}

	private List<AttachmentWrapper> getAttachments(Id caseId) {
		List<AttachmentWrapper> attachmentList = new List<AttachmentWrapper>();

		for (Attachment a : [SELECT Id, Name, BodyLength, LastModifiedDate, IsPrivate, CreatedById, CreatedBy.Name, ParentId FROM Attachment WHERE ParentId = :caseId ORDER BY LastModifiedDate DESC]) {
			attachmentList.add(new AttachmentWrapper(a, 'Attachment'));
		}

		for (FeedItem fi : FeedItemQueryUtil.queryFileFeedItems(caseId)) {
			attachmentList.add(new AttachmentWrapper(fi, 'File'));
		}

		Map<Id, EmailMessage> emailMessages = new Map<Id, EmailMessage>([SELECT Id, Incoming FROM EmailMessage WHERE ParentId = :caseId]);

		if (emailMessages.size() > 0) {
			for (Attachment a : [
					SELECT Id, Name, BodyLength, IsPrivate, LastModifiedDate, CreatedById, CreatedBy.Name, ParentId
					FROM Attachment
					WHERE ParentId IN :emailMessages.keySet()
					ORDER BY LastModifiedDate DESC
			]) {
				EmailMessage em = emailMessages.get(a.ParentId);
				a.IsPrivate = true;
				attachmentList.add(new AttachmentWrapper(a, em.Incoming ? 'Email - Received' : 'Email - Sent'));
			}
		}

		for (ContentDocumentLink cdoc : [
				SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, IsDeleted, ShareType,ContentDocument.OwnerId,
						ContentDocument.Title, ContentDocument.createdDate,ContentDocument.ContentSize,
						ContentDocument.ContentModifiedDate,ContentDocument.Owner.Name
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :caseId
		]) {
			attachmentList.add(new AttachmentWrapper(cdoc, 'Attachment'));
		}

		return attachmentList.isEmpty() ? null : attachmentList;
	}

	private void initArticlesAndEventMessages(Id caseId) {
		List<Case> cases = [select ArticleTest__c, ArticleTest__r.ArticleID__c,ArticleTest__r.Hide_Article__c, ArticleTest__r.RecordType.Name FROM Case WHERE Id = :caseId limit 1];
		if (cases.size() > 0) {
			Id articleId = cases[0].ArticleTest__c;
			//incase hide event found, capture the alert message -- added by kalpita
			// 2017-05-05 NATHAN FRANKLIN added support to pull out 'Safe_Drop_GUID__c' from event messages.
			disclaimer = !String.isBlank(cases[0].ArticleTest__r.Hide_Article__c) ? cases[0].ArticleTest__r.Hide_Article__c : '';
			String query = 'Select Article__c, Article__r.Name, EventDescription__c, ActualDateTime__c, PlannedDateTime__c, PlannedLocation__c, Facility__c,State_Territory_Province__c, Event_Location__c,Facility__r.Name, ActualLocation__c,CommentText__c, SignatoryName__c, EventSource__c, SenderID__c, EventType__c, Status__c, Safe_Drop_GUID__c,container_id__c from EventMessage__c  WHERE Article__c = :articleId ORDER BY ActualDateTime__c DESC';
			System.debug('>>> Article Id: ' + String.valueOf(articleId));
			System.debug('>>> EventMessage query: ' + query);

			List<EventMessage__c> eventMessageList = Database.query(query);
			eventMessages = eventMessageList.isEmpty() ? null : eventMessageList;

			isConsignmentCase = cases[0].ArticleTest__r.RecordType.Name == 'Consignment';

			if (isConsignmentCase) {
				List<String> childArticleIds = new List<String>();
				for (Case c : [SELECT ArticleTest__r.ArticleID__c FROM Case WHERE ParentId = :caseId]) {
					if (!String.isEmpty(c.ArticleTest__r.ArticleID__c)) {
						childArticleIds.add(c.ArticleTest__r.ArticleID__c);
					}
				}

				if (!childArticleIds.isEmpty()) {
					articleSearchResult = TIBCOArticleService.searchArticlesInSFDC(childArticleIds);
				}
			}
		}
	}

	public Integer getNetworkResponseSize() {
		Integer networkResponseSize = 0;
		if (emailsNetworkResp != null) {
			networkResponseSize = networkResponseSize + emailsNetworkResp.size();
		}

		if (faxesNetworkResp != null) {
			networkResponseSize = networkResponseSize + faxesNetworkResp.size();
		}

		// if(fieldTrackingHistory!=null)
		//	 NetworkResponseSize = NetworkResponseSize + fieldTrackingHistory.size();

		if (serviceNowResp != null) {
			networkResponseSize = networkResponseSize + serviceNowResp.size();
		}

		return networkResponseSize;
	}

	/**
	 * The user is able to click a button to 'Attach' the safe drop image to the case.
	 * This will allow them view it as per normal attachments and use it for emailing.
	 */
	@RemoteAction
	public static Map<String, Object> attachDeliveryProof(Id caseId) {
		DeliveryProofAvailability availability = canAttachDeliveryProof(caseId);
		if(availability == DeliveryProofAvailability.AVAILABLE) {
			// all checks have passed, now we execute the job to get the delivery proof PDF attached
			// NOTE: this will perform a DML insert on Attachment after the PDF content is retrieved
			DeliveryProofService.getInstance().attachAPDeliveryProofPdf(new Set<Id>{caseId});

			return new Map<String, Object>{
					'success' => true
			};
		} else {
			return new Map<String, Object>{
				'success' => false,
				'error' => (availability == DeliveryProofAvailability.EXISTS ? 'Delivery proof already exists on case' : 'Delivery proof is not available on the tracked article')
			};
		}
	}

	public static DeliveryProofAvailability canAttachDeliveryProof(Id caseId) {
		DeliveryProofAvailability output = DeliveryProofAvailability.NOT_AVAILABLE;

		// make sure the delivery proof attachment is not already attached to the case record
		String deliveryProofName = DeliveryProofService.DELIVERY_PROOF_CASE_FILENAME;
		Boolean deliveryProofAttachmentExists = ([SELECT COUNT() FROM Attachment WHERE ParentId = :caseId AND Name = :deliveryProofName] > 0);

		if(!deliveryProofAttachmentExists) {
			// check whether the linked article has a delivery proof available based on the article events
			Case c = [Select Id, ReferenceID__c From Case Where Id = :caseId];
			String referenceId = c.ReferenceID__c;

			if (!String.isEmpty(referenceId)) {
				// check whether the article has a delivery proof or not
				Set<String> articlesWithDeliveryProof = DeliveryProofService.getInstance().getDeliveryProofAvailable(new Set<String>{
						referenceId
				});
				if (articlesWithDeliveryProof.contains(referenceId.toUpperCase())) {
					// the article linked to the case has a delivery proof available
					output = DeliveryProofAvailability.AVAILABLE;
				}
			}
		} else {
			output = DeliveryProofAvailability.EXISTS;
		}

		return output;
	}

	public class AttachmentWrapper {
		public Id id { get; private set; }
		public String fileName { get; private set; }
		public Long fileSize { get; private set; }
		public Datetime lastModified { get; private set; }
		public Id createdById { get; private set; }
		public String createByName { get; private set; }
		public String fileUrl { get; private set; }
		public String detailUrl { get; private set; }
		public String fileType { get; private set; }
		public String parentUrl { get; private set; }
		public Boolean isPublic { get; private set; }

		public AttachmentWrapper(Attachment a, String ft) {
			id = a.Id;
			fileName = a.Name;
			fileSize = a.BodyLength;
			lastModified = a.LastModifiedDate;
			createdById = a.CreatedById;
			createByName = a.CreatedBy.Name;
			fileUrl = '/servlet/servlet.FileDownload?file=' + a.Id;
			detailUrl = 'javascript:srcUp(\'/' + a.Id + '?isdtp=vw\')';
			fileType = ft;
			parentUrl = '/' + a.ParentId;
			isPublic = !a.IsPrivate;
			if (fileName.contains('CN08-')) {
				isPublic = false;
			}
		}

		public AttachmentWrapper(ContentDocumentLink a, String ft) {
			id = a.ContentDocumentId;
			fileName = a.ContentDocument.Title;
			fileSize = a.ContentDocument.ContentSize;
			lastModified = a.ContentDocument.ContentModifiedDate;
			createdById = a.ContentDocument.OwnerId;
			createByName = a.ContentDocument.Owner.Name;
			fileUrl = '/' + a.ContentDocumentId;//'/servlet/servlet.FileDownload?file=' + a.ContentDocumentId;
			detailUrl = 'javascript:srcUp(\'/' + a.ContentDocumentId + '?isdtp=vw\')';
			fileType = ft;
			parentUrl = '/' + a.ContentDocumentId;
			isPublic = false;

		}

		public AttachmentWrapper(FeedItem fi, String ft) {
			id = fi.Id;
			fileName = fi.Title;
			// INC1979490 ContentSize field was removed in API version 35.0 
			//fileSize = fi.ContentSize;
			lastModified = fi.LastModifiedDate;
			createdById = fi.InsertedById;
			createByName = fi.InsertedBy.Name;
			fileUrl = '/' + fi.RelatedRecordId;
			detailUrl = 'javascript:srcUp(\'/' + fi.RelatedRecordId + '?isdtp=vw\')';
			fileType = ft;
			parentUrl = '/' + fi.ParentId;
			isPublic = false;
		}
	}
	
 	/*
	* This method returns Voice Call records with matching case Id
	* @param caseId - Case Id
	*/
	private List<VoiceCall> getVoiceCalls(Id caseId) {

		Set<SObjectField> voiceCallFields = new Set<SObjectField>{
			VoiceCall.Id, 
			VoiceCall.Name, 
			VoiceCall.CallStartDateTime, 
			VoiceCall.CallEndDateTime, 
			VoiceCall.CallType
		};

		List<VoiceCall> voiceCallList = VoiceCallsSelector.newInstance(voiceCallFields).selectByRelatedRecordIds(New Set<Id>{caseId},new Set<Object>());
		return voiceCallList.isEmpty() ? null : voiceCallList;
	}
}