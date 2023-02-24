/**
 * @author Nathan Franklin
 * @date 2023-02-01
 * @description Controller for skills based report data from pending service routing data in omni channel
 * @changelog
 * 2023-02-16 - Nathan Franklin - Changed the way the query is generated to try and improve performance of initial run
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

		// check to see if we need to reduce the limit size depending on if the query was recently run or not
		// we do this because if the internal query cache isn't primed, this query can take a significant amount of time to run which increases the risk of concurrent errors
		// by reducing the limit, the request should complete quicker and hopefully avoid the long running request bucket (synchronous transactions > 5 seconds)
		Long startOfDayTime = Datetime.newInstanceGmt(Date.today(), Time.newInstance(0, 0, 0, 0)).getTime() / 1000; // this is the number of seconds for the start of day represented in GMT time

		// NOTE: Datetime.now() is GMT
		Long nowTime = Datetime.now().getTime() / 1000; // this is the number of seconds represented in GMT time

		String lastPrimedAsString = String.valueOf(CacheManager.get('OMNI_SKILLS_REPORT_LAST_PRIMED'));
		Long lastPrimedTime = String.isEmpty(lastPrimedAsString) ? 0 : Long.valueOf(lastPrimedAsString);

		// note lastPrimedTime would be 0 if there is no platform cache entry which means lastPrimedTime would not be > startOfDayTime
		// additionally if the cache was only recently primed within the last x minutes then we treat the request as still 'priming' the cache and keep the limit as low
		Integer rowLimit = MAX_RECORDS_PER_ITERATION;
		Boolean wasRecentlyRun = lastPrimedTime > startOfDayTime && lastPrimedTime < (nowTime - (60*2));
		System.debug('Query cache recently primed: ' + wasRecentlyRun);
		if(!wasRecentlyRun) {
			rowLimit = 50;
		}

		// grab the skill based queues to limit the query to just the queues where skills are applicable
		Set<Id> skillQueueIds = new Set<Id>();
		Map<Id, OmniChannelService.QueueWrapper> omniQueues = OmniChannelService.Cache.queuesWithRoutingConfig;
		for(Id queueId : omniQueues.keySet()) {
			if(omniQueues.get(queueId).routingConfiguration.IsAttributeBased) {
				skillQueueIds.add(queueId);
			}
		}

		// specify a dummy Id to get the process started if one isn't already passed in
		if(String.isEmpty(lastIdRetrieved)) {
			lastIdRetrieved = '0JR000000000000';
		}

		List<PendingServiceRouting> pendingWorkRecords = PendingServiceRoutingSelector.newInstance(rowLimit, new Map<SObjectType, Set<SObjectField>>{
			PendingServiceRouting.SObjectType => new Set<SObjectField>{PendingServiceRouting.Id, PendingServiceRouting.RoutingPriority, PendingServiceRouting.SecondaryRoutingPriority, PendingServiceRouting.WorkItemId},
			Case.SObjectType => new Set<SObjectField>{Case.Id, Case.CreatedDate},
			SkillRequirement.SObjectType => new Set<SObjectField>{SkillRequirement.Id, SkillRequirement.SkillId},
			Skill.SObjectType => new Set<SObjectField>{Skill.DeveloperName, Skill.MasterLabel}
		}).search(new Map<String, Object>{
			'limitToCaseOnly' => true,
			'queueIds' => skillQueueIds,
			'idGreaterThan' => lastIdRetrieved,
			'orderBy' => PendingServiceRouting.Id,
			'sortOrder' => 'asc'
		}, new Set<Object>{
			PendingServiceRoutingSelector.Options.WITH_SKILLREQUIREMENTS, PendingServiceRoutingSelector.Options.WITH_WORKITEM, SkillRequirementSelector.Options.WITH_SKILLS
		}, true);

		JobOutput output = new JobOutput();
		output.records = pendingWorkRecords;
		output.isDone = pendingWorkRecords.size() < rowLimit;
		output.lastId = (pendingWorkRecords.size() > 0 ? pendingWorkRecords[pendingWorkRecords.size()-1].Id : null);

		// store the last time we primed the internal query cache
		// this is to ensure the correct limit clause is added to the soql query depending on whether the internal cache would be primed or not
		if(String.isEmpty(lastPrimedAsString)) {
			// NOTE: Datetime.now() is GMT
			CacheManager.put('OMNI_SKILLS_REPORT_LAST_PRIMED', String.valueOf((Datetime.now().getTime()/1000)));
		}

		return output;
	}

	public class JobOutput {
		@AuraEnabled public List<SObject> records = new List<SObject>();
		@AuraEnabled public String lastId;
		@AuraEnabled public Boolean isDone;
	}

}