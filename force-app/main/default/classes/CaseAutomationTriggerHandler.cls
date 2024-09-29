/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 * 2023-11-23 - Thang Nguyen - include the credit claim case business logic
 * 2024-07-08 - Seth Heang - Added 'filterUnified' to recordtype filtering and register a new module for handling proactive monitoring queue routing
 * 2024-08-20 - George Nguyen - Added registerModule(CaseAutomationClassificationModule.class) to classify cases
 * 2024-09-03 - Seth Heang - registered CaseUnifiedTeamMemberModule for unified case
 * 2024-09-29 - Parveen Kaushik - Added unifiedCases filter for AutomationClassification module
 */
public inherited sharing class CaseAutomationTriggerHandler extends ApplicationTriggerHandler {

	/**
	 * These record types are using a part of pre-filtering records prior to module execution.
	 */
	private static Map<String, Set<Id>> recordTypesByKey {
		get {
			if(recordTypesByKey == null) {
				recordTypesByKey = new Map<String, Set<Id>>{
					'SSSW' => new Set<Id>(),
					'SSSWWithSocial' => new Set<Id>(),
					'StarTrack' => new Set<Id>(),
					'Enterprise_Credit_Dispute_Claim' => new Set<Id>(),
					'Unified' => new Set<Id>()
				};
				List<RecordType> recordTypes = new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'SSSW', 'Social', 'StarTrack', 'Enterprise_Credit_Dispute_Claim', 'Unified'}).values();
				for(RecordType rt : recordTypes) {
					if(rt.DeveloperName.startsWithIgnoreCase('SSSW')) {
						recordTypesByKey.get('SSSW').add(rt.Id);
						recordTypesByKey.get('SSSWWithSocial').add(rt.Id);
					}
					if(rt.DeveloperName.startsWithIgnoreCase('Social')) {
						recordTypesByKey.get('SSSWWithSocial').add(rt.Id);
					}
					if(rt.DeveloperName.startsWithIgnoreCase('StarTrack')) {
						recordTypesByKey.get('StarTrack').add(rt.Id);
					}
					if(rt.DeveloperName.startsWithIgnoreCase('Enterprise_Credit_Dispute_Claim')) {
						recordTypesByKey.get('Enterprise_Credit_Dispute_Claim').add(rt.Id);
					}
					if(rt.DeveloperName.startsWithIgnoreCase('Unified')) {
						recordTypesByKey.get('Unified').add(rt.Id);
					}
				}
			}
			return recordTypesByKey;
		}
		private set;
	}
	
	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
			'filterSSSW' => new List<SObject>(),
			'filterSSSWWithSocial' => new List<SObject>(),
			'filterStarTrack' => new List<SObject>(),
			'filterCreditDisputeClaim' => new List<SObject>(),
			'filterUnified' => new List<SObject>()
		};
		for(SObject record : records) {
			Id recordTypeId = (Id)record.get('RecordTypeId');
			if(recordTypesByKey.get('SSSW').contains(recordTypeId)) {
				filteredRecords.get('filterSSSW').add(record);
			}
			if(recordTypesByKey.get('SSSWWithSocial').contains(recordTypeId)) {
				filteredRecords.get('filterSSSWWithSocial').add(record);
			}
			if(recordTypesByKey.get('StarTrack').contains(recordTypeId)) {
				filteredRecords.get('filterStarTrack').add(record);
			}
			if(recordTypesByKey.get('Enterprise_Credit_Dispute_Claim').contains(recordTypeId)) {
				filteredRecords.get('filterCreditDisputeClaim').add(record);
			}
			if(recordTypesByKey.get('Unified').contains(recordTypeId)) {
				filteredRecords.get('filterUnified').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {
		
		// APCC - SAP-EM Case articles for linking articles to cases and querying articles on the fly
		registerModule(MyCustomerCaseArticlesModule.class, 'filterSSSW');

		registerModule(StarTrackCalculateCaseDepotModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseContactsModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCasePriorityModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseAutomationModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseOwnerModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseCustomerModule.class, 'filterStarTrack'); 
		registerModule(StarTrackDeliveryEnquiryProcessModule.class, 'filterStarTrack');
		registerModule(StarTrackTrackingIDSearchModule.class, 'filterStarTrack');
		registerModule(CreditDisputeClaimCaseModule.class, 'filterCreditDisputeClaim');

		// all of the old case execution logic which hasn't been uplifted yet
		registerModule(CaseLegacyAutomationModule.class);

		// This module will use fields on the case to classify them. Such as Type and Record types
		registerModule(CaseAutomationClassificationModule.class, 'filterUnified');

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
		// NOTE: must run after the legacy code in CaseLegacyAutomationModule. It has logic that depends on Case.AccountId AND must execute after the routing engine - SSSW_Routing.assignCasesAndDescription()
		// Refactor Guidance - the logic in this code needs to be positioned: i) in CaseTriggerUtility.beforeHandler() ii) when caseUtility.assignContactIDToCase() is called
		registerModule(CaseSkillBasedRoutingModule.class, 'filterSSSW');

		// Logic related to proactive monitor queue routing including time-based SLA validation
		registerModule(CaseUnifiedProactiveMonitoringModule.class, 'filterUnified');

		// Update CaseTeamMember from Case's owner
		registerModule(CaseUnifiedTeamMemberModule.class, 'filterUnified');
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			Case.SObjectType,
			Article__c.SObjectType,
			Task.SObjectType,
			CaseMilestone.SObjectType,
			AuthorisedContacts__c.SObjectType,
			PendingServiceRouting.SObjectType,
			CaseInvestigation__c.SObjectType,
			ScheduledAction__c.SObjectType,
			CaseTeamMember.SObjectType
		};
	}

}