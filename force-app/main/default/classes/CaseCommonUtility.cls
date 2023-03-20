/**
  * @author	   : nandan.narasappa@auspost.com.au
  * @date		 : 16/09/2015
  * @description  : Utility Class for Case Triggers
  * @changelog
	Date				User										Comments
	28/09/2015		nandan.narasappa@auspost.com.au			 Added validateCase method
	29/09/2015		nandan.narasappa@auspost.com.au			 Added detectPermanentSpam, closeChildCases, avoidCustomerClose
																	setOwnerToCurrentUser , setArticlesSubscribed & linkCaseToArticles methods
	17/11/2015		nandan.narasappa@auspost.com.au			 Added routeCase method
	20/01/2016		nandan.narasappa@auspost.com.au			 updated linkCaseToArticles to skip API call for unknown articles
	14/04/2016		cliew@salesforce.com						Added entry to CUST_TYPE_QUEUE_MAP for supporting new Customer Type (Case)
																	/ Service SLA (Account) introduced as part of MyPost Business Portal implementation
	25/08/2016		david.e.catindoy@accenture.com			  Added closeRelatedTasksAndWFEmails method to cater additional processes on StarTrack closed cases.
	29/08/2016		eric.shen@auspost.com.au					Add the logic in routeCase that DefaultCaseDetails fields will be appended to case description when case description is empty or a new case, bug fix for INC0699609
	06/09/2016		eric.shen@auspost.com.au					Create a new method to call linkCaseToArticles method to be used in Snap It case for Missing Item enquiry.
	12/10/2016		david.e.catindoy@accenture.com			  Added notificationAutomationModel method to cater StarTrack automated sending of email and SMS notification.
	08/03/2017		david.e.catindoy@accenture.com			  Transferred closeRelatedTasksAndWFEmails method into StarTrackUtil class to let user close the tasks that they don't own when the parent case record was closed.
	18/04/2017		ajudd@salesforce.com						Minor update to notificationAutomationModel to remove SELECT statement
	12/05/2017		scherukuwada@salesforce.com				 If BSP User created Case, then search for the Article in Salesforce first
	15/05/2017		angelo.rivera@auspost.com.au				Added API for handling SNAP IT cases
	08/09/2017		maumita.bandyopadhyay@auspost.com.au		Added logic to consider only Closed cases for NPS
	2017-10-05		nathan.franklin@auspost.com.au			  Commented out linkCaseToArticles, processSnapitMissingItem and invokeTibcoService as they are no longer required.
																	This functionality is now in CaseArticleUtility
	2017-11-13		maumita.bandyopadhyay@auspost.com.au		Modified to Fix the error INC1035423
	2018-07-05		disha.kariya@auspost.com.au		 Modified checkOriginChangeForNPS method
	2018-07-12		nathan.franklin@auspost.com.au	  Removed checkOriginChangeForNPS and checkNPS method 
	2019-02-18		swati.mogadala@auspost.com.au				Modified Cloasechildcase() to popultaechildcase 'Resolution Result' when closing REQ1692813
	2019-03-18		gunith.devasurendra@auspost.com.au		  Added RecursionUtils to identify if AllocateToQueue__c is modified.
	2019-05-06		gunith.devasurendra@auspost.com.au		  Convert Workflow logic to route Cases when state is 'new'ed
	2019-05-06		Edmarco - Mav3rik						   Added logic to allow defined profiles to close case (validateCase Method)
	2019-05-08		seth.p.heang@accenture.com				  Added logic to populate requestor field with current user in 'CAR' case if it's left empty
	2020-04-18		Nathan Franklin - Changed a BSP Profile check to a permission check
	2020-08-20		Nathan Franklin - Refactored
	2020-10-15		naseer.abbasi@auspost.com.au				Updated routeCase() with isInsert parameter
	2020-10-30		naseer.abbasi@auspost.com.au				Updated assignContactIdToCase() to include H&S cases, also updated validateCase to skip H&S cases for duplicates
	2020-11-17		Ranjeewa Silva							  Allow cases with record type "Social Record Type" to be routed based on the rules in SSSW_Routing
	2020-11-25		Ranjeewa Silva							  Fix for a Production Issue - where duplicate contact records are created when guest users submit cases via Help and Support portal.
	2020-01-25		Hara Sahoo								  Modified assignContactIDToCase to allow portal cases via CHAS H&S forms.
	2021-08-26		Steve Judd								  Modified notificationAutomationModel for new Network fields for MW0004540
	2021-09-23		Steve Judd								  Added method for autoCaseClosure and modified compareRec for MW00045402
	2021-09-26		Steve Judd								  Moved method for autoCaseClosure to StarTrack_Constants to allow for reuse
	16.05.2022		SaiSwetha Pingali						   Removed snapIt logic as it is no longer required.
	2022-11-17		Noel Lim									Added 2 routing logic relating to Closed Cases added in routeCase(), a) Reopened Cases in SSSW Closed Omni queue are to be routed b) Closed Cases in an Omni Queue are moved to the SSSW Closed Omni queue
	2023-02-13		Noel Lim									Add logic for Preferred Agent routing in routeCase(), and new method processPreferredAgent()
	2023-03-08		Noel Lim									Add Release 2 TEMPORARY FIX - exclude Preferred Agent routing for cases from portals
	2023-03-17		Noel Lim									Add criteria to routing engine, to allow routing when AllocateToQueue = true only if Owner is not a User, Owner is not the Omni Holding Queue, or Owner is a User but Case is Closed


	************************************************/
	public with sharing class CaseCommonUtility{

	// Constants
	private static final String EMAIL_ORIGIN = 'Email';
	private static final String SOCIAL_ORIGIN = 'Social';
	private static final String ROUTING_TRUE = 'true';
	private static final String ROUTING_FALSE = 'false';
	private static final String LOC_INTERNATIONAL = 'International';
	private static final Set<String> SKIP_CASE_ORIGIN = new Set<String>{'Portal','Email'};  // set of case origins to ignore
	private static final Set<String> SKIP_LINK_ARTICLE_ORIGIN = new Set<String>{'Phone','AP Retail (PM26)'};  // set of case origins to ignore'
	private static final Set<String> SKIP_DUPLICATE_CHECK_BY_ORIGIN = new Set<String>{'Portal'};  // set of case origins to ignore in duplication check

	// CLIEW 14/4/2016: added additional queue map entry for MyPost Business
	private static final Map<String,String> CUST_TYPE_QUEUE_MAP = new Map<String,String>{'International' => 'SSSW_BOH_Group_1',
																							'Consumer' => 'SSSW_BOH_Group_4',
																							'Enterprise' => 'SSSW_BOH_Group_1',
																							'SMB' => 'SSSW_BOH_Group_2',
																							'Gold' => 'SSSW_BOH_Group_2',
																							'MyPost Business' => 'SSSW_BOH_Group_3'};
	private static final Set<String> DEF_QUEUE_SET = new Set<String>{'SSSW_BOH_Group_1','SSSW_BOH_Group_2','SSSW_BOH_Group_3','SSSW_BOH_Group_4'};

	private static final Set<String> ST_CASE_AUTOCLOSE_TEMPLATES = new Set<String>{'StarTrack Redirection Notification - Customer Service','StarTrack Depot Collection Notification - Customer Service', 'StarTrack Check Address Notification - Customer Service'};

	// variables
	public static Boolean isCaseValidated = false;	  // flag to prevent validating case recursively
	public static Boolean isCaseLocalitySet = false;	  // flag to prevent validating case recursively
	public static Boolean isCloseChildCaseRecursive = false;	  // flag to prevent closing child case recursively
	public static Boolean isXferCaseRecursive = false;	  // flag to prevent transfer case recursively
	public static Boolean isCustCloseRecursive = false;	  // flag to prevent recursive customer close invoke
	public static Boolean isArticleSubscribeRecursive = false;	  // flag to prevent recursive article subscription
	public static Boolean isParentCaseUpdateRecursive = false;
	public static Boolean isReferenceIDUpdateRecursive = false;

	public static Boolean isNotifyAutoRecursive = false;
	public static Boolean isduplicateSTRcursive = false;

	private static Set<String> NON_CLOSED_STATUSES = new Set<String>();
	private static Set<Id> validRecTypes;
	private static Set<Id> socialAndSsswRecordTypeIds;

	/**
	 * List of cases that have already been processed for Preferred Agent in this transaction.
	 * There are exception cases where the routing engine will be triggered 2x, such as when a customer responds to a case via Email-to-Case.
	 * In this situation, preferred Agent logic can fire twice and attempt to generate a 2nd PSR for the same Case, which will encounter an Exception and negate the Preferred Agent logic applied in the 1st run.
	 */
	private static Set<Id> m_processedPreferredAgentCaseIds = new Set<Id>();

	private static Map<Id,Group> groupIdMap = new Map<Id,Group>();
	private static Map<String,Group> groupNameMap = new Map<String,Group>();
	//MW004540 Added for determining if user has Autoclosure permission
	private static Boolean isAutoCloseEnabled = false;

		static Map<Id, Group> omniGroups {
			get {
				if(omniGroups == null) {
					omniGroups = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());

					// The Preferred Agent Queue is a "simulated" Omni queue used by the Preferred Agent logic. If there is a preferred agent for the case, then a PSR is created and the case is assigned to this queue
					// We need to include that queue here so that if the Case is Closed whilst in this queue, it should also move to the graveyard. 
					omniGroups.put(OmniChannelService.getInstance().preferredAgentQueueId, new Group(Id = OmniChannelService.getInstance().preferredAgentQueueId));
				}
				return omniGroups;
			}
			private set;
		}
			
		static{
			try{
				// fetch all non-closed status values of case
				if(NON_CLOSED_STATUSES.isEmpty()){
					
					for(Schema.PicklistEntry pickList : Case.Status.getDescribe().getPicklistValues()){
						if(!SSSWConstants.STAT_CLOSED.equalsIgnoreCase(pickList.getValue())){   // check if status is not closed
							NON_CLOSED_STATUSES.add(pickList.getValue());
						}
					}
				}
				// get all valid record types for the SSSW functionality
				validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);

			// Get social Record types
			Set<Id> socialRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()), 'Social');

			socialAndSsswRecordTypeIds = new Set<Id>(validRecTypes);
			socialAndSsswRecordTypeIds.addAll(socialRecTypes);

			groupIdMap = Utility.getGroups(SSSWConstants.QUEUE);
			if(!groupIdMap.isEmpty()){
				for(Group grp : groupIdMap.values()){   // fetch queues to create group map
					groupNameMap.put(grp.DeveloperName,grp);
				}
			}
			isAutoCloseEnabled = StarTrack_Constants.CURRENT_USER_CAN_AUTO_CLOSE_CASE_FROM_TASK;

		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseMilestoneUtility.class.getName(), SSSWConstants.STATIC_BLOCK,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}


	/**
	 * @description	   This method assign cases to existing contact based on supplied email,
						creates new contact if doesn't exist.
	* @param			 caseList - List<Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void assignContactIDToCase(List<Case> caseList){
		List<Case> emailCases = new List<Case>();		   // list of cases with email origin
		List<Case> shortListedCases = new List<Case>();	 // list of cases with name & email populated
		Set<String> emailSet = new Set<String>();		   // set of email addresses
		Map<String,List<Contact>> contactsMap = new Map<String,List<Contact>>();	// map of email and list of contacts
		Map<String,Contact> uniqueContactMap = new Map<String,Contact>();		   // map of name & email combination & contact

		try{
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					if(String.isNotBlank(caseRec.SuppliedEmail)){   // verify if email is populated
						// verify if case origin is not portal, contact Id is not provided & customer details provided in case
						if(!SKIP_CASE_ORIGIN.contains(caseRec.Origin) && caseRec.ContactId == null 
							&& String.isNotBlank(caseRec.First_Name__c) && String.isNotBlank(caseRec.Last_Name__c)) {
								emailSet.add(caseRec.SuppliedEmail);
								shortListedCases.add(caseRec);
							}
						else if(EMAIL_ORIGIN.equalsIgnoreCase(caseRec.Origin)){  // verify if origin is email
							emailSet.add(caseRec.SuppliedEmail);
							emailCases.add(caseRec);
						}
					}
					//verify if case enquiry type is one of the CHAS Enquiry Types and Origin is Portal
						if(String.isNotBlank(caseRec.CHASEnquiryType__c) && CHASConstants.CHAS_ENQUIRY_TYPE.contains(caseRec.CHASEnquiryType__c) && caseRec.ContactId == null && caseRec.Origin == 'Portal'
							&& String.isNotBlank(caseRec.First_Name__c) && String.isNotBlank(caseRec.Last_Name__c)) {
								emailSet.add(caseRec.SuppliedEmail);
								shortListedCases.add(caseRec);
						}
				}
			}

			if(!emailSet.isEmpty()){
				populateContactMaps(emailSet,contactsMap,uniqueContactMap); // method gets contact details required to link with case

				handleContactAssignment(emailCases,contactsMap,uniqueContactMap,false);
				handleContactAssignment(shortListedCases,contactsMap,uniqueContactMap,true);
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_ASSIGN_CONTACT,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description	   This method populates contact map - contactsMap,uniqueContactMap
	* @param			 emailSet - Set<String>, contactsMap - Map<String,List<Contact>>,
						uniqueContactMap - Map<String,String>
	* @return			Void
	* @throws			Method might throw exception which is handled by calling method
	*/
	private static void populateContactMaps(Set<String> emailSet,Map<String,List<Contact>> contactsMap,
												Map<String,Contact> uniqueContactMap){

		String key;
		List<Contact> tmpContacts = new List<Contact>();
		Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
		// Fetch all contacts based on email addresses
		// Use 'WithoutSharingDataAccessHelper' to make the query as it needs to see all contacts in the system,
		List<Contact> contacts = new WithoutSharingDataAccessHelper().selectContactsByEmail(emailSet, rowLimit);
		for(Contact con : contacts){
			tmpContacts = contactsMap.containsKey(con.Email) ? contactsMap.get(con.Email) : new List<Contact>();
			tmpContacts.add(con);
			contactsMap.put(con.Email,tmpContacts); // handling scenairo with multiple contacts for same email address

			key = (String.isNotBlank(con.FirstName) && String.isNotBlank(con.LastName)) ?
					(con.FirstName + con.LastName + con.Email) : null;
			if(String.isNotBlank(key)){ // verify if key is not null
				uniqueContactMap.put(key,con);  // Assumption : Only one contact available with same name & email
			}
		}
		System.debug('** uniqueContactMap ==>'+uniqueContactMap);
	}

	/**
	 * @description	   This method assigns contact id to case from a contact map
	* @return			Void
	* @throws			Method might throw exception which is handled by calling method
	*/
	private static void handleContactAssignment(List<Case> caseList,Map<String,List<Contact>> contactsMap,
													Map<String,Contact> uniqueContactMap,Boolean isShortListed){
		/*
			If contact id for a case is not available, contact is linked based on the combination of firstName,
			lastName, person account & billing number else new person account is created and linked to case.
		*/
		if(isShortListed){  //scenairo where contact is linked based on name, email, person account & billing number
			List<Case> newAccCases = new List<Case>();
			Map<String,Account> accMap = new Map<String,Account>(); // map of new accounts to be created
			for(Case caseRec : caseList){
				String caseKey = caseRec.First_Name__c + caseRec.Last_Name__c + caseRec.SuppliedEmail;
				if(String.isNotBlank(caseKey) && uniqueContactMap.containsKey(caseKey)){
					Contact conTobeLinked = uniqueContactMap.get(caseKey);
					if(conTobeLinked != null && (conTobeLinked.IsPersonAccount || (!conTobeLinked.IsPersonAccount
						&& String.isNotBlank(caseRec.Billing_Number__c)
						&& conTobeLinked.BillingAccount__r != null
						&& String.isNotBlank(conTobeLinked.BillingAccount__r.Customer_Number__c)
						&& caseRec.Billing_Number__c == conTobeLinked.BillingAccount__r.Customer_Number__c))){
						caseRec.ContactId = conTobeLinked.Id;
					}
				}
				if(caseRec.ContactId == null && String.isBlank(caseRec.Billing_Number__c)){
					accMap.put((caseRec.First_Name__c + caseRec.Last_Name__c + caseRec.SuppliedEmail + caseRec.SuppliedPhone),
								createAccount(caseRec.First_Name__c,caseRec.Last_Name__c,
													caseRec.SuppliedEmail,caseRec.SuppliedPhone));

					newAccCases.add(caseRec);
				}
			}

			if(!accMap.isEmpty()){
				linkNewContacts(accMap,newAccCases);
			}
		}
		else{   // for cases with email origin, contact is linked based on the email address
			for(Case caseRec : caseList){
				// First Contact assigned if multiple contacts found as per old implementation
				if(contactsMap.containsKey(caseRec.SuppliedEmail) && contactsMap.get(caseRec.SuppliedEmail) != null
					&& contactsMap.get(caseRec.SuppliedEmail).size() == 1){
					caseRec.ContactId = contactsMap.get(caseRec.SuppliedEmail).get(0).Id;
				}
			}
		}
	}

	/**
	 * @description	   This method creates Account record
	* @return			Account
	* @throws			Method might throw exception which is handled by calling method
	*/
	private static Account createAccount(String firstName,String lastName,String email,String phone){
		Account acc = new Account(FirstName = firstName,LastName = lastName,
									PersonEmail = email,PersonMobilePhone = phone);
		return acc;
	}

	/**
	 * @description	   This method creates Account record
	* @return			Account
	* @throws			Method might throw exception which is handled by calling method
	*/
	private static void linkNewContacts(Map<String,Account> accMap,List<Case> caseList){
		if(!accMap.isEmpty()){
			Database.insert(accMap.values());   // create new accounts for cases with no billing number & contact not linked
			Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit

			// fetch ContactId of newly created consumers
			// Use 'WithoutSharingDataAccessHelper' to make the query as it needs to retrieve the new account ireespective of current user's sharing settings.
			Map<Id,Account> newAccMap = new WithoutSharingDataAccessHelper().selectAccountsById(accMap.values(), rowLimit);

			for(Case caseRec : caseList){   // assign the created account to cases
				String key = (caseRec.First_Name__c + caseRec.Last_Name__c + caseRec.SuppliedEmail + caseRec.SuppliedPhone);
				if(String.isNotBlank(key) && accMap.containsKey(key) && accMap.get(key) != null){
					caseRec.ContactId = newAccMap.get(accMap.get(key).Id) != null ?
											newAccMap.get(accMap.get(key).Id).PersonContactId : caseRec.ContactId;
				}
			}
		}
	}

	/**
	 * @description	   This method is executed whenever case is created & updated, assigns case locality to
						international if product category contains international and also checks for duplicate
						cases for BSP & DDC only based on the combination of
						Customer + Enquiry SubType + Type + Article Number (Reference Id) + Parent Case + IsClosed
	* @param			 caseList - List<Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void validateCase(List<Case> caseList){
		try{
			/*
				Currently duplicate check is for BSP cases only for below combination :
				Customer + Enquiry SubType + Type + Article Number (Reference Id) + Parent Case + IsClosed
			*/
			// Fetch org wide custom setting values to determine if duplicate check required
			UniqueCaseTrigger__c uniqueCaseSetting = UniqueCaseTrigger__c.getOrgDefaults();
			Set<String> uniqueKeySet = new Set<String>();
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					// Set the case locality to international if product category of case contains International
					caseRec.CaseLocality__c = (String.isNotBlank(caseRec.ProductCategory__c)
												&& String.isNotBlank(uniqueCaseSetting.CaseLocality__c)
												&& caseRec.ProductCategory__c.contains(uniqueCaseSetting.CaseLocality__c))
												? uniqueCaseSetting.CaseLocality__c : caseRec.CaseLocality__c;
					isCaseLocalitySet = true;
					// form a unique key to detect duplicate cases
					if(caseRec.ContactId != null && String.isNotBlank(caseRec.ReferenceID__c) && !SKIP_DUPLICATE_CHECK_BY_ORIGIN.contains(caseRec.Origin)){
						String key = caseRec.ContactId + caseRec.EnquirySubType__c + caseRec.Type
										+ caseRec.ReferenceID__c + caseRec.ParentId + caseRec.IsClosed ;
						caseRec.Unique_Case__c = key;
						uniqueKeySet.add(key);
					}
				}
			}

			// verify if unique key set has values and throw duplicate error for BSP & DDC users only.
			// Agents would be able to create duplicate case
			if(!isCaseValidated && !uniqueKeySet.isEmpty() && String.isNotBlank(uniqueCaseSetting.ProfileIds__c) &&
				uniqueCaseSetting.ProfileIds__c.contains(UserInfo.getProfileId().substring(0,15))){
					

				Map<String,Case> matchingCaseMap = new Map<String,Case>();
				Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
				// Fetch existing cases with unique key
				for(Case matchCase : [SELECT CaseNumber,Unique_Case__c FROM Case
										WHERE ID NOT IN: caseList AND Unique_Case__c IN: uniqueKeySet
										LIMIT : rowLimit]){
					matchingCaseMap.put(matchCase.Unique_Case__c,matchCase);
				}

				// throw error if there is a existing case
				for(Case caseRec : caseList){
					if(String.isNotBlank(caseRec.Unique_Case__c) && matchingCaseMap.containsKey(caseRec.Unique_Case__c)
						&& matchingCaseMap.get(caseRec.Unique_Case__c) != null){
						isCaseValidated = true;
						caseRec.addError(Label.DUPE_CASE_ERR_MSG + matchingCaseMap.get(caseRec.Unique_Case__c).CaseNumber);
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_VALIDATE_CASE,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description	   This method is executed whenever case is  updated, assigns case locality to
						international if product category contains international.
	* @param			 caseList - List<Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void validateCase_Update(List<Case> caseList){
		try{
			/*
				Currently duplicate check is for BSP & DDC cases only for below combination :
				Customer + Enquiry SubType + Type + Article Number (Reference Id) + Parent Case + IsClosed
			*/
			// Fetch org wide custom setting values to determine if duplicate check required
			UniqueCaseTrigger__c uniqueCaseSetting = UniqueCaseTrigger__c.getOrgDefaults();
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					// Set the case locality to international if product category of case contains International
					caseRec.CaseLocality__c = (String.isNotBlank(caseRec.ProductCategory__c)
												&& String.isNotBlank(uniqueCaseSetting.CaseLocality__c)
												&& caseRec.ProductCategory__c.contains(uniqueCaseSetting.CaseLocality__c))
												? uniqueCaseSetting.CaseLocality__c : caseRec.CaseLocality__c;
					isCaseLocalitySet = true;
					// form a unique key to detect duplicate cases
					if(caseRec.ContactId != null && String.isNotBlank(caseRec.ReferenceID__c)){
						String key = caseRec.ContactId + caseRec.EnquirySubType__c + caseRec.Type
										+ caseRec.ReferenceID__c + caseRec.ParentId + caseRec.IsClosed ;
						caseRec.Unique_Case__c = key;
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_VALIDATE_CASE,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description	   This method when a case is created, checks if incoming case is sent from spam mail
						and prevents email sent out in future
	* @param			 caseList - List<Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void detectPermanentSpam(List<Case> caseList){
		try{
			Set<String> emailSet = new Set<String>();
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					if(String.isNotBlank(caseRec.SuppliedEmail)){
						emailSet.add(caseRec.SuppliedEmail);	// capture all emails
					}
				}
			}

			if(!emailSet.isEmpty()){	// check if set has values
				Map<String,SpamEmail__c> spamMailMap = new Map<String,SpamEmail__c>();
				Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
				// fetch spam records based on the emails from incoming case
				for(SpamEmail__c spam : [SELECT FromEmail__c FROM SpamEmail__c
											WHERE FromEmail__c IN: emailSet LIMIT : rowLimit]){
					spamMailMap.put(spam.FromEmail__c,spam);
				}

				if(!spamMailMap.isEmpty()){ // check if spamMailMap has values
					for(Case caseRec : caseList){
						// set prevent email to true if email is available in spam table
						caseRec.Prevent_Email__c = spamMailMap.containsKey(caseRec.SuppliedEmail) ? true : caseRec.Prevent_Email__c;
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_DETECT_SPAM,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description	   This method closes all child cases of the case being closed
						with parent's resolution code
	* @param			 caseList - List<Case> , oldMap - Map<Id,Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void closeChildCases(List<Case> caseList,Map<Id,Case> oldMap){
		try{
			Set<Id> caseIds = new Set<Id>();
			List<Case> childCasesToUpdate = new List<Case>();
			// verify if caseList & oldMap got values
			if(caseList != null && !caseList.isEmpty() && oldMap != null && !oldMap.isEmpty()){
				for(Case caseRec : caseList){
					if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
						Case oldCase = oldMap.get(caseRec.Id);
						// verify if case is closed and was not closed previously
						if(SSSWConstants.STAT_CLOSED.equalsIgnoreCase(caseRec.Status)
							&& oldCase != null && caseRec.Status != oldCase.Status){
							caseIds.add(caseRec.Id);
						}
					}
				}

				if(!caseIds.isEmpty()){ // check if parent cases available
					Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
					// fetch all open child cases, set resolution code & status
					for(Case childCase : [SELECT Status, ResolutionCode__c, Parent.ResolutionCode__c,Resolution_Result__c, Parent.Resolution_Result__c FROM Case
											WHERE ParentId IN: caseIds AND Status IN: NON_CLOSED_STATUSES
											LIMIT : rowLimit]){
						childCase.Status = SSSWConstants.STAT_CLOSED;
						childCase.ResolutionCode__c = String.isNotBlank(childCase.Parent.ResolutionCode__c) ? 
														childCase.Parent.ResolutionCode__c : childCase.ResolutionCode__c ; 
														childcase.Resolution_Result__c = String.isNotBlank(childCase.Parent.Resolution_Result__c) ? childCase.Parent.Resolution_Result__c : childCase.Resolution_Result__c;
												
												
						childCase.Bypass_Data_enforcement__c = true;	// setting to force close the child case
						childCasesToUpdate.add(childCase);
					}

					if(!childCasesToUpdate.isEmpty()){  // check if childCasesToUpdate has values
						isCloseChildCaseRecursive = true;
						Database.update(childCasesToUpdate);
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_CLOSE_CHILD_CASE,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

		/**
		 * @description	   This method transfers case to current user if status is set to 'On Hold'
		* @param			 caseList - List<Case> , oldMap - Map<Id,Case>
		* @return			Void
		* @throws			Method might throw exception which is handled by Try-Catch block
		*/
		public void setOwnerToCurrentUser(List<Case> caseList,Map<Id,Case> oldMap){
			try{
				//isXferCaseRecursive = true; // -- kalpita 4.11.17 - moved recursion flag up
				// verify if caseList & oldMap got values
				if(caseList != null && !caseList.isEmpty() && oldMap != null && !oldMap.isEmpty()){
					for(Case caseRec : caseList){
						if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
							Case oldCase = oldMap.get(caseRec.Id);
							// verify if case is set to 'On Hold'
							if(SSSWConstants.STAT_ON_HOLD.equalsIgnoreCase(caseRec.Status)
								&& oldCase != null && caseRec.Status != oldCase.Status){
								isXferCaseRecursive = true;  // -- kalpita 4.11.17 - commented recursion flag in loop
								caseRec.OwnerId = UserInfo.getUserId(); // transfer case to current user
							}
						}
					}
				}
			}
			catch(Exception exp){
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
														CaseCommonUtility.class.getName(), SSSWConstants.METH_XFER_CASE,
														SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}

	/**
	 * @description	   This method links the article to case based on the reference id provided by customer.
						future call made to invokeTibcoService which fetch details from SAP first and then
						links to case.
	* @param			 caseList - List<Case>, oldMap - Map<Id,Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void avoidCustomerClose(List<Case> caseList,Map<Id,Case> oldMap){
		try{
			Map<String, EnquirySubTypes__c> enqSubTypes = EnquirySubTypes__c.getAll();  // fetch enquiry subtypes from custom setting
			//isCustCloseRecursive = true; // -- kalpita 4.11.17 - moved recursion flag up
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
					Case oldCase = oldMap.get(caseRec.Id);  // get old values of case
					// check if case violated the customer milestones at tier 4 and status is closed and case Enquiry Subtype doesn't allow auto close
					if(SSSWConstants.STAT_CLOSED.equalsIgnoreCase(caseRec.Status)
						&& oldCase != null && caseRec.Status != oldCase.Status && caseRec.Customer_Milestones_Violated__c == 4
						&& caseRec.ClosedBySystem__c && String.isNotBlank(caseRec.EnquirySubType__c)
						&& enqSubTypes.containsKey(caseRec.EnquirySubType__c)
						&& enqSubTypes.get(caseRec.EnquirySubType__c).AvoidCustomerClose__c){

						isCustCloseRecursive = true;	// set recursive flag to true   // -- kalpita 4.11.17 - commented recursion flag in loop
						caseRec.Status = oldCase.Status;	// revert case status
						caseRec.AllocateToQueue__c = true;
						caseRec.ResolutionCode__c = null;
						caseRec.ClosedBySystem__c = false;
					}
				}
			}
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_AVOID_CUST_CLOSE,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	//  Replaced with domain module MyCustomerCaseArticleModule
	//	/**
	//	  * @description	   This method subscribes to article if case is subscribed and article is linked
	//	  * @param			 caseList - List<Case>
	//	  * @return			Void
	//	  * @throws			Method might throw exception which is handled by Try-Catch block
	//	  */
	//	public void setArticlesSubscribed(List<Case> caseList){
	//		try{
	//			Set<Id> articleIds = new Set<Id>();
	//			//isArticleSubscribeRecursive = true; // -- kalpita 4.11.17 - moved recursion flag up
	//			for(Case caseRec : caseList){
	//				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype
	//					if(caseRec.ArticleTest__c != null && caseRec.Subscribed__c){	// check if case is subscribed
	//						articleIds.add(caseRec.ArticleTest__c);
	//					}
	//				}
	//			}
	//
	//			if(!articleIds.isEmpty()){
	//				isArticleSubscribeRecursive = true; // set recursive flag to true // -- kalpita 4.11.17 - commented recursion flag in loop
	//				Integer rowLimit = (Limits.getLimitDMLRows() - Limits.getDMLRows());	// get dynamic row limit for DML
	//				// fetch articles to be subscribed
	//				List<Article__c> articlesToSubscribe = new List<Article__c>();
	//				for(Article__c article : [SELECT Id,Subscribed__c FROM Article__c WHERE Id IN: articleIds LIMIT : rowLimit]){
	//					article.Subscribed__c = true;
	//					articlesToSubscribe.add(article);
	//				}
	//				if(!articlesToSubscribe.isEmpty()){ // check if list got values
	//					Database.update(articlesToSubscribe,false);
	//				}
	//			}
	//		}
	//		catch(Exception exp){
	//			// Error Logged to Exception object for analysis
	//			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
	//													CaseCommonUtility.class.getName(), SSSWConstants.METH_SUBSCRIBE_ARTICLE,
	//													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
	//		}
	//	}

		/**
		 * @description	   This method is fetch routing keys based on case key and assigns case to queue. 
		 * From all the updated Cases, we need to identify which Cases need routing. Within the same Tx, some Cases have AllocateToQueue__c been updated (ex: child cases). Those will have to be re-routed.
		 * 
		 * @param			 caseList - Changed Cases
		 * @param			 oldMap - Older Case objects. NULL if it is caused by an insert
		 * @return			Void
		 * @throws			Method might throw exception which is handled by Try-Catch block
		 */
		public void routeCase(List<Case> caseList, Map<Id,Case> oldMap, Boolean isInsert){
			try{
				List<Case> casesTobeRouted = new List<Case>();
				Map<Id,String> caseOriginKeyMap = new Map<Id,String>(); // map of case id and case key with origin
				Map<Id,String> caseNoOriginKeyMap = new Map<Id,String>();	// map of case id and case key without origin

				for(Case csRec : caseList){
					// Check if it is SSSW record type or Social record type.
					if(Utility.isValidRecordType(socialAndSsswRecordTypeIds, csRec.RecordTypeId)){
						System.debug(LoggingLevel.ERROR,'**Case is SSSW Record Type');

						Case oldCase = oldMap != null ? oldMap.get(csRec.Id) : null;	
						// verify if network or description is null & case is set for queue allocation
						System.debug(LoggingLevel.ERROR,'**csRec.Network__c: ' + csRec.Network__c);
						System.debug(LoggingLevel.ERROR,'**csRec.Description: ' + csRec.Description);
						System.debug(LoggingLevel.ERROR,'**csRec.AllocateToQueue__c: ' + csRec.AllocateToQueue__c);


						//Prevent routing of the Case to a new Owner based on certain criterias
						if(csRec.AllocateToQueue__c &&
							(
								(oldCase != null && oldCase.AllocateToQueue__c == csRec.AllocateToQueue__c)
								|| (csRec.OwnerId != null && csRec.OwnerId.getSobjectType() == User.getSObjectType() && csRec.Case_Owner_User_Profile_Name__c == SSSWConstants.SSSW_AGENT_PROFILE  && Utility.getCaseClosedStatus().contains(csRec.Status) == false)
								|| csRec.Permanent_Close__c == true
								|| csRec.OwnerId == OmniChannelService.getInstance().omniHoldingQueueId // Prevent routing of cases in Omni Holding Queue. Note: MyCustomerCaseArticlesModule class has async logic that routes these cases out of the Omni Holding queue
							)
						){
							csRec.AllocateToQueue__c = false;
						}

						if( (csRec.Network__c == null && (oldCase == null || (oldCase != null && (oldCase.Network__c != csRec.Network__c))))
							||
							(String.isBlank(csRec.Description) && (oldCase == null || (oldCase != null && (oldCase.Description != csRec.Description))))
							||
							csRec.AllocateToQueue__c
						){
							System.debug(LoggingLevel.ERROR,'**Case meets evaluation to go to routing method');
							
							setCaseKeyMap(csRec,caseOriginKeyMap,caseNoOriginKeyMap);   // set case key maps

							casesTobeRouted.add(csRec);
						}
					}
				}

				if(!casesTobeRouted.isEmpty()){
					System.debug('casesTobeRouted--->'+casesTobeRouted+'<--oldMap-->'+oldMap);
					SSSW_Routing.assignCasesAndDescription(casesTobeRouted, oldMap, isInsert);
				}


				//The logic below is positioned here instead of in a Domain Module to keep all logic related Case Owner in one place and in the same sequence in Apex execution
				//Placed after the routing engine to ensure the to-be Queue is available for the logic below
				Map<Id,Case> casesPreferredAgentRouting = new Map<Id,Case>();
				for(Case csRec : caseList){
					// Check if it is SSSW record type or Social record type.
					if(Utility.isValidRecordType(socialAndSsswRecordTypeIds, csRec.RecordTypeId)){
						
						Case oldCase = oldMap != null ? oldMap.get(csRec.Id) : null;	// get old values of case		

						//Move eligible Closed Cases to the SSSW Closed Omni Queue					
						if ((oldCase?.Status != csRec.Status || oldCase?.OwnerId != csRec.OwnerId) 
							&& String.isEmpty(OmniChannelService.getInstance().omniClosedCaseQueueId) == false 
							&& Utility.getCaseClosedStatus().contains(csRec.Status) 
							&& omniGroups.containsKey(csRec.OwnerId) 			
						){	
							csRec.OwnerId = OmniChannelService.getInstance().omniClosedCaseQueueId; 
						}
						//Preferred Agent logic, applied for Cases being routed to a Queue with a Routing Configuration (referred to as an Omni Queue).
						else if(oldCase != null 
							&& (new Set<String>{'Web','Portal','BSP','MyPost Business'}).contains(csRec.Origin) == false //Omni Release 2 TEMPORARY FIX
							&& csRec.OwnerId != oldCase.OwnerId						
							&& OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(csRec.OwnerId) == true 
							&& OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(oldCase.OwnerId) == false // only consider if previous owner is not omni, as the case has already been determined as not requiring Preferred Agent in the previous omni queue
							&& csRec.BypassPreferredAgent__c == false 
							&& csRec.PreferredAgentExpiry__c != null // avoids Cases being stuck in the Preferred Agent queue					
							&& String.isEmpty(OmniChannelService.getInstance().preferredAgentQueueId) == false) {
								if(oldCase.OwnerId == OmniChannelService.getInstance().preferredAgentQueueId || m_processedPreferredAgentCaseIds.contains(csRec.Id) ){ 
									// 2 scenarios where the Case already has a manual PSR and so we should not attempt to generate another one, and ensure the queue is in the Preferred Agent queue:
									// a) Case being moved out of Preferred Agent queue without the Bypass flag set, OR 
									// b) Case has already been processed by Preferred Agent in the same transaction
									csRec.OwnerId = OmniChannelService.getInstance().preferredAgentQueueId; 
								} else {
									casesPreferredAgentRouting.put(csRec.Id, csRec); 
								}
						}
					}
				}

				if(casesPreferredAgentRouting.isEmpty() == false) {
					processPreferredAgent(casesPreferredAgentRouting); 
				}

			}
			catch(Exception exp){
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
														CaseCommonUtility.class.getName(), SSSWConstants.METH_INSERT_MILESTONES,
														SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
			}
		}

	/**
	 * @description	   This method sets key value pair of case & routing key
	* @param			 csRec - Case, caseOriginKeyMap - Map<Id,String>, caseNoOriginKeyMap - Map<Id,String>
	* @return			void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	private static void setCaseKeyMap(Case csRec,Map<Id,String> caseOriginKeyMap,Map<Id,String> caseNoOriginKeyMap){
		String keyWithOrigin = SSSWConstants.EMPTY_SPACE ;
		String keyWithOutOrigin = SSSWConstants.EMPTY_SPACE ;
		keyWithOrigin = String.isNotBlank(csRec.ProductCategory__c) ? (keyWithOrigin + csRec.ProductCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.ProductSubCategory__c) ? (keyWithOrigin + csRec.ProductSubCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.Type) ? (keyWithOrigin + csRec.Type) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.EnquirySubType__c) ? (keyWithOrigin + csRec.EnquirySubType__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.Customer_Type__c) ? (keyWithOrigin + csRec.Customer_Type__c) : keyWithOrigin;
		keyWithOrigin = (csRec.IsNewForRouting__c != null && csRec.IsNewForRouting__c) ?
							(keyWithOrigin + ROUTING_TRUE) : (keyWithOrigin + ROUTING_FALSE);

		keyWithOutOrigin = keyWithOrigin ;

		keyWithOrigin = String.isNotBlank(csRec.Origin) ? (keyWithOrigin + csRec.Origin) : keyWithOrigin;

		caseOriginKeyMap.put(csRec.Id,keyWithOrigin);
		caseNoOriginKeyMap.put(csRec.Id,keyWithOutOrigin);
	}

	/**
	 * @description	   This method returns the sssw routing records for the case combination
	* @param			 caseKeys - Set<String>
	* @return			Map<String,SSSWRouting__c>
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	//  private static Map<String,SSSWRouting__c> getSSSWRoutings(Set<String> caseKeys){
	//	 Map<String,SSSWRouting__c> routingMap = new Map<String,SSSWRouting__c>();
	//	 Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
	//	 for(SSSWRouting__c routing : [SELECT Network__c,CaseKey__c,ExcludeFromNPS__c,DefaultCaseDetails__c,Queue_ID__c,AutoEscalate__c
	//									 FROM SSSWRouting__c WHERE CaseKey__c IN: caseKeys ORDER BY CaseKey__c LIMIT : rowLimit]){
	//		 routingMap.put(routing.CaseKey__c,routing);
	//	 }
	//	 return routingMap;
	// } 

	/**
	 * @description	   This method checked the child case for 'Network Responded' and 'Customer Responded' and updated the
						parent status to 'child case updated' and again runs it to route - set 'allocate to queue' flag
	* @param			 (List<Case> childCases
	* @return			NA
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void updateParentForRouting(List<Case> childCases, Map<Id,Case> oldMapCases){
		try {
			List<Case> parentCaseUpd = new List<Case>();
			//loop through all cases updated and check if they are child
			for(Case cse: childCases) {
				//check if is child, and the network or customer has responded
				if(cse.parentId != null &&
					((!SSSWConstants.STAT_NETWORK_RESPONDED.equalsIgnoreCase(oldMapCases.get(cse.Id).Status) &&
						SSSWConstants.STAT_NETWORK_RESPONDED.equalsIgnoreCase(cse.Status)) ||
					(!SSSWConstants.STAT_CUSTOMER_RESPONDED.equalsIgnoreCase(oldMapCases.get(cse.Id).Status) &&
						SSSWConstants.STAT_CUSTOMER_RESPONDED.equalsIgnoreCase(cse.Status)) )) {
					//if yes, update the parent and send for routing
					parentCaseUpd.add(new Case(Id = cse.parentId, Status = SSSWConstants.STAT_CHILD_CASE_UPDATE , AllocateToQueue__c = true));
				}
			}

			if(!parentCaseUpd.isEmpty()) {
				isParentCaseUpdateRecursive = true;			 // set recursive flag to true
				//if any parent cases avaialable, update them.
				Database.update(parentCaseUpd);
			}

		}
		catch(Exception exp) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_PARENT_ROUTING,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @description	   This method when a case is created, updates the hierarchy manager fields in the Case object
	* @param			 caseList - List<Case>
	* @return			Void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	public void updateHierarchyManager(List<Case> caseList){
		try{



				String currentUser = UserInfo.getUserId();
				User managerHierarchy = [SELECT Manager.FirstName, Manager.LastName,
										Manager.Manager.FirstName, Manager.Manager.LastName,
										Manager.Manager.Manager.FirstName, Manager.Manager.Manager.LastName
										from User
										where id =:currentUser ];

		System.debug('updateHierarchyManager : Current User is ' + currentUser  );
		System.debug('updateHierarchyManager : managerHierarchy FirstName ' + managerHierarchy.Manager.FirstName  );
			for(Case caseRec : caseList){
				if(Utility.isValidRecordType(validRecTypes,caseRec.RecordTypeId)){  // verify if its SSSW recordtype

					if ( (managerHierarchy.Manager.FirstName != null && String.isNotBlank(managerHierarchy.Manager.FirstName)) ||
					(managerHierarchy.Manager.LastName  != null && String.isNotBlank(managerHierarchy.Manager.LastName)))
					{
						caseRec.ManagerLevel1__c = managerHierarchy.Manager.FirstName + ' ' + managerHierarchy.Manager.LastName;
					}
					if ( (managerHierarchy.Manager.Manager.FirstName != null && String.isNotBlank(managerHierarchy.Manager.Manager.FirstName)) ||
					(managerHierarchy.Manager.Manager.LastName  != null && String.isNotBlank(managerHierarchy.Manager.Manager.LastName)))
					{
						caseRec.ManagerLevel2__c = managerHierarchy.Manager.Manager.FirstName + ' ' + managerHierarchy.Manager.Manager.LastName;
					}
					if ( (managerHierarchy.Manager.Manager.FirstName != null && String.isNotBlank(managerHierarchy.Manager.Manager.FirstName)) ||
					(managerHierarchy.Manager.Manager.LastName  != null && String.isNotBlank(managerHierarchy.Manager.Manager.LastName)))
					{
						caseRec.ManagerLevel3__c = managerHierarchy.Manager.Manager.Manager.FirstName + ' ' + managerHierarchy.Manager.Manager.Manager.LastName;
					}
				}

			}


		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseCommonUtility.class.getName(), SSSWConstants.METH_UPDATE_MANAGER_HIERARCHY,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	// Send automated notification to customers when case criteria matches with what is in the automation rule table.
	// Created by David Catindoy - Oct 11, 2016
	// Modified by SJudd - Aug 26, 2021  added fields to newCases query
	public static void notificationAutomationModel(Map<Id, Case> newCases, Map<Id, Case> oldCases){

		// Andrew Judd 18/04/17 Updated IF below to reference custom setting instead of using SELECT statement to get profile Id
		//if(!UserInfo.getProfileId().left(15).equals(StarTrack_Settings__c.getOrgDefaults().BSP_Community_User_Profile_Id__c)){
		if(!BspConstants.CURRENT_USER_CAN_ACCESS_BSP) {
			Set<Id> invalidCaseIds = new Set<Id>();
			List<Case> pendingCases = new List<Case>();
			StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
			List<String> excResCodeList = new List<String>();
			if(String.isNotBlank(customSetting.ST_Resolution_Code_Exclusion_List__c)){
				excResCodeList = customSetting.ST_Resolution_Code_Exclusion_List__c.split(',');
			}

			//Query cases that matches criteria
			//MW0004540 Added Special Instructions field
			newCases = new Map<Id, Case>([SELECT Id, RecordType.Name, Status, FCR__c, Subscription_Consign_Summary_Status__c, Enquiry_Type__c, Call_Purpose__c, Exclude_Notification_Automation__c, ArticleTest__r.Consignment_Summary_Status__c, ArticleTest__c, ArticleTest__r.Name,
											CaseNumber, Description_of_contents__c, Description_of_packaging__c, Number_of_Items__c, Network__r.Name, Network__r.Special_Instructions__c,Business_Solutions_Customer__c, ResolutionCode__c, All_Manual_Communications_Completed__c,
											(SELECT Id, Calc_Contact_Email__c, Case__c, Calc_Contact_Mobile_Number__c, Calc_First_Name__c, Calc_Last_Name__c, Notification_Required__c, Notified_on_Status__c, Pref_Method_of_Contact__c, Name
											FROM Authorised_Contacts__r WHERE Notification_Required__c = :StarTrack_Constants.ST_TRUE AND Pref_Method_of_Contact__c != null)
										FROM Case WHERE Id IN :newCases.keySet() AND ArticleTest__c != null AND ResolutionCode__c NOT IN :excResCodeList AND FCR__c = :StarTrack_Constants.ST_FALSE AND RecordType.DeveloperName LIKE :(StarTrack_Constants.CASE_STARTRACK_RECTYPE + '%') AND Status != :StarTrack_Constants.CASE_STATUS_NEW]);
			//Check if retrieved cases is not empty
			if(!newCases.isEmpty()){
				for(Case caseRec : newCases.values()){
					Case oldCaseRec = oldCases.get(caseRec.Id);
					if((caseRec.Authorised_Contacts__r.size() < 1 || StarTrack_Constants.CASE_STAT_PENCUSNOTIF.equals(oldCaseRec.Status) || (StarTrack_Constants.CASE_STAT_REOPENED.equals(oldCaseRec.Status) && StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)))
						&& !caseRec.Status.equals(oldCaseRec.Status)){ //Validate retrieved case record if it has related contact that
						invalidCaseIds.add(caseRec.Id);				//requires notification or if previous case record status is not 'Pending Customer Notification'
					} else if(caseRec.Status.equals(oldCaseRec.Status)){
						invalidCaseIds.add(caseRec.Id);
					}
				}
				if(!invalidCaseIds.isEmpty()){
					for(Id caseId : invalidCaseIds){
						newCases.remove(caseId); //remove all invalid cases
					}
				}
			}

			if(!newCases.isEmpty()){
				//Initialize containers
				Map<Id, Case> matchedCases = new Map<Id, Case>();
				Map<Id, String> caseStatusList = new Map<Id, String>();
				Map<Id, AuthorisedContacts__c> relatedContacts = new Map<Id, AuthorisedContacts__c>();
				Map<Id, String> caseSMSTemplate = new Map<Id, String>();
				Map<Id, String> caseEmailTemplate = new Map<Id, String>();
				List<StarTrack_Automation_Rule__c> stARList = [SELECT Id, Consignment_Summary_Status__c, Case_RecordType__c, Case_Type__c, Case_Purpose__c, Case_Status__c, Case_Action__c, Order__c, Email_Template__c, SMS_Template__c, RecordType.Name, RecordTypeId, BSC__c
															FROM StarTrack_Automation_Rule__c WHERE RecordType.Name = :StarTrack_Constants.NOTIFAUTO_RULEFUNC ORDER BY Order__c];
				if(!stARList.isEmpty()){
					for(Case caseRec : newCases.values()){
						for(StarTrack_Automation_Rule__c stRule : stARList){
							if(compareRec(stRule, caseRec)){ //Compare case record against automation rule table.
								if(caseRec.Exclude_Notification_Automation__c && !caseRec.All_Manual_Communications_Completed__c){ //If case record exclusion is set to true
									caseRec.Status = StarTrack_Constants.CASE_STAT_PENCUSNOTIF;
									pendingCases.add(caseRec);
								} else if(!caseRec.Exclude_Notification_Automation__c && StarTrack_Constants.CASE_ACTSENDNOTIF.equals(stRule.Case_Action__c)){ //If case action is 'Send Notification'
									matchedCases.put(caseRec.Id, caseRec);
									caseStatusList.put(caseRec.Id, caseRec.Status);
									relatedContacts.putAll(caseRec.Authorised_Contacts__r);
									caseSMSTemplate.put(caseRec.Id, stRule.SMS_Template__c);
									caseEmailTemplate.put(caseRec.Id, stRule.Email_Template__c);
								}
								break;
							}
						}
					}
				}

				//Check if not empty
				if(!relatedContacts.isEmpty()){
					Id stSMSRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack SMS').getRecordTypeId(); //Query sms record type.
					//Initialize containers
					List<workflow_Email__c> newWFRecords = new List<workflow_Email__c>();
					List<Task> newSMSTasks = new List<Task>();
					List<AuthorisedContacts__c> changedRelContacts = new List<AuthorisedContacts__c>();

					for(AuthorisedContacts__c relCont : relatedContacts.values()){
						Case caseRec = matchedCases.get(relCont.Case__c); //Get contact parent case record.
						if(StarTrack_Constants.CASE_ORIGIN_PHONE.equals(relCont.Pref_Method_of_Contact__c) || (StarTrack_Constants.CASE_ORIGIN_EMAIL.equals(relCont.Pref_Method_of_Contact__c) && String.isBlank(relCont.Calc_Contact_Email__c)) ||
							(StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isBlank(relCont.Calc_Contact_Mobile_Number__c)) || //Validate if status must be set to 'Pending Customer Notification.'
							(StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isNotBlank(relCont.Calc_Contact_Mobile_Number__c) && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRec.Enquiry_Type__c) && String.isBlank(relCont.Calc_Contact_Email__c)) // MW0004540 set depot collection to pending as is needs both mobile number and email
							&& !StarTrack_Constants.CASE_STAT_PENCUSNOTIF.equals(caseRec.Status) && !caseRec.All_Manual_Communications_Completed__c){
							caseRec.Status = StarTrack_Constants.CASE_STAT_PENCUSNOTIF;
							pendingCases.add(caseRec);
							// MW0004540 Modified to ensure Depot Collection always gets email if customer has given one - not just SMS because email has important Depot Collection Details.
						} else if((StarTrack_Constants.CASE_ORIGIN_EMAIL.equals(relCont.Pref_Method_of_Contact__c) || StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRec.Enquiry_Type__c)) && String.isNotBlank(caseEmailTemplate.get(caseRec.Id)) && String.isNotBlank(relCont.Calc_Contact_Email__c)){
							workflow_Email__c wfe = new workflow_Email__c(Case__c = caseRec.Id, Status__c = StarTrack_Constants.WFE_STATUS_CLOSE, Task_Description__c = relCont.Name + ': ' + caseEmailTemplate.get(caseRec.Id),
																		Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING, Workflow_Email_Alert__c = caseEmailTemplate.get(caseRec.Id), To_Address__c = relCont.Calc_Contact_Email__c,
																		Name = relCont.Name + ': ' + caseEmailTemplate.get(caseRec.Id), Task_Subject__c = relCont.Name + ': ' + caseEmailTemplate.get(caseRec.Id),
																		Consignment_Number__c = String.isNotBlank(caseRec.ArticleTest__c) ? caseRec.ArticleTest__r.Name : '', Enquiry_Type__c = caseRec.Enquiry_Type__c,
																		Case_Number__c = caseRec.CaseNumber, Description_Of_Contents__c = caseRec.Description_of_contents__c, Description_Of_Packaging__c = caseRec.Description_of_packaging__c,
																		Number_of_Items__c = String.valueOf(caseRec.Number_of_Items__c), Network_Name__c = caseRec.Network__r.Name, Special_Instructions__c = caseRec.Network__r.Special_Instructions__c, Contact_First_Name__c = relCont.Calc_First_Name__c);
							newWFRecords.add(wfe);
							if(!caseStatusList.get(caseRec.Id).equals(relCont.Notified_on_Status__c)){
								relCont.Notified_on_Status__c = caseStatusList.get(caseRec.Id);
								changedRelContacts.add(relCont);
							}
						} // MW0004540 Changed from else if to if because Depot Collection will get SMS and emails so it is not either or
						if((StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isNotBlank(caseSMSTemplate.get(caseRec.Id)) && String.isNotBlank(relCont.Calc_Contact_Mobile_Number__c) && !StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRec.Enquiry_Type__c)) || //Validate if mobile notification can be sent.
							(StarTrack_Constants.MOBILE_PREFCONTACT_METHOD.equals(relCont.Pref_Method_of_Contact__c) && String.isNotBlank(caseSMSTemplate.get(caseRec.Id)) && String.isNotBlank(relCont.Calc_Contact_Mobile_Number__c) && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(caseRec.Enquiry_Type__c) && String.isNotBlank(relCont.Calc_Contact_Email__c))) {
							String message = caseSMSTemplate.get(caseRec.Id).replaceAll(StarTrack_Constants.SMSTEMP_CASENUMBER, caseRec.CaseNumber);
							message = message.replaceAll(StarTrack_Constants.SMSTEMP_CONSIGNNUMBER, String.isNotBlank(caseRec.ArticleTest__c) ? caseRec.ArticleTest__r.Name : '');
							Task aTask = new Task(WhatId = caseRec.Id, ActivityDate = Date.today(), Bulk_SMS__c = StarTrack_Constants.ST_TRUE, Description = message, RecordTypeId = stSMSRT, Subject = 'Outbound SMS (' + (message.trim().length()>=19?message.substring(0, 19):message.substring(0)) + ')', Status = 'In Progress', Interaction_Type__c = 'SMS');
							aTask.SMSMessage__c = message;
							aTask.Phone__c = relCont.Calc_Contact_Mobile_Number__c;
							aTask.Case_Phone__c = relCont.Calc_Contact_Mobile_Number__c;

							newSMSTasks.add(aTask);
							if(!caseStatusList.get(caseRec.Id).equals(relCont.Notified_on_Status__c)){
								relCont.Notified_on_Status__c = caseStatusList.get(caseRec.Id);
								changedRelContacts.add(relCont);
							}
						}
					}

					if(!newWFRecords.isEmpty()){
						Database.insert(newWFRecords); //Insert all new workflow email records.
					}

					if(!newSMSTasks.isEmpty()){
						Database.insert(newSMSTasks); //Insert all new SMS records.
						ActivityUtil.sendSMSForStarTrackTasks(newSMSTasks);
					}

					if(!changedRelContacts.isEmpty()){
						Database.update(changedRelContacts); //Update all changed related contacts.
					}
				}
			}

			if(!pendingCases.isEmpty()){
				Database.update(pendingCases); //Update cases sepcified as 'Pending Customer Notification'
			}
		}
	}

	//StarTrack method which is used to match case field values against the automation rule table. - David Catindoy (CreatedDate: Oct 11, 2016)
	//MW0004540 Added check for permissions for autocaseclosure based on rule template and autoCaseClosurepermission
	public static Boolean compareRec(StarTrack_Automation_Rule__c stRule, Case caseRec){
		if(!isAutoCloseEnabled && ST_CASE_AUTOCLOSE_TEMPLATES.Contains(stRule.Email_Template__c)){
			return false;
		}
		if((String.isNotBlank(stRule.Consignment_Summary_Status__c) ? stRule.Consignment_Summary_Status__c.equalsIgnoreCase(caseRec.ArticleTest__r.Consignment_Summary_Status__c) : true) &&
		(String.isNotBlank(stRule.Case_RecordType__c) ? stRule.Case_RecordType__c.equals(caseRec.RecordType.Name) : true) &&
		(String.isNotBlank(stRule.Case_Type__c) ? stRule.Case_Type__c.equals(caseRec.Enquiry_Type__c) : true) && (String.isNotBlank(stRule.Case_Purpose__c) ? stRule.Case_Purpose__c.equals(caseRec.Call_Purpose__c) : true) &&
		(String.isNotBlank(stRule.Case_Status__c) ? stRule.Case_Status__c.equals(caseRec.Status) : true) && (stRule.BSC__c == caseRec.Business_Solutions_Customer__c)){
		return true;
		}
		return false;
	}

	//StarTrack method that is used to detect duplicate inbound email cases and delete all its related contacts. - David Catindoy (CreatedDate: Dec. 1, 2016)
	public static void duplicateStarTrackCases(Map<Id, Case> newCases){
		//Initialize new container.
		Set<Id> dupCasesId = new Set<Id>();
		newCases = new Map<Id, Case>([SELECT Id, Status, StarTrack_RecordType__c, Owner.Name FROM Case WHERE Id IN :newCases.keySet()]); //Query again to get the fields needed.

		for(Case caseRec : newCases.values()){
			if(caseRec.StarTrack_RecordType__c && StarTrack_Constants.RECYCLE_BIN_QUEUE.equals(caseRec.Owner.Name) && StarTrack_Constants.CASE_STAT_CLOSED.equals(caseRec.Status)){ //Validate if it passes criteria.
				dupCasesId.add(caseRec.Id); //Add case id to the container for later processing.
			}
		}

		if(!dupCasesId.isEmpty()){ //Check if list/container has value.
			Database.delete([SELECT Id FROM AuthorisedContacts__c WHERE Case__c IN : dupCasesId]); //Get all related contacts sitting under cases that found to be duplicates.
		}
	}

	/**
	 * If a Case status is changed to New, those cases are flagged to be re-routed (AllocateToQueue__c = true).
	 * This behaviour is applicable only if,
	 *  Types and Product Category values are populated,
	 *  not a High Level Complaints Case and neither a Customer Recovery Case
	 *  SSSW* or Social RecordType
	 * This was initially done with the now deprecated Workflows
	 * ('SSSW - Status Change to NEW - Send to Queue' and 'SSSW - Status change to update queue')
	 * and now moved to Triggers
	 *
	 * @param newCases Updated cases List coming to Trigger
	 * @param oldMap Older Case value Map coming into Trigger
	 */
	public static void markRenewedCasesToRoute(List<Case> newCases, Map<Id,Case> oldMap){

		if (oldMap == null){
			return;
		}

		// Listing of the variables we're monitoring for change
		List<Case> casesNeedToRoute =
				RecursionUtility.getUnprocessedRecords(
								'CaseRenewalTriggerContext',
								newCases,
								new Set<String>{
									'AllocateToQueue__c','Status',
									'ProductCategory__c', 'ProductSubCategory__c', 'EnquirySubType__c', 'Type',
									'IsHLC__c', 'IsCR__c'
								});

			for (Case newCase : casesNeedToRoute){

				Case oldCase = oldMap != null ? oldMap.get(newCase.Id) : null;  // get old values of case

				if ((isStatusChangedToNew(oldCase, newCase)
					&& !newCase.AllocateToQueue__c
					&& ((isCategoriesAndTypesPopulated(newCase) || 
								(isNotHlcAndCr(newCase) && Utility.isValidRecordType(socialAndSsswRecordTypeIds, newCase.RecordTypeId))))
				) || 
				(oldCase != null 
					&& Utility.getCaseClosedStatus().contains(newCase.Status) == false
					&& newCase.Status != oldCase.Status 
					&& String.isEmpty(OmniChannelService.getInstance().omniClosedCaseQueueId) == false && newCase.OwnerId == OmniChannelService.getInstance().omniClosedCaseQueueId)
				){

				newCase.AllocateToQueue__c = true; // Flag to re-route cases again
			}
		}
	}

	/*
	* Generate a PendingServiceRouting record with the PreferredUserId value set to a previous User, based on the Case's existing AgentWork records.
	* The Case's AgentWork record must have been accepted and have an active User as a final criteria before PSRs are generated
	* Cases are assigned to a Queue without a Routing Configuration to allow PendingServiceRouting to be inserted and not overridden by Salesforce.
	*/
	@TestVisible
	private void processPreferredAgent(Map<Id,Case> casesPreferredAgentRouting) {

		//Only some new 
		Map<Id, AgentWork> caseIdsVsAgentWorks = OmniChannelService.getInstance().getCaseIdsWithLatestAcceptedAgentWorks(casesPreferredAgentRouting.keySet());

		if(caseIdsVsAgentWorks.isEmpty() == false) {

			ServiceChannel sc = OmniChannelService.Cache.serviceChannels.get('Case_Channel');
			List<PendingServiceRouting> newPSRs = new List<PendingServiceRouting>();	

			for(Case csRec : casesPreferredAgentRouting.values()) {
				if(caseIdsVsAgentWorks.containsKey(csRec.Id) == true) {
					
					//use the routing configuration of the Omni queue the Case was being routed to
					QueueRoutingConfig routingConfiguration = OmniChannelService.Cache.queuesWithRoutingConfig.get(csRec.OwnerId).routingConfiguration; 

					//PushTimeout cannot be set when IsPreferredUserRequired is set
					newPSRs.add(new PendingServiceRouting(
						PreferredUserId = caseIdsVsAgentWorks.get(csRec.Id).UserId,
						IsPreferredUserRequired = true,
						CapacityPercentage = routingConfiguration.CapacityPercentage, 
						CapacityWeight = routingConfiguration.CapacityWeight, 
						DropAdditionalSkillsTimeout = routingConfiguration.DropAdditionalSkillsTimeout,
						RoutingModel = routingConfiguration.RoutingModel, 
						RoutingPriority = routingConfiguration.RoutingPriority, 
						CustomRequestedDateTime = csRec.CreatedDate, 
						WorkItemId = csRec.Id,
						IsReadyForRouting = true,
						RoutingType = 'SkillsBased', 
						ServiceChannelId = sc.Id,
						SecondaryRoutingPriority = OmniChannelService.getInstance().calculateSecondaryPriority(csRec.Priority, csRec.CreatedDate) //TODO:.... map from Service Channel config... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
					));
				}
			}

			if(newPSRs.isEmpty() == false) {

				//Allow partial success for the insert, as some PSR insert may fail if a Case has an existing PSR already e.g. another inserted PSR has not been deleted
				List<Database.SaveResult> srList = ApplicationDatabase.getInstance().dmlInsert(newPSRs, false);
				
				if(srList.isEmpty() == false){
					for(Integer i=0;i<srList.size();i++){
						Database.SaveResult sr = srList.get(i);

						//Assign the Case of successful PSRs to the Preferred Agent queue
						if (sr.isSuccess()){
							for(PendingServiceRouting newPSR : newPSRs){ 
								if(newPSR.Id != null && newPSR.Id == sr.getId()){
									casesPreferredAgentRouting.get(newPSR.WorkItemId).OwnerId = OmniChannelService.getInstance().preferredAgentQueueId; 
									m_processedPreferredAgentCaseIds.add(newPSR.WorkItemId);
								}							
							}
						} else {
							for (Database.Error err : sr.getErrors()) {	
								System.debug('The following error has occurred on the DML Retry.');
								System.debug(err.getStatusCode() + ': ' + err.getMessage());
							}
						}					
					}		
					
					// log any failed inserts to ensure we can monitor save errors (especially for checking routing failures)
					ApplicationLogger.getInstance().logFailedDatabaseResults(srList, SSSWConstants.SSSW_APP, CaseCommonUtility.class.getName(), 'processPreferredAgent', '', ApplicationLogger.LoggingLevel.ERROR);
				}			
			}
		}
	}

	/**
	 * If Case.Status is changed to New from other value
	 *
	 * @param oldCase Older Case coming into Trigger
	 * @param newCase Updated Case coming to Trigger
	 *
	 * @return true if changed to New
	 */
	private static Boolean isStatusChangedToNew(Case oldCase, Case newCase){
		return oldCase.Status != newCase.Status && newCase.Status == 'New';
	}

	/**
	 * Checks if Case ProductCategory__c, ProductSubCategory__c, EnquirySubType__c, Type are populated
	 *
	 * @param newCase Updated Case coming to Trigger
	 *
	 * @return if ALL of them have a value
	 */
	private static Boolean isCategoriesAndTypesPopulated(Case newCase){
		return (!(newCase.ProductCategory__c == '' || newCase.ProductCategory__c == null ) &&
				!(newCase.ProductSubCategory__c == '' || newCase.ProductSubCategory__c == null) &&
				!(newCase.EnquirySubType__c == '' || newCase.EnquirySubType__c == null) &&
				!(newCase.Type == '' || newCase.Type == null));
	}

	/**
	 * Checks if not a High Level Complaints Case and neither a Customer Recovery Case
	 *
	 * @param newCase Updated Case coming to Trigger
	 *
	 * @return if ALL of them are false
	 */
	private static Boolean isNotHlcAndCr(Case newCase){
		return ((!newCase.IsHLC__c || newCase.IsHLC__c == null) &&
				(!newCase.IsCR__c || newCase.IsCR__c == null));
	}

		/**
		 * Populate requestor field with current user if left empty upon new case creation
		 * 
		 * @param caseTobeUpdated - Updated Case coming to Trigger
		 *
		 * @return void
		 */
		public void populateRequestorWithCurrentUser(List<Case> caseTobeUpdated){
			try{
				// list to capture cases with 'null' requestor
				List<Case> nullRequestorCases = new List<Case>();
				for(Case newCase : caseTobeUpdated){
					// Null Requestor Cases that is not from Email2Case
					if(newCase.requestor__c == null && newCase.SuppliedEmail == null){
						nullRequestorCases.add(newCase);
					}
				}
				// send case with 'null' requestor to the handler class
				if(!nullRequestorCases.isEmpty()){
					// query and get 'CAR' case record type id
					Id caseCAR_RecordTypeId = [Select id, DeveloperName from RecordType where DeveloperName = 'CAR_Request'].id;
					for(Case cCAR: nullRequestorCases){
						// populate requestor's field with current user after confirm that the case is 'CAR' record type
						if(cCAR.recordTypeId.equals(caseCAR_RecordTypeId)){
							cCAR.requestor__c = UserInfo.getUserId();
						}
					}
				} 
			}catch(Exception ex){
				// logging details upon exception occurs
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'NewCaseCreation',
														'CaseCommonUtility', 'populateRequestorWithCurrentUser',
														'CaseTriggerHandler', LoggingLevel.ERROR);
			}
		}

	/**
	 * Private inner class that elevates access privileges of the current user to query data without being limited by
	 * sharing settings.
	 *
	 * IMPORTANT: Not intended for general use. Only for handling special scenarios where it is necessary to query data beyond
	 *			what the current user is allowed to see as per sharing.
	*			E.g. : Public Guest users submitting a case should be linked to existing contacts matching the email address on case.
	*/
	private without sharing class WithoutSharingDataAccessHelper {

		/**
		 * Query contacts by email address.
		 *
		 * @param emailSet Email addresses to query
		 * @param rowLimit number of matching records to return. Mandatory.
		 *
		 * @return List of contact records matched by email address.
		 */
		private List<Contact> selectContactsByEmail(Set<String> emailSet, Integer rowLimit) {

			//Query previously in CaseCommonUtiltiy.populateContactMaps(). Moved here to allow it to run without sharing.
			return [
					SELECT Id,FirstName,LastName,Email,IsPersonAccount,BillingAccount__r.Customer_Number__c
					FROM Contact
					WHERE Email IN:emailSet
					ORDER BY Email
					LIMIT :rowLimit
			];
		}

		/**
		 * Query accounts by Id.
		 *
		 * @param accounts list of accounts to grab ids.
		 * @param rowLimit number of matching records to return. Mandatory.
		 *
		 * @return List of contact records matched by email address.
		 */
		private Map<Id, Account> selectAccountsById(List<Account> accounts, Integer rowLimit) {

			//Query previously in CaseCommonUtiltiy.linkNewContacts(). Moved here to allow it to run without sharing.
			return new Map<Id, Account>([SELECT PersonContactId FROM Account WHERE Id IN:accounts LIMIT :rowLimit]);
		}
	}
}