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

	//default batch size
	private Integer batchSize = 200;
	private static final String ST_MYNETWORK_RECORD_TYPE = 'StarTrack_MyNetwork';


	public STCIMilestoneViolationCheckerBatch() {
	}

	//constructor to set the batch size
	public STCIMilestoneViolationCheckerBatch(Integer batchSize) {
		this.batchSize = batchSize;
	}

	/**
	 * @description Overridable query
	 * @return Database.QueryLocator
	 */
	public virtual Database.QueryLocator getEligibleCaseInvestigations(){
		Id starTrackRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get(ST_MYNETWORK_RECORD_TYPE).getRecordTypeId();
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			CaseInvestigation__c.SObjectType => new Set<SObjectField>{CaseInvestigation__c.Id, CaseInvestigation__c.NetworkMilestoneCurrentTier__c, CaseInvestigation__c.NetworkMilestonesViolated__c, CaseInvestigation__c.NetworkTierEscalationEmail__c, CaseInvestigation__c.NetworkMilestoneNextViolationDatetime__c, CaseInvestigation__c.IsClosed__c},
			Network__c.SObjectType => new Set<SObjectField>{Network__c.Email_1__c, Network__c.Email_2__c},
			Case.SObjectType => new Set<SObjectField>{Case.OwnerId}
		};
		return CaseInvestigationsSelector.newInstance(0, fieldOverrides).selectNetworkMilestoneViolatedOpenCaseInvestigations(Datetime.now(), new Set<Id>{starTrackRecordTypeId}, new Set<Object>{CaseInvestigationsSelector.Options.WITH_NETWORKS, CaseInvestigationsSelector.Options.WITH_CASE_DETAILS});
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return getEligibleCaseInvestigations();
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		try {

			List<CaseInvestigation__c> recsToUpdate = new List<CaseInvestigation__c>();
			// loop through case investigations to increment milestone violation tier
			for (CaseInvestigation__c ci : (List<CaseInvestigation__c>) scope) {
				ci.NetworkMilestoneCurrentTier__c = ci.NetworkMilestoneCurrentTier__c + 1;
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

				//add records to update
				//prevent records to further update as the current configuration in the escalation hierarchy is upto 5 tiers
				if (ci.NetworkMilestoneCurrentTier__c <= 5) {
					recsToUpdate.add(ci);
				}
			}

			if (recsToUpdate.size() > 0) {
				//update case investigations
				List<Database.SaveResult> sResult = ApplicationDatabase.getInstance().dmlUpdate(recsToUpdate, false);
				// Error Logged to Exception object for analysis. logDmlResults method filters out the success and only log errors
				UTIL_LoggingService.logDmlResults(sResult, null, recsToUpdate, 'ST Case Investigation Milestone Voilation Checker',
					STCIMilestoneViolationCheckerBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'ST Case Investigation Milestone Voilation Checker', STCIMilestoneViolationCheckerBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext ctx) {
		Database.executeBatch(this, batchSize);
	}
}