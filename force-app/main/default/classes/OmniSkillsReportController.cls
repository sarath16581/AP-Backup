/**
 * @author Nathan Franklin
 * @date 2023-02-01
 * @description Controller for skills based report data from pending service routing data in omni channel
 *
 * TODO: We should probably consider refactoring the job 'framework' into a separate class. Time limitations have prevented this for now
 *
 * @changelog
*/
public with sharing class OmniSkillsReportController {
	public static final Integer MAX_RECORDS_PER_ITERATION = 1000;

	@AuraEnabled
	public static JobOutput fetchReportDataWithoutSkill() {
		Set<Id> skillIds = new Map<Id, Skill>([SELECT Id FROM Skill]).keySet();
		return fetchReportData(new List<Id>(skillIds));
	}

	/**
	 * Grab a list of cases the user wants to drill down into
	 */
	@AuraEnabled(Cacheable=true)
	public static List<Case> getCases(List<Id> caseIds) {
		return SSSWCasesSelector.newInstance().selectById(new Set<Id>(caseIds)).values();
	}

	/**
	 * Due to limitations around soql rows this has been created to allow retrieval to happen across multiple transactions
	 * The data is processed and crunched on the client side in the omniSkillsReport lwc component
	 */
	@AuraEnabled
	public static JobOutput fetchReportData(List<Id> skillIds) {

		JobOutput output = new JobOutput();

		// need to create a new job which is stored in session state
		// this is needed to track the fetch progress of all the data we need
		// doing this allows us to select more than 50k records which is the current soql rows limit
		Map<String, Job> existingJobs = (Map<String, Job>)CacheManager.get('GENERIC_JOB_STORE');
		if(existingJobs == null) existingJobs = new Map<String, Job>();

		String jobKey = getGuid();
		while(existingJobs.get(jobKey) != null) {
			jobKey = getGuid();
		}

		Job casesJob = new Job();
		casesJob.params.put('jobType', 'omniSkillsReportDataJob');
		casesJob.params.put('skillIds', skillIds);
		casesJob.params.put('currentOffset', 0);
		existingJobs.put(jobKey, casesJob);
		CacheManager.put('GENERIC_JOB_STORE', '', existingJobs);

		output.jobKey = jobKey;
		output.currentOffset = 0;
		output.isDone = false;

		System.debug(output);

		return output;
	}

	@AuraEnabled
	public static JobOutput fetchReportDataIteration(String existingJobKey) {
		Map<String, Job> existingJobs = (Map<String, Job>)CacheManager.get('GENERIC_JOB_STORE');
		if(existingJobs == null) existingJobs = new Map<String, Job>();

		Job existingJob = (Job)existingJobs.get(existingJobKey);
		if(existingJob == null) {
			throw new AuraHandledException('Could not find job');
		}

		String jobType = String.valueOf(existingJob.params.get('jobType'));
		if(jobType != 'omniSkillsReportDataJob') {
			throw new AuraHandledException('Job type is wrong');
		}

		List<Id> skillIds = (List<Id>)existingJob.params.get('skillIds');
		Integer currentOffset = (Integer)existingJob.params.get('currentOffset');

		List<SkillRequirement> records = fetchReportDataIterationWithParams(skillIds, currentOffset);
		currentOffset = currentOffset + records.size();

		JobOutput output = new JobOutput();
		output.records = records;
		output.currentOffset = currentOffset;
		output.isDone = (records.size() == 0);

		if(output.isDone) {
			// destroy the job and free up the session allocation
			existingJobs.remove(existingJobKey);
			CacheManager.put('GENERIC_JOB_STORE', '', existingJobs);
		} else {
			// update the job state in the session state
			existingJob.params.put('currentOffset', currentOffset);
			existingJobs.put(existingJobKey, existingJob);
			CacheManager.put('GENERIC_JOB_STORE', '', existingJobs);
		}

		System.debug(output);

		return output;
	}

	/**
	 * Starting at SkillRequirement gives us a much more predictable result set count
	 * Using sub queries to get child records contributes to soql rows making the query count too unpredictable
	 */
	public static List<SkillRequirement> fetchReportDataIterationWithParams(List<Id> skillIds, Integer currentOffset) {
		List<SkillRequirement> records = [SELECT TYPEOF RelatedRecord WHEN PendingServiceRouting THEN WorkItemId, WorkItem.CreatedDate END, SkillId, Skill.DeveloperName
											FROM SkillRequirement
											WHERE SkillId IN :skillIds
											AND RelatedRecord.Type = 'PendingServiceRouting'
											AND RelatedRecordId IN (SELECT Id FROM PendingServiceRouting
																		WHERE WorkItemId > '500000000000000'
																		AND WorkItemId < '501000000000000')
											ORDER BY RelatedRecordId
											LIMIT :MAX_RECORDS_PER_ITERATION OFFSET :currentOffset];
		return records;
	}

	public static String getGuid() {
		Blob b = Crypto.generateAesKey(128);
		String h = EncodingUtil.convertToHex(b);
		String guid = h.substring(0,8)+ '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20);
		return guid;
	}

	private class Job {
		public Map<String, Object> params = new Map<String, Object>();
	}

	public class JobOutput {
		@AuraEnabled public String jobKey;
		@AuraEnabled public List<SObject> records = new List<SObject>();
		@AuraEnabled public Integer totalRecordCount;
		@AuraEnabled public Integer currentOffset;
		@AuraEnabled public Boolean isDone;
	}

}
