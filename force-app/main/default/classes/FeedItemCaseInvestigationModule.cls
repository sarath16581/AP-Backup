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
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)FeedItemCaseInvestigationModule.newInstance();
		}
	}

	/**
      * @description       This method updates timestamp whenever any StarTrack Contact Center user Post feed on Case Investigation Object.
      * @param             feedItems - List<SObject>, uow - APplicationUnitOfWork
      * @return            Void
      */
      @TestVisible
      private void updateCaseInvestigations( Id loggedInUserProfileId, List<SObject> feedItems, ApplicationUnitOfWork uow) {

		Id profileId = Application.Cache.profileIds.get('SSSW - Service Agent');
            
        List<CaseInvestigation__c> caseInvestigationToUpdate = new List<CaseInvestigation__c>();
        for(FeedItem fItem :  (List<FeedItem>)  feedItems) {

			//update LastContactCentreUpdate__c field on CaseInvestigation ONLY WHEN a chatter is added
			//by users with 'SSSW - Service Agent' profiles.
            if(loggedInUserProfileId == profileId){
                caseInvestigationToUpdate.add( new CaseInvestigation__c(Id = fItem.ParentId, LastContactCentreUpdate__c = System.now()) );
            }
        }

        if(!caseInvestigationToUpdate.isEmpty()){
			//update case investigation records.
			uow.registerDirty(caseInvestigationToUpdate);
        }
      }
}