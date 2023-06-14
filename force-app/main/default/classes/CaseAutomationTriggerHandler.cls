/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 */
public inherited sharing class CaseAutomationTriggerHandler extends ApplicationTriggerHandler {
	
	private static Set<Id> ssswRecordTypes = null;
	private static Set<Id> ssswRecordTypesWithSocial = null;
	private static Set<Id> starTrackRecordTypes = null;

	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override void registerModules() {
		
		// APCC - SAP-EM Case articles for linking articles to cases and querying articles on the fly
		registerModule(MyCustomerCaseArticlesModule.class);

		registerModule(StarTrackCalculateCaseDepotModule.class);
		registerModule(StarTrackSupportCaseContactsModule.class);
		registerModule(StarTrackSupportCasePriorityModule.class);
		registerModule(StarTrackSupportCaseAutomationModule.class);
		registerModule(StarTrackSupportCaseOwnerModule.class);
		registerModule(StarTrackSupportCaseCustomerModule.class); 
		registerModule(StarTrackDeliveryEnquiryProcessModule.class);
		registerModule(StarTrackTrackingIDSearchModule.class);

		// all of the old case execution logic which hasn't been uplifted yet
		registerModule(CaseLegacyAutomationModule.class);

		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(CaseOwnerMetricsModule.class);

		// The case survey Invitation Module tests case data for entry criteria for sending
		// Survey Invitations. Those records which meet specified criteria are enqued and sent to 
		// the survey service and the last survey sent date on the case object is updated to reflect this.
		registerModule(CaseSurveyInvitationModule.class);

		// Logic relating to Omni Skills-based Routing, setting Case fields for Skill assignment
		// Related to SSSW Cases only, the module filters based on recordtype
		// a) Populate Case attributes used in Skills routing rules
		// b) AgentType field for Omni skill assignment
		//
		// NOTE: must run after the legacy code in CaseTriggerHandler.cls. It has logic that depends on Case.AccountId AND must execute after the routing engine - SSSW_Routing.assignCasesAndDescription()
		// Refactor Guidance - the logic in this code needs to be positioned: i) in CaseTriggerUtility.beforeHandler() ii) when caseUtility.assignContactIDToCase() is called
		registerModule(CaseSkillBasedRoutingModule.class);

	}

	//=================================== CUSTOM FILTERS FOR MODULES
	public static List<SObject> filterSSSW(List<SObject> records) {
		if(ssswRecordTypes == null) {
			ssswRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet();
		}
		return ApplicationTriggerHandler.filterByRecordType(records, ssswRecordTypes);
	}

	public static List<SObject> filterSSSWWithSocial(List<SObject> records) {
		if(ssswRecordTypesWithSocial == null) {
			Set<String> developerNames = new Set<String>{'SSSW', 'Social'};
			ssswRecordTypesWithSocial = new RecordTypesSelector().selectByDeveloperNamesLike('Case', developerNames).keySet();
		}
		return ApplicationTriggerHandler.filterByRecordType(records, ssswRecordTypesWithSocial);
	}

	public static List<SObject> filterStarTrackCases(List<SObject> records) {
		if(starTrackRecordTypes == null) {
			starTrackRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
		}
		return ApplicationTriggerHandler.filterByRecordType(records, starTrackRecordTypes);
	}
	//=================================== CUSTOM FILTERS FOR MODULES

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			Case.SObjectType,
			Article__c.SObjectType,
			Task.SObjectType,
			CaseMilestone.SObjectType,
			AuthorisedContacts__c.SObjectType,
			PendingServiceRouting.SObjectType,
			CaseInvestigation__c.SObjectType
		};
	}

}