/**
 * @author Nathan Franklin
 * @date 2023-02-01
 * @description Controller for skills based report data from pending service routing data in omni channel
 * @changelog
*/
public with sharing class OmniSkillsReportController {
	public static final Integer MAX_RECORDS_PER_ITERATION = 1000;

	/**
	 * Grab a list of cases the user wants to drill down into
	 */
	@AuraEnabled(Cacheable=true)
	public static List<Case> getCases(List<Id> caseIds) {
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Case.Id, Case.Status, Case.Priority, Case.CreatedDate, Case.CaseNumber, Case.Type, Case.ProductCategory__c, Case.ProductSubCategory__c, Case.EnquirySubType__c
		};

		return SSSWCasesSelector.newInstance(0, fieldOverrides).selectById(new Set<Id>(caseIds)).values();
	}

	/**
	 * Due to limitations around soql rows this has been created to allow retrieval to happen across multiple transactions
	 * The data is processed and crunched on the client side in the omniSkillsReport lwc component
	 */
	@AuraEnabled
	public static JobOutput fetchReportData(String lastIdRetrieved) {

		// specify a dummy Id to get the process started if one isn't already passed in
		if(String.isEmpty(lastIdRetrieved)) {
			lastIdRetrieved = '0JR000000000000';
		}

		List<PendingServiceRouting> pendingWorkRecords = PendingServiceRoutingSelector.newInstance(MAX_RECORDS_PER_ITERATION, new Map<SObjectType, Set<SObjectField>>{
			PendingServiceRouting.SObjectType => new Set<SObjectField>{PendingServiceRouting.Id, PendingServiceRouting.RoutingPriority, PendingServiceRouting.SecondaryRoutingPriority, PendingServiceRouting.WorkItemId},
			Case.SObjectType => new Set<SObjectField>{Case.Id, Case.CreatedDate},
			SkillRequirement.SObjectType => new Set<SObjectField>{SkillRequirement.Id, SkillRequirement.SkillId},
			Skill.SObjectType => new Set<SObjectField>{Skill.DeveloperName, Skill.MasterLabel}
		}).search(new Map<String, Object>{
			'limitToCaseOnly' => true,
			'limitToSkillWorkOnly' => true,
			'idGreaterThan' => lastIdRetrieved,
			'orderBy' => PendingServiceRouting.Id,
			'sortOrder' => 'asc'
		}, new Set<Object>{
			PendingServiceRoutingSelector.Options.WITH_SKILLREQUIREMENTS, PendingServiceRoutingSelector.Options.WITH_WORKITEM, SkillRequirementSelector.Options.WITH_SKILLS
		}, true);

		JobOutput output = new JobOutput();
		output.records = pendingWorkRecords;
		output.isDone = pendingWorkRecords.size() < MAX_RECORDS_PER_ITERATION;
		output.lastId = (pendingWorkRecords.size() > 0 ? pendingWorkRecords[pendingWorkRecords.size()-1].Id : null);

		return output;
	}

	public class JobOutput {
		@AuraEnabled public List<SObject> records = new List<SObject>();
		@AuraEnabled public String lastId;
		@AuraEnabled public Boolean isDone;
	}

}