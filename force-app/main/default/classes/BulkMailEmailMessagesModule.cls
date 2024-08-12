/**
 * @description
 * The email message module for handling the Bulk Mail email to case
 * @author Thang Nguyen
 * @date 2024-04-05
 * @group Domain
 * @domain EmailMessageCasesDomain
 * @changelog
 * 2024=05-08 - Boris Bachovski - Update First_Email_Response__c field on case when outgoing email is sent + Complete Bulk Mail First Response milestone
 * 2024-08-07 - Ranjeewa Silva - Uplifted to new ApplicationModule framework
 */

 public inherited sharing class BulkMailEmailMessagesModule extends ApplicationModule {

	private static Map<String, EmailToCaseMapping__mdt> emailToCaseMappingMap;

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

	@TestVisible
	private static final Id bulkMailQueueId {
		get {
			if (bulkMailQueueId == null) {
				bulkMailQueueId = BulkMailSettings__c.getOrgDefaults().BulkMailQueueId__c;
			}
			return bulkMailQueueId;
		}
		private set;
	}

	// Setup which triggers this module should respond to
	public BulkMailEmailMessagesModule() {
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
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Bulk Mail Case Management', BulkMailEmailMessagesModule.class.getName(), 'onAfterInsert', BGSConstants.EMAILMESSAGE_TRIGGER, LoggingLevel.ERROR);
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
		Set<Id> milestoneCaseIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		Map<Id, EmailMessage> filteredMessages = new Map<Id, EmailMessage>();
		Map<Id, EmailMessage> emailsToProcess = new Map<Id, EmailMessage>();
		Map<Id, String> emailIdToCaseEmailValueMap = new Map<Id, String>();
		Map<Id, Case> casesMap = new Map<Id, Case>();
		List<Case> casesToUpdate = new List<Case>();

		// Get record type for transport enquiry case
		Id recordTypeId = BulkMailCaseService.getInstance().getBulkMailRecordTypeId();

		// Field overrides for cases
		Set <SObjectField> caseFieldOverrides = new Set <SObjectField>{ Case.Id, Case.Permanent_Close__c, Case.Status, Case.EmailToCaseAddress__c, Case.Priority, Case.Call_Purpose__c, Case.Origin, Case.Enquiry_Type__c, Case.Product_Type__c, Case.Source__c, Case.First_Email_Response__c };

		//Get the selected emailMessage with related case fields, whose parent case recordtype is Bulk Mail
		EmailmessagesSelector emSelector = EmailMessagesSelector.newInstance();
		emSelector.setFieldOverrides(new Map <SObjectType, Set <SObjectField>> { Case.SObjectType => caseFieldOverrides });

		for (EmailMessage em : emSelector.selectByIdsAndParentRecordTypeId(emailIdSet, new Set<Id>{recordTypeId}, 
										new Set <Object>{ EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE })) {
			if (em.Incoming)
			{
				filteredMessages.put(em.Id, em);
				caseIds.add(em.ParentId);
			}

			// Outgoing message (First Response) - add the case Id to the milestoneCaseIds set, we'll complete the Bulk Mail First Response milestone.
	    	if (!em.Incoming && !em.Parent.First_Email_Response__c && (EmailMessageUtil.STATUS_REPLIED.equals(em.Status) || EmailMessageUtil.STATUS_SENT.equals(em.Status))) {
				if (em.Parent.Status == 'New')
				{
					casestoUpdate.add(new Case(Id = em.ParentId, First_Email_Response__c = true, Status = BulkMailCaseService.IN_PROGRESS_STATUS));
				}

				milestoneCaseIds.add(em.ParentId);
			}
		}

		if (!caseIds.isEmpty()) {
			// Grab the cases and their associated incoming email messages to check whether the incoming email messages are the first one attached to the case
			// If it is, then we treat this as a new case and therefore the EmailToCaseAddress__c and other related fields needs to be updated on the case
			// If the case is closed, then re-open the case 

			Datetime currentTimeStamp = currentTime;

			for (Case cs : CasesSelector.newInstance(caseFieldOverrides).selectById(caseIds, new Set <Object> { CasesSelector.Options.WITH_INCOMING_EMAIL_MESSAGES_ASC_ORDER }).values()) {
				casesMap.put(cs.Id, cs);

				if (!cs.Permanent_Close__c && !cs.EmailMessages.isEmpty() && (String.isNotBlank(cs.EmailToCaseAddress__c) || 'Email'.equalsIgnoreCase(cs.Origin) == false)) {
					// New email received - update Case_Update__c field 
					Case caseRecord =  new Case(Id = cs.Id, Case_Update__c = BulkMailCaseService.NEW_EMAIL_RECEIVED, Case_Update_Time__c = currentTimeStamp);
	
					// Re-open the case if there is incoming email message to closed case
					if (BulkMailCaseService.CLOSED_STATUS.equalsIgnoreCase(cs.Status)) {
						caseRecord.Status = BulkMailCaseService.REOPENNED_STATUS;
						caseRecord.OwnerId = bulkMailQueueId;
					}

					casesToUpdate.add(caseRecord);
				} 
				else if (!cs.EmailMessages.isEmpty() && filteredMessages.containsKey(cs.EmailMessages[0].Id) && 'Email'.equalsIgnoreCase(cs.Origin)) {
					//update the case fields if it is new case created from email-to-case
					emailsToProcess.put(cs.EmailMessages[0].Id, filteredMessages.get(cs.EmailMessages[0].Id));
				} 
			}

			if (!emailsToProcess.isEmpty()) {
				//get the configured metadata
				emailToCaseMappingMap = getEmailToCaseMappingMetadata();
				//get the email to case address from the email message
				for (EmailMessage em : emailsToProcess.values()) {
					emailIdToCaseEmailValueMap.put(em.Id, EmailMessageUtil.getEmailToCaseAddressFromHeader(em, emailToCaseMappingMap));
				}
	
				// Remove all messages that don't have a matching Email to case address
				for (Id messageId :emailsToProcess.keySet()) {
					if (!emailToCaseMappingMap.containsKey(emailIdToCaseEmailValueMap.get(messageId))) {
						emailsToProcess.remove(messageId);
					}
				}
	
				// update the cases with the configured metadata for the emails to process
				for (EmailMessage eMessage : emailsToProcess.values()) {
					casesToUpdate.add(getCaseToUpdate(eMessage, casesMap.get(eMessage.ParentId), emailToCaseMappingMap.get(emailIdToCaseEmailValueMap.get(eMessage.Id))));
				}
			}
		}

		if (!casesToUpdate.isEmpty()) {
			//update cases
			uow.registerDirty(casesToUpdate, true, BulkMailEmailMessagesModule.class.getName());
		} 

		// Update the Bulk Mail First Response milestone
		if (!milestoneCaseIds.isEmpty()) {
			// Update the Bulk Mail First Response milestone
			List <CaseMilestone> caseMilestones = new List <CaseMilestone>();
			for (CaseMilestone cm : CaseMilestonesSelector.newInstance().selectByCaseAndMilestoneNames(milestoneCaseIds, new Set<String>{BulkMailCaseService.BULK_MAIL_FIRST_RESPONSE_MILESTONE}, new Set<Object>())) {
				caseMilestones.add(new CaseMilestone(Id = cm.Id, CompletionDate = System.now()));
			}

			// We have to use Database.update method here because the Case Milestone is getting recreated (this original milestone gets deleted and doesn't exist at the time the uow commits), once the case status is changed and the UOW throws an error.
			ApplicationDatabase.getInstance().dmlUpdate(caseMilestones);
		}
	}

	/**
	 * This method returns the case record with updated fields based on the EmailToCaseMapping custom metadata
	 * @param parentCase case record
	 * @param emailToCaseMapping custom metadata record.
	 *
	 * @return updated case record
	 */
	private Case getCaseToUpdate(EmailMessage em, Case parentCase, EmailToCaseMapping__mdt emailToCaseMapping) {
		return new Case(
			Id = parentCase.Id,
			Enquiry_Type__c = BulkMailCaseService.CASE_TYPE,
			Source__c = String.valueOf(em.FromAddress).contains(BulkMailCaseService.INTERNAL_EMAIL_DOMAIN) ? BulkMailCaseService.INTERNAL_CUSTOMER_SOURCE : BulkMailCaseService.CUSTOMER_SOURCE,
			Product_Type__c = String.isNotBlank(emailToCaseMapping.ProductType__c) ? emailToCaseMapping.ProductType__c : parentCase.Product_Type__c,
			EmailToCaseAddress__c = emailToCaseMapping.EmailToCaseAddress__c,
			Call_Purpose__c = String.isNotBlank(emailToCaseMapping.CasePurpose__c) ? emailToCaseMapping.CasePurpose__c : parentCase.Call_Purpose__c
		);
	}
}