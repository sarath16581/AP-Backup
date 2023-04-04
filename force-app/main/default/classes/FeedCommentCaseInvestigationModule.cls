/**
 * @description
 * Domain Module to handle functionality on a FeedComment for Case Investigation.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Mahesh Parvathaneni
 * @date 03/04/2023
 * @changelog
 */

public inherited sharing class FeedCommentCaseInvestigationModule extends ApplicationDomain.Module {

	public static FeedCommentCaseInvestigationModule newInstance() {
		return (FeedCommentCaseInvestigationModule) Application.Utilities.newInstance(FeedCommentCaseInvestigationModule.class);
	}

	// Setup which trigger events this module should respond to
	public FeedCommentCaseInvestigationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateCaseInvestigations(records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'MyNetwork', FeedCommentCaseInvestigationModule.class.getName(), 'onAfterInsert', 'FeedCommentTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	* @description		This method updates the case investigations whenever any StarTrack Contact Center user comment on the post feed of Case Investigation Object.
	* @param			feedComments - List<SObject>, uow - ApplicationUnitOfWork
	* @return			void
	*/
	@TestVisible
	private void updateCaseInvestigations(List<SObject> feedComments, ApplicationUnitOfWork uow) {
		//get profile id for star track support user
		Id profileId = Application.Cache.profileIds.get('StarTrack Support');
		List<CaseInvestigation__c> caseInvestigationToUpdate = new List<CaseInvestigation__c>();
		Set<Id> caseInvestigationIds = new Set<Id>();

		if (UserInfo.getProfileId() == profileId) {
			for (FeedComment fComment : (List<FeedComment>) feedComments) {
				caseInvestigationIds.add(fComment.ParentId);
			}

			for (Id ciId : caseInvestigationIds) {
				//update LastContactCentreUpdate__c field on CaseInvestigation ONLY WHEN a chatter is added
				//by users with 'StarTrack Support' profiles.
				//update Status__c field to 'In Progress' and RequireMoreInformation__c field to false
				caseInvestigationToUpdate.add( new CaseInvestigation__c(Id = ciId, LastContactCentreUpdate__c = System.now(), 
						Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS , RequireMoreInformation__c = false));
			}

			if(!caseInvestigationToUpdate.isEmpty()){
				//update case investigation records.
				uow.registerDirty(caseInvestigationToUpdate);
			}
		}
	}
}