/************************************
 * History
 * May-2015:  scherukuwada@salesforce.com   Added Sharing
 * Aug-2015:  paul.stamer@auspost.com.au	Added null to cloned case for network and ServcieNow fields - INC0592658
 * Sep-2015:  paul.stamer@auspost.com.au	Added null to child case for ServcieNow fields - INC0592658
 * Nov-2015:  kalpita.talwadekar@auspost.com.au	Added new case assign functionality for 'Reassign' button.
 * Jan-2016:  paul.stamer@auspost.com.au	Added false to child & clone case for HLC & CR - INC0636463
 * March-2016:  kalpita.talwadekar@auspost.com.au	Added new check for duplicate case alert.
 * April-2016:  kalpita.talwadekar@auspost.com.au	Added code for estimated delivery date
 11/08/2016  kalpita.talwadekar@auspost.com.au   Updated to add the edd incident fix to include weekends and public holidays
 26/10/2016  nandan.narasappa@auspost.com.au   Added null check at line 1051 to fix INC0835553
 07/11/2016  eric.shen@auspost.com.au		  remove SnappId__c field value when cloning or 'contact another network' button. fix for INC0839946
  07/04/2017  eric.shen@auspost.com.au		  Copy the CaseOriginator__c from parent to child case as per request REQ1081108
21/04/2017  dion.gunn@auspost.com.au	Added new methods/edited existing save methods for Missorts project.
 15/01/2018 nanda.kothamasu@auspost.com.au Added SLA data set to null when Close Case is created - INC0708862
 27/02/2017 dilshan.egodawela@auspost.com.au	 added platform caching to case details page layouts
 08/10/2018 saisweth.pingali@auspost.com.au	 commented calculateEDD as part of INC1224598 as the layout is commented for req REQ1386788
 25/06/2018 disha.kariya@auspost.com.au	 Removed NPSRequired__c and NPSTagDate__c to delete it.
 22/05/2020 dheeraj.mandavilli@auspost.com.au Removed check duplicates and generate attachments from Initialize page method and created new methods.
 2020-06-19 dheeraj.mandavilli@auspost.com.au Removed generateattatchments method from this class and kept in Faxtrigger
 2020-10-15 naseer.abbasi@auspost.com.au		Updated call to SSSW_Routing.assignCasesAndDescription with additional isInsert parameter
 2021-02-02 saiswetha.pingali@auspost.com.au -  Reset 'ClosedbySystem__C' to false on cloning a case.
 2021-04-15 naveen.rajanna@auspost.com.au - added itemHeld flag to be used in frontend js to denote user by alert message.
 2021-09-06 seth.heang@auspost.com.au   Uplift SF API version to 52
 2021-09.20 seth.heang@auspost.com.au   INC1852893 Fix SOQL query bug which caused 'Reassign' button functionality to not working
 2021.10.01	seth.heang@auspost.com.au	INC1859157, INC1859449 Fix SOQL query issue with ReferenceID__c, Status, EnquirySubType__c
 2022-04-08 Naveen Rajanna REQ2804764 - Remove debug and Add null check to prevent nullpointerexception
 2022-11-18 George Nguyen - Added logic to check against the target ownerId: If it is omni and the skills are matching the previous owner's skills then do not allow the case to be Reassigned.
 2023-02-06 Noel Lim - Added Preferred Agent logic, which sets BypassPreferredAgent to true if the case is being routed to an omni queue.
 2023-06-06 - Nathan Franklin - Refactored case reassignment
 2023-07-21 - Nathan Franklin - added an additional check to allow multiple status tracking to be created in reassign case
***********************************/
global class CaseDetailsCaseContExt  {

	public Case myCase {get; set;}
	public Article__c relatedArticle {get; set;}
	public Id caseId {get; set;}
	public List<SectionDetail> sectionDetails {get; set;}
	public Map<String,CustomFieldLabelling__c> caseFieldLabelling {get; set;}
	public Boolean issues {get; set;}
	public Boolean warnings {get; set;}
	public static Case clonedCase {get; set;}
	public static Case childCase {get; set;}
	public static Case toClone {get; set;}
	public string sectionsDisplayOnLoad {get;set;}
	public string variableKeys {get;set;}
	public string fieldArray {get;set;}
	public boolean showPopup {get;set;}
	public boolean remediationAvailable {get; set;}
	private boolean firstClick = true;
	private static final string EXPRESS = 'express';
	private static final string COURIER = 'courier';
	private static final string REGULAR = 'regular';
	private static final string CONFIRM_IMG = 'confirm16.png';
	private static final string ERROR_IMG = 'error16.png';
	private static final string WARNING_IMG = 'warning16.png';
	private static final String GROUP_NAME_EXC_DUP = 'SSSW High Level Complaints';
	private static final String PRD_TYPE_EXC_DUP = 'Unaddressed Mail';
	private static final String SSSW_SERVICE_AGENT = 'SSSW - Service Agent';
	private static final String STAT_CLOSED = 'Closed';
	private static final Map<String,String> deliverEvents = new Map<String,String> {
			'DD-ER13' => 'Delivered',
			'DD-ER14' => 'Delivered - No signature required',
			'DD-ER15' => 'Delivered with Safe Drop (MyPost)',
			'DD-ER37' => 'Delivered',
			'DD-ER38' => 'Delivered with Safe Drop',
			'DDR-ER13' => 'Delivered',
			'DDR-ER14' => 'Delivered',
			'DOM-0001' => 'Delivered',
			'DOM-0008' => 'Item delivered to PO Box',
			'DOM-0009' => 'Item delivered - Customer Pickup',
			'INT-0037' => 'Deliver item (Inb)',
			'INT-2009' => 'Item delivered',
			'INT-2037' => 'Delivered',
			'INT-2038' => 'Transferred to customs broker for delivery',
			'INT-2039' => 'Item delivered in damaged condition',
			'INT-2070' => 'Authority to Leave',
			'INT-2136' => 'Item delivered to PO Box',
			'INT-2137' => 'Item delivered - Customer Pickup'
	};

	public boolean hasEDD {get;set;}
	public Case testCase{get;set;}
	public Boolean missingItemDelayed{get;set;}
	public Boolean infoRequired{get;set; }
	public Boolean missingItemLodgedonAfter{get;set;}
	public Boolean missingItemLodged{get;set;}
	public Date onAfterDate {get;set;}
	public Boolean delayedScan {get;set;}
	public boolean showEDDSec {get;set;}
	public string dateString {get;set;}
	public string iconImageName {get;set;}
	public Case eddCase {get;set;}
	public Case reassignCase {get;set;}
	public string caseCont;
	private Case oldCase ;	// case to have  previous state for Status comparison for HLC CR : Nandan N
	private static final String AWAITING_NETWORK_RESPONSE = 'Awaiting Network Response';
	public Boolean showOwnerPanel {get;set;}
	public Boolean itemHeld {get;set;}

	public Boolean sameMemberAssignment {get;set;}

	/**
	  * @name: CaseDetailsCaseContExt
	  * @desciption: constructor for class
	  * @param: NA
	  * @return: NA
	  *
	  */
	public CaseDetailsCaseContExt(ApexPages.StandardController stdController) {
		caseId = (Id)stdController.getId();
		fieldArray = '';
		caseCont = '';
		remediationAvailable = false;
		itemHeld = false;
	}

	/**
	  * @name: closepopup
	  * @desciption: method to hide the popup window for duplicates
	  * @param: NA
	  * @return: NA
	  *
	  */
	public void closepopup() {
		showPopup = false;
	}

	/**
	  * @name: getRecordTypeId
	  * @desciption: remote action method to get the recordTypeId
	  * @param: string caseType, string productCategory
	  * @return: String
	  *
	  */
	@RemoteAction
	global static string getRecordTypeId(string caseType, string productCategory, String productSubCategory){
		//System.Debug('######### checking record type id ###############');
		string result = '';
		Savepoint sp = Database.setSavepoint();
		Case c = [select id from Case where referenceId__c = 'SSSWCase' limit 1];
		c.referenceId__c = '';
		c.Bypass_Data_enforcement__c = true;
		c.type = caseType;
		c.productCategory__c = productCategory;
		c.productsubcategory__c = productSubCategory; // added by kalpita
		update c;
		result = [select recordTypeid from Case where id=:c.id].RecordTypeId;
		//System.Debug('record type = ' + result);
		Database.rollback(sp);
		return result;
	}

	/**
	  * @name: getErrorsPresent
	  * @desciption: method to display errors on page
	  * @param: NA
	  * @return: Boolean
	  *
	  */
	public Boolean getErrorsPresent() {
		return ApexPages.hasMessages(ApexPages.Severity.ERROR);
	}

	/**
	  * @name: checkValidation
	  * @desciption: method validates the case update
	  * @param: NA
	  * @return: NA
	  *
	  */
	public void checkValidation(){
		try {
			if(caseId != null && !getErrorsPresent()) {
				Savepoint pt = Database.setSavePoint();
				Case c = [select id from Case where id=:caseId limit 1];
				update c;
				Database.rollback(pt);
			}
		}catch(exception ex){
			ApexPages.addMessages(ex);
		}
	}

	/**
	  * @name: getClonedCaseId
	  * @desciption: method to clone the case and redirect to cloned case
	  * @param: Id caseId
	  * @return: String
	  *
	  */
	@RemoteAction
	global static String getClonedCaseId(Id caseId) {
		toClone = Database.query(Util.getCreatableFieldsSOQL('Case','Id = :caseId limit 1'));
		//System.Debug('CaseId**'+caseId);
		//toClone = [Select Id from Case where Id=:caseId limit 1];
		clonedCase = toClone.clone(false, true);
		//clonedCase.ReferenceID__c = '';
		clonedCase.Unique_Case__c = '';
		clonedCase.Status = 'New';
		clonedCase.Permanent_Close__c = false;
		clonedCase.ResolutionCode__c = '';
		//clonedCase.ClosedDate = null;
		clonedCase.RelatedCase__c = caseId;
		clonedCase.Case_Milestone_Violation__c = false;
		clonedCase.Customer_Milestones_Violated__c = null;
		clonedCase.Internal_Milestones_Violated__c = null;
		clonedCase.Facility_Milestones_Violated__c = null;
		clonedCase.Customer_Email_Notification__c = null;
		//clonedCase.Internal_Tier_Escalation_Email__c = clonedCase.RelatedCase__r.Owner.Manager.Email;
		clonedCase.Facility_Tier_Escalation_Email__c = null;
		clonedCase.OwnerId = UserInfo.getuserId();
		clonedCase.NPSAgent__c = null;
		//clonedCase.NPSRequired__c = false;
		clonedCase.NPSScheduledDate__c = null;
		//clonedCase.NPSTagDate__c = null;
		clonedCase.Network__c = null;//31-Aug-15 paul stamer
		clonedCase.Service_Now_Ticket_Number__c = null;//31-Aug-15 paul stamer
		clonedCase.IsHLC__c = false; //13-Jan-16 paul stamer
		clonedCase.IsCR__c = false; //13-Jan-16 paul stamer
		clonedCase.SnappId__c = null; //07-Nov-16 Eric Shen
		clonedCase.SLATargetDate__c = null; //15-Jan-17 Nanda Kothamasu (INC0708862)
		clonedCase.ClosedBySystem__c = false; //02-Feb-2021 SaiSwetha Pingali (REQ2396589)

		insert clonedCase;
		if(clonedCase != null)
		{
			return String.valueOf(clonedCase.Id);
		} else
		{
			return 'cloned case = null';
		}
	}

	/**
	  * @name: getChildCaseId
	  * @desciption: method to return the child case id if it exists
	  * @param: Id caseId
	  * @return: String
	  *
	  */
	@RemoteAction
	global static String getChildCaseId(Id caseId) {
		toClone = Database.query(Util.getCreatableFieldsSOQL('Case','Id = :caseId limit 1'));
		//System.Debug('CaseId**'+caseId);
		//toClone = [Select Id from Case where Id=:caseId limit 1];
		childCase = toClone.clone(false, true);
		//childCase.ReferenceID__c = '';
		childCase.Unique_Case__c = '';
		childCase.Status = 'New';
		childCase.Permanent_Close__c = false;
		childCase.ResolutionCode__c = '';
		//childCase.ClosedDate = null;
		childCase.Network__c = null;
		childCase.Lodgement_Network__c = null;
		childCase.ParentId = caseId;
		childCase.Case_Milestone_Violation__c = false;
		childCase.Customer_Milestones_Violated__c = null;
		childCase.Internal_Milestones_Violated__c = null;
		childCase.Facility_Milestones_Violated__c = null;
		childCase.Customer_Email_Notification__c = null;
		childCase.Internal_Tier_Escalation_Email__c = null;
		childCase.Facility_Tier_Escalation_Email__c = null;
		childCase.parentId = toClone.id;
		childCase.NPSAgent__c = null;
		//childCase.NPSRequired__c = false;
		childCase.NPSScheduledDate__c = null;
		//childCase.NPSTagDate__c = null;
		childCase.Service_Now_Ticket_Number__c = null; //24-Sep-15 paul stamer
		childCase.IsHLC__c = false; //13-Jan-16 paul stamer
		childCase.IsCR__c = false; //13-Jan-16 paul stamer
		childCase.SnappId__c = null; //07-Nov-16 Eric Shen
		childCase.CaseOriginator__c = toClone.CaseOriginator__c; //4-Apr-17 Eric Shen



		insert childCase;
		if(childCase != null)
		{
			return String.valueOf(childCase.Id);
		} else
		{
			return 'child case = null';
		}
	}

	/**
	  * @name: save
	  * @desciption: method to save the case record
	  * @param: NA
	  * @return: NA
	  *
	  */
	public pageReference save()  {
		//Save the remediation fields into the article if applicable
		if(remediationAvailable && relatedArticle.Id != null && validateRemediationData()) {
			saveArticles();
		} else if(remediationAvailable && relatedArticle.Id != null && !validateRemediationData()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure that all Remediation fields are completed before initiating an article/consignment remediation.');
			ApexPages.addMessage(myMsg);
		}
		try
		{
			/** Code to update flag if Status is changed to 'Awaiting Network Response' from CaseDetails Page **/
			if(oldCase != null &&  String.isNotBlank(myCase.Status)
					&& myCase.Status.equalsIgnoreCase(AWAITING_NETWORK_RESPONSE) && oldCase.Status != myCase.Status){
				myCase.IsNetworkResponseFromUI__c = true;
			}
			else{
				myCase.IsNetworkResponseFromUI__c = false;
			}

			//Set itemHeld flag to true used in frontend js to denote user by alert message.
			if(SSSWConstants.CASE_STATUS_CLOSED.equalsIgnoreCase(myCase.Status) && //Case Status is Closed
				SSSWConstants.PM26_ENQ_SUB_TYPE.equalsIgnoreCase(myCase.EnquirySubType__c) && //Enquiry Sub Type = Damaged/Missing contents
				SSSWConstants.CASE_LOCALITY_DOMESTIC.equalsIgnoreCase(myCase.CaseLocality__c) && //Case Locality = Domestic
				SSSWConstants.CASE_ORIGINATOR_ADDRESSEE.equalsIgnoreCase(myCase.CaseOriginator__c)) { //Case Originator = Addressee
					itemHeld = true;
			}

			update myCase;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			issues = true;
		}
		return null;
	}

	/**
	  * @name: doNothing
	  * @desciption: pagereference method to set values in variables before re-rendering
	  * @param: NA
	  * @return: PageReference
	  *
	  */
	public PageReference doNothing() {
		return null;
	}

	/**
	  * @name: close
	  * @desciption: method to close the case record
	  * @param: NA
	  * @return: PageReference
	  *
	  */
	public pageReference close()  {
		myCase.Status = 'Closed';
		//Save the remediation fields into the article if applicable
		if(remediationAvailable && relatedArticle.Id != null && validateRemediationData()) {
			saveArticles();
		} else if(remediationAvailable && relatedArticle.Id != null && !validateRemediationData()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure that all Remediation fields are completed before initiating an article/consignment remediation.');
			ApexPages.addMessage(myMsg);
		}

		//Set itemHeld flag to true used in frontend js to denote user by alert message.
		if(SSSWConstants.PM26_ENQ_SUB_TYPE.equalsIgnoreCase(myCase.EnquirySubType__c) && //Enquiry Sub Type = Damaged/Missing contents
			SSSWConstants.CASE_LOCALITY_DOMESTIC.equalsIgnoreCase(myCase.CaseLocality__c) && //Case Locality = Domestic
			SSSWConstants.CASE_ORIGINATOR_ADDRESSEE.equalsIgnoreCase(myCase.CaseOriginator__c)) { //Case Originator = Addressee
				itemHeld = true;
		}

		try
		{
			update myCase;
		} catch(Exception e)
		{
			ApexPages.addMessages(e);
			issues = true;
		}
		return null;
	}

	/**
	  * @name: updateFieldsWithValues
	  * @desciption: method to create a map of field with its values
	  * @param: Case newOrExistingCase, Map<string, object> fieldsAndValues, boolean ignoreEmptyValues
	  * @return: NA
	  *
	  */
	void updateFieldsWithValues(Case newOrExistingCase, Map<string, object> fieldsAndValues, boolean ignoreEmptyValues){
		Map<String, Schema.SObjectField> fieldNames = Schema.SObjectType.Case.fields.getMap();
		for(string key: fieldsAndValues.keySet()){
			if(fieldNames.containsKey(key)) {
				if(ignoreEmptyValues) {
					if(fieldsAndValues.get(key) != null && fieldsAndValues.get(key) != '') {
						newOrExistingCase.put(key, fieldsAndValues.get(key));
					}
				} else {
					newOrExistingCase.put(key, fieldsAndValues.get(key));
				}
			}
		}
	}

	/**
	  * @name: reloadPicklists
	  * @desciption: method to reload the page based on the pickist selected to update the dependent values
	  * @param: NA
	  * @return: NA
	  *
	  */
	public void reloadPicklists(){
		//System.Debug('===============================  reloadPicklists  =======================================');
		loadPageLayout(true);
	}

	/**
	 * @name: checkDuplicates
	 * @desciption: method to check if the case is duplicate case and show user a popup message
	 * @param: NA
	 * @return: NA
	 *
	 */
	public void checkDuplicates() {
		//code for checking if case is a duplicate based on reference id and show warning to user
		showPopup = false;
		Boolean isHLCUser = false;
		Id grpId = [ Select Id from Group where Name = :GROUP_NAME_EXC_DUP  Limit 1 ].Id;
		for(GroupMember  usrId: [Select Id from GroupMember where UserOrGroupId =: userinfo.getuserId() and
		GroupId =:grpId ]) {
			isHLCUser = true;
		}
		List<String> allowedForDupCheck = new List<String>{'Domestic Parcels', 'Domestic Letters', 'International Parcels', 'International Letters'};
		if(firstClick && !isHLCUser) {
			List<Case> dupCases = new List<Case>();
			dupCases = [Select id from Case where ReferenceID__c= :[Select Id, ReferenceId__c from Case where Id=:caseId].ReferenceId__c
			and Id != :caseId and status!='Closed' and ReferenceID__c!=null and
			ProductSubCategory__c!= :PRD_TYPE_EXC_DUP  and ParentId!= :caseId and
			ProductCategory__c in :allowedForDupCheck];
			Case currentCase = [Select Id, Status, RelatedCase__c, ParentId from Case where  Id=:caseId limit 1];
			if(!dupCases.isEMpty() && !STAT_CLOSED.equalsIgnoreCase(currentCase.Status) && String.isBlank(currentCase.Parentid)) {
				showPopup = true;
				firstClick = false;
			}
		}
	}

	/**
	  * @name: initializePage
	  * @desciption: method Called on page load to set the values
	  * @param: NA
	  * @return: NA
	  *
	  */
	public void initializePage()  {
		//duplicate check for showing message to user -- added by kalpita
		//checkDuplicates();

		isChildCase = false;
		if(caseId!=null)
		{
			this.myCase = [Select Id,
					Type,
					EnquirySubType__c,
					ProductCategory__c,
					DatePosted__c,
					RecordTypeId,
					RecordType.Name,
					articleTest__c,
					articleTest__r.Name,
					articleTest__r.ExpectedDeliveryDate__c,
					mls_Address__c,
					contact.MailingStreet,
					contact.MailingStreet2__c,
					contact.MailingCity,
					contact.MailingState,
					contact.MailingPostalCode,
					contact.name,
					contact.account.name,
					contact.email,
					contact.MailingCountry,
					contact.MailingDPID__c,
					Type_and_Product__c,
					ProductSubCategory__c,
					Address1Line1__c,
					Address2Line1__c,
					Address1Country__c,
					Address1DPID__c,
					Address1line2__c,
					Address1Postcode__c,
					Address1State__c,
					Address1Suburb__c,
					Address1__c,
					Address2Country__c,
					Address2DPID__c,
					Address2line2__c,
					Address2Postcode__c,
					Address2State__c,
					Address2Suburb__c,
					Address2__c,
					ParentId,
					account.ServiceSLA__c,
					Account.Role_Type_Roll_Up__c,
					Owner.Email,
					FacilityOrOutletWCC__c,
					Customer_Type__c,
					ReferenceID__c,
					Origin,
					Status,
					IsNew__c,
					IsNewForRouting__c,
					closedDate,
					NPSScheduledDate__c,
					NPSAgent__c,
					Bypass_Data_enforcement__c,
					Description,
					isHLC__c,	// field related to HLC
					isCR__c,	  // field related to HLC
					OwnerId,
					SocialPostTags__c, // INC1852893 - SOQL query bug
					CaseLocality__c,  // INC1852893 - SOQL query bug
					PreferredAgentExpiry__c,
					BusinessHoursId ,
					AllocateToQueue__c,
					Rework_Reason__c,
					Comment__c,
					IsClosed
			from Case
			where Id = :caseId
			limit 1];
			isChildCase  =	this.myCase.ParentId != null ? true : false;
			this.myCase.Type_and_Product__c = this.myCase.Type + '|' + this.myCase.ProductCategory__c + '|' + this.myCase.ProductSubCategory__c ;
			this.oldCase = this.myCase.clone(true,true,true,true);	// Cloning case to have old state in case there is any update in UI : Nandan N
			//check for edd display
			showEDDSec = this.mycase.RecordType.Name == 'SSSW General Enquiry' || this.mycase.RecordType.Name == 'SSSW Delivery' ? true : false;
			senderCode = this.myCase.Address1Postcode__c;
			receiverCode = this.myCase.Address2Postcode__c ;
			lodgementDate = this.myCase.DatePosted__c;
			//calculate EDD -- added by Kalpita
			eddCase = this.myCase;
			eddCase.DatePosted__c = this.myCase.DatePosted__c;

			reassignCase = this.myCase;
			//commented below function as part of fix for INC1224598 .Delivery Date Details" section on the page is commented for REQ1386788
			//calculateEDD(this.myCase);
		} else
		{
			this.myCase = new Case();
			this.myCase.recordTypeId = [select id from RecordType where SObjectType='Case' and Name = 'SSSW General Enquiry' limit 1].id;
		}
		//System.Debug('-------------------------------------------------------------------------------------');
		//System.Debug('-------------------------------------------------------------------------------------');
		loadPageLayout(false);

		//16-03-2017 Dion Gunn: added as part of MLS remediation project
		relatedArticle = new Article__c();
		if(myCase.ReferenceID__c != null) {
			String cleanReferenceId = myCase.ReferenceID__c.trim();
			List<Article__c> relatedArticleList = [select id, RecordType.DeveloperName, mls_Address__c, mls_Remediate_Article__c, mls_AddressLine1__c, mls_AddressLine2__c, mls_DPID__c, mls_Instructions__c,
					ReferenceID__c, mls_Description__c, mls_Postcode__c, mls_State__c, mls_Suburb__c, RequestorName__c, CCCAgentId__c, FacilityOrOutletWCC__c,
					EventCode__c
			from Article__c where ArticleID__c =: cleanReferenceId limit 1];
			if(!relatedArticleList.isEmpty()) {
				relatedArticle = relatedArticleList[0];
				myCase.mls_Address__c = String.isBlank(relatedArticle.mls_Address__c) ? '' : relatedArticle.mls_Address__c;
			}
			remediationAvailable = isRemediationAvailable(relatedArticle);
		}

	}

	private boolean isRemediationAvailable(Article__c article) {
		if(article.Id == null || myCase.RecordType.Name != 'SSSW Delivery') {
			return false;
		} else if(article.RecordType.DeveloperName == 'Consignment') {
			//Collect all the articles related to the assignment, then all the event messages related to the articles.
			if(getUndeliveredConsinmentArticles(article).isEmpty()) {
				return false;
			}
		} else if(article.RecordType.DeveloperName == 'Article') {
			//Collect all the related event messages and check if it's been delivered.
			List<EventMessage__c> articleEvents = [SELECT EventType__c FROM EventMessage__c where Article__c =: article.Id];
			for(EventMessage__c em : articleEvents) {
				if(deliverEvents.containsKey(em.EventType__c)) {
					return false;
				}
			}
		}
		return true;
	}

	private boolean validState(String state) {
		List<String> validStates = new List<String>{'VIC','NSW','QLD','TAS','SA','NT','WA','ACT'};
		for(String s : validStates) {
			if(s == state) {
				return true;
			}
		}
		return false;
	}

	private boolean validPostCode(String postCode) {
		if(postCode.isNumeric() && postCode.length() == 4) {
			return true;
		}
		return false;
	}

	public List<Article__c> getUndeliveredConsinmentArticles(Article__c article) {
		Map<Id,Article__c> articleInCons = new Map<Id,Article__c>([select Id from Article__c where Consignment__c = :article.Id]);
		List<EventMessage__c> articleConEvents = new List<EventMessage__c>([SELECT Article__c, EventType__c FROM EventMessage__c where Article__c IN:articleInCons.values()]);
		for(Article__c art : articleInCons.values()) {
			for(EventMessage__c em : articleConEvents){
				if(art.Id == em.Article__c && deliverEvents.containsKey(em.EventType__c)) {
					articleInCons.remove(art.Id);
				}
			}
		}
		return articleInCons.values();
	}

	public void saveArticles() {
		if(!validState(relatedArticle.mls_State__c) && relatedArticle.mls_Remediate_Article__c) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure the "Corrected Address" state entered is the 2 or 3 letter abbreviation');
			ApexPages.addMessage(myMsg);
		}
		if(!validPostCode(relatedArticle.mls_Postcode__c) && relatedArticle.mls_Remediate_Article__c) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure the "Corrected Address" postcode is a valid 4 digit postcode');
			ApexPages.addMessage(myMsg);
		}

		if((!validState(relatedArticle.mls_State__c) && relatedArticle.mls_Remediate_Article__c) ||
				(!validPostCode(relatedArticle.mls_Postcode__c)) && relatedArticle.mls_Remediate_Article__c) {
			return;
		}

		if(relatedArticle.RecordType.DeveloperName == 'Consignment' && remediationAvailable) {
			List<Article__c> articleToUpdate = getUndeliveredConsinmentArticles(relatedArticle);
			for(Article__c article : articleToUpdate) {
				article.mls_Remediate_Article__c = relatedArticle.mls_Remediate_Article__c;
				article.mls_AddressLine1__c = relatedArticle.mls_AddressLine1__c;
				article.mls_AddressLine2__c = relatedArticle.mls_AddressLine2__c;
				article.mls_DPID__c = relatedArticle.mls_DPID__c;
				article.mls_Instructions__c = relatedArticle.mls_Instructions__c;
				article.mls_Description__c = relatedArticle.mls_Description__c;
				article.mls_Postcode__c = relatedArticle.mls_Postcode__c;
				article.mls_State__c = relatedArticle.mls_State__c.toUpperCase();
				article.mls_Suburb__c = relatedArticle.mls_Suburb__c.toUpperCase();
				article.RequestorName__c = myCase.Contact.Name;
				article.CCCAgentId__c = myCase.Owner.Email;
				article.FacilityOrOutletWCC__c = myCase.FacilityOrOutletWCC__c;
				article.EventCode__c = 'Remediation';
				article.mls_Address__c = myCase.mls_Address__c;
			}
			if(articleToUpdate.size() > 0) {
				update articleToUpdate;
			}
			//Update the consignment record as well, storing the remediation Addres details for future fetching when viewing the case.
			if(relatedArticle.Id != null) {
				update relatedArticle;
			}
		} else if(relatedArticle.Id != null && relatedArticle.RecordType.DeveloperName == 'Article'){
			relatedArticle.RequestorName__c = myCase.Contact.Name;
			relatedArticle.CCCAgentId__c = myCase.Owner.Email;
			relatedArticle.EventCode__c = 'Remediation';
			relatedArticle.FacilityOrOutletWCC__c = myCase.FacilityOrOutletWCC__c;
			relatedArticle.mls_State__c = relatedArticle.mls_State__c.toUpperCase();
			relatedArticle.mls_Suburb__c = relatedArticle.mls_Suburb__c.toUpperCase();
			relatedArticle.mls_Address__c = myCase.mls_Address__c;
			if(!validState(relatedArticle.mls_State__c)  && relatedArticle.mls_Remediate_Article__c) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure the remediation state entered is the 2 or 3 letter abbreviation');
				ApexPages.addMessage(myMsg);
			}
			if(!validPostCode(relatedArticle.mls_Postcode__c) && relatedArticle.mls_Remediate_Article__c) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure the remediation postcode is a valid 4 digit postcode');
				ApexPages.addMessage(myMsg);
			}

			update relatedArticle;
		}
	}

	private Boolean validateRemediationData() {
		if(relatedArticle.mls_Remediate_Article__c && (String.isBlank(relatedArticle.mls_AddressLine1__c) ||
				String.isBlank(relatedArticle.mls_Instructions__c) || String.isBlank(relatedArticle.mls_Description__c) ||
				String.isBlank(relatedArticle.mls_Postcode__c) || String.isBlank(relatedArticle.mls_Suburb__c) ||
				String.isBlank(relatedArticle.mls_State__c))){
			return false;
		} else if(!relatedArticle.mls_Remediate_Article__c && (String.isNotBlank(relatedArticle.mls_AddressLine1__c) ||
				String.isNotBlank(relatedArticle.mls_Instructions__c) || String.isNotBlank(relatedArticle.mls_Description__c) ||
				String.isNotBlank(relatedArticle.mls_Postcode__c) || String.isNotBlank(relatedArticle.mls_Suburb__c) ||
				String.isNotBlank(relatedArticle.mls_State__c))){
			return false;
		} else {
			return true;
		}
	}


	/**
	  * @name: loadPageLayout
	  * @desciption: method to reload the picklist for dependent fields
	  * @param: boolean maintainValues
	  * @return: NA
	  *
	  */
	void loadPageLayout(boolean maintainValues){
		//System.Debug('############### case record type id: ' + myCase.recordTypeId);
		fieldArray = '';
		String query = 'Select Id';
		sectionDetails = new List<SectionDetail>();
		caseFieldLabelling = new Map<String,CustomFieldLabelling__c>();
		for(CustomFieldLabelling__c cf : [Select
				Id, UniqueKey__c, CaseType__c,
				CaseFieldLabel__c, CaseFieldAPIName__c
		from CustomFieldLabelling__c
		where CaseType__c = :myCase.EnquirySubType__c])
		{
			caseFieldLabelling.put(cf.UniqueKey__c.toLowerCase(), cf);
		}
		//get SSSW-Service Agent Profile id
		Id ServiceAgentProfID = [select Id from Profile where Name =:SSSW_SERVICE_AGENT limit 1].Id;
		//check org cache only for SSSW-Service Agent Profile
		List<DetailLayoutSection> sections = (List<DetailLayoutSection>)CacheManager.get('CASEDETAILS_LAYOUTS',myCase.RecordTypeId);
		if(sections == null || UserInfo.getProfileId() != ServiceAgentProfID){

			// Edit the API version in the url callout to from v29 to v52
			String apiURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v52.0/sobjects/Case/describe/layouts/' + myCase.RecordTypeId;
			HttpRequest req = new HttpRequest();
			req.setEndpoint(apiURL);
			req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
			req.setMethod('GET');
			Http h = new Http();
			HttpResponse res = h.send(req);
			//System.Debug(res.getBody());
			JSONParser parser = JSON.createParser(res.getBody());
			LayoutAPIRoot root = (LayoutAPIRoot)parser.readValueAs(LayoutAPIRoot.class);

			//List<DetailLayoutSection> sections = root.editLayoutSections;
			sections = root.editLayoutSections;
			//cache only for SSSW Service Agent Profile
			if(UserInfo.getProfileId() == ServiceAgentProfID) {
				CacheManager.put('CASEDETAILS_LAYOUTS', myCase.RecordTypeId, sections);
			}

		}


		// Nandan - Added for HLC CR (REQ0490484) to render HLC section for agents part of HLC / CR Queue
		String queueType = HLCUtility.getAgentQueueType(UserInfo.getUserId());
		showOwnerPanel = String.isNotBlank(queueType) && (myCase.isHLC__c || myCase.isCR__c) ? true : false;	// change ownership rendered only for HLC/Cr agent

		sections = HLCUtility.getSectionsBasedOnAccess(sections);
		//System.Debug('** sections ==>'+ sections);
		sectionDetails = new List<SectionDetail>();
		Map<string, integer> sameGroupNameIndexMap = new Map<string, integer>();
		Map<string, string> groupNames = new Map<string, string>();
		Map<string, string> sectionsDisplayOnLoadMappings = new Map<string, string>();
		for(DetailLayoutSection s: sections) {
			SectionDetail sd = new SectionDetail(s.heading,null);
			if(sd.groupName != null && !groupNames.containsKey(sd.groupName)) {
				system.debug('# adding group name = |' + sd.groupName +'|');
				groupNames.put(sd.groupName, sd.groupTag);
				sectionsDisplayOnLoadMappings.put(sd.groupTag, '');
			}
		}

		for(DetailLayoutSection s: sections) {
			if(s.useHeading && !s.useCollapsibleSection) {
				List<FieldDetail> fieldList = new List<FieldDetail>();
				for(LayoutRow r: s.layoutRows){
					for(LayoutItem li: r.layoutItems){
						if(!string.isEmpty(li.label)) {
							for(LayoutComponent c: li.layoutComponents){
								if(c.details != null) {
									string label = '';
									if(caseFieldLabelling.get((c.details.name + myCase.EnquirySubType__c).toLowerCase())!=null)
									{
										label = caseFieldLabelling.get((c.details.name + myCase.EnquirySubType__c).toLowerCase()).CaseFieldLabel__c;
									} else
									{
										label = li.label;
									}
									// Change 'li.editable' to 'li.editableForUpdate' in the condition below due to changes in payload coming from API v31 onward
									FieldDetail d = new FieldDetail(label,c.details.name, li.required,c.details.type, li.editableForUpdate && c.details.updateable);
									if(groupNames.containsKey(label)){
										//System.Debug('# flagging field label = ' + label);
										d.groupTag = groupNames.get(label);
										d.isDynamicDisplay = true;
										sectionsDisplayOnLoadMappings.put(d.groupTag, c.details.name);
									}
									fieldList.add(d);
									query += ', ' + c.details.name;
									fieldArray += ',"' + c.details.name + '"';
								}
							}
						}
					}
				}
				if(!fieldList.isEmpty()) {
					SectionDetail newSectionDetail = new SectionDetail(s.heading,fieldList);
					if(sameGroupNameIndexMap.containsKey(newSectionDetail.groupTag)){
						sameGroupNameIndexMap.put(newSectionDetail.groupTag, sameGroupNameIndexMap.get(newSectionDetail.groupTag) + 1);
					}else{
						sameGroupNameIndexMap.put(newSectionDetail.groupTag, 0);
					}

					newSectionDetail.index = sameGroupNameIndexMap.get(newSectionDetail.groupTag);

					List<string> labelParts = newSectionDetail.myLabel.split(',', 0);
					if(labelParts.size() > 1){
						//System.Debug('>> Label has multi-parts: ' + labelParts.size());
						for(string l: labelParts) {
							//System.Debug('>> part: ' + l);
							SectionDetail cloned = newSectionDetail.clone();
							cloned.myLabel = l;
							sectionDetails.add(cloned);
						}
					}else{
						sectionDetails.add(newSectionDetail);
					}
				}
			}
		}

		if(!query.contains('ArticleTest__c'))
		{
			query += ', ArticleTest__c';
			fieldArray += ',"ArticleTest__c"';
		}
		if(!query.contains('Type'))
		{
			query += ', Type';
			fieldArray += ',"Type"';
		}
		if(!query.contains('ProductCategory__c'))
		{
			query += ', ProductCategory__c';
			fieldArray += ',"ProductCategory__c"';
		}
		if(!query.contains('ProductSubCategory__c'))
		{
			query += ', ProductSubCategory__c';
			fieldArray += ',"ProductSubCategory__c"';
		}

		if(!query.contains('recordTypeId'))
		{
			query += ', recordTypeId';
			fieldArray += ',"recordTypeId"';
		}
		if(!query.contains('RecordType.Name'))
		{
			query += ', RecordType.Name';
		}

		query += ',contact.MailingDPID__c,contact.MailingCountry,contact.MailingStreet,contact.MailingStreet2__c,contact.MailingCity,contact.MailingState,contact.MailingPostalCode,contact.name,contact.account.name,contact.email,Type_and_Product__c';

		query = includeField(query,'Address1Line1__c');
		query = includeField(query,'Address1Country__c');
		query = includeField(query,'Address1DPID__c');
		query = includeField(query,'Address1line2__c');
		query = includeField(query,'Address1Postcode__c');
		query = includeField(query,'Address1State__c');
		query = includeField(query,'Address1Suburb__c');

		query = includeField(query,'Address2Line1__c');
		query = includeField(query,'Address2Country__c');
		query = includeField(query,'Address2DPID__c');
		query = includeField(query,'Address2line2__c');
		query = includeField(query,'Address2Postcode__c');
		query = includeField(query,'Address2State__c');
		query = includeField(query,'Address2Suburb__c');

		query = includeField(query,'Owner.Email');
		query = includeField(query,'FacilityOrOutletWCC__c');

		// Add below fields into the Query to load on the Case layout
	// From v44 onward, only field specified in SELECT Query can be accessed in the code. Else, runtime error on SOQL query is observed.
		query = includeField(query,'BSP_Sender_Name__c');
		query = includeField(query,'BSP_Sender_Address__c');
		query = includeField(query,'BSP_Sender_Company__c');
		query = includeField(query,'BSP_Addressee_Name__c');
		query = includeField(query,'BSP_Addressee_Address__c');
		query = includeField(query,'BSP_Addressee_Company__c');
		query = includeField(query,'Address3__c');
		query = includeField(query,'Address3Line2__c');
		query = includeField(query,'Address3Suburb__c');
		query = includeField(query,'Address3State__c');
		query = includeField(query,'Address3Postcode__c');
		query = includeField(query,'Address3Country__c');
		query = includeField(query,'Address4__c');
		query = includeField(query,'Address4Line2__c');
		query = includeField(query,'Address4Suburb__c');
		query = includeField(query,'Address4State__c');
		query = includeField(query,'Address4Postcode__c');
		query = includeField(query,'Address4Country__c');

		// Fix INC1859157, INC1859449 SOQL fix
		query = includeField(query,'ReferenceID__c');
		query = includeField(query,'Status');
		query = includeField(query,'EnquirySubType__c');

		query += ',articleTest__r.Name,articleTest__r.ExpectedDeliveryDate__c,contact.isPersonAccount,OwnerId from Case where Id = :caseid limit 1';
		id caseid = myCase.id;
		string caseType = myCase.Type;
		string productCategory = myCase.ProductCategory__c;
		String productSubCategory = myCase.ProductSubCategory__c;
		id recordTypeId = myCase.RecordTypeId;
		myCase = database.query(query);
		if(maintainValues) {
			myCase.recordTypeId = recordTypeId;
			myCase.Type = caseType;
			myCase.ProductCategory__c = productCategory;
			myCase.ProductSubCategory__c = productSubCategory;
		}

		myCase.Type_and_Product__c = myCase.Type + '|' + myCase.ProductCategory__c + '|' + myCase.ProductSubCategory__c;

		sectionsDisplayOnLoad = '';
		for(string key: sectionsDisplayOnLoadMappings.keySet()){
			sectionsDisplayOnLoad += ',"' + key + '":"' + myCase.get(sectionsDisplayOnLoadMappings.get(key)) + '"';
		}
		if(sectionsDisplayOnLoad != ''){
			sectionsDisplayOnLoad = '[{' + sectionsDisplayOnLoad.substring(1) + '}]';
		}

		fieldArray = fieldArray.substring(1);
		//System.Debug('%% sectionsDisplayOnLoad = ' + sectionsDisplayOnLoad);
		//System.Debug('%% record type id = ' + myCase.recordTypeId);
		//System.Debug('%% type = ' + myCase.Type);
		//System.Debug('%% product category = ' + myCase.ProductCategory__c);
	}


	string includeField(string query, string fieldName){
		if(!query.contains(fieldName)){
			query += ',' + fieldName;
		}
		return query;
	}

	class SectionDetailsJSON{
		public List<SectionDetail> sectionDetails {get;set;}
	}

	class LayoutItem {
		// editableForUpdate replaces old field 'editable' from v31 onward
		public boolean editableForUpdate {get; set;}
		public string label { get; set; }
		public List<LayoutComponent> layoutComponents { get; set; }
		public boolean required { get; set; }
	}

	class LayoutRow {
		public List<LayoutItem> layoutItems { get; set; }
	}

	class LayoutAPIRoot {
		public List<DetailLayoutSection> detailLayoutSections {get;set;}
		public List<DetailLayoutSection> editLayoutSections {get;set;}
	}

	// Nandan - Added public keyword for reference in HLCUtility
	public class DetailLayoutSection {
		public string heading { get; set; }
		public List<LayoutRow> layoutRows { get; set; }
		public boolean useHeading {get;set;}
		public boolean useCollapsibleSection {get;set;}
	}

	class Details {
		public string label { get; set; }
		public string name { get; set; }
		public string type { get; set; }
		public boolean updateable {get;set;}
	}

	class LayoutComponent {
		public Details details { get; set; }
		public integer displayLines { get; set; }
		public integer tabOrder { get; set; }
		public string type { get; set; }
		public string value { get; set; }
	}

	//added by kalpita for new case management - reassign
	public Boolean isChildCase {get;set;}
	private static final Map<String,String> CUST_TYPE_QUEUE_MAP = new Map<String,String>{'International' => 'SSSW_BOH_Group_1',
	'Consumer' => 'SSSW_BOH_Group_4',
	'Enterprise' => 'SSSW_BOH_Group_1',
	'SMB' => 'SSSW_BOH_Group_2',
	'Silver' => 'SSSW_BOH_Group_2',
	'MyPost Business' => 'SSSW_BOH_Group_3',
	'Gold' => 'SSSW_BOH_Group_2'};

	private static final String REOPEN_QUEUE_NAME = 'SSSW Awaiting Reopen';
	private static final String DAMAGES_IN_TRANSIT = 'Damages in transit';
	private static final String ROUTING_FALSE = 'false';
	private static final String LOC_INTERNATIONAL = 'International';
	private static final String SOCIAL_ORIGIN = 'Social';
	private static final String ROUTING_TRUE = 'true';
	private static Map<Id,Group> groupIdMap = new Map<Id,Group>();
	public String assignedQueueName {get;set;}
	public String skillsList { get; set; }

	/////////////////////// Can be removed after next deployment
	public Boolean isAssign {get;set;}
	public Boolean notAllowedToReassign {get;set;}
	public Boolean sameOwner {get;set;}
	public Boolean doUpdate {get;set;}
	private static Set<String> NON_CLOSED_STATUSES = new Set<String>();
	private static Map<String,Group> groupNameMap = new Map<String,Group>();
	public static Map<String,String> groupNameMapUI {get;set;}
	/////////////////////// Can be removed after next deployment

	public Boolean noAssignmentSameMembershipError { get; set; }
	public Boolean noAssignmentSameSkillsError { get; set; }
	public Boolean noAssignmentCaseClosedError { get; set; }

	/**
	  * @description	   This method will check the new case assign logic and based on routing rules, assign case to respective owner
	  * @param			 NA
	  * @return			Void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	public void assignCase(){
		//Save the remediation fields into the article if applicable
		if(remediationAvailable && relatedArticle.Id != null && validateRemediationData()) {
			saveArticles();
		} else if(remediationAvailable && relatedArticle.Id != null && !validateRemediationData()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure that all Remediation fields are completed before initiating an article/consignment remediation.');
			ApexPages.addMessage(myMsg);
		}

		try{

			QM__c queueSettings = QM__c.getInstance();
			Id temporaryReassignmentQueue = queueSettings.TemporaryReassignmentQueue__c;
			String awaitingReopenQueueId = [Select Id from Group where Name = :REOPEN_QUEUE_NAME limit 1].Id;

			skillsList = '';
			noAssignmentSameMembershipError = false;
			noAssignmentSameSkillsError = false;
			noAssignmentCaseClosedError = false;

			//check if case has child cases
			//check if case has child cases of status - awaiting n/w response
			Boolean setParentCaseToAwaitingReopen = false;
			for(Case childCaseRecord: [Select Id, Status from Case where parentId =: mycase.id]) {
				if(SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE.equalsIgnoreCase(childCaseRecord.Status)) {
					setParentCaseToAwaitingReopen = true;
				}
				if(SSSWConstants.STAT_AWAITING_CUST_RESPONSE.equalsIgnoreCase(childCaseRecord.Status) && DAMAGES_IN_TRANSIT.equalsIgnoreCase(myCase.EnquirySubType__c )) {
					setParentCaseToAwaitingReopen = true;
				}
				if(setParentCaseToAwaitingReopen) {
					break;
				}
			}

			if(setParentCaseToAwaitingReopen) {
				ApplicationDatabase.getInstance().dmlUpdate(new List<Case>{new Case(Id = mycase.Id, OwnerId = awaitingReopenQueueId)});
				return;
			}

			//routing.

			Case caseToBeRouted = reassignCase.clone(true);
			Id previousOwnerId = caseToBeRouted.OwnerId;

			if(caseToBeRouted.IsClosed) {
				noAssignmentCaseClosedError = true;
				return;
			}

			System.debug('caseToBeRouted: ' + caseToBeRouted);

			// force rerouting to occur
			SSSW_Routing.reassignNoCheckOwnerQueue = True;
			caseToBeRouted.AllocateToQueue__c = true;

			if(!String.isBlank(caseToBeRouted.Description)) {
				SSSW_Routing.FlipReassignDescription();
			}

			// simulate the new owner but do not update the record yet!
			SSSW_Routing.assignCasesAndDescription(new List<Case>{caseToBeRouted}, null, false, false, true);

			System.debug('current owner: ' + previousOwnerId);
			System.debug('new simulated owner: ' + caseToBeRouted.OwnerId);

			// check to see if the user is a part of queue membership of the assigned queue
			// if they are then we do not let routing proceceed
			Boolean simulatedQueueIsServicedByCurrentUser = groupIds.contains(caseToBeRouted.OwnerId);
			if(!simulatedQueueIsServicedByCurrentUser) {
				Boolean simulatedQueueIsOmniQueue = OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(caseToBeRouted.OwnerId);

				if(simulatedQueueIsOmniQueue) {
					// set save point so we can revert the update to omni queue (if applicable). We need the PSR in order to compare the target skills vs the skills of the current agent.
					// If they are the same then the whole process should be reverted and show an error message to the user.
					Savepoint sp = Database.setSavepoint();

					// check to see if we need to move the case to a temporary queue if the new owner is the same as the previous
					// just because the new owner is the same, down 't mean the updated skills will be the same
					if(caseToBeRouted.OwnerId == previousOwnerId) {
						ApplicationDatabase.getInstance().dmlUpdate(new List<Case>{new Case(Id = caseToBeRouted.Id, OwnerId = temporaryReassignmentQueue)});

						// We reset this dodgy flag so status tracking is regenerated on the next update...
						// TODO: get rid of silly flag :D 
						CaseTrackingHelper.isUpdateStatusTrackRecursive = false;
					}

					// trigger an update to the owner which will generate a PSR and a set of skill requirements
					ApplicationDatabase.getInstance().dmlUpdate(new List<Case>{new Case(Id = caseToBeRouted.Id, OwnerId = caseToBeRouted.OwnerId, BypassPreferredAgent__c = true, Comment__c = caseToBeRouted.Comment__c)});

					Map<Id, PendingServiceRouting> psrs = new Map<Id, PendingServiceRouting>(PendingServiceRoutingSelector.newInstance().selectByWorkItemId(new Set<Id>{caseToBeRouted.Id}, new Set<Object>()));
					System.debug('psrs: ' + psrs);
					if(!psrs.isEmpty()) {

						List<SkillRequirement> skillsRequirements = SkillRequirementSelector.newInstance().selectByRelatedRecordIds(psrs.keySet(), new Set<Object>{SkillRequirementSelector.Options.WITH_SKILLS});
						System.debug('skillsRequirements: ' + skillsRequirements);
						for(SkillRequirement sr : skillsRequirements) {
							System.debug('sr.Skill: ' + sr.Skill);
						}
						if(!skillsRequirements.isEmpty()) {

							Map<Id, Decimal> userSkillIdVsSkillLevel = new Map<Id, Decimal>();
							for(ServiceResourceSkill srs: ServiceResourceSkillSelector.newInstance().selectByActiveServiceResourceRelatedRecordIds(new Set<Id>{ previousOwnerId }, new Set<Object>())) {
								userSkillIdVsSkillLevel.put(srs.SkillId, srs.SkillLevel);

							}

							Boolean hasAllSkills = true;
							for(SkillRequirement sr: skillsRequirements) {
								// if previous owner does not have the same skill or does have the same skill but lower level then it is a mis-match.
								if(!userSkillIdVsSkillLevel.containsKey(sr.SkillId) || userSkillIdVsSkillLevel.get(sr.SkillId) < sr.SkillLevel) {
									hasAllSkills = false;
									break;
								}
							}

							for(SkillRequirement sr: skillsRequirements) {
								skillsList += (!String.isEmpty(skillsList) ? ', ' : '') + sr.Skill.MasterLabel;
							}

							// user has all the required skills so we should revert the update and show the error to the user.
							if(hasAllSkills == true) {
								ApplicationDatabase.getInstance().dmlRollback(sp);
								noAssignmentSameSkillsError = true;
							}
						} else {
							// no skills which could mean its a queue based assignment or there were no skills mapped
							// either way we allow the update to occur
						}
					} else {
						// something went wrong
						ApplicationDatabase.getInstance().dmlRollback(sp);
						noAssignmentSameSkillsError = true;
					}
				} else {
					// trigger an update to the owner to reassign the case
					ApplicationDatabase.getInstance().dmlUpdate(new List<Case>{new Case(Id = caseToBeRouted.Id, OwnerId = caseToBeRouted.OwnerId, Comment__c = caseToBeRouted.Comment__c)});
				}
			} else {
				// Case can not be reassigned since user is in the queue membership of the assigned queue
				noAssignmentSameMembershipError = true;
			}
		} catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					CaseDetailsCaseContExt.class.getName(), 'assignCase',
					'', LoggingLevel.ERROR);
		}
	}

	/**
	  * @description	   This method sets key value pair of case & routing key
	  * @param			 myCase - Case, caseOriginKeyMap - Map<Id,String>, caseNoOriginKeyMap - Map<Id,String>
	  * @return			void
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	private static void setCaseKeyMap(Case myCase,Map<Id,String> caseOriginKeyMap,Map<Id,String> caseNoOriginKeyMap, String custType ){
		String keyWithOrigin = SSSWConstants.EMPTY_SPACE ;
		String keyWithOutOrigin = SSSWConstants.EMPTY_SPACE ;
		keyWithOrigin = String.isNotBlank(myCase.ProductCategory__c) ? (keyWithOrigin + myCase.ProductCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(myCase.ProductSubCategory__c) ? (keyWithOrigin + myCase.ProductSubCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(myCase.Type) ? (keyWithOrigin + myCase.Type) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(myCase.EnquirySubType__c) ? (keyWithOrigin + myCase.EnquirySubType__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(custType) ? (keyWithOrigin + custType ) : keyWithOrigin;
		keyWithOrigin = (myCase.IsNewForRouting__c != null && myCase.IsNewForRouting__c) ?
				(keyWithOrigin + ROUTING_TRUE) : (keyWithOrigin + ROUTING_FALSE);

		keyWithOutOrigin = keyWithOrigin ;

		keyWithOrigin = String.isNotBlank(myCase.Origin) ? (keyWithOrigin + myCase.Origin) : keyWithOrigin;

		caseOriginKeyMap.put(myCase.Id,keyWithOrigin);
		caseNoOriginKeyMap.put(myCase.Id,keyWithOutOrigin);
	}

	/**
	  * @description	   This method returns the sssw routing records for the case combination
	  * @param			 caseKeys - Set<String>
	  * @return			Map<String,SSSWRouting__c>
	  * @throws			Method might throw exception which is handled by Try-Catch block
	  */
	private static Map<String,SSSWRouting__c> getSSSWRoutings(Set<String> caseKeys){
		Map<String,SSSWRouting__c> routingMap = new Map<String,SSSWRouting__c>();
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		for(SSSWRouting__c routing : [SELECT Network__c,CaseKey__c,ExcludeFromNPS__c,DefaultCaseDetails__c,Queue_ID__c,AutoEscalate__c
		FROM SSSWRouting__c WHERE CaseKey__c IN: caseKeys ORDER BY CaseKey__c LIMIT : rowLimit]){
			routingMap.put(routing.CaseKey__c,routing);
		}
		return routingMap;
	}

	/**
	  * @name: groupIds
	  * @desciption: getter setter variable to get the groups the logged in user is part of
	  * @param: NA
	  * @return: set<ID>
	  *
	  */
	static set<ID> groupIds {
		get {
			if(groupIds == null) {

				groupIds = new set<ID>();
				set<id> userRolesId = new set<id>();
				set<id> groupRelatedId = new set<id>();

				for(GroupMember gm:[Select Group.Id From GroupMember
				where UserOrGroupId = :UserInfo.getUserId() //OR UserOrGroupId IN :groupRelatedId)
				and Group.Type = : SSSWConstants.QUEUE ]) {
					groupIds.add(gm.Group.Id);
				}
			}

			return groupIds;
		}
		// From SF API v42 onward, require 'set' also be declared alongside 'get'
		set;
	}

	public String senderCode {get;set;}
	public String receiverCode {get;set;}
	public Date lodgementDate {get;set;}

	/**
	  * @name: doCalculate
	  * @desciption: method called from UI to calculate EDD when data is filled in on the fly
	  * @param: NA
	  * @return: NA
	  *
	  */
	public void doCalculate() {
		if(!String.isblank(senderCode ) && !String.isblank(receiverCode ) && eddCase.DatePosted__c!=null) {
			calculateEDD(myCase);
		}
	}

	/**
	  * @name: calculateEDD
	  * @desciption: method to calculate the edd based on user input
	  * @param: Case myCase
	  * @return: NA
	  *
	  */
	void calculateEDD(Case testCase) {

		testCase = myCase;
		hasEdd = false;
		//System.Debug(myCAse);
		if(eddCase.DatePosted__c !=null && receiverCode!=null &&
				senderCode!=null &&  testCase.ProductSubCategory__c!= null) {
			AusPostSettings__c settings = AusPostSettings__c.getValues('EstimatedDeliveryDate');
			string dateSent = datetime.newInstance(eddCase.DatePosted__c, time.newInstance(0,0,0,0)).format('yyyyMMdd');
			string articleType = testCase.ProductSubCategory__c.tolowercase().contains('parcel') ? 'parcel' : 'letter';

			string url = settings.URL__c + '?from=' + senderCode.trim() + '&to=' + ReceiverCode.trim() +
					'&type=' + articleType + '&date=' + dateSent;
			//System.Debug('calling url = ' + url);
			HttpRequest req = new HttpRequest();
			req.setEndpoint(url);
			req.setMethod('GET');
			Blob headerValue = Blob.valueOf(settings.Username__c + ':' + settings.Password__c);
			//req.setHeader('AUTH-KEY', 'Basic ' + EncodingUtil.base64Encode(headerValue));
			req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
			req.setHeader('Content-Type','application/json');

			List<service> listOfServices = new List<service>();
			Http http = new Http();

			HttpResponse res;
			// modified by shengpeng.xiao@bluewolf.com at 2014.7.9, adjust for test class
			// Dion Gunn 15/05/2017 - modified back so it can be properly tested with a mock interface.
			//if(!Test.isRunningTest()) {
			res = http.send(req);
			//System.Debug('--response here---'+res);
			/*}else {
				String serviceJson = '{"ha":"ha","regular":{"serviceType":"regular","min":10,"max":20,"sla":"sla"}}';
				String errJson = '{"ha":"ha","regular":{"code":1,"description":"test"}}';
				res = new HttpResponse();
				res.setHeader('Content-Type', 'application/json');
				if(TestDataProvider.httpStatus == 200) res.setBody(serviceJson);
				else res.setBody(errJson);
				res.setStatusCode(TestDataProvider.httpStatus);
			} */
			if(res.getStatusCode() == 400 || res.getStatusCode() == 200){
				//System.Debug('Content from AusPost: ' + res.getBody());
				JSONParser parser = JSON.createParser(res.getBody());
				parser.nextToken();
				//System.Debug('1: ' + parser.getText());
				parser.nextToken();
				//System.Debug('2: ' + parser.getText());
				parser.nextToken();
				//System.Debug('3: ' + parser.getText());

				if(res.getStatusCode() == 200){
					while (parser.nextToken() != null) {
						//System.Debug('4: ' + parser.getText());
						string serviceType = parser.getText();
						parser.nextToken();
						if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
							service s = (service)parser.readValueAs(service.class);
							s.serviceType = serviceType;
							listOfServices.add(s);
							//System.Debug(s);
						}
					}
				} else if(res.getStatusCode() == 400){
					while (parser.nextToken() != null) {
						//System.Debug('7: ' + parser.getText());
						string serviceType = parser.getText();
						parser.nextToken();
						if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
							error e = (error)parser.readValueAs(error.class);
							hasEDD = true;
							dateString = 'Error: ' + e.description;
							break;
						}
					}
				}
			}else {
				hasEDD = true;
				dateString = 'Error: A Network error has occurred. Code: ' + res.getStatusCode();
				infoRequired = true;
				missingItemLodgedonAfter = false;
				missingItemLodged = false;
			}
			//System.Debug('--response here---'+res);
			string serviceType = REGULAR;
			if(testCase.ProductSubCategory__c.tolowercase().contains(COURIER)){
				serviceType = COURIER;
			} else if (testCase.ProductSubCategory__c.tolowercase().contains(EXPRESS)) {
				serviceType = EXPRESS;
			}
			//System.Debug('service type = ' + serviceType);

			if(listOfServices.size() > 0) {
				Service highestMax = null;
				Service userSelected = null;
				string maxDateString = '';
				for(Service s: listOfServices){
					//System.Debug('current service type = ' + s.serviceType);
					if(s.serviceType == serviceType && s.max != null){
						userSelected = s;
					}

					if(highestMax == null && s.max != null){
						highestMax = s;
					}else {
						if(s.max != null && s.max > highestMax.max){
							highestMax = s;
						}
					}
				}

				if(userSelected != null) {
					maxDateString = userSelected.max + '';
				}else {
					maxDateString =  (highestMax != null) ? (highestMax.max + '') : null;   // Nandan : added null check to fix INC0835553
				}
				//System.Debug('max = ' + maxDateString);

				if(maxDateString != null && maxDateString.length() == 8){
					hasEDD = true;
					integer yearPart = integer.valueOf(maxDateString.substring(0, 4));
					integer monthPart = integer.valueOf(maxDateString.substring(4, 6));
					integer dayPart = integer.valueOf(maxDateString.substring(6, 8));
					//System.Debug('year='+yearPart+',month='+monthPart+',day='+dayPart);
					date maxdate = date.newInstance(yearPart, monthPart, dayPart);
					//System.Debug(maxdate);
					//System.Debug(date.today());
					if(maxdate > date.today()){
						iconImageName = CONFIRM_IMG;
					}else if(maxdate < date.today()){
						iconImageName = ERROR_IMG;

					} else {
						iconImageName = WARNING_IMG;
					}


					Integer wrkingDays = 0;
					Integer noOfDays = testCase.ProductSubCategory__c.tolowercase().contains(EXPRESS) ? 1 : 3;
					Date tempDate = testCase.ProductSubCategory__c.tolowercase().contains(EXPRESS) ?  maxDate + 1 : maxDate + 3;
					//System.Debug('--+maxDate'+maxDate);
					Date tempOld;
					//date and date + 1day
					Boolean noWorkingDay = true;
					Date startDate = maxDate;
					Date endDate = tempDate;
					Set<Date> datChecked = new Set<Date>();
					Integer count = 0;
					while(noWorkingDay) {
						//System.Debug('--+startDate '+startDate );
						//System.Debug('--+endDate '+endDate );
						count = 0;
						for(Integer i=1; i<=noOfDays;i++) {
							if(!datChecked.contains(startDate+i) && !checkifItisWorkingDay(startDate+i)) { count++ ; }
							datChecked.add(startDate+i);
							//System.Debug('--+count '+count );
						}
						noWorkingDay = count != 0;
						startDate += count;
						endDate += count;
					}
					if(endDate < system.today()) {
						missingItemLodged = true;
						infoRequired = false;
						missingItemLodgedonAfter = false;
					}
					else {
						onAfterDate = endDate;
						missingItemLodgedonAfter = true;
						missingItemLodged = false;
						infoRequired = false;
					}

					dateString = dayPart + '/' + (monthPart < 10 ? '0' + monthPart: monthPart + '') + '/' + yearPart;
				} else {
					hasEDD = true;
					dateString = 'Error: Unable to retrieve Estimate Delivery Date';
				}
			}
		}
		else {
			infoRequired = true;
			missingItemLodgedonAfter = false;
			missingItemLodged = false;
		}

		for(EventMessage__c em: [Select id, EventDescription__c from EventMessage__c where CommentText__c Like '%delayed%' and Article__c =:testCase.ArticleTest__c]) {
			missingItemDelayed = true;
			infoRequired = false;
			missingItemLodgedonAfter = false;
			missingItemLodged = false;
		}

	}

	List<Holiday> holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];

	public boolean checkifItisWorkingDay(Date currentDate){
		Date weekStart  = currentDate.toStartofWeek();
		//System.Debug('--+'+weekStart+'--+'+currentDate);
		if(weekStart.daysBetween(currentDate) ==6 || weekStart.daysBetween(currentDate) == 0){
			//System.Debug('--+ sat/sun');
			return false;
		}

		for(Holiday hDay:holidays){
			if(currentDate.daysBetween(hDay.ActivityDate) == 0 ){
				//System.Debug('--+ pib hol');
				return false;
			}
		}
		return true;
	}


	public class error {
		public string code {get;set;}
		public string description {get;set;}
	}

	public class service {
		public string serviceType {get;set;}
		public integer min {get;set;}
		public integer max {get;set;}
		public string sla {get;set;}
	}

}