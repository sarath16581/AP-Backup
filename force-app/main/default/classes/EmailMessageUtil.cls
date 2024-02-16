/**************************************************
Description:	Utility Class for Email Message
History:
--------------------------------------------------
30/08/2016  eric.shen@auspost.com.au  add methods to parse email body for snap it case
25/06/2018  disha.kariya@auspost.com.au  Removed NPSRequired__c and NPSTagDate__c commented call to checkNPS
2018-07-10  nathan.franklin@auspost.com.au  Renamed checkNPS to setEmailToCaseAddress as it's more meaningful
2018-08-08  disha.kariya@auspost.com.au		Commented clonePermanentlyClosedCases, cloneCase and reparentEmails method as it is not used.
2018-12-11  disha.kariya@auspost.com.au		Update Case from Email for Secure Post
2022-02-22  naveen.rajanna@auspost.com.au - Added constants for REQ2723199
2022-04-08  naveen.rajanna@auspost.com.au - REQ2804764 - Remove debug and Add null check to prevent nullpointerexception for parseEmailbodySnapIt,setEmailToCaseAddress
2022-05-03  saiswetha.pingali@auspost.com.au - Removed parseEmailbodySnapIT as it is no more used.
2022-11-04  Naveen Rajanna - REQ3018517 Add null check to prevent nullpointerexception for startrackDuplicateInboundEmail
2023-02-09  Swati.mogadala@auspost.com.au - Added 'From Email address' check when filtering ST duplicate cases created from incoming emails
2023-05-29  mahesh.parvathaneni@auspost.com.au - Added record type check for Transport Enquiry record type to not to update the EmailToCaseAddress__c
**************************************************/
public inherited sharing class EmailMessageUtil {

	private static final String REFSTART = 'Article Number:';
	private static final String REFEND = '.';
	public static final String STATUS_NEW = '0';
	public static final String STATUS_READ = '1';
	public static final String STATUS_REPLIED = '2';
	public static final String STATUS_SENT = '3';
	public static final String STATUS_FORWARDED = '4';
	public static final String STATUS_DRAFT = '5';
	private static final String CASE_TRANSPORT_ENQUIRY_RT = 'Transport_Enquiry';

	/**
	 * This is used to set the source email to case address on a case when it's first received
	 */
	public static void setEmailToCaseAddress(Map<id, EmailMessage> newEmails) {
		// Map<Id, id> caseIdVsUserId = new Map<Id, id>();
		// List<Case> casesToUpdate = new List<Case>();
		// Map to store Case to be updated
		Map<Id, Case> caseMap = new Map<Id, Case>();
		// Get Secure Post settings.
		SecurePost__c securePostSetting = SecurePost__c.getInstance();
		// Get Product for Secure Post.
		List<Product2> productList = [SELECT id, name from Product2 where name = :securePostSetting.ProductName__c limit 1];
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			EmailMessage.SObjectType => new Set<SObjectField>{EmailMessage.Id, EmailMessage.ParentId, EmailMessage.Headers, EmailMessage.Incoming, EmailMessage.ToAddress, EmailMessage.CcAddress, EmailMessage.FromAddress},
			Case.SObjectType => new Set<SObjectField>{Case.EmailToCaseAddress__c, Case.Bypass_Data_enforcement__c},
			RecordType.getSObjectType() => new Set<SObjectField>{RecordType.DeveloperName}
		};
		for (EmailMessage em : EmailMessagesSelector.newInstance(fieldOverrides).selectById(newEmails.keySet(), new Set<Object>{EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE})) {
			if (em.Incoming && !String.isBlank(em.headers) && (em.headers).startsWith('Return-Path:')) {
					string[] headerSplits = em.headers.split('\\r?\\n');
					//ignore for Transport Enquiry record type as it is being set in the TransportEnquiryEmailMessagesModule
					if(!CASE_TRANSPORT_ENQUIRY_RT.equals(em.Parent.RecordType.DeveloperName)) {
						em.parent.EmailToCaseAddress__c = headerSplits[0].substring(12);
					}
					em.parent.Email_Bypass_Data_enforcement__c = true;
					caseMap.put(em.ParentId, em.Parent);
			}
			// Added check for Secure Post to update Type & Product on Case for SECURE_POST
			if (securePostSetting!= null && securePostSetting.Email_to_Case_address__c != null && em.ToAddress != null && em.ToAddress.contains(securePostSetting.Email_to_Case_address__c)) { // Check if ToAddress is Secure Post email Address
				if(em.ParentId!= null && caseMap.containsKey(em.ParentId)) { // Check if Case is already added in Map
					Case cs = caseMap.get(em.ParentId);
					cs.Type = securePostSetting.CaseType__c != null ? securePostSetting.CaseType__c : '';
					if(productList != null && productList.size() > 0){
						cs.ProductId = productList[0].id;
					}
					caseMap.put(em.ParentId, cs);
				}
				else { // If case not added in the map
					em.Parent.Type = securePostSetting.CaseType__c != null ? securePostSetting.CaseType__c : '';
					if(productList != null && productList.size() > 0){
						em.Parent.ProductId = productList[0].id;   
					}
					caseMap.put(em.ParentId, em.Parent);
				}
			}
		}
		if(caseMap.size() > 0){
			Database.update(caseMap.values());
		}
	}

	public static void detectSpamEmailOnCases(List<EmailMessage> newEmails) {
		Set<Id> caseIds = new Set<Id>();
		for (EmailMessage em : newEmails) {
			if (em.Incoming && em.parentId != null) {
				caseIds.add(em.parentId);
			}
		}
		Map<String, List<Case>> shortListed = new Map<String, List<Case>>();
		for (Case c : [select Origin, SuppliedEmail, Prevent_Email__c from Case where SuppliedEmail != null and Origin = 'Direct Email' and id in :caseIds]) {
			if (shortListed.get(c.SuppliedEmail) == null) {
				shortListed.put(c.SuppliedEmail, new List<Case>());
			}
			shortListed.get(c.SuppliedEmail).add(c);
		}

		if (!shortListed.isEmpty()) {
			AusPostSettings__c settings = AusPostSettings__c.getValues('Spam Email Settings');
			if (settings == null) {
				settings = new AusPostSettings__c(Name = 'Spam Email Settings', Number1__c = 30);
				insert settings;
			}
			integer secondsInterval = settings.Number1__c == null ? 30 : integer.valueOf(settings.Number1__c);
			Map<String, EmailMessage> emailsToBlacklist = new Map<String, EmailMessage>();
			String currentFromEmail = null;
			for (EmailMessage em : [select FromAddress, parentId, Incoming, createdDate from EmailMessage where id not in :newEmails and Incoming = true and parent.Origin = 'Direct Email' and createdDate = today and FromAddress in :shortListed.keySet() order by FromAddress, createdDate desc]) {
				if (currentFromEmail == null || currentFromEmail != em.FromAddress) {
					if (em.CreatedDate.addSeconds(secondsInterval) > Datetime.now()) {
						emailsToBlacklist.put(em.FromAddress, em);
					}
				}
				currentFromEmail = em.FromAddress;
			}

			if (!emailsToBlacklist.isEmpty()) {
				Set<String> existingBlacklist = new Set<String>();
				for (SpamEmail__c s : [select FromEmail__c from SpamEmail__c where FromEmail__c in :emailsToBlacklist.keySet()]) {
					existingBlacklist.add(s.FromEmail__c);
				}
				Map<String, SpamEmail__c> newBlacklist = new Map<String, SpamEmail__c>();
				for (String email : emailsToBlacklist.keySet()) {
					if (!existingBlacklist.contains(email) && !newBlacklist.containsKey(email)) {
						newBlacklist.put(email, new SpamEmail__c(FromEmail__c = email, Case__c = emailsToBlacklist.get(email).parentId));
					}
				}
				if (!newBlacklist.isEmpty()) {
					insert newBlacklist.values();
				}
			}
		}
	}

	public static void detectPermanentSpam(List<EmailMessage> newEmails) {
		Set<String> emailsToCheck = new Set<String>();
		Map<String, List<EmailMessage>> mappedNewEmails = new Map<String, List<EmailMessage>>();
		for (EmailMessage em : newEmails) {
			if (em.parent != null && em.parent.origin == 'Direct Email' && em.Incoming) {
				emailsToCheck.add(em.FromAddress);
				if (mappedNewEmails.get(em.FromAddress) == null) {
					mappedNewEmails.put(em.FromAddress, new List<EmailMessage>());
				}
				mappedNewEmails.get(em.FromAddress).add(em);
			}
		}

		List<SpamEmail__c> changedSpamEmails = new List<SpamEmail__c>();
		for (SpamEmail__c sp : [select FromEmail__c,Case__c from SpamEmail__c where FromEmail__c in :emailsToCheck]) {
			id caseId = sp.Case__c;
			for (EmailMessage em : mappedNewEmails.get(sp.FromEmail__c)) {
				if (caseId == null) {
					caseId = em.ParentId;
					sp.Case__c = em.ParentId;
					changedSpamEmails.add(sp);
				} else {
					em.ParentId = caseId;
				}
			}
		}

		update changedSpamEmails;
	}

	//Ensures Customer Emails routed back into Salesforce show as Outbound, not Incoming. Also prevents Email to Case 'Notify Case Owner' Issue
	public static void switchInboundToOutbound(List<EmailMessage> newEmails) {
		// fetch Customer Address from Custom Setting
		QM__c configSetting = QM__c.getInstance();
		string custfromAddress = configSetting.CusEmail__c;
		string networkfromAddress = configSetting.NetworkEmail__c;

		for (EmailMessage em : newEmails) {
			if ((em.FromAddress == custfromAddress || em.FromAddress == networkfromAddress) && em.Incoming) {
				em.Incoming = false;
                em.EmailRoutingAddressId = null; // Spring-24 release new field introduced
			}
		}
	}


	//StarTrack method which detects duplicate inbound email message based on email message subject.
	//Created by: David Catindoy (Accenture) - Nov. 24, 2016
	public static void startrackDuplicateInboundEmail(List<EmailMessage> newEmails) {

		//Check if newEmails is not empty.
		if (!newEmails.isEmpty()) {
			//Initialize containers.
			Map<Id, EmailMessage> caseToEmailMessage = new Map<Id, EmailMessage>();
			List<String> emailMessageSubject = new List<String>();
			List<String> fromEmailAddr = new List<String>();
			List<EmailMessage> emailMessageList = new List<EmailMessage>();
			List<EmailMessage> starTrackEmailMessages = new List<EmailMessage>();
			StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
			Set<Id> newCasesId = new Set<Id>();

			for (EmailMessage emailMessageRec : newEmails) {
				caseToEmailMessage.put(emailMessageRec.ParentId, emailMessageRec); //Add Case Id as the key and email record as the value in the map.
			}

			for (Case caseRec : [SELECT Id, RecordType.Developername FROM Case WHERE Id IN :caseToEmailMessage.keySet()]) {
				if (caseRec.RecordType.Developername.startsWith(StarTrack_Constants.CASE_STARTRACK_RECTYPE)) { //Validate if case is a StarTrack record.
					starTrackEmailMessages.add(caseToEmailMessage.get(caseRec.Id));
				}
			}	

			if (!starTrackEmailMessages.isEmpty()) {
				for (EmailMessage newEmail : starTrackEmailMessages) {
					String emailSubject = newEmail.Subject; //Get email message subject to avoid modification in the actual subject field.
					String fromEmailAddress = newEmail.FromAddress; //Get 'FromAddress' from the incoming email
					//Validate if email body contains parent case thread Id.
					// System.debug('Case Thread Id: ' + getThreadId(newEmail.ParentId));
					// System.debug('Current parent id: ' + newEmail.ParentId);
					//REQ3018517
					if (emailSubject != null && newEmail.Incoming && fromEmailAddress!=null &&
							(String.isBlank(newEmail.HTMLBody) || 
								(String.isNotBlank(newEmail.HTMLBody) && !newEmail.HTMLBody.contains(getThreadId(newEmail.ParentId))))) {
						
						//Validate if Subject contains any of the specified prefix.
						if (emailSubject.containsIgnoreCase(StarTrack_Constants.rePrefix) || emailSubject.containsIgnoreCase(StarTrack_Constants.forwardPrefix1) || emailSubject.containsIgnoreCase(StarTrack_Constants.forwardPrefix2)) {
							emailSubject = getEmailSubject(emailSubject); //Call the method that removes all the prefix that is found in the subject.
							emailMessageSubject.add(emailSubject); //Add the new subject value to the container.
							fromEmailAddr.add(fromEmailAddress);// Add the incoming email value to container.
							newCasesId.add(newEmail.ParentId);
							emailMessageList.add(newEmail);
							// System.debug('Valid 255');
						}
					}
				}

				//Check if emailMessageSubject container is not empty.
				if (!emailMessageSubject.isEmpty()) {
					//Initialize new local containers.
					Map<String, Case> caseSubjectMap = new Map<String, Case>();
					Map<Id, Case> parentCase = new Map<Id, Case>();
					List<Case> existingCases = new List<Case>([
							SELECT Id, Subject, CreatedDate, CaseNumber,SuppliedEmail
							FROM Case
							WHERE Id NOT IN :newCasesId AND CreatedDate >= :(System.now() - Integer.valueOf(customSetting.Email2Case_Check_Last_X_Days__c)) AND Subject IN :emailMessageSubject AND SuppliedEmail IN :fromEmailAddr
							AND RecordType.DeveloperName LIKE 'StarTrack%'
							ORDER BY CreatedDate ASC
					]); //Query cases that matches with the criteria. Used ORDER BY CreatedDate ASC to make sure that we get old cases first.
					if (!existingCases.isEmpty()) {
						for (Case caseRec : existingCases) {
							caseSubjectMap.put(caseRec.Subject, caseRec); //Put case subject as the key and case Id as the value. For instance, if two were was found with the same subject, then the old one will be replaced by the most latest record.
						}

						for (EmailMessage emailMessageRec : emailMessageList) {
							String emailSubject = getEmailSubject(emailMessageRec.Subject); //Call the method that removes all the prefix that is found in the subject.
							if (caseSubjectMap.containsKey(emailSubject)) { //Validate if the map contains email message subject.
								parentCase.put(emailMessageRec.ParentId, caseSubjectMap.get(emailSubject));
								emailMessageRec.ParentId = caseSubjectMap.get(emailSubject).Id;//Reassign parent Id to an existing case that matches the subject of the email.
								// System.debug('Success! 277');
							}
						}
					}

					if (!parentCase.isEmpty()) {

						List<Case> casesToUpdate = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c, Origin FROM Case WHERE Id IN :parentCase.keySet()]; //Query cases that are tagged as duplicate.
						for (Case caseRec : casesToUpdate) {
							String subject = StarTrack_Constants.DUPLICATE_CASE + parentCase.get(caseRec.Id).CaseNumber + '-' + caseRec.Subject; //Append duplicate prefix on the subject.
							caseRec.Subject = subject.left(255);
							caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE; //Assign default resolution code.
							caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED; //Set the case status to closed.
							caseRec.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF; //Assign default case/enquiry type.
							caseRec.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEF; //Assign default case purpose.
							if (StarTrack_Constants.CASE_ORIGIN_BSC.equals(caseRec.Origin)) {
								caseRec.Origin = StarTrack_Constants.CASE_ORIGIN_EMAIL; //Change case origin to 'Email' if current value is 'Email - BSC'.
							}
						}
						Database.update(casesToUpdate); //Update case record/s in the container.
					}
				}
			}
		}
		// System.debug(newEmails);
	}

	//StarTrack method to generate case thread id based on the id passed in the parameter.
	//Created by: David Catindoy - Nov. 24, 2016
	private static String getThreadId(String caseId) {
		return '[ ref:_' + UserInfo.getOrganizationId().left(4) + '0' + UserInfo.getOrganizationId().mid(11, 4) + '._' + caseId.left(4) + '0' + caseId.mid(10, 5) + ':ref ]';
	}

	//StarTrack method that removes unnecessary prefix to the subject.
	//Created by: David Catindoy - Nov. 25, 2016
	private static String getEmailSubject(String emailSubject) {
		emailSubject = emailSubject.containsIgnoreCase(StarTrack_Constants.rePrefix) ? emailSubject.remove(StarTrack_Constants.rePrefix).remove(StarTrack_Constants.rePrefix2) : emailSubject;
		emailSubject = emailSubject.containsIgnoreCase(StarTrack_Constants.forwardPrefix1) ? emailSubject.remove(StarTrack_Constants.forwardPrefix1).remove(StarTrack_Constants.forwardPrefix3) : emailSubject;
		emailSubject = emailSubject.containsIgnoreCase(StarTrack_Constants.forwardPrefix2) ? emailSubject.remove(StarTrack_Constants.forwardPrefix2).remove(StarTrack_Constants.forwardPrefix4) : emailSubject;
		return emailSubject;
	}

	public static void processVOCIncidentEmails(List<EmailMessage> newEmails) {
		if (!newEmails.isEmpty()) {
			Map<Id, EmailMessage> emailMessageMap = new Map<Id, EmailMessage>();
			Map<Id, Id> childToParentMap = new Map<Id, Id>();
			List<Case> caseList = new List<Case>();
			for (EmailMessage emailRec : newEmails) {
				if (emailRec.Incoming) {
					emailMessageMap.put(emailRec.ParentId, emailRec);
				}
			}

			for (Case incidentCase : [SELECT Id, ParentId, RecordType.Name FROM Case WHERE ParentId != null AND Id IN :emailMessageMap.keySet() AND RecordType.Name = :StarTrack_Constants.CASE_VOCINC_RT]) {
				childToParentMap.put(incidentCase.Id, incidentCase.ParentId);
			}

			if (!childToParentMap.isEmpty()) {

				for (EmailMessage emailRec : emailMessageMap.values()) {
					emailRec.ParentId = childToParentMap.get(emailRec.ParentId);
				}

				for (Case caseRec : [SELECT Id, Status FROM Case WHERE Id IN :childToParentMap.values()]) {
					if (!StarTrack_Constants.CASE_STAT_AWAITINGREVIEW.equals(caseRec.Status)) {
						caseRec.Status = StarTrack_Constants.CASE_STAT_AWAITINGREVIEW;
						caseList.add(caseRec);
					}
				}

				Database.update(caseList);
			}
		}
	}
}