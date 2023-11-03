/**
*@description		: Copied code from 'bspEnquiryDetail' class and modified to lightning uplift need basis
*@author			: avula.jansirani@auspost.com.au
*@group				: 
*@last modified on	: 08-05-2020 
*@last modified by	: avula.jansirani@auspost.com.au
*Modifications Log
*Ver	Date			Author									Modification
*1.0	08-05-2020		avula.jansirani@auspost.com.au			Initial Version
**/
/**************************************************
Type:					bspEnquiryDetailUplift
History:
--------------------------------------------------
10-08-2020	avula.jansirani@auspost.com.au	Added uplift changes 
16-10-2020	avula.jansirani@auspost.com.au	updated method getCaseFiles() to insert attchments
16-10-2020	avula.jansirani@auspost.com.au	Added method saveAttachment() to insert attchments
31-08-2023	thang.nguyen231@auspost.com.au	SB-109: add credit claim case fields and refactor the getEnquiry function
**************************************************/
public with sharing class bspEnquiryDetailUplift extends bspBaseUplift {

	public static boolean showAttachmentButtonFlag {get;set;}
	public String fileName {get;set;}
	public String fileContentType {get;set;}
	public transient String fileBody {get;set;} // Hasantha changed to trasiant in order to change the upload component to a drag and drop component.
	public String fileBodyLength {get;set;} // Hasantha changed this to String from decimal as we are using an actionFunction for dropzone
	// the currently loaded case passed in from the query String
	public Id enqId { get; set; }
	/**
	* Included so new changes can be deployed
	* If this is in prod then the vars / methods below can be removed
	*/
	public boolean hideSSCR5 {get;set;}


	public static String fromAusPostAddress {
		get {
			if(fromAusPostAddress == null) {
				QM__c qmConfigSetting = QM__c.getInstance();
				fromAusPostAddress = (String.isEmpty(qmConfigSetting.CusEmail__c) ? '' : qmConfigSetting.CusEmail__c);
			}
			return fromAusPostAddress;
		}
		private set;
	}

		/**
	 * Getting given enquiry details,address, files and its comments
	 * */
	@AuraEnabled(cacheable=true)
	public static CaseDetailWrapper getEnquiryDetail(String enquiryNumber) {
		
		CaseDetailWrapper cw = new CaseDetailWrapper();
		cw.authorised = false;
		cw.enq = null;
		
		if(!String.isEmpty(enquiryNumber)) {
			cw.enq = getEnquiry(enquiryNumber);
		}
		
		if(cw.enq != null) {
			cw.authorised = true;
			cw.existingFiles = getCaseFiles(cw.enq.Id);
			setAddressStrings(cw);
			cw.commHistoryList = generateCommHistory(cw.enq); 
		} else {
			// show a not authorised message
			throw new ErrorException(bspBaseUplift.getErrorMessage(BspConstants.ERROR_NOT_AUTHORISED_PAGE));
		}
		return cw;
	}

	/**
	 * Getting given case files 
	 * */
	private static Map<String, String> getCaseFiles(Id caseId){
		Map<String, String> caseFilesMap = new  Map<String, String>();
		List<Attachment> existingAttachments = [SELECT Id, Name, BodyLength, Description, ContentType, createdById
							FROM Attachment
							WHERE ParentId = : caseId
							AND IsPrivate = false
							ORDER BY CreatedDate DESC];

		for(Integer i=0;i<existingAttachments.size();i++) {
			if(existingAttachments[i].Name.length() > 5){
				if(existingAttachments[i].Name.substring(0,5) != bspBaseUplift.doNotShowFile) {
					caseFilesMap.put(existingAttachments[i].Id,existingAttachments[i].Name);
				}
			}else{
				caseFilesMap.put(existingAttachments[i].Id,existingAttachments[i].Name);
			} 
		}

		return caseFilesMap;
	}

	@AuraEnabled
	public static Map<String,String> saveAttachment(Id parentId, String fileName, String base64Data, String fileType) {
		Map<String, String> insertedAttMap = new  Map<String, String>();
		// Decoding base64Data
		base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
		// inserting file
		
		
		Attachment oAttachment = new Attachment();
		oAttachment.parentId = parentId;
		
		oAttachment.Body = EncodingUtil.base64Decode(base64Data);
		oAttachment.Name = fileName;
		oAttachment.ContentType = fileType;
		oAttachment.IsPrivate = false;
		oAttachment.OwnerId = UserInfo.getUserId();
		
		insert oAttachment;

		insertedAttMap.put(oAttachment.Id, oAttachment.Name);
		return insertedAttMap;
	}  

	/*
	* Query the case and if user is having access to case then returning the case otherwise not
	* */
	private static Case getEnquiry(String enquiryNumber) {
		if(enquiryNumber !=null){
			Set<SObjectField> caseFieldsToQuery = new Set<SObjectField>{Case.Id, Case.Subject, Case.CCUServiceUsed__c, Case.ArticleType__c, Case.DatePosted__c, Case.CCUYourReference__c, Case.Permanent_Close__c,
																		Case.ContactId, Case.ReferenceID__c, Case.CreatedDate, Case.Status, Case.LastModifiedDate, Case.CCUEnquiryType__c, Case.CCUItemContents__c,Case.Address2__c, Case.Enquiry_Type__c,
																		Case.BSP_Sender_Name__c, Case.BSP_Sender_Company__c, Case.BSP_Sender_Address__c, Case.Primary_Name__c, Case.Primary_Company__c, Case.Address1__c, Case.Pickup_Booking_Reference__c,
																		Case.BSP_Addressee_Name__c, Case.BSP_Addressee_Company__c, Case.BSP_Addressee_Address__c, Case.Secondary_Contact__c, Case.Secondary_Companry__c,
																		Case.CaseNumber, Case.ProductCategory__c, Case.ProductSubcategory__c, Case.DescriptionOfContents__c, Case.StarTrack_RecordType__c,
																		Case.Article_Receiver_Name__c, Case.Article_Receiver_Address__c, Case.StarTrack_Receiver_Name__c, Case.Address4__c, Case.Description, 
																		Case.AccountId, Case.Related_Billing_Account__c, Case.CreatedById, Case.Enquiry_Status__c,
																		Case.Business_Name__c, Case.Billing_Number__c, Case.Name__c, Case.Email_Address__c, Case.Phone__c, Case.Business_Unit__c, Case.ReasonforCreditClaim__c, Case.Amount_Claimed__c
																	};

			List<Case> enqList = CasesSelector.newInstance(caseFieldsToQuery).selectByCaseNumber(new Set<String>{enquiryNumber}, new Set<Object>{CasesSelector.Options.WITH_CONTACT, CasesSelector.Options.WITH_ARTICLE, CasesSelector.Options.WITH_RECORDTYPE, CasesSelector.Options.WITH_BILLINGACCOUNT}).values(); 											
			
			if(!enqList.isEmpty()) {
				if(bspBaseUplift.isMpbHspFlag) {
					return enqList[0];
				} else if(isCaseAccessible(enqList[0])) {
					return enqList[0]; 
				}
			}
		}
		return null;
	}

	/**
	* Setting fro and to address to the wrapper to display in enquiry details in bsp
	* */
	private static void setAddressStrings(CaseDetailWrapper cw) {
		List<String> tempAdd = new List<String>();
		cw.fromName = (cw.enq.BSP_Sender_Name__c != null ? cw.enq.BSP_Sender_Name__c : cw.enq.Primary_Name__c);
		cw.fromCompany = (cw.enq.BSP_Sender_Company__c != null ? cw.enq.BSP_Sender_Company__c : cw.enq.Primary_Company__c);
		
		if(!String.isBlank(cw.enq.BSP_Sender_Address__c)) {
			if(cw.enq.BSP_Sender_Address__c.contains(','))  {
				tempAdd = cw.enq.BSP_Sender_Address__c.split(',',2);
				cw.fromAddress1 = (tempAdd[0] != null ? tempAdd[0] : '');
				cw.fromAddress2 = (tempAdd[1] != null ? tempAdd[1].trim() : '');
			}
			else  {
				cw.fromAddress1 = cw.enq.BSP_Sender_Address__c;
				cw.fromAddress2 = '';
			}
		}
		if (String.isBlank(cw.fromAddress1))  {
			cw.fromAddress1 = cw.enq.Address1__c;
		}
		cw.toName = (cw.enq.BSP_Addressee_Name__c != null ? cw.enq.BSP_Addressee_Name__c : cw.enq.Secondary_Contact__c);
		cw.toCompany = (cw.enq.BSP_Addressee_Company__c != null ? cw.enq.BSP_Addressee_Company__c : cw.enq.Secondary_Companry__c);
		
		if(!String.isBlank(cw.enq.BSP_Addressee_Address__c))  {
			if(cw.enq.BSP_Addressee_Address__c.contains(',')) {
				tempAdd = cw.enq.BSP_Addressee_Address__c.split(',',2);
				cw.toAddress1 = (tempAdd[0] != null ? tempAdd[0] : '');
				cw.toAddress2 = (tempAdd[1] != null ? tempAdd[1].trim() : '');
			}
			else  {
				cw.toAddress1 = cw.enq.BSP_Addressee_Address__c;
				cw.toAddress2 = '';
			}
		}
		if (String.isBlank(cw.toAddress1)) {
			cw.toAddress1 = cw.enq.Address2__c;
		}
	}

	//Modified by David Catindoy (Feb 10, 2017) to add the capability to close cases that are still pending for approval.
	/**
	 * Close a case
	 * */
	@AuraEnabled
	public static void  closeCase(Id enqId)  {
		Case enq = new Case(Id=enqId);
		enq.Status = BspConstants.CASE_STATUS_CLOSED;
		enq.ResolutionCode__c = 'Customer – Self service';
		Boolean inApproval = Approval.isLocked(enq.Id); //Check if case record is locked.
		try {
			Database.update(enq);
			if(inApproval){//If the record is locked, then it is still pending for approval.
				Database.insert(new CaseComment(CommentBody = 'BSP User closed this case while still pending for approval process.', ParentId = enq.Id)); //Create a comment under the case.
				Approval.UnlockResult result = Approval.unlock(enq.Id); //Unlock the case record.
			}

		} catch(Exception ex) {
			throw new ErrorException(ex);
		}
	}

	/**
	 * Re open a case : Update give case status to 'New'
	 * */
	@AuraEnabled
	public static void  reopenCase(Id enqId) {
		Case enq = new Case(Id=enqId);
		enq.Status = 'New';
		try {
			update enq;
		} catch(Exception ex) {
			throw new ErrorException(ex);
		}
	}

	/**
	 * Add a comment to the case and then update the case status
	 * */
	@AuraEnabled
	public static void addComment(Id enqId, String CommentBodyMsg, String caseRecordTypeName, string caseStatus) { 
		
		CaseComment newCaseComment = new CaseComment();
		newCaseComment.IsPublished = true;
		newCaseComment.ParentId = enqId;
		newCaseComment.CommentBody = CommentBodyMsg;
		
		if(newCaseComment.CommentBody.trim()!=null && newCaseComment.CommentBody.trim()!='') {
			try {
				insert newCaseComment;
			} catch(Exception ex) {
				throw new ErrorException(ex);
			}
		}
		Case enq = new Case(Id=enqId);
		
		if(caseRecordTypeName.startsWith('StarTrack') && (String.isNotBlank(newCaseComment.CommentBody))){
			enq.Case_Update__c = StarTrack_Constants.CASE_UPDATE_CUSTOMERRESP;
			enq.Case_Update_Time__c = System.now();
			
			if (StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER.equals(caseStatus)) {
				enq.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
			}
			try {
				Database.update(enq);
			} catch (Exception ex) {
				throw new ErrorException(ex);
			}
		}
	}

		/**
	 * get the case comments for a given case and build the wrapper list to display in case detail of bsp community
	 * */
	private static  List<commHistory>  generateCommHistory(Case enq) {
		List<commHistory> commHistoryList = new List<commHistory>();
		// this function sorted 2 types of objects (Comm) by CreatedDate DESC, and then added to a wrapper class
		// such that Vf page can access them consistently.
		String avoidSubjects = '%'+String.valueOf(System.Label.ProdRelease1_2)+'%';
		
		List<SObject> comments = [SELECT Id, CommentBody, IsPublished, CreatedDate, CreatedById
									FROM CaseComment
									WHERE IsPublished = true
									AND ParentId = : enq.Id];
		
		System.debug([SELECT Id, HtmlBody, TextBody, CreatedDate, CreatedById,
						Subject, FromAddress, ToAddress, CcAddress, FromName
						FROM EmailMessage
						WHERE ParentId = : enq.Id]);
		
		// only display EmailMessage if it has keyword matched in its FromAddress or ToAddress
		List<SObject> emailMessages = [SELECT Id, HtmlBody, TextBody, CreatedDate, CreatedById,
										Subject, FromAddress, ToAddress, CcAddress, FromName
										FROM EmailMessage
										WHERE ParentId = : enq.Id
										AND (FromAddress LIKE : bspBaseUplift.emailKeyword OR ToAddress LIKE : bspBaseUplift.emailKeyword)
										AND (NOT Subject LIKE :avoidSubjects)];
		
		// We do not display names of internal users so we need to understand what the user types are of each user involved in the updates
		// not sure why but some of these details aren't accessible with CreatedBy.x in above queries
		Set<Id> userIds = new Set<Id>();
		for(SObject comment : comments) {
			userIds.add((Id)comment.get('CreatedById'));
		}
		for(SObject emailMessage : emailMessages) {
			userIds.add((Id)emailMessage.get('CreatedById'));
		}
		
		// use a without sharing inner class in order to grab user details given that internal users will not be accessible
		WithoutSharingExtension extension = new WithoutSharingExtension();
		Map<Id, User> usersInUpdates = extension.getUsersTypes(userIds);
		
		List<SObject> objs = new List<SObject>();
		objs.addAll(comments);
		objs.addAll(emailMessages);
		
		for(SObject s : objs)  {
			commHistoryList.add(new commHistory(s, usersInUpdates.get((Id)s.get('CreatedById'))));
		}
		
		// sort against CreatedDate
		commHistoryList.sort();
		
		return commHistoryList;
	}

	/**
	 * comment history wrapper
	 *  // this wrapper class handles sobject of EmailMessage, Task and CaseComment
	 *   // Note: task is not visible to community user so it is no longer relevant.
	 * */
	public class commHistory implements Comparable
	{
		@AuraEnabled public  SObject record;
		@AuraEnabled public User createdByUser;
		@AuraEnabled public String objType;

		public Integer compareTo(Object compareTo) {
			// make the sorting based on CreatedDate
			commHistory c = (commHistory)compareTo;
			if(getCreatedDate() == c.getCreatedDate()) {
				return 0;
			} else if(getCreatedDateTime() > c.getCreatedDateTime()) {
				return -1;
			} else {
				return 1;
			}
		}

		public Datetime getCreatedDateTime()  {
			// make the sorting based on CreatedDate
			Datetime dt = Datetime.valueOf(record.get('CreatedDate'));
			return dt;
		}

		public commHistory(SObject record, User createdByUser) {
			this.record = record;
			this.createdByUser = createdByUser;

			if (record.getSObjectType() == CaseComment.SObjectType) {
				objType = 'comment';
			} else if(record.getSObjectType() == Task.SObjectType) {
				objType = 'task';
			} else if(record.getSObjectType() == EmailMessage.SObjectType) {
				objType = 'message';
			}
		}

		public String getobjType() {
			return objType;
		}

		private String getCreatedDate() {
			String output = '';
			Datetime dt = Datetime.valueOf(record.get('CreatedDate'));
			output = dt.format();
			return output;
		}
		
		@AuraEnabled
		public String getBody() {
			String output = '';
			if(objType == 'comment') {
				output = String.valueOf(record.get('CommentBody'));
			} else if(objType == 'task') {
				output = String.valueOf(record.get('Description'));
			} else if(objType == 'message') {
				//Subject, FromAddress, ToAddress, Body
				output = 'Subject: ' + String.valueOf(record.get('Subject')) + '<br>';
				output += 'From: ' + String.valueOf(record.get('FromAddress')) + '<br>';
				output += 'To: ' + String.valueOf(record.get('ToAddress')) + '<br>';
				output += '-----------------------------------------------------------------------------------<br>';
				output += String.valueOf(record.get('HtmlBody'));

			}
			return output;
		}

		private String getPostedBy() {
			if((new Set<String>{'comment', 'task'}).contains(objType)) {
				return createdByUser.Name;
			} else if(objType == 'message') {
				// use FromName
				return String.valueOf(record.get('FromName'));
			}

			return null;
		}

		private Boolean isCommunityUser() {
			// determine whether the record is created by 'CCU/BSP Community User' profile
			Boolean output = false;
			if((new Set<String>{'comment', 'task'}).contains(objType)) {
				// is an external user?
				return BspConstants.EXTERNAL_USER_USERTYPE.equalsIgnoreCase(createdByUser.UserType);
			} else if(objType == 'message') {
				// use FromAddress to determine whether it is Community User
				String fromAddress = String.valueOf(record.get('FromAddress'));
				fromAddress = fromAddress.toLowerCase();
				if(!fromAddress.equalsIgnoreCase(fromAusPostAddress)) {
					output = true;
				}
			}
			return output;
		}

		private Boolean isMe() {
			return createdByUser.Id == UserInfo.getUserId();
		}
		
		@AuraEnabled 
		public String getHeader() {
			// due to unique CSS structure, see sample below, this function generates the html String
			String output = '';
			if(isCommunityUser() && !getBody().contains(bspBaseUplift.getErrorMessage('CSV Error')) && !getBody().contains('Number of Cases created via Bulk Upload :')) {
				output = (isMe() ? 'ME ' : 'BSP ')+ '(' + getPostedBy() + ') '+ getCreatedDate();
			} else {
				output = 'Update '+ getCreatedDate() ;
			}

			return output;
		}
	}


	/**
	 * A without sharing class here to retrieve details of users that aren't in the community (Internal users)
	 * Currently, External Org Wide Default for User is Private, hence why a without sharing is required for this call.
	 */
	private without sharing class WithoutSharingExtension {
		public Map<Id, User> getUsersTypes(Set<Id> userIds) {
			return new Map<Id, User>([Select Id, UserType, ProfileId, Name From User Where Id in :userIds]);
		}
	}
	/**
	 *  Wrapper to stoe case details, files, comment history to retun to LWC to disply in case detail
	 * */
	public class CaseDetailWrapper{
		@AuraEnabled  public String fromName { get; private set; }
		@AuraEnabled public String fromCompany { get; private set; }
		@AuraEnabled public String fromAddress1 { get; private set; }
		@AuraEnabled public String fromAddress2 { get; private set; }
		@AuraEnabled public String toName { get; private set; }
		@AuraEnabled public String toCompany { get; private set; }
		@AuraEnabled public String toAddress1 { get; private set; }
		@AuraEnabled public String toAddress2 { get; private set; } 
		@AuraEnabled public Boolean authorised { get; private set; } 
		@AuraEnabled public Case enq;
		@AuraEnabled public List<commHistory> commHistoryList {get;set;}
		@AuraEnabled public Map<String, String> existingFiles {get;set;}
	}

	/** 
	* Custom Exception
	* */
	class ErrorException extends Exception{}
}