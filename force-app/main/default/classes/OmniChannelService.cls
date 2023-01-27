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
* 1.0	7/25/2019, 2:19:17 PM   rajesh.punjabi@mav3rik.com	 Initial Version
* 1.1	16/08/2022				George Nguyen				Added isOmniGroupUser
* 1.1	04/11/2022				George Nguyen				Added instance and setOmniRoutingSecondaryPriority methods
* 1.2	06/12/2022				Noel Lim					Added inner class WithoutSharingRetrieveData and method getUserIdFromLatestAcceptedAgentWork
**/
public inherited sharing class OmniChannelService {

	static OmniChannelService instance;
	public static OmniChannelService getInstance() {
		if (instance == null) {
			instance = (OmniChannelService) Application.Utilities.newInstance(OmniChannelService.class);
		}
		return instance;
	}

	private final Integer defaultSecondaryPriority = 2500;

	public static CacheFactory Cache {
		get {
			if(Cache == null) {
				Cache = new CacheFactory();
			}
			return Cache;
		}
		private set;
	}

	public String preferredAgentQueueId {
		get {
			if(preferredAgentQueueId == null) {
				preferredAgentQueueId = QM__c.getOrgDefaults().PreferredAgentQueueId__c;
			}
			return preferredAgentQueueId;
		}
		private set;
	}

	public final Map<String, Integer> priorityMappingToSecondaryPriorityRange = new Map<String, Integer>{
		'Critical' => 1000,
		'Urgent' => 1000,
		'Normal' => 2000,
		'High' => 2000,
		'Regular' => 3000,
		'Medium' => 4000,
		'Low' => 5000
	};

	private final Map<Integer, Integer> secondaryPriorityRanges = new Map<Integer, Integer> {
		5000 => 4950,
		4000 => 3950,
		3000 => 2950,
		2000 => 1950,
		1000 => 950
	};

	public void setOmniRoutingSecondaryPriority(List<PendingServiceRouting> psrs) {
		if(psrs.isEmpty() == false) {
			for(PendingServiceRouting psr: psrs) {
				if(String.isBlank(psr.WorkItem.Priority) == false) {
					Integer rangeStart = priorityMappingToSecondaryPriorityRange.get(psr.WorkItem.Priority);
					Integer rangeToSet = rangeStart - psr.WorkItem.CreatedDate.date().daysBetween(Datetime.now().date());
					psr.SecondaryRoutingPriority = Math.max(rangeToSet, secondaryPriorityRanges.get(rangeStart));
				}
			}	
		}
	}

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
	
	/*
	* This method returns a map of CaseIds and UserIds, the UserId is the latest Agent who accepted the Case via Omni routing
	*/
	public Map<Id,AgentWork> getUserIdsFromLatestAcceptedAgentWork(Set<Id> caseIds) {
		Map<Id,AgentWork> result = new Map<Id,AgentWork>();
		List<AgentWork> aws = new WithoutSharingRetrieveData().getLatestAcceptedAgentWorkItems(caseIds);

		for(AgentWork agentWork : aws){
			result.put(agentWork.WorkItemId, agentWork);
		}

		return result;
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

	/**
	 * Required to provide elevated privileges for guest users to query the AgentWork object 
	 */
	public without sharing class WithoutSharingRetrieveData{
		
		private List<AgentWork> getLatestAcceptedAgentWorkItems(Set<Id> caseIds){
			return AgentWorkSelector.newInstance().selectByAcceptedWorkItemIds(caseIds, new Set<Object>());
		}
	}

	public class CacheFactory {
		@TestVisible 
		void resetStaticVariablesForUnitTestOnly() {
			serviceChannels = null;
			CacheManager.put('ALL_SERVICE_CHANNELS', null);
			queuesWithRoutingConfig = null;
			CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', null);
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
						queuesWithRoutingConfig = new Map<Id, QueueWrapper>();
	
						List<Group> queues = [SELECT DeveloperName, QueueRoutingConfigId FROM Group WHERE Type = 'Queue' AND QueueRoutingConfigId != NULL];
						Set<Id> queueRoutingConfigIds = new Set<Id>();	
	
						for(Group queue : queues) {
							queueRoutingConfigIds.add(queue.QueueRoutingConfigId);
						}
	
						if(queueRoutingConfigIds.isEmpty() == false){
							List<QueueRoutingConfig> routingConfigs = [SELECT CapacityPercentage, CapacityWeight, DropAdditionalSkillsTimeout, IsAttributeBased, OverflowAssigneeId, 
																PushTimeout, RoutingModel, RoutingPriority, DeveloperName FROM QueueRoutingConfig WHERE Id IN :queueRoutingConfigIds];
							for(Group queue : queues){
								for(QueueRoutingConfig routingConfig : routingConfigs){
									if(queue.QueueRoutingConfigId == routingConfig.Id){
										queuesWithRoutingConfig.put(queue.Id, new QueueWrapper(queue, routingConfig));
									}
								}					
							}
						}		
	
						CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', queuesWithRoutingConfig);
					}
				}
				return queuesWithRoutingConfig;
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