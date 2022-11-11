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

	private final Map<String, Integer> priorityMappingToSecondaryPriorityRange = new Map<String, Integer>{
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
}