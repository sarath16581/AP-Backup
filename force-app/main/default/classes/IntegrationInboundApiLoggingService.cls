/***
 * @description
 *      Coordinates the summarisation of ApiEvent big object data
 *      It uses a series of scheduleable jobs and async-soql queries
*              to extract a portion of the big object dataset for analysis and processing
 *
 * @author Nathan Franklin
 * @date 2021-03-01
 * @group Integration
 * @changelog
 */
global inherited sharing class IntegrationInboundApiLoggingService {

	/**
	 * Kick off the async soql query that extracts the ApiEvent data from big object into custom object for analysis
	 */
	public static void extractBigObjectData() {
		IntegrationApiSettings__c integrationSettings = getIntegrationApiSettings();
		Datetime startingEventDate = integrationSettings.LastInboundQueryApiEventDate__c;
		Datetime endingEventDate = startingEventDate.addHours(Integer.valueOf(integrationSettings.InboundQueryApiAsyncSOQLHourRange__c));
		Long nowTime = Datetime.now().getTime();

		System.debug('endingEventDate TIME: ' + endingEventDate.getTime());
		System.debug('now TIME: ' + nowTime);

		// we take the smaller date of now and the current end date to ensure we can track where to start from next time
		endingEventDate = Datetime.newInstance(Math.min(endingEventDate.getTime(), nowTime));

		System.debug('Normalised endingEventDate TIME: ' + endingEventDate.getTime());

		// Since we can only grab a small chunk (upto 1M records) of data, we use date ranges to control the number of records
		// if the end date is less than now, we need to add another async-soql query to fetch the next chunk of data until the date is now() or greater
		Boolean runAsyncSoqlAgain = (endingEventDate.getTime() < nowTime);

		System.debug('Starting From Event Date: ' + startingEventDate);
		System.debug('Ending Event Date: ' + endingEventDate);
		System.debug('runAsyncSoqlAgain: ' + runAsyncSoqlAgain);

		//ElapsedTime
		// NOTE: Can't use LIMIT or ORDER BY with async-queries
		// grab the data within a certain range.
		// There is a limit of 1M records in an async query (you can buy more limit)
		// If the limit is hit then an error occurs and the query does not continue
		// We could also solve these limitations by using async-queries to run a COUNT(), into another custom object
		//      you would group by hours to get hourly counts and then orchestrate async soqls based on that data
		String bigObjectSoql = 'SELECT ApiType, ApiVersion, Application, Client, ElapsedTime, ' +
				'EventDate, Operation, Platform, QueriedEntities, Query, ' +
				'RowsProcessed, RowsReturned, SourceIp, UserAgent, UserId, Username ' +
				'FROM ApiEvent ' +
				'WHERE EventDate > ' + startingEventDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + ' ' +
				'AND EventDate < ' + endingEventDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
		System.debug('Async SOQL: ' + bigObjectSoql);

		Map<SObjectField, SObjectField> fieldMappings = new Map<SObjectField, SObjectField>{
				ApiEvent.EventDate => ApiEventAnalysis__c.EventDate__c,
				ApiEvent.UserId => ApiEventAnalysis__c.User__c,
				ApiEvent.Platform => ApiEventAnalysis__c.Platform__c,
				ApiEvent.Application => ApiEventAnalysis__c.Application__c,
				ApiEvent.Operation => ApiEventAnalysis__c.Operation__c,
				ApiEvent.ApiVersion => ApiEventAnalysis__c.ApiVersion__c,
				ApiEvent.UserAgent => ApiEventAnalysis__c.UserAgent__c,
				ApiEvent.QueriedEntities => ApiEventAnalysis__c.QueriedEntities__c,
				ApiEvent.Query => ApiEventAnalysis__c.Query__c,
				ApiEvent.ApiType => ApiEventAnalysis__c.ApiType__c,
				ApiEvent.Client => ApiEventAnalysis__c.Client__c,
				ApiEvent.ElapsedTime => ApiEventAnalysis__c.ElapsedTime__c,
				ApiEvent.RowsProcessed => ApiEventAnalysis__c.RowsProcessed__c,
				ApiEvent.RowsReturned => ApiEventAnalysis__c.RowsReturned__c,
				ApiEvent.SourceIp => ApiEventAnalysis__c.SourceIP__c,
				ApiEvent.Username => ApiEventAnalysis__c.Username__c
		};

		// call REST API to kick off an async soql request
		Id jobId = AsyncSOQLService.getInstance().runInsertAsyncSoql(bigObjectSoql, ApiEventAnalysis__c.SObjectType, fieldMappings);

		// schedule the first job to check the status of the async soql query job
		// we keep checking the status until it's complete
		// after it's complete, we proceed to kick the batch job off to process the records
		IntegrationInboundApiStatusScheduler.scheduleOneTimeAsyncSoqlStatusCheck(jobId, endingEventDate, runAsyncSoqlAgain);

	}

	/**
	 * Remove API usage older than x days
	 * This is run at the conclusion of the batch job being run
	 */
	public static void tidyupOldUsageAnalysis() {

	}

	/**
	 * Get the progress of the async soql query and if it's complete
	 * If it's complete then kick off the batch analysis
	 */
	public static void maybeProcessResults() {

	}

	/**
	 * Kick off the batch that processes data extracted into our custom object
	 */
	public static void runAnalysis() {

	}

	/**
	 * Use only once to enable scheduled jobs for daily analysis
	 */
	public static void enableJobScheulde() {

	}

	/**
	 * Use to disable the scheduled job to kick off daily analysis
	 */
	public static void disableJobScheulde() {

	}

	public static IntegrationApiSettings__c getIntegrationApiSettings() {
		IntegrationApiSettings__c integrationSettings = IntegrationApiSettings__c.getOrgDefaults();
		if(integrationSettings == null) integrationSettings = new IntegrationApiSettings__c();

		if(integrationSettings.InboundQueryApiAsyncSOQLHourRange__c == null) integrationSettings.InboundQueryApiAsyncSOQLHourRange__c = 6;
		if(integrationSettings.InboundQueryApiBatchScopeSize__c == null) integrationSettings.InboundQueryApiBatchScopeSize__c = 2000;
		if(integrationSettings.InboundQueryApiMaxRowsPerBatchJob__c == null) integrationSettings.InboundQueryApiMaxRowsPerBatchJob__c = 50000000;
		if(integrationSettings.InboundQueryApiAsyncStatusInterval__c == null) integrationSettings.InboundQueryApiAsyncStatusInterval__c = 5;
		if(integrationSettings.LastInboundQueryApiEventDate__c == null) integrationSettings.LastInboundQueryApiEventDate__c = Datetime.now().addDays(-14);

		return integrationSettings;
	}

	public class BatchableException extends Exception {}

}