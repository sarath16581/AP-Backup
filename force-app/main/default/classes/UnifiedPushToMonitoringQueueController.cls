/**
 * @description Controller Class for unifiedPushToMonitoringQueue LWC.
 *			This LWC is a Modal Popup on Quick Action that will push the Case to Unified Customer Service Monitoring Queue.
 * @author Seth Heang
 * @date 2024-07-10
@changelog
2024-07-10 - Seth Heang - Created
 */
public with sharing class UnifiedPushToMonitoringQueueController {

	/**
	 * @description Fetch unified customer service monitoring queue Id from custom setting
	 * @return Id
	 */
	@AuraEnabled(Cacheable=true)
	public static Id getUnifiedCustomerServiceMonitoringQueueId() {
		return QM__c.getInstance()?.UnifiedDefaultMonitoringQueueId__c;
	}
}