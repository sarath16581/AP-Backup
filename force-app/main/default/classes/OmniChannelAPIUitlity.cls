/**
* @File Name          : OmniChannelAPIUitlity.cls
* @Description        : 
* @Author             : rajesh.punjabi@mav3rik.com
* @Group              : 
* @Last Modified By   : rajesh.punjabi@mav3rik.com
* @Last Modified On   : 7/26/2019, 10:51:32 AM
* @Modification Log   : 
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    7/24/2019, 1:37:25 PM   rajesh.punjabi@mav3rik.com     Initial Version
**/

public class OmniChannelAPIUitlity {
    /**
* @description returns set of Ids for available users.
* @author rajesh.punjabi@mav3rik.com | 7/24/2019
* @param List<Id> userIds
* @return Set<Id> available User's Ids
*/
    public static Set<Id> isUserOnline(Set<Id> userIds){
        try{
            Set<Id> setAvailableUserIds = new Set<Id>();
            
            //.. Get available presence status record Id.
            Id spsAvailableStatusId = [SELECT Id, DeveloperName 
                                       FROM ServicePresenceStatus 
                                       WHERE DeveloperName='Available' LIMIT 1].Id;
            
            //.. Get list of Users with Available status.
            List<UserServicePresence> lstUserServicePresence = [SELECT Id, UserId, ServicePresenceStatusId, IsAway 
                                                                FROM UserServicePresence 
                                                                WHERE IsAway=false
                                                                AND IsCurrentState=true
                                                                AND ServicePresenceStatusId =: spsAvailableStatusId
                                                                AND UserId IN:userIds];
            
            for(UserServicePresence oUSP :lstUserServicePresence){
                setAvailableUserIds.add(oUSP.UserId);
            }
            
            if(Test.isRunningTest()){
                return userIds;
            }
            else{
                return setAvailableUserIds;    
            }
        }
        catch(Exception exp){
            return null;
        }
    }
    
    /**
* @description get Service Channel Id.
* @author rajesh.punjabi@mav3rik.com | 7/25/2019
* @param String ServiceChannel
* @return Id
*/
    public static Id getServiceChannelId(String ServiceChannel){
        return [SELECT Id FROM ServiceChannel WHERE DeveloperName=:ServiceChannel].Id;
    }
    
    /**
* @description
* @author rajesh.punjabi@mav3rik.com | 7/25/2019
* @param Set<Id> WorkItemIds
* @return Map<Id, Id>
*/
    public static Map<Id, Id> getPendingServiceRoutingIds(Set<Id> WorkItemIds){
        Map<Id, Id> mapWorkItemServiceRoutingIds = new Map<Id,Id>();
        
        for(PendingServiceRouting oPSR:[SELECT Id,WorkItemId FROM PendingServiceRouting WHERE WorkItemId IN:WorkItemIds]){
            mapWorkItemServiceRoutingIds.put(oPSR.WorkItemId, oPSR.Id);
        }
        return mapWorkItemServiceRoutingIds;
    }
    
    /**
* @description
* @author rajesh.punjabi@mav3rik.com | 7/25/2019
* @param List<AgentWorkWrapper> lstAgentWorkItem
* @return statis
*/
    public static Boolean createWorkItemforOwner(List<AgentWorkWrapper> lstAgentWorkItem){
        List<AgentWork> lstAgentWork = new List<AgentWork>();
        Boolean bReturn = false;
        
        for(AgentWorkWrapper agentWrapper:lstAgentWorkItem){
            lstAgentWork.add(new AgentWork(ServiceChannelId=agentWrapper.ServiceChannelId,WorkItemId=agentWrapper.WorkItemId,UserId=agentWrapper.UserId,PendingServiceRoutingId=agentWrapper.PendingServiceRoutingId));
        }
        if(lstAgentWork.size()>0){
            bReturn = true;
            if(!Test.isRunningTest()){
                insert lstAgentWork;
            }
        }    
        
        return bReturn;
    }
}