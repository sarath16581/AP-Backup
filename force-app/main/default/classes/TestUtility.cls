/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 24/06/2015
  * @description  : Utility class for creating test data in test Class
  * @changelog
  * 2022-02-14 - Nathan Franklin - Added BGS entitlement test data creation
  */
@isTest
public with sharing class TestUtility{

	// Constants
	private static final String USR_TMP_EMAIL = 'us.name@vmail.com';
	private static final String ENCODE_KEY = 'UTF-8';
	private static final String TIME_ZONE = 'America/Los_Angeles';
	private static final String LOCALE_KEY = 'en_US';
	private static final String USER_POSTFIX = '@testorg.com';
	private static final String MANUAL_ROWCAUSE = 'Manual';
	private static final String SSSW_ENTITLEMENTS = 'SSSW Entitlements';
	private static final String ORGANISATION = 'Organisation';
	private static final String STD_ENTITLEMENT_SSSW = 'Standard Entitlement - SSSW';
	private static final String STD_ENTITLEMENT_BGS = 'Standard Entitlement BGS - VIC';
	private static final String STD_ENTITLEMENT = 'Standard Entitlement';
	private static final String PHONE_SUPPORT = 'Phone Support';


	/**
	 * Generate random number
	*/
	public static String generateRandomPhoneNumber(){
		Long phoneNumber = Math.abs(Crypto.getRandomInteger());
		phoneNumber += Math.abs(Crypto.getRandomInteger());
		phoneNumber += Math.abs(Crypto.getRandomInteger());
		return String.valueOf(phoneNumber).left(10);
	}

	/**
	  * @description	   This method creates user for testing
	  * @param			 lastName , profileId, roleId
	  * @return			User
	  * @throws			NA
	  */
	public static User createUser(String lastName,Id profileId,Id roleId){
		User usr = new User(alias = lastName, email= USR_TMP_EMAIL,
				emailencodingkey= ENCODE_KEY, lastname = lastName,
				timezonesidkey=TIME_ZONE,
				languagelocalekey=LOCALE_KEY,
				localesidkey= LOCALE_KEY, profileid = profileId,
				UserRoleId= roleId,
				username= lastName + System.currentTimeMillis() + USER_POSTFIX);
		return usr;
	}

	/**
	  * @description	   This method creates portal user for testing
	  * @param			 lastName , profileId, contactId
	  * @return			User
	  * @throws			NA
	  */
	public static User createPortalUser(String lastName,Id profileId,Id contactId){
		User usr = createUser(lastName,profileId,null);
		usr.ContactId = contactId;
		return usr;
	}

	/**
	  * @description	   This method creates business account for testing
	  * @param			 name , rectTypeId
	  * @return			Account
	  * @throws			NA
	  */
	public static Account createBusinessAccount(String name,Id recTypeId){
		Account acc = new Account(Name = name,RecordTypeId = recTypeId);
		return acc;
	}

	/**
	  * @description	   This method creates Person account for testing
	  * @param			 lastName , rectTypeId
	  * @return			Account
	  * @throws			NA
	  */
	public static Account createPersonAccount(String lastName,Id rectTypeId){
		Account acc = new Account(LastName = lastName,RecordTypeId = rectTypeId, Phone=generateRandomPhoneNumber() );
		return acc;
	}

	/**
	  * @description	   This method creates contact for testing
	  * @param			 firstName, lastName , email, accId
	  * @return			Contact
	  * @throws			NA
	  */
	public static Contact createContact(String firstName,String lastName,String email,Id accId){
		Contact con = new Contact(FirstName = firstName,LastName = lastName,Email = email,AccountId = accId, Phone=generateRandomPhoneNumber());
		return con;
	}

	/**
	  * @description	   This method creates opportunity for testing
	  * @param			 oppName, accId, status , closeDate
	  * @return			Opportunity
	  * @throws			NA
	  */
	public static Opportunity createOpportunity(String oppName,Id accId,String status,Date closeDate){
		Opportunity opp = new Opportunity(Name = oppName,StageName = status,CloseDate = closeDate,AccountId = accId);
		return opp;
	}

	/**
	  * @description	   This method creates opportunity product classification for testing
	  * @param			 accId, oppId, prodId
	  * @return			Opp_Product_Classification__c
	  * @throws			NA
	  */
	public static Opp_Product_Classification__c createOPC(Id accId,Id oppId,Id prodId){
		Opp_Product_Classification__c opc = new Opp_Product_Classification__c(Account__c = accId,
				Opportunity__c = oppId,
				Product__c = prodId);
		return opc;
	}

	/**
	  * @description	   This method creates product for testing
	  * @param			 prodName, prodFamily, prodClass
	  * @return			Product2
	  * @throws			NA
	  */
	public static Product2 createProduct(String prodName,String prodFamily,String prodClass){
		Product2 prodRec = new Product2(Name = prodName,Family = prodFamily,Classification__c = prodClass);
		return prodRec;
	}

	/**
	  * @description	   This method creates Billing Accountfor testing
	  * @param			 name , accId
	  * @return			Billing_Account__c
	  * @throws			NA
	  */
	public static Billing_Account__c createBillingAccount(String name,Id accId){
		Billing_Account__c billAcc = new Billing_Account__c(Name = name,Organisation__c = accId);
		return billAcc;
	}

	/**
	  * @description	   This method creates case for testing
	  * @param			 subj , status, accId, contId, recTypeId
	  * @return			Case
	  * @throws			NA
	  */
	public static Case createCase(String subj,String status,String type,Id accId,Id contId,Id recTypeId){
		Case caseRec = new Case(Subject = subj,Status = status,Type = type,AccountId = accId,
				ContactId = contId,RecordTypeId = recTypeId);
		return caseRec;
	}

	/**
	  * @description	   This method fetch User role based on developer name
	  * @param			 roleDevName
	  * @return			UserRole
	  * @throws			NA
	  */
	public static UserRole getUserRole(String roleDevName){
		UserRole role = [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName =: roleDevName LIMIT 1];
		return role;
	}

	/**
	  * @description	   This method creates share record on case to simulate criteria based sharing
	  * @param			 caseId, accessLevel, usrGrpId
	  * @return			CaseShare
	  * @throws			NA
	  */
	public static CaseShare createCaseShare(Id caseId,String accessLevel,Id usrGrpId){
		CaseShare caseShareRec = new CaseShare(CaseId = caseId,CaseAccessLevel = accessLevel,
				UserOrGroupId = usrGrpId,RowCause = MANUAL_ROWCAUSE);
		return caseShareRec;
	}

	/**
	  * @description	   This method creates test chatter group for unit testing
	  * @param			 grpName, type
	  * @return			CollaborationGroup
	  * @throws			NA
	  */
	public static CollaborationGroup createChatterGroup(String grpName,String type){
		CollaborationGroup chatterGroup = new CollaborationGroup(Name = grpName,CollaborationType = type);
		return chatterGroup;
	}

	/**
	  * @description	   This method creates test chatter post for unit testing
	  * @param			 body, parentId
	  * @return			FeedItem
	  * @throws			NA
	  */
	public static FeedItem createChatterPost(String body,Id parentId){
		FeedItem post = new FeedItem(Body = body,ParentId = parentId);
		return post;
	}

	/**
	  * @description	   This method creates test chatter post comment for unit testing
	  * @param			 body, postId
	  * @return			FeedComment
	  * @throws			NA
	  */
	public static FeedComment createChatterPostComment(String body,Id postId){
		FeedComment comment = new FeedComment(CommentBody = body,FeedItemId = postId);
		return comment;
	}

	/**
	  * @description	   This method creates test note for unit testing
	  * @param			 title, body, postId
	  * @return			Note
	  * @throws			NA
	  */
	public static Note createNote(String title,String body,Id parentId){
		Note ntRec = new Note(Title = title,Body = body,ParentId = parentId);
		return ntRec;
	}

	/**
	  * @description	   This method creates test attachment for unit testing
	  * @param			 title, body, postId
	  * @return			Attachment
	  * @throws			NA
	  */
	public static Attachment createAttachment(Blob body,Id parentId){
		Attachment attRec = new Attachment(Body = body,ParentId = parentId);
		return attRec;
	}

	/**
	  * @description	   This method creates test article for unit testing
	  * @param			 articleId, count, sender, receiver, prodCategory
	  * @return			Article__c
	  * @throws			NA
	  */
	public static Article__c createArticle(String articleId,Integer count,String sender,String receiver,String prodCategory){
		Article__c article = new Article__c(Name = articleId,ArticleID__c = articleId,ArticleCount__c = count,
				ProductCategory__c = prodCategory,SenderName__c = sender,
				ReceiverName__c = receiver);
		return article;
	}

	/**
	  * @description	   This method creates test event message for unit testing
	  * @param			 articleId, actualDate, evntDesc, signName, signXString
	  * @return			EventMessage__c
	  * @throws			NA
	  */
	public static EventMessage__c createEventMessage(Id articleId,DateTime actualDate,String evntDesc,String signName,String signXString){
		EventMessage__c evntMsg = new EventMessage__c(Article__c = articleId,EventDescription__c = evntDesc,
				ActualDateTime__c = actualDate,SignatoryName__c = signName,
				SignatureXString__c = signXString);
		return evntMsg;
	}

	/**
	  * @description	   This method creates network (facility) for testing
	  * @param			 name , rectTypeId, email
	  * @return			Network__c
	  * @throws			NA
	  */
	public static Network__c createNetwork(String name,Id recTypeId,String email){
		Network__c ntwrk = new Network__c(Name = name,RecordTypeId = recTypeId,Email__c = email, Portal_Licenses__c = 99);
		return ntwrk;
	}

	/**
	  * @description	   This method creates network (facility) user for testing
	  * @param			 name , rectTypeId, email
	  * @return			Network_User__c
	  * @throws			NA
	  */
	public static Facility_User__c createNetworkUser(Id ntwrkId,Id usrId){
		Facility_User__c ntwrkUser = new Facility_User__c(Network__c = ntwrkId,User__c = usrId);
		return ntwrkUser;
	}

	/**
	  * @description	   This method creates authorized contact for testing
	  * @param			 authorizingId , authorisedId, recTypeId
	  * @return			AuthorisedContacts__c
	  * @throws			NA
	  */
	public static AuthorisedContacts__c createAuthorizedContact(Id authorizingId,Id authorisedId,Id recTypeId){
		AuthorisedContacts__c authcon = new AuthorisedContacts__c(AuthorisingContact__c = authorizingId,
				AuthorisedContact__c = authorisedId,RecordTypeId = recTypeId);
		return authcon;
	}

	/**
	  * @description	   This method creates Spam Email for testing
	  * @param			 spamEmail
	  * @return			SpamEmail__c
	  * @throws			NA
	  */
	public static SpamEmail__c createSpamEmail(String spamEmail){
		SpamEmail__c spam = new SpamEmail__c(FromEmail__c = spamEmail);
		return spam;
	}

	/**
	  * @description	   This method creates fax for testing
	  * @param			 caseId, fromAdd, toAdd, faxBody, subj
	  * @return			Fax__c
	  * @throws			NA
	  */
	public static Fax__c createFax(Id caseId,String fromAdd,String toAdd,String faxBody,String subj){
		Fax__c faxRec = new Fax__c(Case__c = caseId,From__c = fromAdd,To__c = toAdd,Body__c = faxBody,Subject__c = subj);
		return faxRec;
	}

	/**
	  * @description	   This method creates Entitlement used for testing
	  * @param			 name , strtDate, strtDate, endDate, type, slaId, accId
	  * @return			Entitlement
	  * @throws			NA
	  */
	public static Entitlement createEntitlement(String name,Date strtDate,Date endDate,String type,Id slaId,Id accId){
		Entitlement entlmnt = new Entitlement(Name = name,StartDate = strtDate,EndDate = endDate,
				Type = type,SlaProcessId = slaId,AccountId = accId);
		return entlmnt;
	}

	/**
	  * @description	   This method creates SSSW Routing for testing
	  * @param			 spamEmail
	  * @return			SSSWRouting__c
	  * @throws			NA
	  */
	public static SSSWRouting__c createSSSWRouting(String prodCat,String prodSubCat,String caseType,String enqSubType,
			String custQueueType,String origin){
		SSSWRouting__c routing = new SSSWRouting__c(ProductCategory__c = prodCat,ProductSubCategory__c = prodSubCat,
				CaseType__c = caseType,EnquirySubType__c = enqSubType,
				CustomerQueueType__c = custQueueType,Origin__c = origin);
		return routing;
	}

	/**
	  * @description	   This method creates SSSW Routing for testing
	  * @param			 spamEmail
	  * @return			SSSWRouting__c
	  * @throws			NA
	  */
	public static SSSWRouting__c createSSSWRouting(String prodCat,String prodSubCat,String caseType,String enqSubType,
			String custQueueType,String origin, String matchOn, String recTypeName){
		Id devRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'SSSWRouting__c' AND DeveloperName =:recTypeName].Id;
		SSSWRouting__c routing = new SSSWRouting__c(ProductCategory__c = prodCat,ProductSubCategory__c = prodSubCat,
				CaseType__c = caseType,EnquirySubType__c = enqSubType, Match_Rules_On__c = matchOn,
				CustomerQueueType__c = custQueueType,Origin__c = origin, recordtypeId = devRecordTypeId);
		return routing;
	}

	/**
	  * @description	   This method creates test data used to trigger entitlement process
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	public static void createTestEntitlementProcessData(){
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account ssswEntitlement = TestUtility.createBusinessAccount(SSSW_ENTITLEMENTS,
				accRecTypeMap.get(ORGANISATION).getRecordTypeId());
		Database.insert(ssswEntitlement);
		SlaProcess sla = [SELECT Id,Name,IsActive,IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true
		AND Name =: STD_ENTITLEMENT_SSSW LIMIT 1];
		Entitlement stdEntlmnt = TestUtility.createEntitlement(STD_ENTITLEMENT,Date.Today(),Date.Today() + 365,
				PHONE_SUPPORT,sla.Id,ssswEntitlement.Id);
		Database.insert(stdEntlmnt);
	}

	/**
	  * @description	   This method creates test data used to trigger entitlement process for Service Advisor Cases
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	public static void createBGSDefaultEntitlementProcessData(){
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Account entitlementRecord = TestUtility.createBusinessAccount(BGSConstants.BGS_ENTITLEMENT_STANDARD,
				accRecTypeMap.get(ORGANISATION).getRecordTypeId());
		Database.insert(entitlementRecord);

		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault, BusinessHoursId FROM SlaProcess WHERE IsVersionDefault = TRUE AND Name =: STD_ENTITLEMENT_BGS LIMIT 1];
		Entitlement standardEntitlement = TestUtility.createEntitlement(BGSConstants.BGS_ENTITLEMENT_VIC,Date.today(),Date.today() + 365, PHONE_SUPPORT,sla.Id,entitlementRecord.Id);
		standardEntitlement.BusinessHoursId = sla.BusinessHoursId;
		Database.insert(standardEntitlement);
	}

	/**
	  * @description	   Method to create Custom Setting record to determine severity level.
	  * @param			 NA
	  * @return			void
	  * @throws			NA
	  */
	public static void severityLevelValue(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		Database.insert(logLevel);
	}

	/**
	  * @description	   Method to create Custom Setting record for Unique Case Trigger.
	  * @param			 NA
	  * @return			void
	  * @throws			NA
	  */
	public static void createUniqueCaseCustomSetting(){
		UniqueCaseTrigger__c custSetting = new UniqueCaseTrigger__c();
		custSetting.ProfileIds__c = '{\'00e90000001eeTh\',\'00e90000001eeTi\'}';
		custSetting.Enabled__c = true;
		custSetting.CaseLocality__c = 'International';
		Database.insert(custSetting);
	}

	/**
	  * @description	   Method to create Custom Setting record for Enquiry SubType.
	  * @param			 NA
	  * @return			void
	  * @throws			NA
	  */
	public static void createEnquirySubTypeCustomSetting(){
		EnquirySubTypes__c custSetting = new EnquirySubTypes__c();
		custSetting.Name = 'Damaged/Missing contents';
		custSetting.AvoidCustomerClose__c = true;
		Database.insert(custSetting);
	}

	/**
	  * @description	   Method to create Custom Setting record for Event Message type
	  * @param			 NA
	  * @return			void
	  * @throws			NA
	  */
	public static void createEventMsgTypeCustomSetting(){
		List<EventMessageTypes__c> evntMsgSettings = new List<EventMessageTypes__c>();
		EventMessageTypes__c er13 = new EventMessageTypes__c();
		er13.Name = 'DD-ER13';
		er13.SignatureAttachmentOnCase__c = true;

		EventMessageTypes__c er14 = new EventMessageTypes__c();
		er14.Name = 'DD-ER14';
		er14.SignatureAttachmentOnCase__c = true;

		evntMsgSettings.add(er13);
		evntMsgSettings.add(er14);

		Database.insert(evntMsgSettings);
	}

	/**
	  * @description	   Method to create Custom Setting record for Status Tracking Record type mapping.
	  * @param			 NA
	  * @return			void
	  * @throws			NA
	  */
	public static void createStatTrackingCustomSetting(){
		List<StatusTrackingRecordTypeMapping__c> settingList = new List<StatusTrackingRecordTypeMapping__c>();
		StatusTrackingRecordTypeMapping__c deliverySetting = new StatusTrackingRecordTypeMapping__c();
		deliverySetting.Name = 'SSSW Delivery';
		deliverySetting.CaseRecordType__c = 'SSSW Delivery';
		deliverySetting.StatusTrackingRecordType__c = SSSWConstants.RECTYPE_ST_GENERAL;

		StatusTrackingRecordTypeMapping__c faxSetting = new StatusTrackingRecordTypeMapping__c();
		faxSetting.Name = 'SSSW Fax';
		faxSetting.CaseRecordType__c = 'SSSW Fax';
		faxSetting.StatusTrackingRecordType__c = SSSWConstants.RECTYPE_ST_GENERAL;

		StatusTrackingRecordTypeMapping__c enquirySetting = new StatusTrackingRecordTypeMapping__c();
		enquirySetting.Name = 'SSSW General Enquiry';
		enquirySetting.CaseRecordType__c = 'SSSW General Enquiry';
		enquirySetting.StatusTrackingRecordType__c = SSSWConstants.RECTYPE_ST_GENERAL;

		StatusTrackingRecordTypeMapping__c serviceSetting = new StatusTrackingRecordTypeMapping__c();
		serviceSetting.Name = 'SSSW Service';
		serviceSetting.CaseRecordType__c = 'SSSW Service';
		serviceSetting.StatusTrackingRecordType__c = SSSWConstants.RECTYPE_ST_GENERAL;

		settingList.add(deliverySetting);
		settingList.add(faxSetting);
		settingList.add(enquirySetting);
		settingList.add(serviceSetting);

		Database.insert(settingList);
	}

	public static Location createLocation(String name,Id recTypeId){
		Location loc = Location.newInstance(28.635308,77.22496);

		return loc;
	}
}