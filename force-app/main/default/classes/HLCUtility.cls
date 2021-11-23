/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 15/06/2015
  * @description  : Utility Class for HLC CR (REQ0490484)
  * @changelog
  * 2021-09-15	seth.heang@auspost.com.au	Uplift SF API version to 52
  */
public without sharing class HLCUtility{
    
    public enum AGENT_QUEUE { HLC, CR } // Enum to store type of queue
    
    // Constants
    public static final String QUEUE = 'QUEUE';
    public static final String HLC_QUEUE = 'SSSW_High_Level_Complaints';
    public static final Set<String> AGENT_QUEUE_SET = new Set<String> {'SSSW_High_Level_Complaints','SSSW_Customer_Recovery'};
    public static final Map<String,String> QUEUE_NAME_MAP = new Map<String,String> {'SSSW_High_Level_Complaints' => 'HLC',
                                                                                      'SSSW_Customer_Recovery' => 'CR'};
    public static final Map<String,String> QUEUE_SEC_MAP = new Map<String,String> {'HLC' => 'HLC / Customer Recovery',
                                                                                      'CR' => 'HLC / Customer Recovery'};
    
    //variables
    public static Set<Id> agentQueueIdSet = new Set<Id>();  // variable used in CaseTriggerHelper to check case ownership and to be accessed after getAgentQueueType
    
    /**
      * @description       This method checks if current user is part of HLC or customer recovery queue
      * @param             NA
      * @return            String
      * @throws            Method might throw exception which is handled by Try-Catch block
      */        
    public static String getAgentQueueType(Id userId){
        String retVal = null;           // return value based on queue
        
        try{
            Map<Id,Group> queueMap = getGroupDetails(AGENT_QUEUE_SET,QUEUE);    // variable to store queue details
            Map<Id,GroupMember> queueMbrMap = getGroupMembers(queueMap.keyset());
            System.debug('** queueMap ==>'+ queueMap);
            System.debug('** queueMbrMap ==>'+ queueMbrMap);
            // verify if current user is part of the HLC or CR queue
            if(queueMbrMap.containsKey(userId)){
                retVal = QUEUE_NAME_MAP.get(queueMap.get(queueMbrMap.get(userId).GroupId).DeveloperName);   // determine queue type based on developername
            }
        }
        catch(Exception exp){
            System.debug('** Stack Trace ==>'+ exp.getStackTraceString());
            retVal = null;
        }
        System.debug('** retVal ==>'+ retVal);
        return retVal;
    }
    
    /**
      * @description       This method hides HLC section for agents not part of HLC or CR queue
      * @param             sectionList - List<CaseDetailsCaseContExt.DetailLayoutSection>
      * @return            List<CaseDetailsCaseContExt.DetailLayoutSection>
      * @throws            NA
      */        
    public static List<CaseDetailsCaseContExt.DetailLayoutSection> getSectionsBasedOnAccess(List<CaseDetailsCaseContExt.DetailLayoutSection> sectionList){
        List<CaseDetailsCaseContExt.DetailLayoutSection> sections = sectionList;
        if(sections != null && !sections.isEmpty()){
            String queueType = getAgentQueueType(UserInfo.getUserId());
            if(String.isBlank(queueType)){
                for(Integer i=0; i < sections.size(); i++){
                    if(String.isNotBlank(sections[i].heading) && ( QUEUE_SEC_MAP.get(AGENT_QUEUE.HLC.name()) != null 
                        && sections[i].heading.equalsIgnoreCase(QUEUE_SEC_MAP.get(AGENT_QUEUE.CR.name())))){
                        sections.remove(i);
                    }
                }
            }
        }
        System.debug('** sections ==>'+ sections);
        return sections;
    }
    
    /**
      * @description       This method returns Queue based on queue api name
      * @param             Set<String> - queueDevNameSet
      * @return            Map<Id,Group>
      * @throws            NA
      */        
    public static Map<Id,Group> getGroupDetails(Set<String> grpDevNameSet,String grpType){
        Map<Id,Group> grpMap = new Map<Id,Group>();
        for(Group  grp : [SELECT Id,DeveloperName FROM Group WHERE Type =: grpType AND DeveloperName IN: grpDevNameSet LIMIT 2]){
            grpMap.put(grp.id,grp);
        }
        System.debug('** grpMap ==>'+ grpMap);
        return grpMap;
    }
    
    /**
      * @description       This method returns gorup members based on group ids
      * @param             Set<Id> - grpIds
      * @return            Map<Id,GroupMember>
      * @throws            NA
      */        
    public static Map<Id,GroupMember> getGroupMembers(Set<Id> grpIds){
        Map<Id,GroupMember> grpMbrMap = new Map<Id,GroupMember>();
        Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());
        for(GroupMember mbr : [SELECT Id,UserOrGroupId,GroupId FROM GroupMember WHERE GroupId IN: grpIds ORDER BY GroupId 
                                LIMIT : rowLimit]){
            grpMbrMap.put(mbr.UserOrGroupId,mbr);
        }
        System.debug('** grpMbrMap ==>'+ grpMbrMap);
        return grpMbrMap;
    }
}