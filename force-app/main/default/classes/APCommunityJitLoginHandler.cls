/***********************************************************************
Test Class: APCommunityUserUtility_Test

Description:This Jit handler is linked with 'Australia Post Community' community and is responsible for assigning permission set named as 'AP Online Community Membership' 
            to new/existing users ,so that in future if users access to community needs to restricted then it can be done by just removing 'AP Online Community Membership'
            permission set. A new Temp profile 'DDC Consumer Community User Temp' which is a cloned of existing 'DDC Consumer Community User' is used for community user creation,
            so that user access to community is fully controlled by permission set and not by profile 'DDC Consumer Community User'.

            When an user tries to login to 'Australia Post Community' then based on federationIdentifier and 'MyPost ApCommunity' Single sign-on,
            system would identify if it is a new user or existing user and below features would be achieved using APCommunityJitLoginHandler.

            1.In case of New User
                a. A new comunity user record is created with profile as 'DDC Consumer Community User Temp'.
                b. The Temp profile will be active for up to 1-5 seconds until a future job runs.
                c. Future job will assign 'AP Online Community Membership' permission set to newly created user.
                d. Future job will revert back the profile to  'DDC Consumer Community User' for newly created user.

            NOTE:a. Because of Salesforce MIX DML limitation portal user creation and permission set assignment can not be 
                    done synchronously.Hence an asynchrouns future job will be triggerd to assign to 'AP Online Community Membership'
                    permission set and reverting back the profile to 'DDC Consumer Community User'

                 b. Temp profile is used for community user creation, since original profile will not be member of community and user 
                    access to community is controlled by permission set named as 'AP Online Community Membership'.        

            2. In case of Existing User
                  a. A newly created field 'Disallow Community Stepup' will control the access to community.
                  b. if 'Disallow Community Stepup' is true, then user login will be denied and a proper message would be displayed to user.
                  c. If 'Disallow Community Stepup' is false and an inactive user tries to login, then the user will be activated in system and will be logged in successfully.
                  d. If 'Disallow Community Stepup'  is false and an active user having profile as 'DDC Consumer Community User' or 'DDC Consumer Community User Temp' tries to log in , 
                     then they will be assigned with 'AP Online Community Membership' Permission set on the fly if they do not have it assigned already.
            
            NOTE: This class is responsible for  new community user provisioning and update on existing community user record. It is not responsible
                  for update on community user related Account/Contact record.

    History:                     
---------------------------- -------------------------------------------------------------------------------
2019-10-22  arjun.singh@auspost.com.au  Created
************************************************************************/
global class APCommunityJitLoginHandler implements Auth.SamlJitHandler {

    private class JitException extends Exception{}    
    public static final string DISALLOWED_COMMUNITY_SEPTUP_MESSAGE = 'Community Access is restricted' ;
    public static final String AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_NAME = 'AP_Online_Community_Membership' ;    
    public static final String DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME = 'DDC Consumer Community User'; 
    public static final String DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME = 'Consumer Community Temp Access User';
    public static final String APPLICATION_NAME = 'APCommunityCustomJitHandler';

    public static Id ddcCommunityProfileId;
    public static Map<String, Id> profilesMap ;

    public static final Id AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID{
        get{
            if(AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID ==  null){
                AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID = [SELECT id FROM PermissionSet WHERE name =: AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_NAME].Id;
            }
            return AP_ONLINE_COMMUNITY_MEMBERSHIP_PERMISSIONSET_ID;
        }    
        set;
    }
    /**
    * @Description   Returns DDC Community Profile Map       
    * @param          n/a
    * @return          Map<String, Id>
    */
    public Map<String, Id> getProfilesDetails(){
        Map<String, Id> profileMap = new Map<String, Id>();
        Set<String> profilesNameSet = new Set<String>();
        profilesNameSet.add(DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME);
        profilesNameSet.add(DDC_CONSUMER_COMMUNITY_USER_TEMP_PROFILE_NAME);
        for(Profile communityProfile : [Select Id, Name From Profile Where Name IN: profilesNameSet]){            
            profileMap.put(communityProfile.Name, communityProfile.Id);
            if(communityProfile.Name == DDC_CONSUMER_COMMUNITY_USER_PROFILE_NAME){
                ddcCommunityProfileId = communityProfile.Id ; 
            }
        }
        return profileMap;
    }
    /**
     * Method is called in case federationidentifier does not exists in the system
     * and new user provisioning is required before login to Community  
     */
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = new User();
        try{
            handleJit(true, u, samlSsoProviderId, communityId, portalId,
            federationIdentifier, attributes, assertion);
        }Catch (Exception e){
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), APPLICATION_NAME,APCommunityJitLoginHandler.class.getName(), 'createUser',null, LoggingLevel.ERROR);
        }            
        return u;
    }
    /**
     * Method is called in case federationidentifier does exists in the system
     * and user is an existing user and tris to login to community  
     */
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        try{
            User u = APCommunityUserUtility.getCurrentUserDetails(userId); 
            
            // Disallow_Community_Stepup__c attribute is used to control the community access to User. If it is set as true
            // for any user, then they will be denied access to community and a message will be displayed when they try to login to community
            if(u.Disallow_Community_Stepup__c){
                throw new JitException(DISALLOWED_COMMUNITY_SEPTUP_MESSAGE);
            }else{
                handleJit(false, u, samlSsoProviderId, communityId, portalId,
                federationIdentifier, attributes, assertion);
            }
        } Catch (Exception e){
            string errMsg = e.getMessage();
            if(errMsg.contains(DISALLOWED_COMMUNITY_SEPTUP_MESSAGE)){
                throw new JitException(DISALLOWED_COMMUNITY_SEPTUP_MESSAGE);
            }else{
                UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), APPLICATION_NAME,APCommunityJitLoginHandler.class.getName(), 'updateUser',null, LoggingLevel.ERROR);
            }
            
            
        }    
    }
    /**
     * Method is called from either createUser/updateUser
     * with input parameters captures from createUser/updateUser methods 
     */
    public void handleJit(Boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User newUser = new User();
        Account newAccount = new Account();
        profilesMap = getProfilesDetails();        
        if(communityId != null || portalId != null) {
            if(create){
                newAccount =  APCommunityUserUtility.createAPCommunityUserAccount(u, attributes);  
            }          
            newUser = APCommunityUserUtility.createUpdateAPCommunityUser(create, u, newAccount, attributes, federationIdentifier);
        }
    }
}