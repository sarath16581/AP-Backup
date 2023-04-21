/**
 * @description Domain Module generic for Case Email Messages
 * @author Naveen Rajanna
 * @date 2022-10-12
 * @group Modules
 * @domain EmailMessageCasesDomain
 * @test EmailMessageGenericCaseAutomationMd_Test
 * @changelog
 * 2022-10-12 - Naveen Rajanna - Created - REQ2859152
 */
public inherited sharing class EmailMessageGenericCaseAutomationModule extends ApplicationDomain.Module {
	public static EmailMessageGenericCaseAutomationModule newInstance() {
		return (EmailMessageGenericCaseAutomationModule) Application.Utilities.newInstance(EmailMessageGenericCaseAutomationModule.class);
	}

	// Setup which triggers this module should respond to
	public EmailMessageGenericCaseAutomationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	/**
	 * Methods to invoke on after insert trigger context
	 * @param records Email Messages in Trigger.New
	 * @param uow
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			setEmailToCaseFields(records, uow);
			setInternationalCases(records, uow);
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(e),
					'',
					EmailMessageGenericCaseAutomationModule.class.getName(),
					'onAfterInsert',
					'EmailMessage',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	// This method gets all the emails (To, CC and BCC) from the email message and checks if any of them matches with the one in the custom setting InternationalEmailToCaseEmail__c. 
	// If they do then it set the Case's product category to the custom setting's InternationalProductCategory__c
	void setInternationalCases(List<EmailMessage> records, ApplicationUnitOfWork uow) {
		QM__c settings = QM__c.getOrgDefaults();
		List<Case> casesToUpdate = new List<Case>();
		if(String.isBlank(settings.InternationalEmailToCaseEmail__c) == false && String.isBlank(settings.InternationalProductCategory__c) == false) {
			for(EmailMessage em: records) {
				Set<String> emails = getUniqueEmails(em.ToAddress);
				emails.addAll(getUniqueEmails(em.CCAddress));
				emails.addAll(getUniqueEmails(em.BCCAddress));

				if(emails.contains(settings.InternationalEmailToCaseEmail__c) == true) {
					casesToUpdate.add(new Case(Id = em.ParentId, ProductCategory__c = settings.InternationalProductCategory__c));
				}
			}
		}

		if(casesToUpdate.isEmpty() == false) {
			uow.registerDirty(casesToUpdate, new List<SObjectField>{ Case.ProductCategory__c }, 'In EmailMessageGenericCaseAutomationModule trying to set the product category');
		}
	}

	Set<String> getUniqueEmails(String emailString) {
		Set<String> result = new Set<String>();
		if(String.isBlank(emailString) == false) {
			for(String email: emailString.split(';')) { // just in case there are more than one; they are separated by ';'
				result.add(email.trim());
			}
		}
		return result;
	}

	/**
	 * Populate certain Case fields from incoming emails
	 * @param records Trigger.new
	 * @param uow
	 */
	public void setEmailToCaseFields(List<EmailMessage> records, ApplicationUnitOfWork uow) {
		List<Case> caseUpdateList = new List<Case>();
		Set<Id> emailIdSet = (new Map<Id, EmailMessage>(records)).keySet();

		// Get selected emailMessage with related case fields
		EmailMessagesSelector selector = EmailMessagesSelector.newInstance();
		Set<Object> selectorOptions = new Set<Object>{
			EmailMessagesSelector.Options.WITH_CASE,
			EmailMessagesSelector.Options.FILTER_INCOMING
		};
		List<EmailMessage> emailList = selector.selectById(emailIdSet, selectorOptions);

		for (EmailMessage em : emailList) {
			// Set Case LastIncomingEmailAddress__c based on FromAddress for an incoming email
			if (!em.FromAddress.equalsIgnoreCase(em.Parent.LastIncomingEmailAddress__c)) {
				caseUpdateList.add(new Case(Id = em.ParentId, LastIncomingEmailAddress__c = em.FromAddress));
			}
			//TODO: Move logic from setEmailToCaseAddress in Email Trigger to here
		}

		if (!caseUpdateList.isEmpty()) {
			//register to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
			uow.registerDirty(caseUpdateList);
		}
	}
}