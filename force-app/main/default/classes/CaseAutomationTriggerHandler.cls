/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 */
public inherited sharing class CaseAutomationTriggerHandler extends ApplicationTriggerHandler {

	private static Map<String, Set<Id>> recordTypesByKey {
		get {
			if(recordTypesByKey == null) {
				recordTypesByKey = new Map<String, Set<Id>>{
					'SSSW' => new Set<Id>(),
					'SSSWWithSocial' => new Set<Id>(),
					'StarTrack' => new Set<Id>()
				};
				List<RecordType> recordTypes = new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{'SSSW', 'Social', 'StarTrack'}).values();

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
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
			'filterSSSW' => new List<SObject>(),
			'filterSSSWWithSocial' => new List<SObject>(),
			'filterStarTrack' => new List<SObject>()
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

		}
		return filteredRecords;
	}

	public override void registerModules() {
		
		// APCC - SAP-EM Case articles for linking articles to cases and querying articles on the fly
		// NOTE: the 'SSSW' if the filter key which passes records set in the primeRecordFilters method
		registerModule(MyCustomerCaseArticlesModule.class, 'filterSSSW');

		registerModule(StarTrackCalculateCaseDepotModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseContactsModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCasePriorityModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseAutomationModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseOwnerModule.class, 'filterStarTrack');
		registerModule(StarTrackSupportCaseCustomerModule.class, 'filterStarTrack'); 
		registerModule(StarTrackDeliveryEnquiryProcessModule.class, 'filterStarTrack');
		registerModule(StarTrackTrackingIDSearchModule.class, 'filterStarTrack');

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
		// NOTE: must run after the legacy code in CaseLegacyAutomationModule. It has logic that depends on Case.AccountId AND must execute after the routing engine - SSSW_Routing.assignCasesAndDescription()
		// Refactor Guidance - the logic in this code needs to be positioned: i) in CaseTriggerUtility.beforeHandler() ii) when caseUtility.assignContactIDToCase() is called
		registerModule(CaseSkillBasedRoutingModule.class, 'filterSSSW');

	}

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