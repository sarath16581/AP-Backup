/*
 * @author George Nguyen
 * @date 2022-11-08
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @description this is where all the test data generation in relation to Omni should go. 
 * @changelog
 * 2022-11-08 - George Nguyen - Created
*/
@IsTest
public with sharing class OmniChannelTestDataFactory {

	public static List<ServiceChannel> getServiceChannels(Integer count, String relatedEntityName, String relatedEntrySecondaryRoutingPriorityField, Boolean generateIds) {
		return (List<ServiceChannel>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ServiceChannel.SObjectType, new Map<SObjectField, Object> {
				ServiceChannel.DeveloperName => 'ServiceChannel_%count%',
				ServiceChannel.RelatedEntity => relatedEntityName,
				ServiceChannel.SecRoutingPriorityField => relatedEntrySecondaryRoutingPriorityField
		}, count), generateIds);
	}
	
	public static List<PendingServiceRouting> getPendingServiceRoutings(Integer count, Id serviceChannelId, Set<Id> workitemIds, Boolean generateIds) {
		return (List<PendingServiceRouting>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PendingServiceRouting.SObjectType, new Map<SObjectField, Object> {
			PendingServiceRouting.CustomRequestedDateTime => Datetime.now(), 
			PendingServiceRouting.WorkItemId => workitemIds,
			PendingServiceRouting.IsReadyForRouting => false,
			PendingServiceRouting.RoutingModel => 'MostAvailable',
			PendingServiceRouting.RoutingType => 'SkillsBased',
			PendingServiceRouting.RoutingPriority => 10,
			PendingServiceRouting.ServiceChannelId => serviceChannelId
		}, count), generateIds);
	}

	public static List<AgentWork> getAgentWorks(Integer count, Id userId, Set<Id> workitemIds, Boolean generateIds) {
		return (List<AgentWork>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(AgentWork.SObjectType, new Map<SObjectField, Object> {
			AgentWork.UserId => userId,
			AgentWork.WorkItemId => workitemIds
		}, count), generateIds);
	}
}
