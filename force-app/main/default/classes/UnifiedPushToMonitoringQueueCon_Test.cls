/***
 * @author Seth Heang
 * @description Test class for UnifiedPushToMonitoringQueueController
 * @changelog
 * 2024-08-02 - Seth Heang - Created
 */
@IsTest
public with sharing class UnifiedPushToMonitoringQueueCon_Test {
	/**
	 * Test: Retrieve the unified customer service monitoring queue successfully
	 */
	@IsTest
	static void testGetUnifiedCustomerServiceMonitoringQueueId() {
		QM__c custSetting = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		custSetting.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		insert custSetting;

		Test.startTest();
		Id unifiedMonitoringQueueResultId = UnifiedPushToMonitoringQueueController.getUnifiedCustomerServiceMonitoringQueueId();
		Test.stopTest();

		Assert.areEqual(
				unifiedMonitoringQueue.Id,
				unifiedMonitoringQueueResultId,
				'Unified Monitoring Queue Id should match but instead got ' + unifiedMonitoringQueueResultId
		);
	}
}