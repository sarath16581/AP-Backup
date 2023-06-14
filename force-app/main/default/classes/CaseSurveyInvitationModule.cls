/***
 * @author Ken McGuire
 * @date 2022-04-26
 * @description Send Surveys out to a Case that has meet survey entry criteria.  
 * @changelog
 * 2023-06-14 - Nathan Franklin - uplift to domainless architecture
 */
public inherited sharing  class CaseSurveyInvitationModule extends ApplicationDomain.Module {
	
    /*
	 * Creates a new instance of the utility to facilitate dependency injection for mocking
	 * @return the new instance
	 * @deprecated
	 */
	public static CaseSurveyInvitationModule newInstance() {
		return (CaseSurveyInvitationModule)Application.Utilities.newInstance(CaseSurveyInvitationModule.class);
	}
    
	/*
	 * A persistant instance of the utility used to identify those records which require a survey to be sent out
	 * and enque processthe surveys to be sent.
	 * @return the static instance of the case survey utility.
	 */
	private static SurveyService caseSurveyService {
		get {
			if (caseSurveyService == null) caseSurveyService = SurveyService.getInstance();
			return caseSurveyService;  
		}
		private set;
	}

	// Constructor
	public CaseSurveyInvitationModule() {
		// Setup which triggers this module should respond to
		getTriggerEvents().enableAfterUpdate().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow)  {
		try {
			sendSurveyInvitations(records, null, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	public override void  onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
		try {
			sendSurveyInvitations(records, existingRecords, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/*
	 * Uses the Survey Utility to identify and send surveys for qualifying records
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 */
	private void sendSurveyInvitations(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        Application.Profiler.start('CaseSurveyInvitationModule.sendSurveyInvitations');

		// enquedRecordUpdates contains a map of update values to case objects that will be applied when the survey invitations are sent.
		// Namely, the "last survey sent date" field will be set to the current Date.
		Map<Id,SObject> enquedRecordUpdates = new Map<Id,SObject>();
		
        for (Id currentRecordId : caseSurveyService.enqueSurveyInvitations(records,existingRecords)) {
			enquedRecordUpdates.put(currentRecordId,new Case(Id = currentRecordId, LastSurveySentDate__c = Date.today()));
		}

		if(enquedRecordUpdates.size()>0) {
			caseSurveyService.sendInvitations(enquedRecordUpdates);
		}
        Application.Profiler.stop('CaseSurveyInvitationModule.sendSurveyInvitations');
	}
}