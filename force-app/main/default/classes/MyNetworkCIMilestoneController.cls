/**
 * @File Name          : MyNetworkCIMilestoneController.cls
 * @Description        : Controller class for MyNetwork Case Investigation Milestone
 * @Author             : Mahesh Parvathaneni
 * @changelog
 **/

public with sharing class MyNetworkCIMilestoneController {

	//constants
	@TestVisible
	private static final String OPEN_VIOLATION = 'Open Violation';
	@TestVisible
	private static final String REMAINING = 'Remaining';
	private static final String NETWORK_TIER = 'Network Tier';
	private static final String NETWORK_TIER_2 = 'Network Tier 2';

	@AuraEnabled
	public static NetworkMilestoneWrapper getCaseInvestigationNetworkMilestones(Id caseInvestigationId){
		try {
			NetworkMilestoneWrapper wrapper = new NetworkMilestoneWrapper();
			//get the case investigation
			List<CaseInvestigation__c> caseInvestigations = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{caseInvestigationId}).values();
			CaseInvestigation__c ci = caseInvestigations.size() > 0 ? caseInvestigations[0] : null;

			wrapper.hasMilestonesViolated = false;

			if (ci != null && ci.NetworkMilestoneCurrentTier__c != null) {
				//business hours id for SSSW sydney
				Id businessHoursId = getSSSWSydneyBusinessHourId();
				wrapper.hasMilestonesViolated = true;
				wrapper.isBusinessHours = areWeWithinSpecifiedBusinessHours(businessHoursId);

				if (ci != null && ci.NetworkMilestoneCurrentTier__c <= 2) {
					//for network tiers 1 and 2
					wrapper.networkTierName = NETWORK_TIER + ' ' + String.valueOf(ci.NetworkMilestoneCurrentTier__c);
					Long diffInMilliSeconds = BusinessHours.diff(businessHoursId, System.now(), ci.NetworkMilestoneNextViolationDatetime__c);
					Integer timeRemainingOrCompleted = ((diffInMilliSeconds/1000)/60).intValue();
					wrapper.timeRemainingOrCompleted = Math.abs(timeRemainingOrCompleted);
					wrapper.percentTimeCompleted = getPercentTimeCompleted(ci, timeRemainingOrCompleted, businessHoursId);
					wrapper.status = wrapper.percentTimeCompleted >= 100 ? OPEN_VIOLATION : REMAINING;
				} else {
					wrapper.networkTierName = NETWORK_TIER_2;
					Long diffInMilliSeconds = Math.abs(BusinessHours.diff(businessHoursId, ci.NetworkMilestoneLastViolationDatetime__c, System.now()));
					wrapper.timeRemainingOrCompleted = ((diffInMilliSeconds/1000)/60).intValue();
					wrapper.percentTimeCompleted = 100;
					wrapper.status = OPEN_VIOLATION;
				}
			}

			return wrapper;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	//get the business for the SSSWSydney
	private static Id getSSSWSydneyBusinessHourId(){
		return BusinessHoursSelector.newInstance().selectByName(new Set<String> {'SSSWSydney'})[0].Id;
	}

	//function to get the percent of time completed to render for the progress bar
	private static Integer getPercentTimeCompleted(CaseInvestigation__c ci, Integer timeRemainingOrCompleted, String businessHoursId) {
		Long timeDiff;

		if (timeRemainingOrCompleted < 0) {
			//if the violation time already passed, return 100
			return 100;
		}

		if (ci.NetworkMilestoneCurrentTier__c == 1) {
			timeDiff = BusinessHours.diff(businessHoursId, ci.MilestoneTimeStartDatetime__c, ci.NetworkMilestoneNextViolationDatetime__c);
		} else {
			timeDiff = BusinessHours.diff(businessHoursId, ci.NetworkMilestoneLastViolationDatetime__c, ci.NetworkMilestoneNextViolationDatetime__c);
		}
		Decimal targetResponseInMins = ((timeDiff/1000)/60);

		return Math.round((1 - (Decimal.valueOf(timeRemainingOrCompleted) / targetResponseInMins)) * 100);
	}

	//function to check whether the current time is in Business hours
	private static Boolean areWeWithinSpecifiedBusinessHours(String businessHoursId) {
		return BusinessHours.isWithin(businessHoursId, Datetime.now());
	}

	public class NetworkMilestoneWrapper {
		@AuraEnabled
		public Boolean hasMilestonesViolated {get; set;}
		@AuraEnabled
		public string networkTierName {get; set;}
		@AuraEnabled
		public Integer timeRemainingOrCompleted {get; set;} 
		@AuraEnabled
		public Integer percentTimeCompleted {get; set;}
		@AuraEnabled
		public String status {get; set;}
		@AuraEnabled
		public Boolean isBusinessHours {get; set;}
	}
}