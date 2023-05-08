/**
 * @description Service class for updating case investigations related to feed items/feed comments
 * @author Mahesh Parvathaneni
 * @date 02/05/2023
 * @changelog
 */

 public inherited sharing class STCaseInvestigationFeedService {

	/**
	* Grabs a new instance of this class
	* Using Application.Utilities allows us to override this interface with a mock class for unit testing
	*/
	public static STCaseInvestigationFeedService getInstance() {
		return (STCaseInvestigationFeedService)Application.Utilities.getInstance(STCaseInvestigationFeedService.class);
	}

	@TestVisible
	private Datetime currentTime {
		get{
			if(currentTime == null){
				currentTime = System.now();
			}
			return currentTime;
		}
		private set;
	}

	/**
	 * This method updates the case investigation records related to feed item/feed comment
	 * Updates the LastContactCentreUpdate__c, RequireMoreInformation__c for a case investigation when feed item/comment is inserted.
	 * Updates the Status__c and SentToNetworkDatetime__c when the case investigation is in closed (or) require more information status.
	 */
	public void updateCaseInvestigationsRelatedToFeed(Set<Id> caseInvestigationIds, ApplicationUnitOfWork uow) {
		Map<Id, CaseInvestigation__c> caseInvestigationMap;
		List<CaseInvestigation__c> caseInvestigationsToUpdate = new List<CaseInvestigation__c>();

		try {
			if (caseInvestigationIds.size() > 0) {
				//field overrides for case investigation
				Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
					CaseInvestigation__c.SObjectType => new Set<SObjectField>{CaseInvestigation__c.Id, CaseInvestigation__c.Status__c, CaseInvestigation__c.SentToNetworkDatetime__c}
				};
				//get case investigations
				caseInvestigationMap = CaseInvestigationsSelector.newInstance(fieldOverrides).selectById(caseInvestigationIds);
			}
			
			Datetime currentTimeStamp = currentTime;
	
			for (Id ciId : caseInvestigationIds) {
				CaseInvestigation__c ciToUpdate = new CaseInvestigation__c();
				ciToUpdate.Id = ciId;
				ciToUpdate.LastContactCentreUpdate__c = currentTimeStamp;
				ciToUpdate.RequireMoreInformation__c = false;
				
				if (caseInvestigationMap.size() > 0 && caseInvestigationMap.containsKey(ciId)) {
					ciToUpdate.Status__c = caseInvestigationMap.get(ciId).Status__c;
					ciToUpdate.SentToNetworkDatetime__c = caseInvestigationMap.get(ciId).SentToNetworkDatetime__c;
					//update the sent to network date and status if the current case investigation status is Closed or More information required
					if (caseInvestigationMap.get(ciId).Status__c == MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS || 
						caseInvestigationMap.get(ciId).Status__c == MyNetworkConstants.CASE_INVESTIGATION_MORE_INFO_REQUIRED) {
							ciToUpdate.Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS;
							ciToUpdate.SentToNetworkDatetime__c = currentTimeStamp;
					} else if (caseInvestigationMap.get(ciId).Status__c != MyNetworkConstants.CASE_INVESTIGATION_NEW_STATUS) {
						//update the Status to In Progress for all other scenarios
						ciToUpdate.Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS;
					}
				}
				caseInvestigationsToUpdate.add(ciToUpdate);
			}
	
			if(!caseInvestigationsToUpdate.isEmpty()){
				//update case investigation records.
				uow.registerDirty(caseInvestigationsToUpdate, new List<SObjectField>{ CaseInvestigation__c.LastContactCentreUpdate__c, CaseInvestigation__c.Status__c, CaseInvestigation__c.RequireMoreInformation__c, CaseInvestigation__c.SentToNetworkDatetime__c}, true, STCaseInvestigationFeedService.class.getName());
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'StarTrack MyNetwork', STCaseInvestigationFeedService.class.getName(), 'updateCaseInvestigationsRelatedToFeed', 'updateCaseInvestigations' , LoggingLevel.ERROR);
		}
		
	}
}