/**
 * @description
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Mahesh Parvathaneni
 * @date 2023-05-26
 * @group Domain
 * @domain EmailMessageCasesDomain
 * @changelog
 */

public inherited sharing class TransportEnquiryEmailMessagesModule extends ApplicationDomain.Module {

	//constants
	private static Map<String, EmailToCaseMapping__mdt> emailToCaseMappingMap;
	private static Set<String> emailHeaders = new Set<String>{'Return-Path','Delivered-To'};

	/**
	 * This method get the map of email address to email to case mapping metadata
	 */
	@TestVisible
	private static Map<String, EmailToCaseMapping__mdt> getEmailToCaseMappingMetadata() {
		if (emailToCaseMappingMap == null) {
			emailToCaseMappingMap = new Map<String, EmailToCaseMapping__mdt>();
			//get active email to case mapping metadata
			for (EmailToCaseMapping__mdt mapping : EmailToCaseMappingsSelector.newInstance().selectAll(new Set<Object>{ EmailToCaseMappingsSelector.Options.FILTER_ACTIVE })) {
				emailToCaseMappingMap.put(mapping.EmailToCaseAddress__c.toLowerCase(), mapping);
			}
		}
		return emailToCaseMappingMap;
	}

	@TestVisible
	private Datetime currentTime {
		get{
			if(currentTime == null){
				currentTime = System.now();
			}
			return currentTime;
		}
		private set;
	}

	public static TransportEnquiryEmailMessagesModule newInstance() {
		return (TransportEnquiryEmailMessagesModule) Application.Utilities.newInstance(TransportEnquiryEmailMessagesModule.class);
	}

	// Setup which triggers this module should respond to
	public TransportEnquiryEmailMessagesModule() {
		getTriggerEvents().enableAfterInsert();
	}

	/**
	 * This method is called when a new EmailMessage is being inserted
	 * @param records list of email messages
	 * @param uow instance of UnitOfWork
	 *
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateRelatedCases(records, uow); //update related case fields
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Transport Enquiry Case Management', TransportEnquiryEmailMessagesModule.class.getName(), 'onAfterInsert', BGSConstants.EMAILMESSAGE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * This method performs updated to related case records
	 * @param newEmails list of email messages
	 * @param uow instance of UnitOfWork
	 *
	 */
	public void updateRelatedCases(List<SObject> newEmails, ApplicationUnitOfWork uow) {
		Set<Id> emailIdSet = (new Map<Id,SObject>(newEmails)).keySet(); //Set containing emailmessage Id whose parent id is of case
		Set<Id> caseIds = new Set<Id>();
		Map<Id, EmailMessage> filteredMessages = new Map<Id, EmailMessage>();
		Map<Id, EmailMessage> emailsToProcess = new Map<Id, EmailMessage>();
		Map<Id, String> emailIdToCaseEmailValueMap = new Map<Id, String>();
		Map<Id, Case> casesMap = new Map<Id, Case>();
		List<Case> casesToUpdate = new List<Case>();

		//get record type for transport enquiry case
		Id recordTypeId = TransportEnquiryCaseService.getInstance().getTransportEnquiryRecordTypeId();

		//Get the selected emailMessage with related case fields, whose parent case recordtype is Transport enquiry
		for (EmailMessage em : EmailMessagesSelector.newInstance().selectByIdsAndParentRecordTypeId(emailIdSet, new Set<Id>{recordTypeId}, 
										new Set<Object>{EmailMessagesSelector.Options.FILTER_INCOMING, EmailMessagesSelector.Options.WITH_CASE})) {
			filteredMessages.put(em.Id, em);
			caseIds.add(em.ParentId);
		}

		if (!caseIds.isEmpty()) {
			// Grab the cases and their associated incoming email messages to check whether the incoming email messages are the first one attached to the case
			//  If it is, then we treat this as a new case and therefore the EmailToCaseAddress__c and other related fields needs to be updated on the case
			//  If the case is closed, then re-open the case 

			Datetime currentTimeStamp = currentTime;
			//field overrides for cases
			Set<SObjectField> fieldOverrides = new Set<SObjectField>{Case.Id, Case.Permanent_Close__c, Case.Status, Case.Network__c, Case.EmailToCaseAddress__c, Case.Priority, Case.Call_Purpose__c};

			for (Case cs : CasesSelector.newInstance(fieldOverrides).selectById(caseIds, new Set<Object>{CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER}).values()) {
				casesMap.put(cs.Id, cs);
				if(!cs.Permanent_Close__c && !cs.EmailMessages.isEmpty() && cs.EmailMessages.size() > 1 && String.isNotBlank(cs.EmailToCaseAddress__c)) {
					// New email received - update Case_Update__c field 
					Case caseRecord =  new Case(Id = cs.Id, Case_Update__c = TransportEnquiryCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = currentTimeStamp);
					// Re-open the case if there is incoming email message to closed case
					if (cs.Status == TransportEnquiryCaseService.CLOSED_STATUS) {
						caseRecord.Status = TransportEnquiryCaseService.NEW_STATUS;
					}
					casesToUpdate.add(caseRecord);
				} else if (!cs.EmailMessages.isEmpty() && filteredMessages.containsKey(cs.EmailMessages[0].Id)) {
					//update the case fields if it is new case created from email-to-case
					emailsToProcess.put(cs.EmailMessages[0].Id, filteredMessages.get(cs.EmailMessages[0].Id));
				} 
			}

			if (!emailsToProcess.isEmpty()) {
				//get the configured metadata
				emailToCaseMappingMap = getEmailToCaseMappingMetadata();
				//get the email to case address from the email message
				for (EmailMessage em : emailsToProcess.values()) {
					emailIdToCaseEmailValueMap.put(em.Id, getEmailToCaseAddressFromHeader(em));
				}
	
				// Remove all messages that don't have a matching Email to case address
				for (Id messageId :emailsToProcess.keySet()) {
					if (!emailToCaseMappingMap.containsKey(emailIdToCaseEmailValueMap.get(messageId))) {
						emailsToProcess.remove(messageId);
					}
				}
	
				// update the cases with the configured metadata for the emails to process
				for (EmailMessage eMessage : emailsToProcess.values()) {
					casesToUpdate.add(getCaseToUpdate(casesMap.get(eMessage.ParentId), emailToCaseMappingMap.get(emailIdToCaseEmailValueMap.get(eMessage.Id))));
				}
			}
		}

		if (!casesToUpdate.isEmpty()) {
			//update cases
			uow.registerDirty(casesToUpdate, true, TransportEnquiryEmailMessagesModule.class.getName());
		}
	}

	/**
	 * This method returns the email to case address from the EmailMessage which is configured in custom metadata. Loops through the header list and search for Return-Path or Delivered-To header.
	 * @param mail emailMessage record
	 *
	 * @return EmailAddress that matches to the EmailToCaseMapping custom metadata
	 */
	private String getEmailToCaseAddressFromHeader(EmailMessage mail) {
		String emailAddress;
		Map<String, List<String>> headerToEmailsMap = new Map<String, List<String>>();
		
		// Loop through the email headers and get the emails mapped to Return-Path and Delivered-To header.
		// If an email is sent (either To, Cc or Bcc) to any of the configured email to case address in our metadata, it will be captured in Return-Path (or) Delivered-To header.

		// All header lines are separated with \n
		for (String headerLine : mail.Headers.split('\n')) {
			// Split headerLine on first colon in two pieces
			List<String> segments = headerLine.split(':', 2);
			//check if there is header key and value and header key exists in our emailHeaders to track
			if (segments.size() > 1 && emailHeaders.contains(segments[0]) && String.isNotBlank(segments[1])) {
				if(headerToEmailsMap.get(segments[0]) == null) {
					headerToEmailsMap.put(segments[0], new List<String>());
				}
				//check if it is Return-Path header
				//extract the email address (testcaseau@outlook.com) from the Return-Path (ex- Return-Path:testcaseau+ SRS = PJ0XO = CJ = auspost.com.au = test.ap @outlook.com)
				if (segments[0].equalsIgnoreCase('Return-Path')) {
					segments[1] = segments[1].substringBefore('+').trim() + '@' + segments[1].substringAfterLast('@').trim();
				} 
				headerToEmailsMap.get(segments[0]).add(segments[1].trim());
			}
		}

		//Loop through the emailHeaders and get the first matching email from the configured metadata
		for (String header : emailHeaders) {
			if (String.isBlank(emailAddress) && headerToEmailsMap.size() > 0 && headerToEmailsMap.containsKey(header)) {
				for (String email : headerToEmailsMap.get(header)) {
					if (emailToCaseMappingMap.containsKey(email)) {
						emailAddress = email.toLowerCase();
						break;
					}
				}
			}
		}

		return emailAddress;
	}

	/**
	 * This method returns the case record with updated fields based on the EmailToCaseMapping custom metadata
	 * @param parentCase case record
	 * @param emailToCaseMapping custom metadata record.
	 *
	 * @return updated case record
	 */
	private Case getCaseToUpdate(Case parentCase, EmailToCaseMapping__mdt emailToCaseMapping) {
		return new Case(
			Id = parentCase.Id,
			Priority = String.isNotBlank(emailToCaseMapping.CasePriority__c) ? emailToCaseMapping.CasePriority__c : parentCase.Priority,
			Network__r = String.isNotBlank(emailToCaseMapping.AssignNetworkWCIS__c) ? new Network__c(Org_ID__c = emailToCaseMapping.AssignNetworkWCIS__c)  : new Network__c(Id = parentCase.Network__c),
			EmailToCaseAddress__c = emailToCaseMapping.EmailToCaseAddress__c,
			Call_Purpose__c = String.isNotBlank(emailToCaseMapping.CasePurpose__c) ? emailToCaseMapping.CasePurpose__c : parentCase.Call_Purpose__c
		);
	}
}