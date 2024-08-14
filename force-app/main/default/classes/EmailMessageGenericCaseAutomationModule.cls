/**
 * @description Application Module generic for Case Email Messages
 * @author Naveen Rajanna
 * @date 2022-10-12
 * @group Modules
 * @domain EmailMessageCasesDomain
 * @test EmailMessageGenericCaseAutomationMd_Test
 * @changelog
 * 2022-10-12 - Naveen Rajanna - Created - REQ2859152
 * 2024-08-07 - Ranjeewa Silva - Uplifted to new ApplicationModule framework
 */
public inherited sharing class EmailMessageGenericCaseAutomationModule extends ApplicationModule {

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