/**
 * @description
 * Domain Module to handle functionality on a FeedComment for Case Investigation.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Mahesh Parvathaneni
 * @date 03/04/2023
 * @changelog
 * 03/05/2023 - Mahesh Parvathaneni - Updated - SF-942 - Set the Sent to Network Date field on case investigation
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
		Set<Id> ciIds = new Set<Id>();
		Id profileId = Application.Cache.profileIds.get('StarTrack Support');

		//update case investigations only by 'StarTrack Support' profile users
		if(UserInfo.getProfileId() == profileId){
			//get the case investigation ids
			for (FeedComment fComment : (List<FeedComment>) feedComments) {
				ciIds.add(fComment.ParentId);
			}
	
			if(!ciIds.isEmpty()){
				//call to STCaseInvestigationFeedService to update case investigation records 
				STCaseInvestigationFeedService.getInstance().updateCaseInvestigationsRelatedToFeed(ciIds, uow);
			}
		}
	}
}