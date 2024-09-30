/**
* @File Name		  : OmniChannelService.cls
* @Description		: To create work item for callback reminders.
* @Author			 : rajesh.punjabi@mav3rik.com
* @Group			  : 
* @Last Modified By   : rajesh.punjabi@mav3rik.com
* @Last Modified On   : 8/8/2019, 10:51:12 AM
* @Modification Log   : 
*==============================================================================
* Ver		 Date					 Author	  			  Modification
*==============================================================================
* 1.0	7/25/2019, 2:19:17 PM   rajesh.punjabi@mav3rik.com	Initial Version
* 1.1	16/08/2022				George Nguyen				Added isOmniGroupUser
* 1.1	04/11/2022				George Nguyen				Added instance and setOmniRoutingSecondaryPriority methods
* 1.2	06/12/2022				Noel Lim					Added inner class WithoutSharingRetrieveData and method getUserIdFromLatestAcceptedAgentWork
*		31/01/2023				Noel Lim					Updated secondaryPriorityRanges from a 50-point range to a 150-point range 
*		01/02/2023				Noel Lim					Update method getUserIdFromLatestAcceptedAgentWork to getCaseIdsWithLatestAcceptedAgentWorks, only return active UserIds. Updated secondaryPriorityRanges from a 50-point range to a 150-point range 
* 		10/02/2023				George Nguyen				Added rerouteCasesWithPreferredAgentByPass and Cache
*		17/03/2023				Noel Lim					Added class variables omniClosedCaseQueueId and omniHoldingQueueId
*		19/04/2023				George Nguyen				Added getUserIdsWithPreferredAgentSkills which gets the list of user ids that have Preferred agent skills
*		16/07/2024				Ranjeewa Silva				Updates to support Unified case routing and preferred agent selection.
*		30/09/2024				Ranjeewa Silva				Updated to use AgentWork.Case__c in finding the latest accepted AgentWork in-scope for a Case.
**/
public inherited sharing class OmniChannelService {

	static OmniChannelService instance;
	public static OmniChannelService getInstance() {
		if (instance == null) {
			instance = (OmniChannelService) Application.Utilities.newInstance(OmniChannelService.class);
		}
		return instance;
	}

	public static CacheFactory Cache {
		get {
			if(Cache == null) {
				Cache = new CacheFactory();
			}
			return Cache;
		}
		private set;
	}

	private final Integer defaultSecondaryPriority = 2500;

	public String preferredAgentQueueId {
		get {
			if(preferredAgentQueueId == null) {
				preferredAgentQueueId = QM__c.getOrgDefaults().PreferredAgentQueueId__c;
			}
			return preferredAgentQueueId;
		}
		private set;
	}

	public String omniClosedCaseQueueId {
		get {
			if(omniClosedCaseQueueId == null) {
				omniClosedCaseQueueId = QM__c.getOrgDefaults().ClosedQueueId__c;
			}
			return omniClosedCaseQueueId;
		}
		private set;
	}

	public String omniHoldingQueueId {
		get {
			if(omniHoldingQueueId == null) {
				omniHoldingQueueId = QM__c.getOrgDefaults().HoldingQueueId__c;
			}
			return omniHoldingQueueId;
		}
		private set;
	}

	public String omniDefaultQueueId {
		get {
			if(omniDefaultQueueId == null) {
				omniDefaultQueueId = QM__c.getOrgDefaults().DefaultOmniQueueId__c;
			}
			return omniDefaultQueueId;
		}
		private set;
	}

	public String omniUnifiedDefaultQueueId {
		get {
			if (omniUnifiedDefaultQueueId == null) {
				omniUnifiedDefaultQueueId = QM__c.getOrgDefaults().UnifiedDefaultOmniQueueId__c;
			}
			return omniUnifiedDefaultQueueId;
		}
		private set;
	}

	public String unifiedMonitoringQueueId {
		get {
			if (unifiedMonitoringQueueId == null) {
				unifiedMonitoringQueueId = QM__c.getOrgDefaults().UnifiedDefaultMonitoringQueueId__c;
			}
			return unifiedMonitoringQueueId;
		}
		private set;
	}

	public static Decimal omniUnifiedPreferredAgentExpiry {
		get {
			if (omniUnifiedPreferredAgentExpiry == null) {
				omniUnifiedPreferredAgentExpiry = QM__c.getOrgDefaults().UnifiedPreferredAgentExpiry__c;
			}
			return omniUnifiedPreferredAgentExpiry;
		}
		private set;
	}

	public static Decimal defaultPreferredAgentExpiry {
		get {
			if (defaultPreferredAgentExpiry == null) {
				defaultPreferredAgentExpiry = QM__c.getOrgDefaults().DefaultPreferredAgentExpiry__c;
			}
			return defaultPreferredAgentExpiry;
		}
		private set;
	}

	// this stores the qualified skills for Preferred Agents
	@TestVisible public Set<String> preferredAgentQualifySkillDeveloperNames {
		get {
			if(preferredAgentQualifySkillDeveloperNames == null) {				
				preferredAgentQualifySkillDeveloperNames = new Set<String>();
				for(String devName: QM__c.getOrgDefaults().PreferredAgentSkillDeveloperNames__c.split(',')) {
					if(String.isBlank(devName) == false) {
						preferredAgentQualifySkillDeveloperNames.add(devName.trim());
					}
				}
			}
			return preferredAgentQualifySkillDeveloperNames;
		}
		private set;
	}

	public List<Case> rerouteCasesWithPreferredAgentByPass(List<PendingServiceRouting> psrs) {
		List<Case> casesToUpdate = new List<Case>();
		for(PendingServiceRouting psr: psrs) {
			casesToUpdate.add(new Case(
				Id = psr.WorkitemId, 
				BypassPreferredAgent__c = true,
				AllocateToQueue__c  = true,
				Bypass_Data_enforcement__c  = true,
				Email_Bypass_Data_enforcement__c = true,
				PreferredAgentExpiry__c = null
			));
		}

		return casesToUpdate;
	}

	public static final Map<String, Integer> priorityMappingToSecondaryPriorityRange = new Map<String, Integer>{
		'Critical' => 1000,
		'Urgent' => 1000,
		'Normal' => 2000,
		'High' => 2000,
		'Regular' => 3000,
		'Medium' => 4000,
		'Low' => 5000
	};

	/*
	* Note these values in the range are assigned to the Case OmniRoutingSecondaryPriority__c picklist field, which has a 1000-value limit.
	*/
	private final Map<Integer, Integer> secondaryPriorityRanges = new Map<Integer, Integer> {
		5000 => 4850,
		4000 => 3850,
		3000 => 2850,
		2000 => 1850,
		1000 => 850
	};

	/*
	* this method calculates the secondary priority value by checking on the diff between the created date and now. 
	* it takes the max between the calculated date and the lower end of the range (omni works by lowest to highest)
	*/
	public Integer calculateSecondaryPriority(String priority, Datetime aDate) {
		Integer rangeStart = priorityMappingToSecondaryPriorityRange.get(priority);
		Integer rangeToSet = rangeStart - aDate.date().daysBetween(Datetime.now().date());
		return Math.max(rangeToSet, secondaryPriorityRanges.get(rangeStart));
	}

	/*
	* This method sets the SecondaryRoutingPriority to a calculated value if the Case's priority is set. 
	* The SecondaryRoutingPriority is being used by Omni to prioritise the case assignment to agents. 
	*/
	public void setOmniRoutingSecondaryPriority(List<PendingServiceRouting> psrs) {
		if(psrs.isEmpty() == false) {
			for(PendingServiceRouting psr: psrs) {
				if(String.isBlank(psr.WorkItem.Priority) == false) {
					psr.SecondaryRoutingPriority = calculateSecondaryPriority(psr.WorkItem.Priority, psr.WorkItem.CreatedDate);
				}
			}	
		}
	}

	/*
	* This method sets the OmniRoutingSecondaryPriority__c on the case. This field is configured in the Omni routing and it is monitored by Omni. 
	* Whenever this field changes and there is a PSR that is open, Omni will update those PRS > SecondaryRoutingPriority to this value. 
	* If a priority is not defined in the priority mapping then it is set to a default value
	* Or else if the setHighestValueOfRange = true it will bypass the calculation and will set it to the highest value from the priority mapping (which is lowest priorty for Omni for that group)
	*/
	public void setOmniRoutingSecondaryPriority(List<Case> cases, Boolean setHighestValueOfRange) {
		if(cases.isEmpty() == false) {
			for(Case c: cases) {
				if(String.isBlank(c.Priority) == false) {
					if(priorityMappingToSecondaryPriorityRange.containsKey(c.Priority) == true) {
						Integer rangeStart = priorityMappingToSecondaryPriorityRange.get(c.Priority);
						if(setHighestValueOfRange == false) {
							Integer rangeToSet = rangeStart - c.CreatedDate.date().daysBetween(Datetime.now().date());
							c.OmniRoutingSecondaryPriority__c = String.valueOf(Math.max(rangeToSet, secondaryPriorityRanges.get(rangeStart)));
						} else {
							c.OmniRoutingSecondaryPriority__c = String.valueOf(rangeStart);
						}
					} else {
						c.OmniRoutingSecondaryPriority__c = String.valueOf(defaultSecondaryPriority);						
					}
				}
			}	
		}
	}
	


	/*
	* Returns a singleton check for current user if they are part of any Omni Group assignment. 
	*/
	public static Boolean currentUserIsPartOfOmniGroup {
		get {
			if(currentUserIsPartOfOmniGroup == null) {
				currentUserIsPartOfOmniGroup = getOmniPresenceDeveloperNameByUserIdOrProfileId(UserInfo.getUserId(), UserInfo.getProfileId()).isEmpty() == false;
			}
			return currentUserIsPartOfOmniGroup;
		}
		private set;
	}

	/*
	* This method returns a unique list of all the DeveloperName of the Omni presence where the userid or profileid has been assigned to
	*/
	static Set<String> getOmniPresenceDeveloperNameByUserIdOrProfileId(Id userId, Id profileId) {
		Set<String> result = new Set<String>();
		if(profileId != null) {
			for(PresenceUserConfigProfile config: [SELECT PresenceUserConfig.DeveloperName FROM PresenceUserConfigProfile WHERE ProfileId =: profileId]) {
				result.add(config.PresenceUserConfig.DeveloperName);
			}
		}
		if(userId != null) {
			for(PresenceUserConfigUser config: [SELECT PresenceUserConfig.DeveloperName FROM PresenceUserConfigUser WHERE UserId =: userId]) {
				result.add(config.PresenceUserConfig.DeveloperName);
			}
		}
		return result;
	}

	/**
	 * Return the latest accepted AgentWork in scope for cases, if available, for each of the case ids passed in.
	 * AgentWork directly on Case record or child records of below sobject types are considered in scope for Cases:
	 *  - ContactRequest
	 *  - LiveChatTranscript
	 *  - VoiceCall
	 *
	 * @param caseIds Set of Case Ids to get latest accepted AgentWork.
	 *
	 * @return Map of latest accepted AgentWork to case Ids passed in. key : case Id, value : AgentWork record
	 *		 Only work items with accepted AgentWork record are included in the map.
	 */
	public Map<Id, AgentWork> getLatestAcceptedAgentWorkInCaseScope(Set<Id> caseIds) {
		Map<Id, AgentWork> results = new Map<Id, AgentWork>();
		// we need to find the last accepted AgentWork for each case considering AgentWork on Case and child interaction
		// records (ContactRequest, Voice, Chat). AgentWork on Case and it's related child interaction records have
		// AgentWork.Case__c field populated by automation (See CaseRecordPopulationModule and AgentWorkCaseAutomationModule).
		// this makes it easier to find latest accepted AgentWork in scope for case records.
		for(AgentWork aw: new WithoutSharingRetrieveData().getLatestAcceptedAgentWorkItems(caseIds)) {
			// list returned by selector is sorted AcceptedDate DESC so we only need to take the first AgentWork on each case.
			if(!results.containsKey(aw.Case__c)) {
				results.put(aw.Case__c, aw);
			}
		}
		return results;
	}

	/**
	* @description create work item for agents if agent is online.
	* @author rajesh.punjabi@mav3rik.com | 8/8/2019
	* @param List<Callback_Request__c> lstCallbackReminders
	* @return void
	*/
	public static Boolean assignRemindertoAgent(List<Callback_Request__c> lstCallbackReminders){
		Boolean bReturn = false;
		List<AgentWorkWrapper> lstAgentWorkWrapper = new List<AgentWorkWrapper>();   
		AgentWorkWrapper agentWorkWrap;
		Id serviceChannelId = OmniChannelAPIUitlity.getServiceChannelId('Callback_Request_Channel');
		Map<Id, Id> mapWorkItemPendingRoutingIds = OmniChannelAPIUitlity.getPendingServiceRoutingIds((new Map<Id,Callback_Request__c>(lstCallbackReminders)).keySet());
		
		for(Callback_Request__c lstCR:lstCallbackReminders){
			agentWorkWrap = new AgentWorkWrapper();
			agentWorkWrap.ServiceChannelId = serviceChannelId;
			agentWorkWrap.WorkItemId = lstCR.Id;
			agentWorkWrap.UserId = lstCR.CreatedById;
			agentWorkWrap.PendingServiceRoutingId = mapWorkItemPendingRoutingIds.get(lstCR.Id);
			lstAgentWorkWrapper.add(agentWorkWrap); 
		}
		if(Test.isRunningTest()){
			bReturn = true;	
		}
		else{
			if(lstAgentWorkWrapper.size()>0){
				OmniChannelAPIUitlity.createWorkItemforOwner(lstAgentWorkWrapper);
			}	
		}
		
		return bReturn;
	}

	/*
	* This method returns a set of userids that have the specified skills 
	*/
	public Set<Id> getUserIdsWithPreferredAgentSkills(Set<Id> userIds) {
		Set<Id> result = new Set<Id>();
		for(ServiceResourceSkill srs: new WithoutSharingRetrieveData().getPreferredAgentServiceResourceSkills(userIds)) {
			result.add(srs.ServiceResource.RelatedRecordId);
		}
		return result;
	}

	/**
	 * Verify agents eligibility to work on items assigned to omni-channel queues.
	 *  - If work item is assigned to a queue configured for 'Skills-Based' routing, an eligible preferred agent must
	 *	possess required skills.
	 *  - If work item is assigned to a queue configured for 'Queue-Based' routing, an eligible preferred agent must
	 *	be a queue member.
	 *
	 * @param verifiableAgentEligibility agents to check eligibility for specified queue. key : queue Id, value : set of user ids to check.
	 *
	 * @return eligible agents for each queue. key : queue id, value : set of eligible agent user ids
	 */
	public Map<Id, Set<Id>> verifyEligibilityForOmniChannelQueues(Map<Id, Set<Id>> verifiableAgentEligibility) {

		Map<Id, Set<Id>> queueBasedEligibility = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> skillsBasedEligibility = new Map<Id, Set<Id>>();

		for (Id omniQueueId: verifiableAgentEligibility.keySet()) {
			// get omni routing configuration linked to this omni-enabled queue.
			QueueRoutingConfig routingConfiguration = OmniChannelService.Cache.queuesWithRoutingConfig.get(omniQueueId)?.routingConfiguration;
			if (routingConfiguration != null && routingConfiguration.IsAttributeBased) {
				// skill based routing check
				skillsBasedEligibility.put(omniQueueId, verifiableAgentEligibility.get(omniQueueId));
			} else if (routingConfiguration != null){
				// queue based routing check
				queueBasedEligibility.put(omniQueueId, verifiableAgentEligibility.get(omniQueueId));
			}
		}

		Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();
		if (!skillsBasedEligibility.isEmpty()) {
			results.putAll(verifySkillBasedEligibility(skillsBasedEligibility));
		}
		if (!queueBasedEligibility.isEmpty()) {
			results.putAll(verifyQueueBasedEligibility(queueBasedEligibility));
		}

		return results;
	}

	/**
	 * Check eligibility of agents to work on items assigned to 'Queue Based' omni channel queues. Eligibility is checked
	 * only for the supplied agent users.
	 *
	 * @param verifiableQueueBasedEligibility agents to check membership for specified queue. key : queue Id, value : set of user ids to check.
	 *
	 * @return eligible agents for each queue. key : queue id, value : set of eligible agent user ids
	 */
	private Map<Id, Set<Id>> verifyQueueBasedEligibility(Map<Id, Set<Id>> verifiableQueueBasedEligibility) {

		// find eligible users for the queues. we need to consider other public groups who are members of the queue too.
		// for current use case we only support below 2 scenarios:
		//	  - Users configured as direct member of the omni queue
		//	  - Users who are direct members of a public group that is configured as a member of the omni queue
		// all other scenarios are no supported.
		Map<Id, Set<Id>> eligibleQueueMembers = expandGroupMemberUsers(verifiableQueueBasedEligibility.keySet(), true);

		Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();
		for (Id queueId: eligibleQueueMembers.keySet()) {
			Set<Id> agentIds = eligibleQueueMembers.get(queueId);
			// check if we are asked to verify membership of 'agentIds' for the queue.
			// we should only return group members for the memberships we are requested to check.
			agentIds.retainAll(verifiableQueueBasedEligibility.get(queueId));
			results.put(queueId, agentIds);
		}

		return results;
	}

	/**
	 * Expand group membership for specified public groups and return the users who are group members.
	 *
	 * Supports expanding nested public groups only one level deep if 'expandDirectMemberGroups' is set to true.
	 *
	 * @param groupIds public group ids
	 * @param expandDirectMemberGroups if true, include users who are direct members of child groups of specified groups.
	 *
	 * @return group membership mapping, key - group id (from groupIds parameter), value - member user ids
	 */
	private Map<Id, Set<Id>> expandGroupMemberUsers(Set<Id> groupIds, Boolean expandDirectMemberGroups) {
		Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();

		// query public groups by group ids. also retrieve direct members of these groups. direct members can be a user
		// or another group based on the configuration.
		Map<Id, Group> groups = new WithoutSharingRetrieveData().getGroupsWithDirectMembers(groupIds);

		// store group id mappings for child groups that are direct members of parent groups queried. note that one
		// child group could be a member of multiple parent groups.
		// key - child group id, value - set of parent group ids.
		Map<Id, Set<Id>> nestedGroupMappings = new Map<Id, Set<Id>>();

		for (Group groupRecord: groups.values()) {
			// we need to return the member users for each group
			results.put(groupRecord.Id, new Set<Id>());

			for (GroupMember member: groupRecord.GroupMembers) {
				if (member.UserOrGroupId.getSobjectType() == User.SObjectType) {
					// direct member is a User. add to the results to be returned.
					results.get(groupRecord.Id).add(member.UserOrGroupId);
				} else if (expandDirectMemberGroups) {
					// direct member is a Group and we need to expand this nested group to find it's direct member users.
					// store the mapping in 'nestedGroupMappings' so we can resolve memberships for the parent group at the end.
					Set<Id> parentGroups = nestedGroupMappings.get(member.UserOrGroupId);
					if (parentGroups == null) {
						parentGroups = new Set<Id>();
						nestedGroupMappings.put(member.UserOrGroupId, parentGroups);
					}
					parentGroups.add(member.GroupId);
				}
			}
		}

		if (expandDirectMemberGroups && !nestedGroupMappings.isEmpty()) {
			// 'expandDirectMemberGroups = true' and we have found child groups which are direct members of the groups passed in.
			// recursively call this method, but this time with 'expandDirectMemberGroups = false'.
			// for this use case, we are only interested in users who are direct members of the identified child groups.
			Map<Id, Set<Id>> nestedGroupMemberUsers = expandGroupMemberUsers(nestedGroupMappings.keySet(), false);
			for (Id nestedGroupId: nestedGroupMemberUsers.keySet()) {
				// we now have member users for child groups we expanded.
				Set<Id> memberUsers = nestedGroupMemberUsers.get(nestedGroupId);
				// we need to map them back to the parent group ids passed into this method before returning.
				for (Id parentGroupId: nestedGroupMappings.get(nestedGroupId)) {
					results.get(parentGroupId).addAll(memberUsers);
				}
			}
		}

		return results;
	}

	/**
	 * Check eligibility of agents to work on items assigned to skills based omni channel queues. Eligibility is checked
	 * only for the supplied agent users.
	 *
	 * @param verifiableSkillsEligibility agents to check skills for omni channel queues - key : queue id, value : Set of user Ids to check.
	 *
	 * @return eligible agents for each queue. key : queue id, value : set of eligible agent user ids
	 */
	private Map<Id, Set<Id>> verifySkillBasedEligibility(Map<Id, Set<Id>> verifiableSkillsEligibility) {
		Set<Id> agentIds = new Set<Id>();
		for (Set<Id> userIds: verifiableSkillsEligibility.values()) {
			agentIds.addAll(userIds);
		}

		// call method currently used by SSSW cases to check preferred agent skills. however this is checking the agents
		// possess a org specific set of skills configured in org wide custom setting - QM__c.getOrgDefaults().PreferredAgentSkillDeveloperNames__c
		Set<Id> agentsQualifiedBySkills = getUserIdsWithPreferredAgentSkills(agentIds);

		Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();
		for (Id omniQueueId: verifiableSkillsEligibility.keySet()) {
			Set<Id> verifiable = new Set<Id>(verifiableSkillsEligibility.get(omniQueueId));
			verifiable.retainAll(agentsQualifiedBySkills);
			results.put(omniQueueId, verifiable);
		}
		return results;
	}

	/**
	 * Required to provide elevated privileges for guest users to query the AgentWork object
	 */
	public without sharing class WithoutSharingRetrieveData{

		private List<AgentWork> getLatestAcceptedAgentWorkItems(Set<Id> caseIds){
			return AgentWorkSelector.newInstance(0, new Set<SObjectField>{AgentWork.Id, AgentWork.WorkItemId, AgentWork.UserId, AgentWork.AcceptDateTime}).selectAcceptedAgentWorkByCaseIdsAndActiveUser(caseIds, new Set<Object>());
		}

		private List<ServiceResourceSkill> getPreferredAgentServiceResourceSkills(Set<Id> userIds){
			Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				ServiceResourceSkill.SObjectType => new Set<SObjectField>{ServiceResourceSkill.Id, ServiceResourceSkill.ServiceResourceId},
				ServiceResource.SObjectType => new Set<SObjectField>{ServiceResource.RelatedRecordId}
			};
			return ServiceResourceSkillSelector.newInstance(0, fieldOverrides).selectByActiveServiceResourceRelatedRecordIdsAndSkills(userIds, OmniChannelService.getInstance().preferredAgentQualifySkillDeveloperNames, new Set<Object> { ServiceResourceSkillSelector.Options.WITH_SERVICE_RESOURCE });
		}

		private Map<Id, QueueWrapper> getQueuesWithRoutingConfigs() {
			Map<Id, QueueWrapper> queuesWithRoutingConfig = new Map<Id, QueueWrapper>();

			// platform currently don't allow querying related QueueRoutingConfig fields from Group. hence we need
			// to query omni queues from Group first and then separately query QueueRoutingConfig.
			Map<Id, Group> queueGroups = ((GroupsSelector)GroupsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
					Group.Id, Group.DeveloperName, Group.QueueRoutingConfigId
			})).selectOmniQueues(new Set<Object>());

			Set<Id> queueRoutingConfigIds = new Set<Id>();
			for(Group queue : queueGroups.values()) {
				queueRoutingConfigIds.add(queue.QueueRoutingConfigId);
			}

			if (!queueRoutingConfigIds.isEmpty()) {

				Set<SObjectField> fieldOverrides = new Set<SObjectField>{
						QueueRoutingConfig.CapacityPercentage, QueueRoutingConfig.CapacityWeight, QueueRoutingConfig.DropAdditionalSkillsTimeout,
						QueueRoutingConfig.IsAttributeBased, QueueRoutingConfig.OverflowAssigneeId, QueueRoutingConfig.PushTimeout,
						QueueRoutingConfig.RoutingModel, QueueRoutingConfig.RoutingPriority, QueueRoutingConfig.DeveloperName
				};

				Map<Id, QueueRoutingConfig> routingConfigs = new Map<Id, QueueRoutingConfig>(
						((QueueRoutingConfigSelector)QueueRoutingConfigSelector.newInstance().setFieldOverrides(fieldOverrides)).selectById(queueRoutingConfigIds)
				);

				for(Group queue : queueGroups.values()){
					QueueRoutingConfig routingConfig = routingConfigs.get(queue.QueueRoutingConfigId);
					if (routingConfig != null) {
						queuesWithRoutingConfig.put(queue.Id, new QueueWrapper(queue, routingConfig));
					}
				}
			}

			return queuesWithRoutingConfig;
		}

		private Map<Id, Group> getGroupsWithDirectMembers(Set<Id> groupIds) {
			Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
					Group.SObjectType => new Set<SObjectField>{Group.Id, Group.Type},
					GroupMember.SObjectType => new Set<SObjectField>{
							GroupMember.Id, GroupMember.GroupId, GroupMember.UserOrGroupId
					}
			};

			return ((GroupsSelector)GroupsSelector.newInstance().setFieldOverrides(fieldOverrides)).selectById(groupIds, new Set<Object>{
					GroupsSelector.Options.WITH_DIRECT_MEMBERS
			});
		}
	}

	public class CacheFactory {
		@TestVisible 
		void resetStaticVariablesForUnitTestOnly() {
			serviceChannels = null;
			CacheManager.put('ALL_SERVICE_CHANNELS', null);
			queuesWithRoutingConfig = null;
			CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', null);
			queuesToAgentType = null;
			CacheManager.put('QUEUES_TO_AGENT_TYPE', null);
		}

		public Map<String, ServiceChannel> serviceChannels {
			get {
				if(serviceChannels == null) {
					serviceChannels = (Map<String, ServiceChannel>)CacheManager.get('ALL_SERVICE_CHANNELS');
					if(serviceChannels == null) {
						serviceChannels = new Map<String, ServiceChannel>();
						for(ServiceChannel sc: [SELECT AfterConvoWorkMaxTime,DeveloperName,DoesMinimizeWidgetOnAccept,HasAfterConvoWorkTimer,RelatedEntity,SecRoutingPriorityField FROM ServiceChannel]) {
							serviceChannels.put(sc.DeveloperName, sc);
						}
						CacheManager.put('ALL_SERVICE_CHANNELS', serviceChannels);
					}
				}
				return serviceChannels;
			}
			private set;
		}

		public Map<Id, QueueWrapper> queuesWithRoutingConfig {
			get {
				if(queuesWithRoutingConfig == null) {
					queuesWithRoutingConfig = (Map<Id, QueueWrapper>)CacheManager.get('QUEUES_WITH_ROUTING_CONFIG');
					if(queuesWithRoutingConfig == null) {
						queuesWithRoutingConfig = (new WithoutSharingRetrieveData()).getQueuesWithRoutingConfigs();
						
						CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', queuesWithRoutingConfig);
					}
				}
				return queuesWithRoutingConfig;
			}
			private set;
		}

		public Map<String, String> queuesToAgentType {
			get {
				if(queuesToAgentType == null) {
					queuesToAgentType = (Map<String, String>)CacheManager.get('QUEUES_TO_AGENT_TYPE');
					if(queuesToAgentType == null) {
						queuesToAgentType = new Map<String, String>();
	
						List<SSSW_Queue_to_Agent_Type__mdt> queueAgentTypes = [SELECT QueueId__c, AgentType__c from SSSW_Queue_to_Agent_Type__mdt];
						for(SSSW_Queue_to_Agent_Type__mdt qat : queueAgentTypes){
							queuesToAgentType.put(qat.QueueId__c,qat.AgentType__c);
						}
	
						CacheManager.put('QUEUES_TO_AGENT_TYPE', queuesToAgentType);
					}
				}
				return queuesToAgentType;
			}
			private set;
		}
	}

	public class QueueWrapper {
		public Group queue {get; private set;}
		public QueueRoutingConfig routingConfiguration {get; private set;}

		public QueueWrapper(Group inputQueue, QueueRoutingConfig inputRoutingConfig) {
			queue = inputQueue;
			routingConfiguration = inputRoutingConfig;
		}
	}
}