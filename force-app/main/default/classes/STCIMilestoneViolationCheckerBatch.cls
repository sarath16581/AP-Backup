/**
* @author Mahesh Parvathaneni
* @date 24/01/2023
* @tag Batch
* @tag Case Investigation SObject
* @domain StarTrack MyNetwork
* @description Batch job responsible for checking milestone violation on case investigation records
* @changelog
*/

public class STCIMilestoneViolationCheckerBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

	/**
	 * @description Overridable query
	 * @return Database.QueryLocator
	 */
	public virtual Database.QueryLocator getEligibleCaseInvestigations(){
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			CaseInvestigation__c.SObjectType => new Set<SObjectField>{CaseInvestigation__c.Id, CaseInvestigation__c.NetworkMilestoneCurrentViolatedTier__c, CaseInvestigation__c.NetworkMilestonesViolated__c, CaseInvestigation__c.NetworkTierEscalationEmail__c, CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c, CaseInvestigation__c.IsClosed__c},
			Network__c.SObjectType => new Set<SObjectField>{Network__c.Email_1__c, Network__c.Email_2__c},
			Case.SObjectType => new Set<SObjectField>{Case.OwnerId}
		};
		return CaseInvestigationsSelector.newInstance(0, fieldOverrides).selectNetworkMilestoneViolatedOpenCaseInvestigations(Datetime.now(), new Set<Object>{CaseInvestigationsSelector.Options.WITH_NETWORKS, CaseInvestigationsSelector.Options.WITH_CASE_DETAILS});
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return getEligibleCaseInvestigations();
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		try {

			// loop through case investigations to increment milestone violation tier
			for (CaseInvestigation__c ci : (List<CaseInvestigation__c>) scope) {
				ci.NetworkMilestoneCurrentViolatedTier__c = ci.NetworkMilestoneCurrentViolatedTier__c != null ? ci.NetworkMilestoneCurrentViolatedTier__c + 1 : 1;
				ci.NetworkMilestonesViolated__c = ci.NetworkMilestonesViolated__c != null ? ci.NetworkMilestonesViolated__c + 1 : 1;

				//set the network tier escalation email
				if (ci.NetworkMilestonesViolated__c == 1) {
					if (ci.Network__r.Email_1__c != null) {
						ci.NetworkTierEscalationEmail__c = ci.Network__r.Email_1__c;
					} else {
						ci.OwnerId = ci.Case__r.OwnerId;
					}
				} else if(ci.NetworkMilestonesViolated__c == 2) {
					if (ci.Network__r.Email_2__c != null) {
						ci.NetworkTierEscalationEmail__c = ci.Network__r.Email_2__c;
					} else {
						ci.OwnerId = ci.Case__r.OwnerId;
					}
				}
			}

			//update case investigations
			List<Database.SaveResult> sResult = ApplicationDatabase.getInstance().dmlUpdate(scope, false);
			// Error Logged to Exception object for analysis. logDmlResults method filters out the success and only log errors
			UTIL_LoggingService.logDmlResults(sResult, null, scope, 'ST Case Investigation Milestone Voilation Checker',
				STCIMilestoneViolationCheckerBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ST Case Investigation Milestone Voilation Checker', STCIMilestoneViolationCheckerBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext ctx) {
		Database.executeBatch(new STCIMilestoneViolationCheckerBatch());
	}
}