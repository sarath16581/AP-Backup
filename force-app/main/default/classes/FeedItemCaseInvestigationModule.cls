/**
 * @description
 * Domain Module to handle functionality on a FeedItem.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Dattaraj Deshmukh
 * @date 23/11/2022
 * @group Domain
 * @domain PUD
 * @changelog
 * 23/11/2022 - Dattaraj Deshmukh - Created.
 * 21/03/2023 - Mahesh Parvathaneni - Updated - SF-853 - Set the status and Require more information fields on case investigation
 * 03/05/2023 - Mahesh Parvathaneni - Updated - SF-942 - updated to use the service class to update case investigations
 */

 public inherited sharing class FeedItemCaseInvestigationModule extends ApplicationDomain.Module  {
	public static FeedItemCaseInvestigationModule newInstance() {
		return (FeedItemCaseInvestigationModule) Application.Utilities.newInstance(FeedItemCaseInvestigationModule.class);
	}

	// Setup which trigger events this module should respond to
	public FeedItemCaseInvestigationModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateCaseInvestigations(Userinfo.getProfileId(), records, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'MyNetwork', FeedItemCaseInvestigationModule.class.getName(), 'onAfterInsert', 'FeedItemTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	* @description		This method updates the case investigations whenever any StarTrack Contact Center user Post feed on Case Investigation Object.
	* @param			feedItems - List<SObject>, uow - APplicationUnitOfWork
	* @return			Void
	*/
	@TestVisible
	private void updateCaseInvestigations( Id loggedInUserProfileId, List<SObject> feedItems, ApplicationUnitOfWork uow) {
		Set<Id> ciIds = new Set<Id>();
		Id profileId = Application.Cache.profileIds.get('StarTrack Support');
		//update case investigations only by 'StarTrack Support' profile users
		if(loggedInUserProfileId == profileId){
			//get the case investigation ids
			for (FeedItem fItem :  (List<FeedItem>)  feedItems) {
				ciIds.add(fItem.ParentId);
			}
	
			if(!ciIds.isEmpty()){
				//call to STCaseInvestigationFeedService to update case investigation records 
				STCaseInvestigationFeedService.getInstance().updateCaseInvestigationsRelatedToFeed(ciIds, uow);
			}
		}
	}
}