/*
 * @author George Nguyen
 * @date 2022-11-08
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @description this is where all the test data generation in relation to Omni should go. 
 * @changelog
 * 2022-11-08 - George Nguyen - Created
 * 2023-02-16 - Noel Lim - Added method getQueuesToAgentType
 * 2024-07-22 - Ranjeewa Silva - Method parameter type updates to accept Object type inplace of specified types to promote reuse.
*/
@IsTest
public with sharing class OmniChannelTestDataFactory {

	/**
	 * Returns new ServiceResourceSkill records
	 * @param count number of records to return.
	 * @param skillIds maps to ServiceResourceSkill.SkillId (Supports Id / Set<Id> / List<Id>)
	 * @param serviceResourceIds maps to ServiceResourceSkill.ServiceResourceId (Supports Id / Set<Id> / List<Id>)
	 * @param generateIds generate record ids on new records
	 *
	 * @return new ServiceResourceSkill records.
	 */
	public static List<ServiceResourceSkill> getServiceResourceSkills(Integer count, Object skillIds, Object serviceResourceIds, Boolean generateIds) {
		return (List<ServiceResourceSkill>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ServiceResourceSkill.SObjectType, new Map<SObjectField, Object> {
			ServiceResourceSkill.SkillId => skillIds,
			ServiceResourceSkill.SkillLevel => 1,
			ServiceResourceSkill.ServiceResourceId => serviceResourceIds
		}, count), generateIds);
	}
	
	public static List<ServiceResource> getServiceResources(Integer count, String resourceType, Boolean generateIds) {
		return (List<ServiceResource>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ServiceResource.SObjectType, new Map<SObjectField, Object> {
			ServiceResource.Name => 'ServiceResource_%count%',
			ServiceResource.ResourceType => resourceType,
			ServiceResource.IsActive => true
		}, count), generateIds);
	}	

	public static List<Skill> getSkills(Integer count, Boolean generateIds) {
		return (List<Skill>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Skill.SObjectType, new Map<SObjectField, Object> {
			Skill.DeveloperName => 'Skill_%count%',
			Skill.MasterLabel => 'Skill_%count%'
		}, count), generateIds);
	}	

	public static List<SkillRequirement> getSkillRequirements(Integer count, Set<Id> skillIds, Set<Id> relatedRecordIds, Boolean generateIds) {
		return (List<SkillRequirement>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(SkillRequirement.SObjectType, new Map<SObjectField, Object> {
			SkillRequirement.SkillId => skillIds,
			SkillRequirement.SkillLevel => 1,
			SkillRequirement.RelatedRecordId => relatedRecordIds
		}, count), generateIds);
	}

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

	/**
	 * Returns new AgentWork records
	 *
	 * @param count number of records to return.
	 * @param userIds maps to AgentWork.UserId (Supports Id / Set<Id> / List<Id>)
	 * @param workitemIds maps to AgentWork.WorkItemId (Supports Id / Set<Id> / List<Id>)
	 * @param generateIds generate record ids on new records
	 *
	 * @return new AgentWork records.
	 */
	public static List<AgentWork> getAgentWorks(Integer count, Object userIds, Object workitemIds, Boolean generateIds) {
		return (List<AgentWork>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(AgentWork.SObjectType, new Map<SObjectField, Object> {
			AgentWork.UserId => userIds,
			AgentWork.WorkItemId => workitemIds
		}, count), generateIds);
	}	

	public static Map<String,String> getQueuesToAgentType(Id queueId){
		

		Schema.DescribeFieldResult agentTypeField = Case.AgentType__c.getDescribe();
		List<Schema.PicklistEntry> agentTypePickvals = agentTypeField.getPicklistValues();
		String agentTypeVal;
		for(Schema.PicklistEntry pe : agentTypePickvals){
			if(pe.IsActive()){
				agentTypeVal = pe.getValue();
				break;
			}
		}
		
		return new Map<String,String>{queueId => agentTypeVal};
	}
}