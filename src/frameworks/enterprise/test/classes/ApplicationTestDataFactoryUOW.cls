/**
* @description Contains all the test data methods for Unit of Work test classes
* @author Nathan Franklin
* @date 2021-07-23
* @group Tests
* @tags mocking, apex mocks, tests, data factory, test data
* @changelog
*/
@IsTest
public class ApplicationTestDataFactoryUOW {

	public static List<AsyncWorkerEvent__e> getAsyncWorkerEvents(Integer count, Object classType) {
		List<AsyncWorkerEvent__e> output = (List<AsyncWorkerEvent__e>)ApplicationTestDataFactory.populateSObjects(AsyncWorkerEvent__e.SObjectType, new Map<SObjectField, Object> {
				AsyncWorkerEvent__e.MaxNumberRetries__c => ApplicationUnitOfWork.MAX_LOCK_FAIL_RETRY_ATTEMPTS,
				AsyncWorkerEvent__e.CurrentLockRetryAttempts__c => 0,
				AsyncWorkerEvent__e.UserId__c => UserInfo.getUserId(),
				AsyncWorkerEvent__e.ClassType__c => classType,
				AsyncWorkerEvent__e.CurrentStackDepth__c => 0
		}, count);

		return output;
	}

	public static List<AsyncWorker__c> getAsyncWorkerRecords(Integer count, Object classType, Object queueableIds, Boolean generateIds) {
		List<AsyncWorker__c> output = (List<AsyncWorker__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(AsyncWorker__c.SObjectType, new Map<SObjectField, Object> {
				AsyncWorker__c.MaxNumberRetries__c => ApplicationUnitOfWork.MAX_LOCK_FAIL_RETRY_ATTEMPTS,
				AsyncWorker__c.UserId__c => UserInfo.getUserId(),
				AsyncWorker__c.ClassType__c => classType,
				AsyncWorker__c.QueueableJobId__c => queueableIds,
				AsyncWorker__c.CurrentStackDepth__c => 0
		}, count), generateIds);

		return output;
	}
	
}