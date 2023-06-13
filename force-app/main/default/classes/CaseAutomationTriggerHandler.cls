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

		// all of the old case execution logic which hasn't been uplifted yet
		registerModule(CaseLegacyAutomationModule.class);

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