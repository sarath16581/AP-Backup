/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 03/07/2015
  * @description  : Helper Class for FeedItemTrigger
  */
public with sharing class FeedItemTriggerHelper{
    
    // Constants
    private static final String COMMA = ',';
    private static final String PARENT_ID = 'ParentId';
    private static final String ACCESS_ERROR_MSG = 'Error verifying your access. Please contact system administrator.';
    
    // variables
    private static User currentUser{
        get{
            if(currentUser == null){
                currentUser = [SELECT Id,UserRoleId,ProfileId FROM User 
                        WHERE Id =: UserInfo.getUserId() LIMIT 1];
            }
            return currentUser;
        }
    }
    
    private static Set<Id> currentUserPermissionSets{
        get{
            Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());                        // Get Query Row Limit
            if(currentUserPermissionSets == null){
                currentUserPermissionSets = new Set<Id>();
                for(PermissionSetAssignment assgnt : [SELECT Id, PermissionSetId,AssigneeId
                                                        FROM PermissionSetAssignment
                                                        WHERE AssigneeId = :Userinfo.getUserId() 
                                                        LIMIT : rowLimit]){
                    currentUserPermissionSets.add(assgnt.PermissionSetId);
                }
            }
            return currentUserPermissionSets;
        }
    }
    
    /**
      * @description       This method is invoked from FeedItemTriggerHandler &  FeedCommentTriggerHandler to
                           verify if user is authorized to post to chatter group
      * @param             recList - List<SObject> 
      * @return            Void
      * @throws            Method might throw exception which is handled by try-catch block
      */    
    public void verifyAccess(List<SObject> recList){
        
        Map<Id,Set<Id>> grpUserIdMap = new Map<Id,Set<Id>>();   // map of group id and set of users
        Map<Id,Set<Id>> grpProfleIdMap = new Map<Id,Set<Id>>(); // map of group id and set of profiles
        Map<Id,Set<Id>> grpRoleIdMap = new Map<Id,Set<Id>>();   // map of group id and set of roles
        Map<Id,Set<Id>> grpPermissionSetIdMap = new Map<Id,Set<Id>>();   // map of group id and set of permssionset
        
        try{
            // fetch data from custom setting to restrict creating post or comment
            Map<String, AllowChatterPostSettings__c> postSettings = AllowChatterPostSettings__c.getAll(); 
            Set<Id> chatterGroups = new Set<Id>();
            if(postSettings != null & !postSettings.isEmpty()){ // verify if data is available in custom setting
                for(AllowChatterPostSettings__c postSttng : postSettings.values()){
                    if(String.isNotBlank(postSttng.ChatterGroup__c)){
                        chatterGroups.add(postSttng.ChatterGroup__c);
                    }
                    if(!String.isBlank(postSttng.AllowUsers__c)){
                        Set<Id> tmpUserSet = new Set<Id>();
                        tmpUserSet.addAll((List<Id>)TriggerHelper.trimStringList(postSttng.AllowUsers__c.trim().split(COMMA)));   // split multiple records
                        grpUserIdMap.put(postSttng.ChatterGroup__c,tmpUserSet);
                    }
                    if(!String.isBlank(postSttng.AllowProfiles__c)){
                        Set<Id> tmpProfileSet = new Set<Id>();
                        tmpProfileSet.addAll((List<Id>)TriggerHelper.trimStringList(postSttng.AllowProfiles__c.trim().split(COMMA))); // split multiple records
                        grpProfleIdMap.put(postSttng.ChatterGroup__c,tmpProfileSet);
                    }
                    if(!String.isBlank(postSttng.AllowRoles__c)){
                        Set<Id> tmpRoleSet = new Set<Id>();
                        tmpRoleSet.addAll((List<Id>)TriggerHelper.trimStringList(postSttng.AllowRoles__c.trim().split(COMMA)));   // split multiple records
                        grpRoleIdMap.put(postSttng.ChatterGroup__c,tmpRoleSet);
                    }
                    if(!String.isBlank(postSttng.AllowPermissionSet__c)){
                        Set<Id> tmpPermSet = new Set<Id>();
                        tmpPermSet.addAll((List<Id>)TriggerHelper.trimStringList(postSttng.AllowPermissionSet__c.trim().split(COMMA)));   // split multiple records
                        grpPermissionSetIdMap.put(postSttng.ChatterGroup__c,tmpPermSet);
                    }
                }
                System.debug('** grpUserIdMap ==>'+grpUserIdMap);
                System.debug('** grpProfleIdMap ==>'+grpProfleIdMap);
                System.debug('** grpRoleIdMap ==>'+grpRoleIdMap);
                System.debug('** grpPermissionSetIdMap ==>'+grpPermissionSetIdMap);
                
                for(SObject obj : recList){
                    Id parentId = (Id)obj.get(PARENT_ID);
                    if(parentId != null){
                        if((!grpUserIdMap.isEmpty() || !grpProfleIdMap.isEmpty() ||  !grpRoleIdMap.isEmpty() || !grpPermissionSetIdMap.isEmpty()) 
                            && chatterGroups.contains(parentId)){                           
                            Boolean isPermissionSetAvailable = false;
                            Set<Id> fullPermSet = new Set<Id>();
                            if(grpPermissionSetIdMap.containsKey(parentId)){
                                fullPermSet = grpPermissionSetIdMap.get(parentId);
                                System.debug('** currentUserPermissionSets ==>'+currentUserPermissionSets);
                                System.debug('** fullPermSet ==>'+fullPermSet);
                                isPermissionSetAvailable = currentUserPermissionSets.retainAll(fullPermSet) && currentUserPermissionSets.size() > 0;  // check if user's permission set is allowed to post
                            }
                            System.debug('** currentUser ==>'+currentUser);
                            System.debug('** fullPermSet ==>'+fullPermSet);
                            System.debug('** isPermissionSetAvailable ==>'+isPermissionSetAvailable);
                            System.debug('** User ==>'+ (!grpUserIdMap.isEmpty() && grpUserIdMap.containsKey(parentId) && !grpUserIdMap.get(parentId).contains(currentUser.Id)));
                            System.debug('** Profile ==>'+(!grpProfleIdMap.isEmpty() && grpProfleIdMap.containsKey(parentId) && !grpProfleIdMap.get(parentId).contains(currentUser.ProfileId)));
                            System.debug('** Role  ==>'+(!grpRoleIdMap.isEmpty() && grpRoleIdMap.containsKey(parentId) && !grpRoleIdMap.get(parentId).contains(currentUser.UserRoleId)));
                            if((!grpUserIdMap.isEmpty() && grpUserIdMap.containsKey(parentId) && grpUserIdMap.get(parentId).contains(currentUser.Id))
                                || (!grpProfleIdMap.isEmpty() && grpProfleIdMap.containsKey(parentId) && grpProfleIdMap.get(parentId).contains(currentUser.ProfileId))
                                || (!grpRoleIdMap.isEmpty() && grpRoleIdMap.containsKey(parentId) && grpRoleIdMap.get(parentId).contains(currentUser.UserRoleId))
                                || (isPermissionSetAvailable)){
                                continue;
                            }
                            else{
                                obj.addError(Label.CHATTER_POST_ACCESS_MSG);
                            }
                        }
                    }
                }
            }
        }
        catch(Exception exp){
            System.debug('** Stack Trace ==>'+ exp.getStackTraceString());
            for(SObject obj : recList){
                obj.addError(ACCESS_ERROR_MSG);    // throw error message to user in case of failure
            }
        }
    }
    
}